import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../data/local_storage_repository.dart';
import '../models/app_models.dart';
import '../models/default_data.dart';

class HospitalAppState extends ChangeNotifier {
  HospitalAppState({
    required this.repository,
  });

  final LocalStorageRepository repository;
  final Uuid _uuid = const Uuid();

  bool initialized = false;
  int tabIndex = 0;
  String patientSearchQuery = '';
  bool patientInHospitalOnly = false;
  String templateSearchQuery = '';
  String fieldConfigModule = 'patient';

  AppData data = AppData.empty();
  SecuritySettings security = const SecuritySettings(
    passwordEnabled: false,
    passwordValue: '',
  );
  bool sessionUnlocked = true;
  String? _lastErrorMessage;

  String? takeLastErrorMessage() {
    final msg = _lastErrorMessage;
    _lastErrorMessage = null;
    return msg;
  }

  String createRuntimeId(String prefix) => _createId(prefix);

  Future<void> initialize() async {
    final snapshot = await repository.load();
    if (snapshot == null) {
      data = buildDefaultAppData(_createId);
      security = const SecuritySettings(passwordEnabled: false, passwordValue: '');
    } else {
      data = snapshot.data;
      security = snapshot.security;
    }
    _repairAndNormalizeData();
    sessionUnlocked = !isPasswordEnabled;
    initialized = true;
    notifyListeners();
  }

  String _createId(String prefix) {
    final random = _uuid.v4().substring(0, 8);
    return '${prefix}_${DateTime.now().millisecondsSinceEpoch}_$random';
  }

  void setTab(int index) {
    if (tabIndex == index) return;
    tabIndex = index;
    notifyListeners();
  }

  bool get isPasswordEnabled {
    return security.passwordEnabled && security.passwordValue.isNotEmpty;
  }

  int get patientCount => data.patients.length;

  int get inHospitalCount => getInHospitalPatientNoSet().length;

  List<PatientRecord> get patients {
    final rows = List<PatientRecord>.from(data.patients);
    rows.sort((a, b) => a.admissionNo.compareTo(b.admissionNo));
    return rows;
  }

  List<PatientRecord> get filteredPatients {
    final keyword = patientSearchQuery.trim().toLowerCase();
    final inHospitalSet = getInHospitalPatientNoSet();

    return patients.where((row) {
      if (patientInHospitalOnly && !inHospitalSet.contains(row.admissionNo)) {
        return false;
      }
      if (keyword.isEmpty) return true;
      final no = row.admissionNo.toLowerCase();
      final name = (row.values['name'] ?? '').toString().toLowerCase();
      return no.contains(keyword) || name.contains(keyword);
    }).toList();
  }

  Set<String> getInHospitalPatientNoSet() {
    return data.admissions
        .where((row) => (row.values['status'] ?? '').toString() == '在院')
        .map((e) => e.admissionNo)
        .toSet();
  }

  List<AdmissionRecord> admissionsOf(String admissionNo) {
    final rows = data.admissions
        .where((row) => row.admissionNo == admissionNo)
        .toList(growable: false);
    rows.sort((a, b) {
      final ad = (a.values['admitDate'] ?? '').toString();
      final bd = (b.values['admitDate'] ?? '').toString();
      return bd.compareTo(ad);
    });
    return rows;
  }

  List<DailyRecord> dailyOf(String admissionId) {
    final rows = data.dailyRecords
        .where((row) => row.admissionId == admissionId)
        .toList(growable: false);
    rows.sort((a, b) {
      final ad = (a.values['recordDate'] ?? '').toString();
      final bd = (b.values['recordDate'] ?? '').toString();
      return bd.compareTo(ad);
    });
    return rows;
  }

  List<AssessmentRecord> assessmentsOf(String admissionId) {
    final rows = List<AssessmentRecord>.from(
      data.admissionAssessments[admissionId] ?? const <AssessmentRecord>[],
    );
    rows.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return rows;
  }

  List<ImagingItem> imagingOf(String admissionId) {
    return List<ImagingItem>.from(
      data.admissionImaging[admissionId] ?? const <ImagingItem>[],
    );
  }

  PatientRecord? findPatient(String admissionNo) {
    return data.patients.cast<PatientRecord?>().firstWhere(
          (row) => row?.admissionNo == admissionNo,
          orElse: () => null,
        );
  }

  AdmissionRecord? findAdmission(String id) {
    return data.admissions.cast<AdmissionRecord?>().firstWhere(
          (row) => row?.id == id,
          orElse: () => null,
        );
  }

  DailyRecord? findDaily(String id) {
    return data.dailyRecords.cast<DailyRecord?>().firstWhere(
          (row) => row?.id == id,
          orElse: () => null,
        );
  }

  void setPatientSearchQuery(String value) {
    patientSearchQuery = value;
    notifyListeners();
  }

  void toggleInHospitalFilter() {
    patientInHospitalOnly = !patientInHospitalOnly;
    notifyListeners();
  }

  bool hasInHospitalAdmission(String admissionNo) {
    return data.admissions.any(
      (row) =>
          row.admissionNo == admissionNo &&
          (row.values['status'] ?? '').toString() == '在院',
    );
  }

  bool upsertPatient({
    required Map<String, dynamic> values,
    String? editingAdmissionNo,
  }) {
    _lastErrorMessage = null;
    final admissionNo = (values['admissionNo'] ?? '').toString().trim();
    if (admissionNo.isEmpty) {
      _lastErrorMessage = '住院号不能为空';
      return false;
    }

    final duplicated = data.patients.any(
      (row) => row.admissionNo == admissionNo && row.admissionNo != editingAdmissionNo,
    );
    if (duplicated) {
      _lastErrorMessage = '住院号已存在';
      return false;
    }

    final payload = _applySchemaCoercion(values, schemaOf('patient'));
    payload['admissionNo'] = admissionNo;

    if (editingAdmissionNo != null) {
      data = data.copyWith(
        patients: data.patients.map((row) {
          if (row.admissionNo != editingAdmissionNo) return row;
          return PatientRecord(admissionNo: editingAdmissionNo, values: payload);
        }).toList(),
      );
    } else {
      final rows = List<PatientRecord>.from(data.patients);
      rows.insert(0, PatientRecord(admissionNo: admissionNo, values: payload));
      data = data.copyWith(patients: rows);
    }

    _persistDataAndNotify();
    return true;
  }

  void deletePatient(String admissionNo) {
    final affectedAdmissionIds = data.admissions
        .where((row) => row.admissionNo == admissionNo)
        .map((row) => row.id)
        .toSet();

    final nextAssessments = Map<String, List<AssessmentRecord>>.from(data.admissionAssessments)
      ..removeWhere((key, _) => affectedAdmissionIds.contains(key));
    final nextImaging = Map<String, List<ImagingItem>>.from(data.admissionImaging)
      ..removeWhere((key, _) => affectedAdmissionIds.contains(key));

    data = data.copyWith(
      patients: data.patients.where((row) => row.admissionNo != admissionNo).toList(),
      admissions: data.admissions.where((row) => row.admissionNo != admissionNo).toList(),
      dailyRecords: data.dailyRecords
          .where((row) => !affectedAdmissionIds.contains(row.admissionId))
          .toList(),
      admissionAssessments: nextAssessments,
      admissionImaging: nextImaging,
    );
    _persistDataAndNotify();
  }

  bool upsertAdmission({
    required String admissionNo,
    required Map<String, dynamic> values,
    String? editingId,
  }) {
    _lastErrorMessage = null;

    if (editingId == null && hasInHospitalAdmission(admissionNo)) {
      _lastErrorMessage = '该病人已有在院记录，不能重复新增入院';
      return false;
    }

    final payload = _applySchemaCoercion(values, schemaOf('admission'));
    payload['admissionNo'] = admissionNo;
    payload['admitDate'] = (payload['admitDate'] ?? '').toString();

    if ((payload['admitDate'] ?? '').toString().isEmpty) {
      _lastErrorMessage = '入院日期不能为空';
      return false;
    }

    if (editingId != null) {
      data = data.copyWith(
        admissions: data.admissions.map((row) {
          if (row.id != editingId) return row;
          return AdmissionRecord(
            id: row.id,
            admissionNo: admissionNo,
            values: <String, dynamic>{
              ...row.values,
              ...payload,
              '_id': row.id,
              'admissionNo': admissionNo,
            },
          );
        }).toList(),
      );
    } else {
      final id = _createId('adm');
      final rows = List<AdmissionRecord>.from(data.admissions);
      rows.insert(
        0,
        AdmissionRecord(
          id: id,
          admissionNo: admissionNo,
          values: <String, dynamic>{
            ...payload,
            '_id': id,
            'admissionNo': admissionNo,
          },
        ),
      );
      data = data.copyWith(admissions: rows);
    }

    _persistDataAndNotify();
    return true;
  }

  void deleteAdmission(String admissionId) {
    final nextAssessments = Map<String, List<AssessmentRecord>>.from(data.admissionAssessments)
      ..remove(admissionId);
    final nextImaging = Map<String, List<ImagingItem>>.from(data.admissionImaging)
      ..remove(admissionId);

    data = data.copyWith(
      admissions: data.admissions.where((row) => row.id != admissionId).toList(),
      dailyRecords: data.dailyRecords
          .where((row) => row.admissionId != admissionId)
          .toList(),
      admissionAssessments: nextAssessments,
      admissionImaging: nextImaging,
    );
    _persistDataAndNotify();
  }

  bool upsertDaily({
    required String admissionId,
    required Map<String, dynamic> values,
    String? editingId,
  }) {
    _lastErrorMessage = null;
    final payload = _applySchemaCoercion(values, schemaOf('daily'));
    if ((payload['recordDate'] ?? '').toString().isEmpty) {
      _lastErrorMessage = '记录日期不能为空';
      return false;
    }

    if (editingId != null) {
      data = data.copyWith(
        dailyRecords: data.dailyRecords.map((row) {
          if (row.id != editingId) return row;
          return DailyRecord(
            id: row.id,
            admissionId: admissionId,
            values: <String, dynamic>{
              ...row.values,
              ...payload,
              '_id': row.id,
              'admissionId': admissionId,
            },
          );
        }).toList(),
      );
    } else {
      final id = _createId('daily');
      final rows = List<DailyRecord>.from(data.dailyRecords);
      rows.add(
        DailyRecord(
          id: id,
          admissionId: admissionId,
          values: <String, dynamic>{
            ...payload,
            '_id': id,
            'admissionId': admissionId,
          },
        ),
      );
      data = data.copyWith(dailyRecords: rows);
    }

    _persistDataAndNotify();
    return true;
  }

  void deleteDaily(String dailyId) {
    data = data.copyWith(
      dailyRecords: data.dailyRecords.where((row) => row.id != dailyId).toList(),
    );
    _persistDataAndNotify();
  }

  void addImaging(String admissionId, List<ImagingItem> items) {
    if (items.isEmpty) return;
    final merged = <ImagingItem>[
      ...imagingOf(admissionId),
      ...items,
    ];
    final next = Map<String, List<ImagingItem>>.from(data.admissionImaging)
      ..[admissionId] = merged;
    data = data.copyWith(admissionImaging: next);
    _persistDataAndNotify();
  }

  void removeImaging(String admissionId, String imageId) {
    final remain = imagingOf(admissionId).where((e) => e.id != imageId).toList();
    final next = Map<String, List<ImagingItem>>.from(data.admissionImaging);
    if (remain.isEmpty) {
      next.remove(admissionId);
    } else {
      next[admissionId] = remain;
    }
    data = data.copyWith(admissionImaging: next);
    _persistDataAndNotify();
  }

  void upsertAssessment({
    required String admissionId,
    required AssessmentRecord record,
    String? editingId,
  }) {
    final rows = assessmentsOf(admissionId);
    if (editingId == null) {
      rows.add(record);
    } else {
      final idx = rows.indexWhere((e) => e.id == editingId);
      if (idx >= 0) {
        rows[idx] = record;
      } else {
        rows.add(record);
      }
    }
    final next = Map<String, List<AssessmentRecord>>.from(data.admissionAssessments)
      ..[admissionId] = rows;
    data = data.copyWith(admissionAssessments: next);
    _persistDataAndNotify();
  }

  void deleteAssessment(String admissionId, String assessmentId) {
    final remain = assessmentsOf(admissionId).where((e) => e.id != assessmentId).toList();
    final next = Map<String, List<AssessmentRecord>>.from(data.admissionAssessments);
    if (remain.isEmpty) {
      next.remove(admissionId);
    } else {
      next[admissionId] = remain;
    }
    data = data.copyWith(admissionAssessments: next);
    _persistDataAndNotify();
  }

  TemplateDisease? findDisease(String diseaseId) {
    for (final disease in data.templates) {
      if (disease.id == diseaseId) return disease;
    }
    return null;
  }

  TemplateVersion? findVersion(String diseaseId, String versionId) {
    final disease = findDisease(diseaseId);
    if (disease == null) return null;
    for (final version in disease.versions) {
      if (version.id == versionId) return version;
    }
    return null;
  }

  String resolveAssessmentLevel(TemplateVersion version, double score) {
    for (final rule in version.gradeRules) {
      if (score >= rule.min && score <= rule.max) {
        return rule.level;
      }
    }
    return '未分级';
  }

  double calculateAssessmentScore(TemplateVersion version, Map<String, String> selections) {
    var total = 0.0;
    for (final item in version.items) {
      final selectedId = selections[item.id];
      if (selectedId == null) continue;
      for (final option in item.options) {
        if (option.id == selectedId) {
          total += option.score;
          break;
        }
      }
    }
    return total;
  }

  List<TemplateDisease> get filteredTemplateDiseases {
    final keyword = templateSearchQuery.trim().toLowerCase();
    if (keyword.isEmpty) return data.templates;
    return data.templates.where((disease) {
      final name = disease.diseaseName.toLowerCase();
      final code = disease.diseaseCode.toLowerCase();
      return name.contains(keyword) || code.contains(keyword);
    }).toList();
  }

  void setTemplateSearchQuery(String value) {
    templateSearchQuery = value;
    notifyListeners();
  }

  bool upsertTemplateDisease({
    String? editingId,
    required String diseaseName,
    required String diseaseCode,
    required String description,
  }) {
    final name = diseaseName.trim();
    if (name.isEmpty) return false;

    final rows = List<TemplateDisease>.from(data.templates);
    if (editingId == null) {
      rows.insert(
        0,
        TemplateDisease(
          id: _createId('tpld'),
          diseaseName: name,
          diseaseCode: diseaseCode.trim(),
          description: description.trim(),
          versions: const <TemplateVersion>[],
        ),
      );
    } else {
      final idx = rows.indexWhere((e) => e.id == editingId);
      if (idx < 0) return false;
      final current = rows[idx];
      rows[idx] = TemplateDisease(
        id: current.id,
        diseaseName: name,
        diseaseCode: diseaseCode.trim(),
        description: description.trim(),
        versions: current.versions,
      );
    }

    data = data.copyWith(templates: rows);
    _persistDataAndNotify();
    return true;
  }

  void deleteTemplateDisease(String diseaseId) {
    data = data.copyWith(
      templates: data.templates.where((e) => e.id != diseaseId).toList(),
    );
    _persistDataAndNotify();
  }

  bool upsertTemplateVersion({
    required String diseaseId,
    String? editingId,
    required String versionName,
    required String year,
    required String description,
  }) {
    final diseaseIdx = data.templates.indexWhere((e) => e.id == diseaseId);
    if (diseaseIdx < 0) return false;
    final disease = data.templates[diseaseIdx];
    final versions = List<TemplateVersion>.from(disease.versions);
    if (editingId == null) {
      versions.insert(
        0,
        TemplateVersion(
          id: _createId('tplv'),
          versionName: versionName.trim().isEmpty ? '未命名版本' : versionName.trim(),
          year: year.trim(),
          description: description.trim(),
          items: const <TemplateItem>[],
          gradeRules: const <TemplateGradeRule>[],
        ),
      );
    } else {
      final idx = versions.indexWhere((e) => e.id == editingId);
      if (idx < 0) return false;
      final current = versions[idx];
      versions[idx] = TemplateVersion(
        id: current.id,
        versionName: versionName.trim().isEmpty ? current.versionName : versionName.trim(),
        year: year.trim(),
        description: description.trim(),
        items: current.items,
        gradeRules: current.gradeRules,
      );
    }

    final diseases = List<TemplateDisease>.from(data.templates);
    diseases[diseaseIdx] = TemplateDisease(
      id: disease.id,
      diseaseName: disease.diseaseName,
      diseaseCode: disease.diseaseCode,
      description: disease.description,
      versions: versions,
    );
    data = data.copyWith(templates: diseases);
    _persistDataAndNotify();
    return true;
  }

  void deleteTemplateVersion(String diseaseId, String versionId) {
    final diseaseIdx = data.templates.indexWhere((e) => e.id == diseaseId);
    if (diseaseIdx < 0) return;
    final disease = data.templates[diseaseIdx];
    final versions = disease.versions.where((e) => e.id != versionId).toList();
    final diseases = List<TemplateDisease>.from(data.templates);
    diseases[diseaseIdx] = TemplateDisease(
      id: disease.id,
      diseaseName: disease.diseaseName,
      diseaseCode: disease.diseaseCode,
      description: disease.description,
      versions: versions,
    );
    data = data.copyWith(templates: diseases);
    _persistDataAndNotify();
  }

  bool upsertTemplateItem({
    required String diseaseId,
    required String versionId,
    String? editingId,
    required String name,
    required List<TemplateOption> options,
  }) {
    final versionRef = _locateVersion(diseaseId, versionId);
    if (versionRef == null) return false;
    final items = List<TemplateItem>.from(versionRef.version.items);
    if (editingId == null) {
      items.add(
        TemplateItem(
          id: _createId('tpli'),
          name: name.trim().isEmpty ? '未命名测评项' : name.trim(),
          options: options,
        ),
      );
    } else {
      final idx = items.indexWhere((e) => e.id == editingId);
      if (idx < 0) return false;
      items[idx] = TemplateItem(
        id: editingId,
        name: name.trim().isEmpty ? items[idx].name : name.trim(),
        options: options,
      );
    }
    _patchVersion(
      versionRef: versionRef,
      version: TemplateVersion(
        id: versionRef.version.id,
        versionName: versionRef.version.versionName,
        year: versionRef.version.year,
        description: versionRef.version.description,
        items: items,
        gradeRules: versionRef.version.gradeRules,
      ),
    );
    return true;
  }

  void deleteTemplateItem(String diseaseId, String versionId, String itemId) {
    final versionRef = _locateVersion(diseaseId, versionId);
    if (versionRef == null) return;
    final items = versionRef.version.items.where((e) => e.id != itemId).toList();
    _patchVersion(
      versionRef: versionRef,
      version: TemplateVersion(
        id: versionRef.version.id,
        versionName: versionRef.version.versionName,
        year: versionRef.version.year,
        description: versionRef.version.description,
        items: items,
        gradeRules: versionRef.version.gradeRules,
      ),
    );
  }

  bool upsertTemplateGradeRule({
    required String diseaseId,
    required String versionId,
    String? editingId,
    required double min,
    required double max,
    required String level,
    required String note,
  }) {
    final versionRef = _locateVersion(diseaseId, versionId);
    if (versionRef == null) return false;
    final rules = List<TemplateGradeRule>.from(versionRef.version.gradeRules);
    if (editingId == null) {
      rules.add(
        TemplateGradeRule(
          id: _createId('tplg'),
          min: min,
          max: max,
          level: level.trim().isEmpty ? '未命名等级' : level.trim(),
          note: note.trim(),
        ),
      );
    } else {
      final idx = rules.indexWhere((e) => e.id == editingId);
      if (idx < 0) return false;
      rules[idx] = TemplateGradeRule(
        id: editingId,
        min: min,
        max: max,
        level: level.trim().isEmpty ? rules[idx].level : level.trim(),
        note: note.trim(),
      );
    }
    _patchVersion(
      versionRef: versionRef,
      version: TemplateVersion(
        id: versionRef.version.id,
        versionName: versionRef.version.versionName,
        year: versionRef.version.year,
        description: versionRef.version.description,
        items: versionRef.version.items,
        gradeRules: rules,
      ),
    );
    return true;
  }

  void deleteTemplateGradeRule(String diseaseId, String versionId, String ruleId) {
    final versionRef = _locateVersion(diseaseId, versionId);
    if (versionRef == null) return;
    final rules = versionRef.version.gradeRules.where((e) => e.id != ruleId).toList();
    _patchVersion(
      versionRef: versionRef,
      version: TemplateVersion(
        id: versionRef.version.id,
        versionName: versionRef.version.versionName,
        year: versionRef.version.year,
        description: versionRef.version.description,
        items: versionRef.version.items,
        gradeRules: rules,
      ),
    );
  }

  List<FieldSchema> schemaOf(String moduleKey) {
    return List<FieldSchema>.from(data.schemas[moduleKey] ?? const <FieldSchema>[]);
  }

  List<FieldSchema> listSchemaOf(String moduleKey) {
    return schemaOf(moduleKey).where((field) => field.showInList).toList();
  }

  void setFieldConfigModule(String moduleKey) {
    fieldConfigModule = moduleKey;
    notifyListeners();
  }

  bool addCustomField(String moduleKey, FieldSchema field) {
    _lastErrorMessage = null;
    final schema = schemaOf(moduleKey);
    if (schema.any((e) => e.key == field.key)) {
      _lastErrorMessage = '字段键名重复';
      return false;
    }
    final next = <String, List<FieldSchema>>{
      ...data.schemas,
      moduleKey: <FieldSchema>[...schema, field],
    };
    data = data.copyWith(schemas: next);
    _backfillField(moduleKey, field.key, _defaultValueForField(field));
    _persistDataAndNotify();
    return true;
  }

  bool updateField(String moduleKey, String oldKey, FieldSchema updated) {
    _lastErrorMessage = null;
    final schema = schemaOf(moduleKey);
    final idx = schema.indexWhere((e) => e.key == oldKey);
    if (idx < 0) {
      _lastErrorMessage = '字段不存在';
      return false;
    }
    if (oldKey != updated.key && schema.any((e) => e.key == updated.key)) {
      _lastErrorMessage = '字段键名重复';
      return false;
    }
    if (isCoreRequiredField(moduleKey, oldKey) && oldKey != updated.key) {
      _lastErrorMessage = '核心字段不允许修改键名';
      return false;
    }

    if (oldKey != updated.key) {
      _renameField(moduleKey, oldKey, updated.key);
    }
    schema[idx] = updated;

    final next = <String, List<FieldSchema>>{
      ...data.schemas,
      moduleKey: schema,
    };
    data = data.copyWith(schemas: next);
    _enforceCoreFieldRules();
    _persistDataAndNotify();
    return true;
  }

  bool deleteField(String moduleKey, String key) {
    _lastErrorMessage = null;
    if (isCoreRequiredField(moduleKey, key)) {
      _lastErrorMessage = '核心字段不允许删除';
      return false;
    }
    final schema = schemaOf(moduleKey);
    final idx = schema.indexWhere((e) => e.key == key);
    if (idx < 0) {
      _lastErrorMessage = '字段不存在';
      return false;
    }
    schema.removeAt(idx);
    final next = <String, List<FieldSchema>>{
      ...data.schemas,
      moduleKey: schema,
    };
    data = data.copyWith(schemas: next);
    _dropFieldFromRows(moduleKey, key);
    _persistDataAndNotify();
    return true;
  }

  void toggleFieldVisibility(String moduleKey, String key, bool visible) {
    final schema = schemaOf(moduleKey);
    final idx = schema.indexWhere((e) => e.key == key);
    if (idx < 0) return;
    final target = schema[idx];
    final safeVisible = moduleKey == 'patient' && key == 'admissionNo' ? false : visible;
    schema[idx] = target.copyWith(showInList: safeVisible);
    final next = <String, List<FieldSchema>>{
      ...data.schemas,
      moduleKey: schema,
    };
    data = data.copyWith(schemas: next);
    _persistDataAndNotify();
  }

  void reorderFields(String moduleKey, int oldIndex, int newIndex) {
    final schema = schemaOf(moduleKey);
    if (oldIndex < 0 || oldIndex >= schema.length) return;
    var targetIndex = newIndex;
    if (targetIndex > oldIndex) {
      targetIndex -= 1;
    }
    if (targetIndex < 0 || targetIndex >= schema.length) return;
    final item = schema.removeAt(oldIndex);
    schema.insert(targetIndex, item);
    final next = <String, List<FieldSchema>>{
      ...data.schemas,
      moduleKey: schema,
    };
    data = data.copyWith(schemas: next);
    _persistDataAndNotify();
  }

  bool isCoreRequiredField(String moduleKey, String key) {
    return (moduleKey == 'patient' && key == 'admissionNo') ||
        (moduleKey == 'admission' && key == 'admitDate');
  }

  String exportDataJson() {
    return data.toPrettyJson();
  }

  Future<bool> importDataFromJson(String jsonText) async {
    final text = jsonText.trim();
    if (text.isEmpty) return false;
    try {
      final raw = jsonDecode(text);
      if (raw is! Map) return false;
      final parsed = raw.map((key, value) => MapEntry(key.toString(), value));
      final candidate = (parsed['data'] is Map)
          ? (parsed['data'] as Map).map((key, value) => MapEntry(key.toString(), value))
          : parsed;
      data = AppData.fromJson(candidate);
      _repairAndNormalizeData();
      await repository.saveData(data);
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> enableOrChangePassword(String password) async {
    security = security.copyWith(
      passwordEnabled: true,
      passwordValue: password,
    );
    sessionUnlocked = true;
    await repository.saveSecurity(security);
    notifyListeners();
  }

  Future<void> disablePassword() async {
    security = security.copyWith(
      passwordEnabled: false,
      passwordValue: '',
    );
    sessionUnlocked = true;
    await repository.saveSecurity(security);
    notifyListeners();
  }

  bool verifyPassword(String password) {
    if (!isPasswordEnabled) return true;
    final ok = password == security.passwordValue;
    sessionUnlocked = ok;
    notifyListeners();
    return ok;
  }

  void lockSession() {
    if (!isPasswordEnabled) return;
    sessionUnlocked = false;
    notifyListeners();
  }

  void _persistDataAndNotify() {
    _repairAndNormalizeData();
    unawaited(repository.saveData(data));
    notifyListeners();
  }

  void _repairAndNormalizeData() {
    _enforceCoreFieldRules();
    _repairSchemas();
    _repairRows();
    _repairRelations();
    _repairTemplatePayload();
  }

  void _enforceCoreFieldRules() {
    final patientSchema = schemaOf('patient');
    final pIdx = patientSchema.indexWhere((e) => e.key == 'admissionNo');
    if (pIdx >= 0) {
      patientSchema[pIdx] = patientSchema[pIdx].copyWith(
        required: true,
        locked: true,
        showInList: false,
      );
      data = data.copyWith(
        schemas: <String, List<FieldSchema>>{
          ...data.schemas,
          'patient': patientSchema,
        },
      );
    }

    final admissionSchema = schemaOf('admission');
    final aIdx = admissionSchema.indexWhere((e) => e.key == 'admitDate');
    if (aIdx >= 0) {
      admissionSchema[aIdx] = admissionSchema[aIdx].copyWith(
        required: true,
        locked: true,
      );
      data = data.copyWith(
        schemas: <String, List<FieldSchema>>{
          ...data.schemas,
          'admission': admissionSchema,
        },
      );
    }
  }

  void _repairSchemas() {
    final requiredModules = <String>[
      'patient',
      'admission',
      'daily',
      'templateDisease',
      'templateVersion',
    ];
    final next = <String, List<FieldSchema>>{...data.schemas};
    for (final module in requiredModules) {
      next[module] = List<FieldSchema>.from(next[module] ?? const <FieldSchema>[]);
    }
    data = data.copyWith(schemas: next);
  }

  void _repairRows() {
    final patientSchema = schemaOf('patient');
    final admissionSchema = schemaOf('admission');
    final dailySchema = schemaOf('daily');

    final repairedPatients = data.patients
        .where((row) => row.admissionNo.trim().isNotEmpty)
        .map((row) {
      final map = _fillDefaults(row.values, patientSchema);
      map['admissionNo'] = row.admissionNo;
      return PatientRecord(admissionNo: row.admissionNo, values: map);
    }).toList();

    final repairedAdmissions = data.admissions
        .where((row) => row.id.trim().isNotEmpty && row.admissionNo.trim().isNotEmpty)
        .map((row) {
      final map = _fillDefaults(row.values, admissionSchema);
      map['_id'] = row.id;
      map['admissionNo'] = row.admissionNo;
      return AdmissionRecord(id: row.id, admissionNo: row.admissionNo, values: map);
    }).toList();

    final admissionIdSet = repairedAdmissions.map((e) => e.id).toSet();
    final repairedDaily = data.dailyRecords
        .where((row) => row.id.trim().isNotEmpty && admissionIdSet.contains(row.admissionId))
        .map((row) {
      final map = _fillDefaults(row.values, dailySchema);
      map['_id'] = row.id;
      map['admissionId'] = row.admissionId;
      return DailyRecord(id: row.id, admissionId: row.admissionId, values: map);
    }).toList();

    data = data.copyWith(
      patients: repairedPatients,
      admissions: repairedAdmissions,
      dailyRecords: repairedDaily,
    );
  }

  void _repairRelations() {
    final admissionIdSet = data.admissions.map((e) => e.id).toSet();

    final nextAssessments = <String, List<AssessmentRecord>>{};
    for (final entry in data.admissionAssessments.entries) {
      if (!admissionIdSet.contains(entry.key)) continue;
      final rows = entry.value.where((e) => e.id.trim().isNotEmpty).toList();
      if (rows.isNotEmpty) {
        nextAssessments[entry.key] = rows;
      }
    }

    final nextImaging = <String, List<ImagingItem>>{};
    for (final entry in data.admissionImaging.entries) {
      if (!admissionIdSet.contains(entry.key)) continue;
      final rows = entry.value.where((e) => e.src.trim().isNotEmpty).toList();
      if (rows.isNotEmpty) {
        nextImaging[entry.key] = rows;
      }
    }

    data = data.copyWith(
      admissionAssessments: nextAssessments,
      admissionImaging: nextImaging,
    );
  }

  void _repairTemplatePayload() {
    final next = data.templates.map((disease) {
      final versions = disease.versions.map((version) {
        final items = version.items.map((item) {
          final options = item.options
              .where((opt) => opt.id.trim().isNotEmpty)
              .toList();
          return TemplateItem(
            id: item.id,
            name: item.name,
            options: options,
          );
        }).toList();
        final rules = version.gradeRules
            .where((rule) => rule.id.trim().isNotEmpty)
            .toList();
        return TemplateVersion(
          id: version.id,
          versionName: version.versionName,
          year: version.year,
          description: version.description,
          items: items,
          gradeRules: rules,
        );
      }).toList();
      return TemplateDisease(
        id: disease.id,
        diseaseName: disease.diseaseName,
        diseaseCode: disease.diseaseCode,
        description: disease.description,
        versions: versions,
      );
    }).toList();

    data = data.copyWith(templates: next);
  }

  Map<String, dynamic> _fillDefaults(
    Map<String, dynamic> source,
    List<FieldSchema> schema,
  ) {
    final next = <String, dynamic>{...source};
    for (final field in schema) {
      if (!next.containsKey(field.key)) {
        next[field.key] = _defaultValueForField(field);
      }
    }
    return next;
  }

  Map<String, dynamic> _applySchemaCoercion(
    Map<String, dynamic> source,
    List<FieldSchema> schema,
  ) {
    final next = <String, dynamic>{...source};
    for (final field in schema) {
      if (!next.containsKey(field.key)) continue;
      final value = next[field.key];
      if (field.type == FieldType.number) {
        final parsed = num.tryParse((value ?? '').toString());
        next[field.key] = parsed?.toString() ?? '';
      } else if (field.type == FieldType.images) {
        if (value is List<ImagingItem>) {
          next[field.key] = value.map((e) => e.toJson()).toList();
        } else if (value is List) {
          next[field.key] = value;
        } else {
          next[field.key] = <dynamic>[];
        }
      } else {
        next[field.key] = (value ?? '').toString();
      }
    }
    return next;
  }

  dynamic _defaultValueForField(FieldSchema field) {
    switch (field.type) {
      case FieldType.select:
        return field.options.isNotEmpty ? field.options.first : '';
      case FieldType.images:
        return <dynamic>[];
      default:
        return '';
    }
  }

  void _dropFieldFromRows(String moduleKey, String key) {
    if (moduleKey == 'patient') {
      data = data.copyWith(
        patients: data.patients.map((row) {
          final values = <String, dynamic>{...row.values}..remove(key);
          return PatientRecord(admissionNo: row.admissionNo, values: values);
        }).toList(),
      );
      return;
    }
    if (moduleKey == 'admission') {
      data = data.copyWith(
        admissions: data.admissions.map((row) {
          final values = <String, dynamic>{...row.values}..remove(key);
          return AdmissionRecord(id: row.id, admissionNo: row.admissionNo, values: values);
        }).toList(),
      );
      return;
    }
    if (moduleKey == 'daily') {
      data = data.copyWith(
        dailyRecords: data.dailyRecords.map((row) {
          final values = <String, dynamic>{...row.values}..remove(key);
          return DailyRecord(id: row.id, admissionId: row.admissionId, values: values);
        }).toList(),
      );
    }
  }

  void _backfillField(String moduleKey, String key, dynamic value) {
    if (moduleKey == 'patient') {
      data = data.copyWith(
        patients: data.patients.map((row) {
          if (row.values.containsKey(key)) return row;
          final values = <String, dynamic>{...row.values, key: value};
          return PatientRecord(admissionNo: row.admissionNo, values: values);
        }).toList(),
      );
      return;
    }
    if (moduleKey == 'admission') {
      data = data.copyWith(
        admissions: data.admissions.map((row) {
          if (row.values.containsKey(key)) return row;
          final values = <String, dynamic>{...row.values, key: value};
          return AdmissionRecord(id: row.id, admissionNo: row.admissionNo, values: values);
        }).toList(),
      );
      return;
    }
    if (moduleKey == 'daily') {
      data = data.copyWith(
        dailyRecords: data.dailyRecords.map((row) {
          if (row.values.containsKey(key)) return row;
          final values = <String, dynamic>{...row.values, key: value};
          return DailyRecord(id: row.id, admissionId: row.admissionId, values: values);
        }).toList(),
      );
    }
  }

  void _renameField(String moduleKey, String oldKey, String newKey) {
    if (moduleKey == 'patient') {
      data = data.copyWith(
        patients: data.patients.map((row) {
          final values = <String, dynamic>{...row.values};
          if (values.containsKey(oldKey)) {
            values[newKey] = values[oldKey];
            values.remove(oldKey);
          }
          return PatientRecord(admissionNo: row.admissionNo, values: values);
        }).toList(),
      );
      return;
    }
    if (moduleKey == 'admission') {
      data = data.copyWith(
        admissions: data.admissions.map((row) {
          final values = <String, dynamic>{...row.values};
          if (values.containsKey(oldKey)) {
            values[newKey] = values[oldKey];
            values.remove(oldKey);
          }
          return AdmissionRecord(id: row.id, admissionNo: row.admissionNo, values: values);
        }).toList(),
      );
      return;
    }
    if (moduleKey == 'daily') {
      data = data.copyWith(
        dailyRecords: data.dailyRecords.map((row) {
          final values = <String, dynamic>{...row.values};
          if (values.containsKey(oldKey)) {
            values[newKey] = values[oldKey];
            values.remove(oldKey);
          }
          return DailyRecord(id: row.id, admissionId: row.admissionId, values: values);
        }).toList(),
      );
    }
  }

  _VersionRef? _locateVersion(String diseaseId, String versionId) {
    final diseaseIndex = data.templates.indexWhere((e) => e.id == diseaseId);
    if (diseaseIndex < 0) return null;
    final disease = data.templates[diseaseIndex];
    final versionIndex = disease.versions.indexWhere((e) => e.id == versionId);
    if (versionIndex < 0) return null;
    return _VersionRef(
      diseaseIndex: diseaseIndex,
      versionIndex: versionIndex,
      disease: disease,
      version: disease.versions[versionIndex],
    );
  }

  void _patchVersion({
    required _VersionRef versionRef,
    required TemplateVersion version,
  }) {
    final diseases = List<TemplateDisease>.from(data.templates);
    final versions = List<TemplateVersion>.from(versionRef.disease.versions);
    versions[versionRef.versionIndex] = version;
    diseases[versionRef.diseaseIndex] = TemplateDisease(
      id: versionRef.disease.id,
      diseaseName: versionRef.disease.diseaseName,
      diseaseCode: versionRef.disease.diseaseCode,
      description: versionRef.disease.description,
      versions: versions,
    );
    data = data.copyWith(templates: diseases);
    _persistDataAndNotify();
  }
}

class _VersionRef {
  _VersionRef({
    required this.diseaseIndex,
    required this.versionIndex,
    required this.disease,
    required this.version,
  });

  final int diseaseIndex;
  final int versionIndex;
  final TemplateDisease disease;
  final TemplateVersion version;
}
