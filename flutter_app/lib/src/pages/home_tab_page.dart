import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_models.dart';
import '../state/hospital_app_state.dart';
import '../widgets/dialog_utils.dart';
import '../widgets/dynamic_form_dialog.dart';
import '../widgets/field_grid.dart';
import '../widgets/responsive_layout.dart';
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
    final listSchema = state
        .listSchemaOf('patient')
        .where((field) => field.key != 'name' && field.key != 'admissionNo')
        .toList();
    final patients = state.filteredPatients;
    final nursingLevels = state.patientNursingLevels;
    final nursingLevelFilter = state.patientNursingLevelFilter;
    final nursingLevelCounts = state.patientNursingLevelCounts;
    final nursingLevelColors = state.patientNursingLevelColors;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          '首页',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final layout = ResponsiveLayout.fromWidth(constraints.maxWidth);
          return ResponsiveBody(
            layout: layout,
            child: ListView(
              padding: layout.listPadding(bottom: 100),
              children: [
                _HeroCard(
                  patientCount: state.patientCount,
                  inHospitalCount: state.inHospitalCount,
                  filterActive: state.patientInHospitalOnly,
                  onToggleFilter: state.toggleInHospitalFilter,
                  nursingLevels: nursingLevels,
                  activeNursingLevel: nursingLevelFilter,
                  nursingLevelCounts: nursingLevelCounts,
                  nursingLevelColors: nursingLevelColors,
                  onSelectNursingLevel: state.setPatientNursingLevelFilter,
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                    Tooltip(
                      message: '新增病人',
                      child: IconButton.filled(
                        onPressed: () => _openPatientDialog(context),
                        icon: const Icon(Icons.add_rounded),
                        iconSize: 20,
                        visualDensity: layout.isTablet
                            ? VisualDensity.standard
                            : VisualDensity.compact,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (patients.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 20),
                    child: Center(
                      child: Text(
                        '暂无病人记录',
                        style: TextStyle(color: Color(0xFF7488A4)),
                      ),
                    ),
                  )
                else if (layout.useTwoPane)
                  LayoutBuilder(
                    builder: (context, box) {
                      const gap = 10.0;
                      final itemWidth = (box.maxWidth - gap) / 2;
                      return Wrap(
                        spacing: gap,
                        runSpacing: 10,
                        children: [
                          for (final patient in patients)
                            SizedBox(
                              width: itemWidth,
                              child: _PatientCard(
                                patient: patient,
                                listSchema: listSchema,
                                nursingLevelColors: nursingLevelColors,
                                onOpen: () => _openPatientDetail(
                                    context, patient.admissionNo),
                                onEdit: () => _openPatientDialog(context,
                                    editing: patient),
                                onDelete: () => _deletePatient(
                                    context, patient.admissionNo),
                              ),
                            ),
                        ],
                      );
                    },
                  )
                else
                  for (final patient in patients)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _PatientCard(
                        patient: patient,
                        listSchema: listSchema,
                        nursingLevelColors: nursingLevelColors,
                        onOpen: () =>
                            _openPatientDetail(context, patient.admissionNo),
                        onEdit: () =>
                            _openPatientDialog(context, editing: patient),
                        onDelete: () =>
                            _deletePatient(context, patient.admissionNo),
                      ),
                    ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _openPatientDetail(
      BuildContext context, String admissionNo) async {
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
    final initial = _buildInitialValues(
        schema, editing?.values ?? const <String, dynamic>{});

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
    required this.nursingLevels,
    required this.activeNursingLevel,
    required this.nursingLevelCounts,
    required this.nursingLevelColors,
    required this.onSelectNursingLevel,
  });

  final int patientCount;
  final int inHospitalCount;
  final bool filterActive;
  final VoidCallback onToggleFilter;
  final List<String> nursingLevels;
  final String activeNursingLevel;
  final Map<String, int> nursingLevelCounts;
  final Map<String, String> nursingLevelColors;
  final ValueChanged<String> onSelectNursingLevel;

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
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
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
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _NursingFilterChip(
                  text: '全部 $patientCount',
                  active: activeNursingLevel.isEmpty,
                  color: null,
                  onTap: () => onSelectNursingLevel(''),
                ),
                for (final level in nursingLevels)
                  _NursingFilterChip(
                    text: '$level ${nursingLevelCounts[level] ?? 0}',
                    active: activeNursingLevel == level,
                    color: _parseHexColor(nursingLevelColors[level]),
                    onTap: () => onSelectNursingLevel(level),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NursingFilterChip extends StatelessWidget {
  const _NursingFilterChip({
    required this.text,
    required this.active,
    required this.color,
    required this.onTap,
  });

  final String text;
  final bool active;
  final Color? color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final toneColor = color ?? const Color(0xFF8FA6C2);
    final background = active
        ? Color.alphaBlend(
            toneColor.withValues(alpha: 0.26), const Color(0xFFF5F9FF))
        : const Color(0xFFF7FBFF);
    final border =
        active ? toneColor.withValues(alpha: 0.55) : const Color(0xFFDCE7F5);
    final textColor =
        active ? const Color(0xFF1F3149) : const Color(0xFF5A6A7E);
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: border),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: textColor,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
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
    return SizedBox(
      height: 66,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF7FBFF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5EEF9)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8.5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
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
        child: SizedBox(
          height: 66,
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
                color:
                    active ? const Color(0xFF84B8F2) : const Color(0xFFE5EEF9),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8.5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Text(
                      '在院病人',
                      style: TextStyle(
                        color: active
                            ? const Color(0xFF2F5F96)
                            : const Color(0xFF5A6A7E),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      active
                          ? Icons.filter_alt_rounded
                          : Icons.filter_alt_outlined,
                      size: 14,
                      color: active
                          ? const Color(0xFF2F5F96)
                          : const Color(0xFF8AA0BC),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: active
                        ? const Color(0xFF2F5F96)
                        : const Color(0xFF1F3149),
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
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
    required this.nursingLevelColors,
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
  });

  final PatientRecord patient;
  final List<FieldSchema> listSchema;
  final Map<String, String> nursingLevelColors;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final nursingLevel =
        (patient.values['nursingLevel'] ?? '').toString().trim();
    final nursingColor = _parseHexColor(nursingLevelColors[nursingLevel]);
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFDCE7F5)),
      ),
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
                  if (nursingLevel.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        color: nursingColor == null
                            ? const Color(0xFFF5F9FF)
                            : Color.alphaBlend(
                                nursingColor.withValues(alpha: 0.20),
                                const Color(0xFFF5F9FF),
                              ),
                        border: Border.all(
                          color: nursingColor == null
                              ? const Color(0xFFD9E5F4)
                              : nursingColor.withValues(alpha: 0.58),
                        ),
                      ),
                      child: Text(
                        nursingLevel,
                        style: TextStyle(
                          color: nursingColor == null
                              ? const Color(0xFF4E627D)
                              : const Color(0xFF314560),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                    title: '编辑病人',
                    icon: Icons.edit_rounded,
                    color: const Color(0xFF2C89D8),
                    onTap: onEdit,
                  ),
                  _ActionText(
                    title: '删除病人',
                    icon: Icons.delete_outline_rounded,
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

Color? _parseHexColor(String? raw) {
  final value = (raw ?? '').trim();
  if (value.isEmpty) return null;
  var hex = value.replaceAll('#', '');
  if (hex.length == 6) {
    hex = 'FF$hex';
  }
  if (hex.length != 8) return null;
  final parsed = int.tryParse(hex, radix: 16);
  if (parsed == null) return null;
  return Color(parsed);
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
