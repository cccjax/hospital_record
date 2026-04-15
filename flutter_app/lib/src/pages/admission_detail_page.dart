import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/app_models.dart';
import '../state/hospital_app_state.dart';
import '../widgets/app_add_button.dart';
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
    final dailyCount = dailyList.length;
    final imagingCount = imaging.length;
    final assessmentCount = assessments.length;

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
                  action: _HeaderIconAction(
                    title: '编辑入院详情',
                    icon: Icons.edit_rounded,
                    onTap: () => _editAdmission(context, admission),
                  ),
                  child: FieldGrid(
                    schema: admissionFields,
                    values: admission.values,
                    variant: FieldGridVariant.table,
                    compact: true,
                    showColumnDivider: false,
                  ),
                ),
                SectionCard(
                  title: '影像资料',
                  action: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _CountPill(text: '$imagingCount 张'),
                      const SizedBox(width: 6),
                      _HeaderIconAction(
                        title: '拍照上传',
                        icon: Icons.photo_camera_rounded,
                        onTap: () => _pickFromCamera(context),
                      ),
                      const SizedBox(width: 6),
                      _HeaderIconAction(
                        title: '从相册选择',
                        icon: Icons.photo_library_rounded,
                        onTap: () => _pickFromAlbum(context),
                      ),
                    ],
                  ),
                  child: imaging.isEmpty
                      ? const _EmptySectionHint(
                          text: '暂无影像资料，可拍照或从相册上传',
                          icon: Icons.image_not_supported_rounded,
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
                  action: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _CountPill(text: '$assessmentCount 条'),
                      const SizedBox(width: 6),
                      _AddAssessmentMenuButton(
                        onSelected: (catalog) => _openAssessmentEdit(
                          context,
                          catalog: catalog,
                        ),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _AssessmentCatalogSwitcher(
                        view: _assessmentCatalogView,
                        illnessCount: illnessAssessments.length,
                        diagnosisCount: diagnosisAssessments.length,
                        onChange: (catalog) {
                          setState(() {
                            _assessmentCatalogView = catalog;
                          });
                        },
                      ),
                      const SizedBox(height: 10),
                      if (activeAssessments.isEmpty)
                        _EmptySectionHint(
                          text: _assessmentCatalogView ==
                                  TemplateCatalogType.assessment
                              ? '暂无病情测评记录'
                              : '暂无诊断测评记录',
                          icon: _assessmentCatalogView ==
                                  TemplateCatalogType.assessment
                              ? Icons.monitor_heart_outlined
                              : Icons.fact_check_outlined,
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
                  action: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _CountPill(text: '$dailyCount 条'),
                      const SizedBox(width: 6),
                      _HeaderIconAction(
                        title: '新增日常记录',
                        icon: Icons.add_rounded,
                        onTap: () => _openDailyDialog(context),
                      ),
                    ],
                  ),
                  child: dailyList.isEmpty
                      ? const _EmptySectionHint(
                          text: '暂无日常记录',
                          icon: Icons.event_note_rounded,
                        )
                      : LayoutBuilder(
                          builder: (context, box) {
                            const gap = 10.0;
                            const minCardWidth = 248.0;
                            final crossAxisCount =
                                ((box.maxWidth + gap) / (minCardWidth + gap))
                                    .floor()
                                    .clamp(1, 3);
                            final cardWidth =
                                (box.maxWidth - gap * (crossAxisCount - 1)) /
                                    crossAxisCount;
                            return Wrap(
                              spacing: gap,
                              runSpacing: gap,
                              children: [
                                for (final row in dailyList)
                                  SizedBox(
                                    width: cardWidth,
                                    child: _DailyCard(
                                      row: row,
                                      listSchema: dailyListSchema,
                                      onOpen: () =>
                                          _openDailyDetail(context, row.id),
                                      onEdit: () => _openDailyDialog(context,
                                          editing: row),
                                      onDelete: () =>
                                          _deleteDaily(context, row.id),
                                    ),
                                  ),
                              ],
                            );
                          },
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
    final imageBytes = _decodeDataUri(image.src);
    showDialog<void>(
      context: context,
      barrierColor: const Color(0xCC091423),
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: const Color(0xFF0B1626),
              border: Border.all(color: const Color(0x334A6A92)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x66000B16),
                  blurRadius: 26,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: InteractiveViewer(
                      minScale: 1,
                      maxScale: 5,
                      panEnabled: true,
                      scaleEnabled: true,
                      child: ColoredBox(
                        color: const Color(0xFF0B1626),
                        child: Center(
                          child: Image.memory(
                            imageBytes,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(999),
                      onTap: () => Navigator.of(dialogContext).pop(),
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0x80111F32),
                          border: Border.all(color: const Color(0x4D8AA8CA)),
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          size: 20,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                const Positioned(
                  left: 14,
                  right: 14,
                  bottom: 12,
                  child: Text(
                    '双指可放大/缩小，拖动可查看细节',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFFCEE0F6),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
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
        color: const Color(0xFFF8FBFF),
        border: Border.all(color: const Color(0xFFE7EEF8)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120F2744),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(13, 12, 13, 13),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(
              Icons.person_rounded,
              size: 18,
              color: Color(0xFF3F6E9F),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    patientName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1F3149),
                    ),
                  ),
                  _HeroChip(
                    icon: Icons.badge_outlined,
                    text: '住院号 $admissionNo',
                  ),
                  _HeroChip(
                    icon: Icons.calendar_month_outlined,
                    text: '住院日期 $admitDate',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({
    required this.icon,
    required this.text,
  });

  final IconData icon;
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
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: const Color(0xFF5A7091)),
            const SizedBox(width: 5),
            Text(
              text,
              style: const TextStyle(
                color: Color(0xFF4E627D),
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AssessmentCatalogSwitcher extends StatelessWidget {
  const _AssessmentCatalogSwitcher({
    required this.view,
    required this.illnessCount,
    required this.diagnosisCount,
    required this.onChange,
  });

  final TemplateCatalogType view;
  final int illnessCount;
  final int diagnosisCount;
  final ValueChanged<TemplateCatalogType> onChange;

  @override
  Widget build(BuildContext context) {
    Widget buildOption({
      required TemplateCatalogType catalog,
      required IconData icon,
      required String label,
      required int count,
    }) {
      final selected = view == catalog;
      final foreground =
          selected ? const Color(0xFF2E5F92) : const Color(0xFF5F738D);
      return Expanded(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(9),
            onTap: () => onChange(catalog),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOut,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(9),
                color: selected ? const Color(0xFFDDEEFF) : Colors.transparent,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 16, color: foreground),
                  const SizedBox(width: 6),
                  Text(
                    '$label $count',
                    style: TextStyle(
                      color: foreground,
                      fontSize: 12.5,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 42,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFD3E0F1)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(3),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              buildOption(
                catalog: TemplateCatalogType.assessment,
                icon: Icons.monitor_heart_outlined,
                label: '病情测评',
                count: illnessCount,
              ),
              const SizedBox(width: 3),
              buildOption(
                catalog: TemplateCatalogType.diagnosis,
                icon: Icons.fact_check_outlined,
                label: '诊断测评',
                count: diagnosisCount,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderIconAction extends StatelessWidget {
  const _HeaderIconAction({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isAddAction = icon.codePoint == Icons.add_rounded.codePoint &&
        icon.fontFamily == Icons.add_rounded.fontFamily;
    if (isAddAction) {
      return AppAddIconButton(
        tooltip: title,
        onPressed: onTap,
        size: 38,
        iconSize: 20,
        borderRadius: 11,
      );
    }
    return AppToneIconButton(
      icon: icon,
      tooltip: title,
      onPressed: onTap,
      size: 38,
      iconSize: 20,
      borderRadius: 11,
    );
  }
}

class _AddAssessmentMenuButton extends StatefulWidget {
  const _AddAssessmentMenuButton({
    required this.onSelected,
  });

  final ValueChanged<TemplateCatalogType> onSelected;

  @override
  State<_AddAssessmentMenuButton> createState() =>
      _AddAssessmentMenuButtonState();
}

class _AddAssessmentMenuButtonState extends State<_AddAssessmentMenuButton> {
  final GlobalKey _anchorKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: '新增测评',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: _anchorKey,
          borderRadius: BorderRadius.circular(11),
          onTap: _openMenu,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFEEF5FF),
                  Color(0xFFE4F0FF),
                ],
              ),
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: AppAddButtonTokens.border),
              boxShadow: const [
                BoxShadow(
                  color: AppAddButtonTokens.shadow,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.add_rounded,
                    size: 18,
                    color: AppAddButtonTokens.foreground,
                  ),
                  SizedBox(width: 4),
                  Text(
                    '新增测评',
                    style: TextStyle(
                      color: AppAddButtonTokens.foreground,
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                    ),
                  ),
                  SizedBox(width: 2),
                  Icon(
                    Icons.arrow_drop_down_rounded,
                    size: 20,
                    color: AppAddButtonTokens.foreground,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openMenu() async {
    final anchorContext = _anchorKey.currentContext;
    if (anchorContext == null) {
      return;
    }
    final box = anchorContext.findRenderObject() as RenderBox?;
    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (box == null || overlay == null) {
      return;
    }

    final topLeft = box.localToGlobal(Offset.zero, ancestor: overlay);
    final bottomRight = box.localToGlobal(
      box.size.bottomRight(Offset.zero),
      ancestor: overlay,
    );
    final menuTop = topLeft.dy + box.size.height + 6;
    final position = RelativeRect.fromLTRB(
      topLeft.dx,
      menuTop,
      overlay.size.width - bottomRight.dx,
      overlay.size.height - menuTop,
    );

    final selected = await showMenu<TemplateCatalogType>(
      context: context,
      position: position,
      color: const Color(0xFFF8FBFF),
      surfaceTintColor: Colors.transparent,
      elevation: 10,
      constraints:
          const BoxConstraints(minWidth: 180, maxWidth: 200, maxHeight: 220),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFD6E3F3)),
      ),
      items: const [
        PopupMenuItem<TemplateCatalogType>(
          value: TemplateCatalogType.assessment,
          padding: EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          height: 42,
          child: _MenuOptionRow(
            icon: Icons.monitor_heart_outlined,
            text: '新增病情测评',
          ),
        ),
        PopupMenuItem<TemplateCatalogType>(
          value: TemplateCatalogType.diagnosis,
          padding: EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          height: 42,
          child: _MenuOptionRow(
            icon: Icons.fact_check_outlined,
            text: '新增诊断测评',
          ),
        ),
      ],
    );
    if (selected != null) {
      widget.onSelected(selected);
    }
  }
}

class _MenuOptionRow extends StatelessWidget {
  const _MenuOptionRow({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        child: Row(
          children: [
            Icon(icon, size: 16, color: const Color(0xFF557292)),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF334A64),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CountPill extends StatelessWidget {
  const _CountPill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF4F8FF),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFD7E4F3)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Text(
          text,
          style: const TextStyle(
            color: Color(0xFF57708D),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _EmptySectionHint extends StatelessWidget {
  const _EmptySectionHint({
    required this.text,
    required this.icon,
  });

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FBFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDDE8F6)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF768CA8)),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: Color(0xFF7A8CA4),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
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
    final title = (row.values['recordDate'] ?? '-').toString().trim();
    final infoRows = _buildInfoRows();
    final sketchImages = _extractImageSources(row.values['quickSketches']);

    return Card(
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 152),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 24, 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: const Color(0xFFD4E3F7),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.event_note_rounded,
                                  size: 14,
                                  color: Color(0xFF3E6A9D),
                                ),
                              ),
                              const SizedBox(width: 7),
                              Flexible(
                                child: Text(
                                  title.isEmpty ? '-' : title,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1F3149),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        _ActionText(
                          title: '编辑日常记录',
                          icon: Icons.edit_rounded,
                          color: const Color(0xFF2B88D8),
                          onTap: onEdit,
                        ),
                        const SizedBox(width: 4),
                        _ActionText(
                          title: '删除日常记录',
                          icon: Icons.delete_outline_rounded,
                          color: const Color(0xFFD35067),
                          onTap: onDelete,
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    const Divider(
                      height: 1,
                      thickness: 1,
                      color: Color(0xFFE4EBF6),
                    ),
                    const SizedBox(height: 6),
                    for (var i = 0; i < infoRows.length; i++)
                      Padding(
                        padding: EdgeInsets.only(
                          bottom: i == infoRows.length - 1 ? 0 : 5,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 66,
                              child: Text(
                                infoRows[i].label,
                                style: const TextStyle(
                                  color: Color(0xFF6D829E),
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                  height: 1.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                infoRows[i].value,
                                style: const TextStyle(
                                  color: Color(0xFF20364F),
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                  height: 1.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (sketchImages.isNotEmpty) ...[
                      const SizedBox(height: 7),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(
                            width: 66,
                            child: Text(
                              '速记白板',
                              style: TextStyle(
                                color: Color(0xFF6D829E),
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                                height: 1.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: _DailySketchPreview(
                              src: sketchImages.first,
                              count: sketchImages.length,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const Positioned(
              right: 2,
              top: 0,
              bottom: 0,
              child: Align(
                alignment: Alignment.center,
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
    );
  }

  List<_DailyInfoRow> _buildInfoRows() {
    final rows = <_DailyInfoRow>[];
    for (final field in listSchema) {
      if (field.key == 'recordDate') continue;
      final raw = row.values[field.key];
      String text;
      if (field.type == FieldType.images && raw is List) {
        text = '共 ${raw.length} 张';
      } else {
        text = (raw ?? '-').toString().trim();
      }
      rows.add(
        _DailyInfoRow(
          label: field.label,
          value: text.isEmpty ? '-' : text,
        ),
      );
      if (rows.length >= 4) break;
    }
    if (rows.isEmpty) {
      return const <_DailyInfoRow>[
        _DailyInfoRow(label: '字段', value: '暂无可视字段'),
      ];
    }
    return rows;
  }

  List<String> _extractImageSources(dynamic raw) {
    if (raw is! List) return const <String>[];
    final results = <String>[];
    for (final item in raw) {
      if (item is String) {
        final text = item.trim();
        if (text.isNotEmpty) {
          results.add(text);
        }
        continue;
      }
      if (item is Map) {
        final src = item['src'];
        if (src is String && src.trim().isNotEmpty) {
          results.add(src.trim());
        }
      }
    }
    return results;
  }
}

class _DailyInfoRow {
  const _DailyInfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;
}

class _DailySketchPreview extends StatelessWidget {
  const _DailySketchPreview({
    required this.src,
    required this.count,
  });

  final String src;
  final int count;

  @override
  Widget build(BuildContext context) {
    final bytes = _DailySketchThumbCache.decode(src);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 84,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F7FF),
              border: Border.all(color: const Color(0xFFD7E5F7)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: bytes == null
                ? const Center(
                    child: Icon(
                      Icons.broken_image_outlined,
                      size: 17,
                      color: Color(0xFF8BA2BE),
                    ),
                  )
                : Image.memory(
                    bytes,
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.medium,
                  ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              count > 1 ? '已添加 $count 张白板' : '已添加 1 张白板',
              style: const TextStyle(
                color: Color(0xFF526D8A),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DailySketchThumbCache {
  static final Map<String, Uint8List?> _cache = <String, Uint8List?>{};

  static Uint8List? decode(String src) {
    return _cache.putIfAbsent(src, () {
      final raw = src.trim();
      if (raw.isEmpty) return null;
      try {
        final payload = raw.contains(',') ? raw.split(',').last : raw;
        return base64Decode(payload);
      } catch (_) {
        return null;
      }
    });
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
          padding: const EdgeInsets.fromLTRB(12, 11, 10, 11),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFFD4E3F7),
                            ),
                          ),
                          child: const Icon(
                            Icons.analytics_outlined,
                            size: 14,
                            color: Color(0xFF3E6A9D),
                          ),
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 5,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1F3149),
                                ),
                              ),
                              _MetaChip(
                                icon: Icons.layers_outlined,
                                text: '模板 $versionText',
                              ),
                              _MetaChip(
                                icon: Icons.schedule_rounded,
                                text: timeText,
                              ),
                            ],
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
                    if (version != null && version.gradeRules.isNotEmpty) ...[
                      const SizedBox(height: 7),
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

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.icon,
    required this.text,
  });

  final IconData icon;
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
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: const Color(0xFF5A7091)),
            const SizedBox(width: 4),
            Text(
              text,
              style: const TextStyle(
                color: Color(0xFF4E627D),
                fontSize: 11.5,
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
      child: SizedBox(
        width: 34,
        height: 34,
        child: IconButton(
          onPressed: onTap,
          icon: Icon(icon, size: 18),
          visualDensity: VisualDensity.compact,
          style: IconButton.styleFrom(
            backgroundColor: color.withValues(alpha: 0.12),
            foregroundColor: color,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: EdgeInsets.zero,
            minimumSize: const Size(34, 34),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      ),
    );
  }
}
