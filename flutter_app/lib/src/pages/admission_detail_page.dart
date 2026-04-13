import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/app_models.dart';
import '../state/hospital_app_state.dart';
import '../widgets/app_back_button.dart';
import '../widgets/assessment_score_bar.dart';
import '../widgets/dialog_utils.dart';
import '../widgets/dynamic_form_dialog.dart';
import '../widgets/field_grid.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/section_card.dart';
import 'assessment_edit_page.dart';
import 'assessment_readonly_page.dart';
import 'daily_detail_page.dart';

class AdmissionDetailPage extends StatefulWidget {
  const AdmissionDetailPage({
    super.key,
    required this.admissionId,
  });

  final String admissionId;

  @override
  State<AdmissionDetailPage> createState() => _AdmissionDetailPageState();
}

class _AdmissionDetailPageState extends State<AdmissionDetailPage> {
  final ImagePicker _picker = ImagePicker();
  TemplateCatalogType _assessmentCatalogView = TemplateCatalogType.assessment;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<HospitalAppState>();
    final admission = state.findAdmission(widget.admissionId);
    if (admission == null) {
      return Scaffold(
        appBar: _buildAppBar(),
        body: const Center(child: Text('入院记录不存在')),
      );
    }
    final patient = state.findPatient(admission.admissionNo);

    final admissionFields = state
        .schemaOf('admission')
        .where((field) => field.showInList || field.required)
        .toList();
    final dailyListSchema = state
        .listSchemaOf('daily')
        .where((f) => f.key != 'recordDate')
        .toList();
    final dailyList = state.dailyOf(widget.admissionId);
    final assessments = state.assessmentsOf(widget.admissionId);
    final imaging = state.imagingOf(widget.admissionId);
    final illnessAssessments = assessments
        .where((record) =>
            _resolveAssessmentCatalog(state, record) ==
            TemplateCatalogType.assessment)
        .toList(growable: false);
    final diagnosisAssessments = assessments
        .where((record) =>
            _resolveAssessmentCatalog(state, record) ==
            TemplateCatalogType.diagnosis)
        .toList(growable: false);
    final activeAssessments =
        _assessmentCatalogView == TemplateCatalogType.assessment
            ? illnessAssessments
            : diagnosisAssessments;

    return Scaffold(
      appBar: _buildAppBar(),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final layout = ResponsiveLayout.fromWidth(constraints.maxWidth);
          return ResponsiveBody(
            layout: layout,
            child: ListView(
              padding: layout.listPadding(),
              children: [
                _HeroSummary(
                  patientName: patient == null
                      ? '未命名病人'
                      : '${patient.values['name'] ?? '-'}',
                  admissionNo: admission.admissionNo,
                  admitDate:
                      (admission.values['admitDate'] ?? 'Not set').toString(),
                ),
                const SizedBox(height: 10),
                SectionCard(
                  title: '入院详情',
                  action: Tooltip(
                    message: '编辑入院详情',
                    child: FilledButton.tonal(
                      onPressed: () => _editAdmission(context, admission),
                      child: const Icon(Icons.edit_rounded),
                    ),
                  ),
                  child: FieldGrid(
                    schema: admissionFields,
                    values: admission.values,
                  ),
                ),
                SectionCard(
                  title: '影像资料',
                  action: Wrap(
                    spacing: 6,
                    children: [
                      FilledButton.tonal(
                        onPressed: () => _pickFromCamera(context),
                        child: const Text('拍照'),
                      ),
                      FilledButton.tonal(
                        onPressed: () => _pickFromAlbum(context),
                        child: const Text('相册'),
                      ),
                    ],
                  ),
                  child: imaging.isEmpty
                      ? const Text(
                          '暂无影像资料，可使用拍照或相册上传',
                          style: TextStyle(color: Color(0xFF7588A1)),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  '点击缩略图查看原图',
                                  style: TextStyle(
                                    color: Color(0xFF2B3F5E),
                                    fontSize: 13,
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(999),
                                    color: const Color(0xFFF5F9FF),
                                    border: Border.all(
                                        color: const Color(0xFFD9E5F4)),
                                  ),
                                  child: Text(
                                    '共 ${imaging.length} 张',
                                    style: const TextStyle(
                                      color: Color(0xFF4E627D),
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (final image in imaging)
                                  _ImagingThumb(
                                    image: image,
                                    onPreview: () =>
                                        _previewImage(context, image),
                                    onDelete: () =>
                                        _deleteImage(context, image.id),
                                  ),
                              ],
                            ),
                          ],
                        ),
                ),
                SectionCard(
                  title: '住院测评',
                  action: Wrap(
                    spacing: 6,
                    children: [
                      Tooltip(
                        message: '新增病情测评',
                        child: FilledButton.tonal(
                          onPressed: () => _openAssessmentEdit(
                            context,
                            catalog: TemplateCatalogType.assessment,
                          ),
                          child: const Icon(Icons.add_chart_rounded),
                        ),
                      ),
                      Tooltip(
                        message: '新增诊断测评',
                        child: FilledButton.tonal(
                          onPressed: () => _openAssessmentEdit(
                            context,
                            catalog: TemplateCatalogType.diagnosis,
                          ),
                          child: const Icon(Icons.add_task_rounded),
                        ),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.tonal(
                              onPressed: () {
                                setState(() {
                                  _assessmentCatalogView =
                                      TemplateCatalogType.assessment;
                                });
                              },
                              style: FilledButton.styleFrom(
                                backgroundColor: _assessmentCatalogView ==
                                        TemplateCatalogType.assessment
                                    ? const Color(0xFFD8ECFF)
                                    : null,
                              ),
                              child: Text('病情测评 ${illnessAssessments.length}'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: FilledButton.tonal(
                              onPressed: () {
                                setState(() {
                                  _assessmentCatalogView =
                                      TemplateCatalogType.diagnosis;
                                });
                              },
                              style: FilledButton.styleFrom(
                                backgroundColor: _assessmentCatalogView ==
                                        TemplateCatalogType.diagnosis
                                    ? const Color(0xFFD8ECFF)
                                    : null,
                              ),
                              child:
                                  Text('诊断测评 ${diagnosisAssessments.length}'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (activeAssessments.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            '暂无测评记录',
                            style: TextStyle(color: Color(0xFF7488A4)),
                          ),
                        )
                      else
                        for (final record in activeAssessments)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _AssessmentCard(
                              record: record,
                              state: state,
                              onOpen: () =>
                                  _openAssessmentReadOnly(context, record.id),
                              onEdit: () => _openAssessmentEdit(
                                context,
                                editingId: record.id,
                                catalog:
                                    _resolveAssessmentCatalog(state, record),
                              ),
                              onDelete: () =>
                                  _deleteAssessment(context, record.id),
                            ),
                          ),
                    ],
                  ),
                ),
                SectionCard(
                  title: '日常记录',
                  action: Tooltip(
                    message: '新增日常记录',
                    child: FilledButton.tonal(
                      onPressed: () => _openDailyDialog(context),
                      child: const Icon(Icons.add_rounded),
                    ),
                  ),
                  child: Column(
                    children: [
                      for (final row in dailyList)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _DailyCard(
                            row: row,
                            listSchema: dailyListSchema,
                            onOpen: () => _openDailyDetail(context, row.id),
                            onEdit: () =>
                                _openDailyDialog(context, editing: row),
                            onDelete: () => _deleteDaily(context, row.id),
                          ),
                        ),
                      if (dailyList.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            '暂无日常记录',
                            style: TextStyle(color: Color(0xFF7488A4)),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      automaticallyImplyLeading: false,
      leadingWidth: 56,
      leading: const Padding(
        padding: EdgeInsets.only(left: 12),
        child: AppBackButton(),
      ),
      title: const Text(
        '入院详情',
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
    );
  }

  Future<void> _editAdmission(
      BuildContext context, AdmissionRecord admission) async {
    final state = context.read<HospitalAppState>();
    final schema = state.schemaOf('admission');
    await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return DynamicFormDialog(
          title: '编辑入院信息',
          schema: schema,
          initialValues: admission.values,
          onSubmit: (values) async {
            final ok = state.upsertAdmission(
              admissionNo: admission.admissionNo,
              values: values,
              editingId: admission.id,
            );
            return ok ? null : (state.takeLastErrorMessage() ?? '保存失败');
          },
        );
      },
    );
  }

  Future<void> _openDailyDialog(
    BuildContext context, {
    DailyRecord? editing,
  }) async {
    final state = context.read<HospitalAppState>();
    final schema = state.schemaOf('daily');
    final initial = <String, dynamic>{
      for (final field in schema) field.key: '',
      ...?editing?.values,
      if (editing == null)
        'recordDate': DateFormat('yyyy-MM-dd').format(DateTime.now()),
    };

    await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return DynamicFormDialog(
          title: editing == null ? '新增日常记录' : '编辑日常记录',
          schema: schema,
          initialValues: initial,
          onSubmit: (values) async {
            final ok = state.upsertDaily(
              admissionId: widget.admissionId,
              values: values,
              editingId: editing?.id,
            );
            return ok ? null : (state.takeLastErrorMessage() ?? '保存失败');
          },
        );
      },
    );
  }

  Future<void> _openDailyDetail(BuildContext context, String dailyId) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DailyDetailPage(dailyId: dailyId),
      ),
    );
  }

  Future<void> _deleteDaily(BuildContext context, String dailyId) async {
    final confirmed = await showDeleteConfirmDialog(
      context,
      title: '删除日常记录',
      content: '确认删除这条日常记录吗？',
    );
    if (!confirmed) return;
    if (!context.mounted) return;
    context.read<HospitalAppState>().deleteDaily(dailyId);
  }

  Future<void> _openAssessmentEdit(
    BuildContext context, {
    String? editingId,
    TemplateCatalogType? catalog,
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AssessmentEditPage(
          admissionId: widget.admissionId,
          editingAssessmentId: editingId,
          initialCatalog: catalog,
        ),
      ),
    );
  }

  Future<void> _openAssessmentReadOnly(
      BuildContext context, String assessmentId) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AssessmentReadonlyPage(
          admissionId: widget.admissionId,
          assessmentId: assessmentId,
        ),
      ),
    );
  }

  Future<void> _deleteAssessment(
      BuildContext context, String assessmentId) async {
    final confirmed = await showDeleteConfirmDialog(
      context,
      title: '删除测评记录',
      content: '确认删除这条住院测评记录吗？',
    );
    if (!confirmed) return;
    if (!context.mounted) return;
    context
        .read<HospitalAppState>()
        .deleteAssessment(widget.admissionId, assessmentId);
  }

  TemplateCatalogType _resolveAssessmentCatalog(
    HospitalAppState state,
    AssessmentRecord record,
  ) {
    final byRecord = state.findVersion(
      record.diseaseId,
      record.versionId,
      catalog: record.catalog,
    );
    if (byRecord != null) return record.catalog;

    final byAssessment = state.findVersion(
      record.diseaseId,
      record.versionId,
      catalog: TemplateCatalogType.assessment,
    );
    if (byAssessment != null) return TemplateCatalogType.assessment;

    final byDiagnosis = state.findVersion(
      record.diseaseId,
      record.versionId,
      catalog: TemplateCatalogType.diagnosis,
    );
    if (byDiagnosis != null) return TemplateCatalogType.diagnosis;

    return record.catalog;
  }

  Future<void> _pickFromCamera(BuildContext context) async {
    final file = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 78,
      maxWidth: 1920,
    );
    if (file == null) return;
    if (!context.mounted) return;
    await _appendImages(context, [file]);
  }

  Future<void> _pickFromAlbum(BuildContext context) async {
    final files = await _picker.pickMultiImage(
      imageQuality: 78,
      maxWidth: 1920,
    );
    if (files.isEmpty) return;
    if (!context.mounted) return;
    await _appendImages(context, files);
  }

  Future<void> _appendImages(BuildContext context, List<XFile> files) async {
    final state = context.read<HospitalAppState>();
    final items = <ImagingItem>[];
    for (final file in files) {
      final bytes = await file.readAsBytes();
      final base64 = base64Encode(bytes);
      final ext = file.path.toLowerCase().endsWith('.png') ? 'png' : 'jpeg';
      items.add(
        ImagingItem(
          id: state.createRuntimeId('img'),
          src: 'data:image/$ext;base64,$base64',
          name: file.name,
        ),
      );
    }
    if (items.isNotEmpty) {
      state.addImaging(widget.admissionId, items);
    }
  }

  void _previewImage(BuildContext context, ImagingItem image) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(20),
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.memory(
                _decodeDataUri(image.src),
                fit: BoxFit.contain,
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _deleteImage(BuildContext context, String imageId) async {
    final confirmed = await showDeleteConfirmDialog(
      context,
      title: '删除影像',
      content: '确认删除该影像资料吗？',
    );
    if (!confirmed) return;
    if (!context.mounted) return;
    context.read<HospitalAppState>().removeImaging(widget.admissionId, imageId);
  }

  Uint8List _decodeDataUri(String src) {
    final index = src.indexOf(',');
    final payload = index >= 0 ? src.substring(index + 1) : src;
    return base64Decode(payload);
  }
}

class _HeroSummary extends StatelessWidget {
  const _HeroSummary({
    required this.patientName,
    required this.admissionNo,
    required this.admitDate,
  });

  final String patientName;
  final String admissionNo;
  final String admitDate;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFFFFFFFF), Color(0xFFF4F8FF)],
        ),
        border: Border.all(color: const Color(0xFFE7EEF8)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x160F2744),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(13, 12, 13, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              patientName,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1F3149),
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _HeroChip(text: '住院号 $admissionNo'),
                _HeroChip(text: '住院日期 $admitDate'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F9FF),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFD9E5F4)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Text(
          text,
          style: const TextStyle(
            color: Color(0xFF4E627D),
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _ImagingThumb extends StatelessWidget {
  const _ImagingThumb({
    required this.image,
    required this.onPreview,
    required this.onDelete,
  });

  final ImagingItem image;
  final VoidCallback onPreview;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        InkWell(
          onTap: onPreview,
          borderRadius: BorderRadius.circular(10),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 88,
              height: 88,
              child: Image.memory(
                _decode(image.src),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        Positioned(
          top: -6,
          right: -6,
          child: IconButton.filledTonal(
            onPressed: onDelete,
            icon: const Icon(Icons.close_rounded, size: 14),
            visualDensity: VisualDensity.compact,
            iconSize: 14,
            padding: const EdgeInsets.all(4),
          ),
        ),
      ],
    );
  }

  Uint8List _decode(String src) {
    final index = src.indexOf(',');
    final payload = index >= 0 ? src.substring(index + 1) : src;
    return base64Decode(payload);
  }
}

class _DailyCard extends StatelessWidget {
  const _DailyCard({
    required this.row,
    required this.listSchema,
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
  });

  final DailyRecord row;
  final List<FieldSchema> listSchema;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            (row.values['recordDate'] ?? '-').toString(),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1F3149),
                            ),
                          ),
                        ),
                        _ActionText(
                          title: '编辑日常记录',
                          icon: Icons.edit_rounded,
                          color: const Color(0xFF2B88D8),
                          onTap: onEdit,
                        ),
                        _ActionText(
                          title: '删除日常记录',
                          icon: Icons.delete_outline_rounded,
                          color: const Color(0xFFD35067),
                          onTap: onDelete,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    FieldGrid(
                      schema: listSchema,
                      values: row.values,
                      compact: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(
                width: 18,
                child: Center(
                  child: Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: Color(0xFF7E95B3),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AssessmentCard extends StatelessWidget {
  const _AssessmentCard({
    required this.record,
    required this.state,
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
  });

  final AssessmentRecord record;
  final HospitalAppState state;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    var catalog = record.catalog;
    var version = state.findVersion(
      record.diseaseId,
      record.versionId,
      catalog: catalog,
    );
    if (version == null) {
      final fallbackAssessment = state.findVersion(
        record.diseaseId,
        record.versionId,
        catalog: TemplateCatalogType.assessment,
      );
      final fallbackDiagnosis = state.findVersion(
        record.diseaseId,
        record.versionId,
        catalog: TemplateCatalogType.diagnosis,
      );
      if (fallbackAssessment != null) {
        catalog = TemplateCatalogType.assessment;
        version = fallbackAssessment;
      } else if (fallbackDiagnosis != null) {
        catalog = TemplateCatalogType.diagnosis;
        version = fallbackDiagnosis;
      }
    }
    final disease = state.findDisease(record.diseaseId, catalog: catalog);
    final score = version == null
        ? 0.0
        : state.calculateAssessmentScore(version, record.selections);
    final title = disease?.diseaseName ?? '未知病种';
    final versionText = version?.versionName ?? '-';
    final timeText = DateFormat('yyyy-MM-dd HH:mm').format(record.createdAt);

    return Card(
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1F3149),
                            ),
                          ),
                        ),
                        _ActionText(
                          title: '编辑测评记录',
                          icon: Icons.edit_rounded,
                          color: const Color(0xFF2B88D8),
                          onTap: onEdit,
                        ),
                        _ActionText(
                          title: '删除测评记录',
                          icon: Icons.delete_outline_rounded,
                          color: const Color(0xFFD35067),
                          onTap: onDelete,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _MiniField(
                            label: '模板版本',
                            value: versionText,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _MiniField(
                            label: '测评时间',
                            value: timeText,
                          ),
                        ),
                      ],
                    ),
                    if (version != null && version.gradeRules.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7FBFF),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFDCE7F5)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(8, 7, 8, 7),
                          child: AssessmentScoreBar(
                            score: score,
                            rules: version.gradeRules,
                            compact: true,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(
                width: 18,
                child: Center(
                  child: Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: Color(0xFF7E95B3),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniField extends StatelessWidget {
  const _MiniField({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF7FBFF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5EEF9)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF6F829B),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: Color(0xFF1F334B),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionText extends StatelessWidget {
  const _ActionText({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: title,
      child: IconButton(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        visualDensity: VisualDensity.compact,
        color: color,
      ),
    );
  }
}
