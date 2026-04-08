import 'dart:convert';

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
    final dailyListSchema = state.listSchemaOf('daily').where((f) => f.key != 'recordDate').toList();
    final dailyList = state.dailyOf(widget.admissionId);
    final assessments = state.assessmentsOf(widget.admissionId);
    final imaging = state.imagingOf(widget.admissionId);

    return Scaffold(
      appBar: _buildAppBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
        children: [
          SectionCard(
            title: '入院详情',
            action: FilledButton.tonal(
              onPressed: () => _editAdmission(context, admission),
              child: const Text('编辑'),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        patient == null
                            ? '-'
                            : '${patient.values['name'] ?? '-'}  (${patient.admissionNo})',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF20344E),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _CountChip(label: '日常记录', value: '${dailyList.length}'),
                    const SizedBox(width: 8),
                    _CountChip(label: '影像资料', value: '${imaging.length}'),
                    const SizedBox(width: 8),
                    _CountChip(label: '住院测评', value: '${assessments.length}'),
                  ],
                ),
                const SizedBox(height: 10),
                FieldGrid(
                  schema: admissionFields,
                  values: admission.values,
                ),
              ],
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
                    '暂无影像资料',
                    style: TextStyle(color: Color(0xFF7588A1)),
                  )
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final image in imaging)
                        _ImagingThumb(
                          image: image,
                          onPreview: () => _previewImage(context, image),
                          onDelete: () => _deleteImage(context, image.id),
                        ),
                    ],
                  ),
          ),
          SectionCard(
            title: '住院测评',
            action: FilledButton.tonal(
              onPressed: () => _openAssessmentEdit(context),
              child: const Text('新增测评'),
            ),
            child: Column(
              children: [
                for (final record in assessments)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _AssessmentCard(
                      record: record,
                      state: state,
                      onOpen: () => _openAssessmentReadOnly(context, record.id),
                      onEdit: () => _openAssessmentEdit(context, editingId: record.id),
                      onDelete: () => _deleteAssessment(context, record.id),
                    ),
                  ),
                if (assessments.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      '暂无测评记录',
                      style: TextStyle(color: Color(0xFF7488A4)),
                    ),
                  ),
              ],
            ),
          ),
          SectionCard(
            title: '日常记录',
            action: FilledButton.tonal(
              onPressed: () => _openDailyDialog(context),
              child: const Text('新增日常'),
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
                      onEdit: () => _openDailyDialog(context, editing: row),
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

  Future<void> _editAdmission(BuildContext context, AdmissionRecord admission) async {
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
      if (editing == null) 'recordDate': DateFormat('yyyy-MM-dd').format(DateTime.now()),
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
    context.read<HospitalAppState>().deleteDaily(dailyId);
  }

  Future<void> _openAssessmentEdit(
    BuildContext context, {
    String? editingId,
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AssessmentEditPage(
          admissionId: widget.admissionId,
          editingAssessmentId: editingId,
        ),
      ),
    );
  }

  Future<void> _openAssessmentReadOnly(BuildContext context, String assessmentId) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AssessmentReadonlyPage(
          admissionId: widget.admissionId,
          assessmentId: assessmentId,
        ),
      ),
    );
  }

  Future<void> _deleteAssessment(BuildContext context, String assessmentId) async {
    final confirmed = await showDeleteConfirmDialog(
      context,
      title: '删除测评记录',
      content: '确认删除这条住院测评记录吗？',
    );
    if (!confirmed) return;
    context.read<HospitalAppState>().deleteAssessment(widget.admissionId, assessmentId);
  }

  Future<void> _pickFromCamera(BuildContext context) async {
    final file = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 78,
      maxWidth: 1920,
    );
    if (file == null) return;
    await _appendImages(context, [file]);
  }

  Future<void> _pickFromAlbum(BuildContext context) async {
    final files = await _picker.pickMultiImage(
      imageQuality: 78,
      maxWidth: 1920,
    );
    if (files.isEmpty) return;
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
    context.read<HospitalAppState>().removeImaging(widget.admissionId, imageId);
  }

  List<int> _decodeDataUri(String src) {
    final index = src.indexOf(',');
    final payload = index >= 0 ? src.substring(index + 1) : src;
    return base64Decode(payload);
  }
}

class _CountChip extends StatelessWidget {
  const _CountChip({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFF3F7FC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFD9E4F3)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Column(
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 13, color: Color(0xFF6F8199)),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF233A57),
                ),
              ),
            ],
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
          borderRadius: BorderRadius.circular(12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
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

  List<int> _decode(String src) {
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
          padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            (row.values['recordDate'] ?? '-').toString(),
                            style: const TextStyle(
                              fontSize: 29,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1C3249),
                            ),
                          ),
                        ),
                        _ActionText(title: '编辑', color: const Color(0xFF2B88D8), onTap: onEdit),
                        _ActionText(title: '删除', color: const Color(0xFFD35067), onTap: onDelete),
                      ],
                    ),
                    const SizedBox(height: 8),
                    FieldGrid(
                      schema: listSchema,
                      values: row.values,
                      compact: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(
                width: 30,
                child: Center(
                  child: Icon(
                    Icons.chevron_right_rounded,
                    size: 27,
                    color: Color(0xFF607B99),
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
    final disease = state.findDisease(record.diseaseId);
    final version = state.findVersion(record.diseaseId, record.versionId);
    final title = disease?.diseaseName ?? '未知病种';
    final versionText = version?.versionName ?? '-';
    final timeText = DateFormat('yyyy-MM-dd HH:mm').format(record.createdAt);
    final score = version == null ? 0.0 : state.calculateAssessmentScore(version, record.selections);

    return Card(
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 29,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1D324A),
                            ),
                          ),
                        ),
                        _ActionText(title: '编辑', color: const Color(0xFF2B88D8), onTap: onEdit),
                        _ActionText(title: '删除', color: const Color(0xFFD35067), onTap: onDelete),
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
                    const SizedBox(height: 8),
                    if (version != null)
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4F8FD),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFD8E4F3)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                          child: AssessmentScoreBar(
                            score: score,
                            rules: version.gradeRules,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(
                width: 30,
                child: Center(
                  child: Icon(
                    Icons.chevron_right_rounded,
                    size: 27,
                    color: Color(0xFF607B99),
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
        color: const Color(0xFFF3F7FC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFD8E3F3)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF6F829B),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: Color(0xFF1F334B),
                fontSize: 18,
                fontWeight: FontWeight.w700,
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
    required this.color,
    required this.onTap,
  });

  final String title;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          child: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}
