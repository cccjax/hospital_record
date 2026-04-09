import 'dart:convert';

enum FieldType {
  text,
  number,
  date,
  textarea,
  select,
  images,
}

FieldType fieldTypeFromString(String value) {
  switch (value) {
    case 'number':
      return FieldType.number;
    case 'date':
      return FieldType.date;
    case 'textarea':
      return FieldType.textarea;
    case 'select':
      return FieldType.select;
    case 'images':
      return FieldType.images;
    case 'text':
    default:
      return FieldType.text;
  }
}

String fieldTypeToString(FieldType value) {
  switch (value) {
    case FieldType.number:
      return 'number';
    case FieldType.date:
      return 'date';
    case FieldType.textarea:
      return 'textarea';
    case FieldType.select:
      return 'select';
    case FieldType.images:
      return 'images';
    case FieldType.text:
      return 'text';
  }
}

class FieldSchema {
  const FieldSchema({
    required this.key,
    required this.label,
    required this.type,
    required this.required,
    required this.locked,
    required this.showInList,
    required this.computed,
    required this.options,
  });

  final String key;
  final String label;
  final FieldType type;
  final bool required;
  final bool locked;
  final bool showInList;
  final bool computed;
  final List<String> options;

  FieldSchema copyWith({
    String? key,
    String? label,
    FieldType? type,
    bool? required,
    bool? locked,
    bool? showInList,
    bool? computed,
    List<String>? options,
  }) {
    return FieldSchema(
      key: key ?? this.key,
      label: label ?? this.label,
      type: type ?? this.type,
      required: required ?? this.required,
      locked: locked ?? this.locked,
      showInList: showInList ?? this.showInList,
      computed: computed ?? this.computed,
      options: options ?? this.options,
    );
  }

  factory FieldSchema.fromJson(Map<String, dynamic> json) {
    return FieldSchema(
      key: (json['key'] ?? '').toString(),
      label: (json['label'] ?? '').toString(),
      type: fieldTypeFromString((json['type'] ?? 'text').toString()),
      required: json['required'] == true,
      locked: json['locked'] == true,
      showInList: json['showInList'] != false,
      computed: json['computed'] == true,
      options: (json['options'] is List)
          ? (json['options'] as List)
              .map((e) => e.toString())
              .where((e) => e.isNotEmpty)
              .toList()
          : const [],
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'key': key,
      'label': label,
      'type': fieldTypeToString(type),
      'required': required,
      'locked': locked,
      'showInList': showInList,
      if (computed) 'computed': true,
      if (options.isNotEmpty) 'options': options,
    };
  }
}

class PatientRecord {
  PatientRecord({
    required this.admissionNo,
    required this.values,
  }) {
    values['admissionNo'] = admissionNo;
  }

  final String admissionNo;
  final Map<String, dynamic> values;

  factory PatientRecord.fromJson(Map<String, dynamic> json) {
    final cloned = _cloneMap(json);
    final admissionNo = (cloned['admissionNo'] ?? '').toString();
    return PatientRecord(
      admissionNo: admissionNo,
      values: cloned,
    );
  }

  Map<String, dynamic> toJson() {
    final cloned = _cloneMap(values);
    cloned['admissionNo'] = admissionNo;
    return cloned;
  }
}

class AdmissionRecord {
  AdmissionRecord({
    required this.id,
    required this.admissionNo,
    required this.values,
  }) {
    values['admissionNo'] = admissionNo;
  }

  final String id;
  final String admissionNo;
  final Map<String, dynamic> values;

  factory AdmissionRecord.fromJson(Map<String, dynamic> json) {
    final cloned = _cloneMap(json);
    final id = (cloned['_id'] ?? cloned['id'] ?? '').toString();
    final admissionNo = (cloned['admissionNo'] ?? '').toString();
    return AdmissionRecord(
      id: id,
      admissionNo: admissionNo,
      values: cloned,
    );
  }

  Map<String, dynamic> toJson() {
    final cloned = _cloneMap(values);
    cloned['_id'] = id;
    cloned['admissionNo'] = admissionNo;
    return cloned;
  }
}

class DailyRecord {
  DailyRecord({
    required this.id,
    required this.admissionId,
    required this.values,
  }) {
    values['admissionId'] = admissionId;
  }

  final String id;
  final String admissionId;
  final Map<String, dynamic> values;

  factory DailyRecord.fromJson(Map<String, dynamic> json) {
    final cloned = _cloneMap(json);
    final id = (cloned['_id'] ?? cloned['id'] ?? '').toString();
    final admissionId = (cloned['admissionId'] ?? '').toString();
    return DailyRecord(
      id: id,
      admissionId: admissionId,
      values: cloned,
    );
  }

  Map<String, dynamic> toJson() {
    final cloned = _cloneMap(values);
    cloned['_id'] = id;
    cloned['admissionId'] = admissionId;
    return cloned;
  }
}

class ImagingItem {
  const ImagingItem({
    required this.id,
    required this.src,
    required this.name,
  });

  final String id;
  final String src;
  final String name;

  factory ImagingItem.fromJson(Map<String, dynamic> json) {
    return ImagingItem(
      id: (json['id'] ?? '').toString(),
      src: (json['src'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'src': src,
      'name': name,
    };
  }
}

class TemplateOption {
  const TemplateOption({
    required this.id,
    required this.label,
    required this.score,
  });

  final String id;
  final String label;
  final double score;

  factory TemplateOption.fromJson(Map<String, dynamic> json) {
    return TemplateOption(
      id: (json['id'] ?? '').toString(),
      label: (json['label'] ?? '').toString(),
      score: _toDouble(json['score']),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'label': label,
      'score': score,
    };
  }
}

class TemplateItem {
  const TemplateItem({
    required this.id,
    required this.name,
    required this.options,
  });

  final String id;
  final String name;
  final List<TemplateOption> options;

  factory TemplateItem.fromJson(Map<String, dynamic> json) {
    return TemplateItem(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      options: (json['options'] is List)
          ? (json['options'] as List)
              .whereType<Map>()
              .map((e) => TemplateOption.fromJson(_cloneMap(e)))
              .toList()
          : const [],
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'options': options.map((e) => e.toJson()).toList(),
    };
  }
}

class TemplateGradeRule {
  const TemplateGradeRule({
    required this.id,
    required this.min,
    required this.max,
    required this.level,
    required this.note,
  });

  final String id;
  final double min;
  final double max;
  final String level;
  final String note;

  factory TemplateGradeRule.fromJson(Map<String, dynamic> json) {
    return TemplateGradeRule(
      id: (json['id'] ?? '').toString(),
      min: _toDouble(json['min']),
      max: _toDouble(json['max']),
      level: (json['level'] ?? '').toString(),
      note: (json['note'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'min': min,
      'max': max,
      'level': level,
      'note': note,
    };
  }
}

class TemplateVersion {
  const TemplateVersion({
    required this.id,
    required this.versionName,
    required this.year,
    required this.description,
    required this.items,
    required this.gradeRules,
    this.extraValues = const <String, dynamic>{},
  });

  final String id;
  final String versionName;
  final String year;
  final String description;
  final List<TemplateItem> items;
  final List<TemplateGradeRule> gradeRules;
  final Map<String, dynamic> extraValues;

  factory TemplateVersion.fromJson(Map<String, dynamic> json) {
    final raw = _cloneMap(json);
    const knownKeys = <String>{
      'id',
      'versionName',
      'year',
      'description',
      'items',
      'gradeRules',
    };
    final extras = <String, dynamic>{};
    for (final entry in raw.entries) {
      if (!knownKeys.contains(entry.key)) {
        extras[entry.key] = entry.value;
      }
    }
    return TemplateVersion(
      id: (raw['id'] ?? '').toString(),
      versionName: (raw['versionName'] ?? '').toString(),
      year: (raw['year'] ?? '').toString(),
      description: (raw['description'] ?? '').toString(),
      items: (raw['items'] is List)
          ? (raw['items'] as List)
              .whereType<Map>()
              .map((e) => TemplateItem.fromJson(_cloneMap(e)))
              .toList()
          : const [],
      gradeRules: (raw['gradeRules'] is List)
          ? (raw['gradeRules'] as List)
              .whereType<Map>()
              .map((e) => TemplateGradeRule.fromJson(_cloneMap(e)))
              .toList()
          : const [],
      extraValues: extras,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      ...extraValues,
      'id': id,
      'versionName': versionName,
      'year': year,
      'description': description,
      'items': items.map((e) => e.toJson()).toList(),
      'gradeRules': gradeRules.map((e) => e.toJson()).toList(),
    };
  }
}

class TemplateDisease {
  const TemplateDisease({
    required this.id,
    required this.diseaseName,
    required this.diseaseCode,
    required this.description,
    required this.versions,
    this.extraValues = const <String, dynamic>{},
  });

  final String id;
  final String diseaseName;
  final String diseaseCode;
  final String description;
  final List<TemplateVersion> versions;
  final Map<String, dynamic> extraValues;

  factory TemplateDisease.fromJson(Map<String, dynamic> json) {
    final raw = _cloneMap(json);
    const knownKeys = <String>{
      'id',
      'diseaseName',
      'diseaseCode',
      'description',
      'versions',
    };
    final extras = <String, dynamic>{};
    for (final entry in raw.entries) {
      if (!knownKeys.contains(entry.key)) {
        extras[entry.key] = entry.value;
      }
    }
    return TemplateDisease(
      id: (raw['id'] ?? '').toString(),
      diseaseName: (raw['diseaseName'] ?? '').toString(),
      diseaseCode: (raw['diseaseCode'] ?? '').toString(),
      description: (raw['description'] ?? '').toString(),
      versions: (raw['versions'] is List)
          ? (raw['versions'] as List)
              .whereType<Map>()
              .map((e) => TemplateVersion.fromJson(_cloneMap(e)))
              .toList()
          : const [],
      extraValues: extras,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      ...extraValues,
      'id': id,
      'diseaseName': diseaseName,
      'diseaseCode': diseaseCode,
      'description': description,
      'versions': versions.map((e) => e.toJson()).toList(),
    };
  }
}

class AssessmentRecord {
  const AssessmentRecord({
    required this.id,
    required this.diseaseId,
    required this.versionId,
    required this.selections,
    required this.createdAt,
  });

  final String id;
  final String diseaseId;
  final String versionId;
  final Map<String, String> selections;
  final DateTime createdAt;

  factory AssessmentRecord.fromJson(Map<String, dynamic> json) {
    final selectionsRaw = _cloneMap(json['selections']);
    return AssessmentRecord(
      id: (json['id'] ?? '').toString(),
      diseaseId: (json['diseaseId'] ?? '').toString(),
      versionId: (json['versionId'] ?? '').toString(),
      selections: selectionsRaw.map(
        (key, value) => MapEntry(key.toString(), value.toString()),
      ),
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()) ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'diseaseId': diseaseId,
      'versionId': versionId,
      'selections': selections,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class SecuritySettings {
  const SecuritySettings({
    required this.passwordEnabled,
    required this.passwordValue,
  });

  final bool passwordEnabled;
  final String passwordValue;

  SecuritySettings copyWith({
    bool? passwordEnabled,
    String? passwordValue,
  }) {
    return SecuritySettings(
      passwordEnabled: passwordEnabled ?? this.passwordEnabled,
      passwordValue: passwordValue ?? this.passwordValue,
    );
  }

  factory SecuritySettings.fromJson(Map<String, dynamic> json) {
    return SecuritySettings(
      passwordEnabled: json['passwordEnabled'] == true,
      passwordValue: (json['passwordValue'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'passwordEnabled': passwordEnabled,
      'passwordValue': passwordValue,
    };
  }
}

class AppData {
  const AppData({
    required this.schemas,
    required this.patients,
    required this.admissions,
    required this.dailyRecords,
    required this.templates,
    required this.admissionAssessments,
    required this.admissionImaging,
  });

  final Map<String, List<FieldSchema>> schemas;
  final List<PatientRecord> patients;
  final List<AdmissionRecord> admissions;
  final List<DailyRecord> dailyRecords;
  final List<TemplateDisease> templates;
  final Map<String, List<AssessmentRecord>> admissionAssessments;
  final Map<String, List<ImagingItem>> admissionImaging;

  factory AppData.empty() {
    return const AppData(
      schemas: <String, List<FieldSchema>>{},
      patients: <PatientRecord>[],
      admissions: <AdmissionRecord>[],
      dailyRecords: <DailyRecord>[],
      templates: <TemplateDisease>[],
      admissionAssessments: <String, List<AssessmentRecord>>{},
      admissionImaging: <String, List<ImagingItem>>{},
    );
  }

  AppData copyWith({
    Map<String, List<FieldSchema>>? schemas,
    List<PatientRecord>? patients,
    List<AdmissionRecord>? admissions,
    List<DailyRecord>? dailyRecords,
    List<TemplateDisease>? templates,
    Map<String, List<AssessmentRecord>>? admissionAssessments,
    Map<String, List<ImagingItem>>? admissionImaging,
  }) {
    return AppData(
      schemas: schemas ?? this.schemas,
      patients: patients ?? this.patients,
      admissions: admissions ?? this.admissions,
      dailyRecords: dailyRecords ?? this.dailyRecords,
      templates: templates ?? this.templates,
      admissionAssessments: admissionAssessments ?? this.admissionAssessments,
      admissionImaging: admissionImaging ?? this.admissionImaging,
    );
  }

  factory AppData.fromJson(Map<String, dynamic> json) {
    final rawSchemas = _cloneMap(json['schemas']);
    final parsedSchemas = <String, List<FieldSchema>>{};
    for (final entry in rawSchemas.entries) {
      final value = entry.value;
      if (value is! List) continue;
      parsedSchemas[entry.key.toString()] = value
          .whereType<Map>()
          .map((e) => FieldSchema.fromJson(_cloneMap(e)))
          .toList();
    }

    final patients = (json['patients'] is List)
        ? (json['patients'] as List)
            .whereType<Map>()
            .map((e) => PatientRecord.fromJson(_cloneMap(e)))
            .toList()
        : <PatientRecord>[];

    final admissions = (json['admissions'] is List)
        ? (json['admissions'] as List)
            .whereType<Map>()
            .map((e) => AdmissionRecord.fromJson(_cloneMap(e)))
            .toList()
        : <AdmissionRecord>[];

    final admissionIdSet = admissions.map((e) => e.id).toSet();

    final dailyRecords = (json['dailyRecords'] is List)
        ? (json['dailyRecords'] as List)
            .whereType<Map>()
            .map((e) => DailyRecord.fromJson(_cloneMap(e)))
            .where((e) => admissionIdSet.contains(e.admissionId))
            .toList()
        : <DailyRecord>[];

    final templates = (json['templates'] is List)
        ? (json['templates'] as List)
            .whereType<Map>()
            .map((e) => TemplateDisease.fromJson(_cloneMap(e)))
            .toList()
        : <TemplateDisease>[];

    final admissionAssessmentsRaw = _cloneMap(json['admissionAssessments']);
    final admissionAssessments = <String, List<AssessmentRecord>>{};
    for (final entry in admissionAssessmentsRaw.entries) {
      if (!admissionIdSet.contains(entry.key)) continue;
      final value = entry.value;
      if (value is Map && value['records'] is List) {
        admissionAssessments[entry.key] = (value['records'] as List)
            .whereType<Map>()
            .map((e) => AssessmentRecord.fromJson(_cloneMap(e)))
            .toList();
        continue;
      }
      if (value is List) {
        admissionAssessments[entry.key] = value
            .whereType<Map>()
            .map((e) => AssessmentRecord.fromJson(_cloneMap(e)))
            .toList();
      }
    }

    final admissionImagingRaw = _cloneMap(json['admissionImaging']);
    final admissionImaging = <String, List<ImagingItem>>{};
    for (final entry in admissionImagingRaw.entries) {
      if (!admissionIdSet.contains(entry.key)) continue;
      final value = entry.value;
      if (value is! List) continue;
      admissionImaging[entry.key] = value
          .whereType<Map>()
          .map((e) => ImagingItem.fromJson(_cloneMap(e)))
          .where((e) => e.src.isNotEmpty)
          .toList();
    }

    return AppData(
      schemas: parsedSchemas,
      patients: patients,
      admissions: admissions,
      dailyRecords: dailyRecords,
      templates: templates,
      admissionAssessments: admissionAssessments,
      admissionImaging: admissionImaging,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'schemas': schemas.map(
        (key, value) => MapEntry(
          key,
          value.map((e) => e.toJson()).toList(),
        ),
      ),
      'patients': patients.map((e) => e.toJson()).toList(),
      'admissions': admissions.map((e) => e.toJson()).toList(),
      'dailyRecords': dailyRecords.map((e) => e.toJson()).toList(),
      'templates': templates.map((e) => e.toJson()).toList(),
      'admissionAssessments': admissionAssessments.map(
        (key, value) => MapEntry(
          key,
          <String, dynamic>{
            'records': value.map((e) => e.toJson()).toList(),
          },
        ),
      ),
      'admissionImaging': admissionImaging.map(
        (key, value) => MapEntry(
          key,
          value.map((e) => e.toJson()).toList(),
        ),
      ),
    };
  }

  String toPrettyJson() {
    return const JsonEncoder.withIndent('  ').convert(toJson());
  }
}

class StorageSnapshot {
  const StorageSnapshot({
    required this.data,
    required this.security,
  });

  final AppData data;
  final SecuritySettings security;
}

Map<String, dynamic> _cloneMap(dynamic raw) {
  if (raw is Map<String, dynamic>) {
    return Map<String, dynamic>.from(raw);
  }
  if (raw is Map) {
    return raw.map(
      (key, value) => MapEntry(key.toString(), value),
    );
  }
  return <String, dynamic>{};
}

double _toDouble(dynamic raw) {
  if (raw is num) return raw.toDouble();
  return double.tryParse((raw ?? '').toString()) ?? 0;
}
