import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_models.dart';
import '../state/hospital_app_state.dart';
import '../widgets/dialog_utils.dart';
import '../widgets/dynamic_form_dialog.dart';
import '../widgets/field_grid.dart';
import 'patient_detail_page.dart';

class HomeTabPage extends StatefulWidget {
  const HomeTabPage({super.key});

  @override
  State<HomeTabPage> createState() => _HomeTabPageState();
}

class _HomeTabPageState extends State<HomeTabPage> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    final state = context.read<HospitalAppState>();
    _searchController = TextEditingController(text: state.patientSearchQuery);
    _searchController.addListener(() {
      state.setPatientSearchQuery(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<HospitalAppState>();
    final listSchema = state.listSchemaOf('patient')
        .where((field) => field.key != 'name' && field.key != 'admissionNo')
        .toList();

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          '首页',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
        children: [
          _HeroCard(
            patientCount: state.patientCount,
            inHospitalCount: state.inHospitalCount,
            filterActive: state.patientInHospitalOnly,
            onToggleFilter: state.toggleInHospitalFilter,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: '输入住院号/姓名搜索',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () => _openPatientDialog(context),
                child: const Text('新增'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final patient in state.filteredPatients)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _PatientCard(
                patient: patient,
                listSchema: listSchema,
                onOpen: () => _openPatientDetail(context, patient.admissionNo),
                onEdit: () => _openPatientDialog(context, editing: patient),
                onDelete: () => _deletePatient(context, patient.admissionNo),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _openPatientDetail(BuildContext context, String admissionNo) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PatientDetailPage(admissionNo: admissionNo),
      ),
    );
  }

  Future<void> _openPatientDialog(
    BuildContext context, {
    PatientRecord? editing,
  }) async {
    final state = context.read<HospitalAppState>();
    final schema = state.schemaOf('patient');
    final initial = _buildInitialValues(schema, editing?.values ?? const <String, dynamic>{});

    await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return DynamicFormDialog(
          title: editing == null ? '新增病人' : '编辑病人',
          schema: schema,
          initialValues: initial,
          onSubmit: (values) async {
            final ok = state.upsertPatient(
              values: values,
              editingAdmissionNo: editing?.admissionNo,
            );
            return ok ? null : (state.takeLastErrorMessage() ?? '保存失败');
          },
        );
      },
    );
  }

  Future<void> _deletePatient(BuildContext context, String admissionNo) async {
    final confirmed = await showDeleteConfirmDialog(
      context,
      title: '删除病人',
      content: '删除后将同步删除该病人的入院记录、日常记录、测评和影像资料，是否继续？',
    );
    if (!confirmed) return;
    if (!context.mounted) return;
    context.read<HospitalAppState>().deletePatient(admissionNo);
  }

  Map<String, dynamic> _buildInitialValues(
    List<FieldSchema> schema,
    Map<String, dynamic> seed,
  ) {
    final next = <String, dynamic>{};
    for (final field in schema) {
      final raw = seed[field.key];
      if (raw != null) {
        next[field.key] = raw;
      } else if (field.type == FieldType.select) {
        next[field.key] = field.options.isNotEmpty ? field.options.first : '';
      } else {
        next[field.key] = '';
      }
    }
    return next;
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.patientCount,
    required this.inHospitalCount,
    required this.filterActive,
    required this.onToggleFilter,
  });

  final int patientCount;
  final int inHospitalCount;
  final bool filterActive;
  final VoidCallback onToggleFilter;

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
            const Text(
              '概览',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1F3149),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              '病人档案支持实时检索与快速编辑',
              style: TextStyle(
                color: Color(0xFF5F6F85),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _HeroMetric(
                    label: '病人总数',
                    value: '$patientCount',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _FilterStatCard(
                    value: '$inHospitalCount',
                    active: filterActive,
                    onTap: onToggleFilter,
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

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({
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

class _FilterStatCard extends StatelessWidget {
  const _FilterStatCard({
    required this.value,
    required this.active,
    required this.onTap,
  });

  final String value;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            gradient: active
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: <Color>[Color(0xFFE9F4FF), Color(0xFFF0F9FF)],
                  )
                : null,
            color: active ? null : const Color(0xFFF7FBFF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: active ? const Color(0xFF84B8F2) : const Color(0xFFE5EEF9),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8.5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '在院病人',
                style: TextStyle(
                  color: active ? const Color(0xFF2F5F96) : const Color(0xFF5A6A7E),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  color: active ? const Color(0xFF2F5F96) : const Color(0xFF1F3149),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                active ? '已筛选在院病人' : '点击筛选在院病人',
                style: TextStyle(
                  color: active ? const Color(0xFF2F5F96) : const Color(0xFF6582A7),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PatientCard extends StatelessWidget {
  const _PatientCard({
    required this.patient,
    required this.listSchema,
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
  });

  final PatientRecord patient;
  final List<FieldSchema> listSchema;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      (patient.values['name'] ?? '-').toString(),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1F3149),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: const Color(0xFFF5F9FF),
                      border: Border.all(color: const Color(0xFFD9E5F4)),
                    ),
                    child: Text(
                      '住院号 ${patient.admissionNo}',
                      style: const TextStyle(
                        color: Color(0xFF4E627D),
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 5),
                  _ActionText(
                    title: '编辑',
                    color: const Color(0xFF2C89D8),
                    onTap: onEdit,
                  ),
                  _ActionText(
                    title: '删除',
                    color: const Color(0xFFD54E67),
                    onTap: onDelete,
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: Color(0xFF7E95B3),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              FieldGrid(
                schema: listSchema,
                values: patient.values,
                compact: true,
              ),
            ],
          ),
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
      padding: const EdgeInsets.only(left: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          child: Text(
            title,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}
