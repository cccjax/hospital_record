import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_models.dart';
import '../state/hospital_app_state.dart';
import '../widgets/dialog_utils.dart';
import '../widgets/dynamic_form_dialog.dart';
import '../widgets/field_grid.dart';
import '../widgets/section_card.dart';
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
          SectionCard(
            title: '概览',
            action: FilledButton.tonal(
              onPressed: state.toggleInHospitalFilter,
              child: Text(state.patientInHospitalOnly ? '在院筛选: 开' : '在院筛选: 关'),
            ),
            child: Row(
              children: [
                _StatPill(label: '病人总数', value: '${state.patientCount}'),
                const SizedBox(width: 8),
                _StatPill(label: '在院病人', value: '${state.inHospitalCount}'),
              ],
            ),
          ),
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

class _StatPill extends StatelessWidget {
  const _StatPill({
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
          color: const Color(0xFFEEF4FD),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFD9E5F6)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF72849D),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: Color(0xFF1C3F67),
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
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
          padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      (patient.values['name'] ?? '-').toString(),
                      style: const TextStyle(
                        fontSize: 27,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E324A),
                      ),
                    ),
                  ),
                  Text(
                    patient.admissionNo,
                    style: const TextStyle(
                      color: Color(0xFF5B6F89),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 8),
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
                  const SizedBox(width: 2),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 28,
                    color: Color(0xFF68819E),
                  ),
                ],
              ),
              const SizedBox(height: 8),
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
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Text(
            title,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
