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
    final admissionListSchema = state.listSchemaOf('admission')
        .where((f) => f.key != 'admitDate')
        .toList();
    final admissions = state.admissionsOf(admissionNo);

    return Scaffold(
      appBar: _buildAppBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
        children: [
          SectionCard(
            title: '病人概况',
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
    final title = (row.values['admitDate'] ?? '-').toString();
    final status = (row.values['status'] ?? '').toString();

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
                        if (status.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: status == '在院'
                                  ? const Color(0xFFE6F3E9)
                                  : const Color(0xFFEEF2F7),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: status == '在院'
                                    ? const Color(0xFFB5D8BC)
                                    : const Color(0xFFCFD7E2),
                              ),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: status == '在院'
                                    ? const Color(0xFF2A7F3D)
                                    : const Color(0xFF596C84),
                              ),
                            ),
                          ),
                        _InlineAction(title: '编辑', color: const Color(0xFF2888D8), onTap: onEdit),
                        _InlineAction(title: '删除', color: const Color(0xFFD34C64), onTap: onDelete),
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
              const SizedBox(width: 2),
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
      padding: const EdgeInsets.only(left: 5),
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
