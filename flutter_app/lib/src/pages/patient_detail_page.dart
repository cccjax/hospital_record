import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/app_models.dart';
import '../state/hospital_app_state.dart';
import '../widgets/app_add_button.dart';
import '../widgets/app_back_button.dart';
import '../widgets/dialog_utils.dart';
import '../widgets/dynamic_form_dialog.dart';
import '../widgets/field_grid.dart';
import '../widgets/section_card.dart';
import 'admission_detail_page.dart';

class PatientDetailPage extends StatelessWidget {
  const PatientDetailPage({
    super.key,
    required this.admissionNo,
  });

  final String admissionNo;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<HospitalAppState>();
    final patient = state.findPatient(admissionNo);
    if (patient == null) {
      return Scaffold(
        appBar: _buildAppBar(),
        body: const Center(child: Text('病人不存在')),
      );
    }

    final patientSchema =
        state.schemaOf('patient').where((f) => f.key != 'admissionNo').toList();
    final admissionListSchema = state
        .listSchemaOf('admission')
        .where((f) => f.key != 'admitDate')
        .toList();
    final admissions = state.admissionsOf(admissionNo);
    final admissionCount = admissions.length;

    return Scaffold(
      appBar: _buildAppBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
        children: [
          SectionCard(
            title: '基础信息',
            action: _HeaderIconAction(
              title: '编辑基础信息',
              icon: Icons.edit_rounded,
              onTap: () => _openPatientEditDialog(context, patient),
            ),
            child: FieldGrid(
              schema: patientSchema,
              values: patient.values,
              variant: FieldGridVariant.table,
              showColumnDivider: false,
            ),
          ),
          SectionCard(
            title: '入院记录',
            action: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _CountPill(text: '$admissionCount 条'),
                const SizedBox(width: 6),
                _HeaderIconAction(
                  title: '新增入院记录',
                  icon: Icons.add_rounded,
                  onTap: () => _openCreateAdmissionDialog(context),
                ),
              ],
            ),
            child: admissions.isEmpty
                ? const _EmptySectionHint(
                    text: '暂无入院记录',
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
                          for (final admission in admissions)
                            SizedBox(
                              width: cardWidth,
                              child: _AdmissionCard(
                                row: admission,
                                listSchema: admissionListSchema,
                                onOpen: () =>
                                    _openAdmissionDetail(context, admission.id),
                                onEdit: () => _openEditAdmissionDialog(
                                    context, admission),
                                onDelete: () =>
                                    _deleteAdmission(context, admission.id),
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
        '病人明细',
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
    );
  }

  Future<void> _openAdmissionDetail(
      BuildContext context, String admissionId) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AdmissionDetailPage(admissionId: admissionId),
      ),
    );
  }

  Future<void> _openPatientEditDialog(
      BuildContext context, PatientRecord patient) async {
    final state = context.read<HospitalAppState>();
    final schema = state.schemaOf('patient');
    await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return DynamicFormDialog(
          title: '编辑病人信息',
          schema: schema,
          initialValues: patient.values,
          onSubmit: (values) async {
            final ok = state.upsertPatient(
              values: values,
              editingAdmissionNo: patient.admissionNo,
            );
            return ok ? null : (state.takeLastErrorMessage() ?? '保存失败');
          },
        );
      },
    );
  }

  Future<void> _openCreateAdmissionDialog(BuildContext context) async {
    final state = context.read<HospitalAppState>();
    if (state.hasInHospitalAdmission(admissionNo)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('该病人已有在院记录，不能重复新增入院')),
      );
      return;
    }

    final schema = state.schemaOf('admission');
    final now = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final initial = <String, dynamic>{
      for (final field in schema)
        field.key: field.type == FieldType.select && field.options.isNotEmpty
            ? field.options.first
            : '',
      'admitDate': now,
      'status': '在院',
    };

    await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return DynamicFormDialog(
          title: '新增入院记录',
          schema: schema,
          initialValues: initial,
          onSubmit: (values) async {
            final ok = state.upsertAdmission(
              admissionNo: admissionNo,
              values: values,
            );
            return ok ? null : (state.takeLastErrorMessage() ?? '保存失败');
          },
        );
      },
    );
  }

  Future<void> _openEditAdmissionDialog(
      BuildContext context, AdmissionRecord admission) async {
    final state = context.read<HospitalAppState>();
    final schema = state.schemaOf('admission');
    await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return DynamicFormDialog(
          title: '编辑入院记录',
          schema: schema,
          initialValues: admission.values,
          onSubmit: (values) async {
            final ok = state.upsertAdmission(
              admissionNo: admissionNo,
              values: values,
              editingId: admission.id,
            );
            return ok ? null : (state.takeLastErrorMessage() ?? '保存失败');
          },
        );
      },
    );
  }

  Future<void> _deleteAdmission(
      BuildContext context, String admissionId) async {
    final confirmed = await showDeleteConfirmDialog(
      context,
      title: '删除入院记录',
      content: '删除后该入院下的日常记录、测评记录与影像资料也会一起删除，是否继续？',
    );
    if (!confirmed) return;
    if (!context.mounted) return;
    context.read<HospitalAppState>().deleteAdmission(admissionId);
  }
}

class _AdmissionCard extends StatelessWidget {
  const _AdmissionCard({
    required this.row,
    required this.listSchema,
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
  });

  final AdmissionRecord row;
  final List<FieldSchema> listSchema;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final title = (row.values['admitDate'] ?? '-').toString().trim();
    final status = (row.values['status'] ?? '').toString();
    final isInHospital = status == '在院';
    final infoRows = _buildInfoRows();

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
                                  Icons.calendar_month_rounded,
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
                              if (status.isNotEmpty) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isInHospital
                                        ? const Color(0xFFE8F7F3)
                                        : const Color(0xFFF5F9FF),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: isInHospital
                                          ? const Color(0xFFBDE6DD)
                                          : const Color(0xFFD9E5F4),
                                    ),
                                  ),
                                  child: Text(
                                    status,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: isInHospital
                                          ? const Color(0xFF0F695F)
                                          : const Color(0xFF596C84),
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        _InlineAction(
                          title: '编辑入院记录',
                          icon: Icons.edit_rounded,
                          color: const Color(0xFF2888D8),
                          onTap: onEdit,
                        ),
                        _InlineAction(
                          title: '删除入院记录',
                          icon: Icons.delete_outline_rounded,
                          color: const Color(0xFFD34C64),
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

  List<_AdmissionInfoRow> _buildInfoRows() {
    final rows = <_AdmissionInfoRow>[];
    for (final field in listSchema) {
      if (field.key == 'status') continue;
      final raw = row.values[field.key];
      final text = (raw ?? '-').toString().trim();
      rows.add(
        _AdmissionInfoRow(
          label: field.label,
          value: text.isEmpty ? '-' : text,
        ),
      );
      if (rows.length >= 4) break;
    }
    if (rows.isEmpty) {
      return const <_AdmissionInfoRow>[
        _AdmissionInfoRow(label: '字段', value: '暂无可视字段'),
      ];
    }
    return rows;
  }
}

class _AdmissionInfoRow {
  const _AdmissionInfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;
}

class _InlineAction extends StatelessWidget {
  const _InlineAction({
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
        width: 30,
        height: 30,
        child: IconButton(
          onPressed: onTap,
          icon: Icon(icon, size: 16),
          visualDensity: VisualDensity.compact,
          style: IconButton.styleFrom(
            backgroundColor: color.withValues(alpha: 0.12),
            foregroundColor: color,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(9),
            ),
            padding: EdgeInsets.zero,
            minimumSize: const Size(30, 30),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
        size: 34,
        iconSize: 18,
        borderRadius: 10,
      );
    }
    return Tooltip(
      message: title,
      child: FilledButton.tonal(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          minimumSize: const Size(34, 34),
          maximumSize: const Size(34, 34),
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          visualDensity: VisualDensity.compact,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Icon(icon, size: 18),
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
