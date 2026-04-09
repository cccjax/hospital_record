import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/app_models.dart';
import '../state/hospital_app_state.dart';
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

    final patientSchema = state.schemaOf('patient').where((f) => f.key != 'admissionNo').toList();
    final admissionListSchema = state.listSchemaOf('admission').where((f) => f.key != 'admitDate').toList();
    final admissions = state.admissionsOf(admissionNo);
    final totalDailyCount = admissions.fold<int>(0, (sum, row) => sum + state.dailyOf(row.id).length);

    return Scaffold(
      appBar: _buildAppBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
        children: [
          _HeroSummary(
            patientName: (patient.values['name'] ?? '未命名病人').toString(),
            admissionNo: admissionNo,
            admissionCount: admissions.length,
            dailyCount: totalDailyCount,
          ),
          const SizedBox(height: 10),
          SectionCard(
            title: '基础信息',
            action: FilledButton.tonal(
              onPressed: () => _openPatientEditDialog(context, patient),
              child: const Text('编辑基础信息'),
            ),
            child: FieldGrid(
              schema: patientSchema,
              values: patient.values,
            ),
          ),
          SectionCard(
            title: '入院记录',
            action: FilledButton.tonal(
              onPressed: () => _openCreateAdmissionDialog(context),
              child: const Text('新增入院'),
            ),
            child: Column(
              children: [
                for (final admission in admissions)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _AdmissionCard(
                      row: admission,
                      listSchema: admissionListSchema,
                      onOpen: () => _openAdmissionDetail(context, admission.id),
                      onEdit: () => _openEditAdmissionDialog(context, admission),
                      onDelete: () => _deleteAdmission(context, admission.id),
                    ),
                  ),
                if (admissions.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      '暂无入院记录',
                      style: TextStyle(color: Color(0xFF7A8CA4)),
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
        '病人明细',
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
    );
  }

  Future<void> _openAdmissionDetail(BuildContext context, String admissionId) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AdmissionDetailPage(admissionId: admissionId),
      ),
    );
  }

  Future<void> _openPatientEditDialog(BuildContext context, PatientRecord patient) async {
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

  Future<void> _openEditAdmissionDialog(BuildContext context, AdmissionRecord admission) async {
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

  Future<void> _deleteAdmission(BuildContext context, String admissionId) async {
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

class _HeroSummary extends StatelessWidget {
  const _HeroSummary({
    required this.patientName,
    required this.admissionNo,
    required this.admissionCount,
    required this.dailyCount,
  });

  final String patientName;
  final String admissionNo;
  final int admissionCount;
  final int dailyCount;

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
            const SizedBox(height: 4),
            Text(
              '住院号 $admissionNo · 基础信息与住院过程记录',
              style: const TextStyle(
                color: Color(0xFF5F6F85),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _HeroStat(
                    label: '入院记录',
                    value: '$admissionCount',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _HeroStat(
                    label: '日常记录',
                    value: '$dailyCount',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF7FBFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5EEF9)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF5A6A7E),
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF1F3149),
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
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
    final title = (row.values['admitDate'] ?? '-').toString();
    final status = (row.values['status'] ?? '').toString();

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
                        if (status.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: status == '在院'
                                  ? const Color(0xFFE8F7F3)
                                  : const Color(0xFFF5F9FF),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: status == '在院'
                                    ? const Color(0xFFBDE6DD)
                                    : const Color(0xFFD9E5F4),
                              ),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: status == '在院'
                                    ? const Color(0xFF0F695F)
                                    : const Color(0xFF596C84),
                                fontSize: 12,
                              ),
                            ),
                          ),
                        const SizedBox(width: 5),
                        _InlineAction(title: '编辑', color: const Color(0xFF2888D8), onTap: onEdit),
                        _InlineAction(title: '删除', color: const Color(0xFFD34C64), onTap: onDelete),
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
              const SizedBox(width: 4),
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

class _InlineAction extends StatelessWidget {
  const _InlineAction({
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
      padding: const EdgeInsets.only(left: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          child: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: color,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}
