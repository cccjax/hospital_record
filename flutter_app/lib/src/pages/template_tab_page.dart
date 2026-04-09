import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_models.dart';
import '../state/hospital_app_state.dart';
import '../widgets/dialog_utils.dart';
import '../widgets/dynamic_form_dialog.dart';
import '../widgets/field_grid.dart';
import '../widgets/section_card.dart';
import 'template_version_page.dart';

class TemplateTabPage extends StatefulWidget {
  const TemplateTabPage({super.key});

  @override
  State<TemplateTabPage> createState() => _TemplateTabPageState();
}

class _TemplateTabPageState extends State<TemplateTabPage> {
  String _expandedDiseaseId = '';
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    final state = context.read<HospitalAppState>();
    _searchController = TextEditingController(text: state.templateSearchQuery);
    _searchController.addListener(() {
      state.setTemplateSearchQuery(_searchController.text);
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
    final diseases = state.filteredTemplateDiseases;
    final totalDiseases = state.data.templates.length;
    final totalVersions = state.data.templates.fold<int>(0, (sum, disease) => sum + disease.versions.length);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          '模板',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
        children: [
          _TemplateHeroCard(
            diseaseCount: totalDiseases,
            versionCount: totalVersions,
          ),
          const SizedBox(height: 10),
          SectionCard(
            title: '病种模板',
            action: FilledButton(
              onPressed: () => _openDiseaseDialog(context),
              child: const Text('新增病种'),
            ),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: '搜索病种名称或编码',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
          ),
          if (diseases.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text(
                '暂无病种模板，请先新增病种',
                style: TextStyle(color: Color(0xFF7588A1)),
              ),
            ),
          for (final disease in diseases)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _DiseaseCard(
                state: state,
                disease: disease,
                expanded: _expandedDiseaseId == disease.id,
                onToggle: () {
                  setState(() {
                    _expandedDiseaseId = _expandedDiseaseId == disease.id ? '' : disease.id;
                  });
                },
                onOpenVersion: (version) => _openVersionPage(context, disease.id, version.id),
                onAddVersion: () => _openVersionDialog(context, diseaseId: disease.id),
                onEditDisease: () => _openDiseaseDialog(context, editing: disease),
                onDeleteDisease: () => _deleteDisease(context, disease.id),
                onEditVersion: (version) =>
                    _openVersionDialog(context, diseaseId: disease.id, editing: version),
                onDeleteVersion: (version) => _deleteVersion(context, disease.id, version.id),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _openVersionPage(
    BuildContext context,
    String diseaseId,
    String versionId,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TemplateVersionPage(
          diseaseId: diseaseId,
          versionId: versionId,
        ),
      ),
    );
  }

  Future<void> _openDiseaseDialog(
    BuildContext context, {
    TemplateDisease? editing,
  }) async {
    final state = context.read<HospitalAppState>();
    final moduleSchema = state
        .schemaOf('templateDisease')
        .where((field) => !field.computed && field.key != 'diseaseName')
        .toList();
    final dialogSchema = <FieldSchema>[
      const FieldSchema(
        key: 'diseaseName',
        label: '病种名称',
        type: FieldType.text,
        required: true,
        locked: false,
        showInList: true,
        computed: false,
        options: <String>[],
      ),
      ...moduleSchema,
    ];
    final initialValues = <String, dynamic>{
      for (final field in dialogSchema)
        field.key: field.type == FieldType.select && field.options.isNotEmpty
            ? field.options.first
            : '',
    };
    if (editing != null) {
      initialValues['diseaseName'] = editing.diseaseName;
      for (final field in moduleSchema) {
        initialValues[field.key] = state.templateDiseaseFieldValue(editing, field.key) ?? '';
      }
    }

    await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return DynamicFormDialog(
          title: editing == null ? '新增病种' : '编辑病种',
          schema: dialogSchema,
          initialValues: initialValues,
          onSubmit: (values) async {
            final ok = state.upsertTemplateDisease(
              editingId: editing?.id,
              values: values,
            );
            return ok ? null : (state.takeLastErrorMessage() ?? '保存失败');
          },
        );
      },
    );
  }

  Future<void> _openVersionDialog(
    BuildContext context, {
    required String diseaseId,
    TemplateVersion? editing,
  }) async {
    final state = context.read<HospitalAppState>();
    final moduleSchema = state
        .schemaOf('templateVersion')
        .where((field) => !field.computed && field.key != 'versionName')
        .toList();
    final dialogSchema = <FieldSchema>[
      const FieldSchema(
        key: 'versionName',
        label: '版本名称',
        type: FieldType.text,
        required: true,
        locked: false,
        showInList: true,
        computed: false,
        options: <String>[],
      ),
      ...moduleSchema,
    ];
    final initialValues = <String, dynamic>{
      for (final field in dialogSchema)
        field.key: field.type == FieldType.select && field.options.isNotEmpty
            ? field.options.first
            : '',
    };
    if (editing != null) {
      initialValues['versionName'] = editing.versionName;
      for (final field in moduleSchema) {
        initialValues[field.key] = state.templateVersionFieldValue(editing, field.key) ?? '';
      }
    }

    await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return DynamicFormDialog(
          title: editing == null ? '新增版本' : '编辑版本',
          schema: dialogSchema,
          initialValues: initialValues,
          onSubmit: (values) async {
            final ok = state.upsertTemplateVersion(
              diseaseId: diseaseId,
              editingId: editing?.id,
              values: values,
            );
            return ok ? null : (state.takeLastErrorMessage() ?? '保存失败');
          },
        );
      },
    );
  }

  Future<void> _deleteDisease(BuildContext context, String diseaseId) async {
    final confirmed = await showDeleteConfirmDialog(
      context,
      title: '删除病种',
      content: '确认删除该病种及其所有版本、测评项和分级规则吗？',
    );
    if (!confirmed) return;
    if (!context.mounted) return;
    context.read<HospitalAppState>().deleteTemplateDisease(diseaseId);
  }

  Future<void> _deleteVersion(
    BuildContext context,
    String diseaseId,
    String versionId,
  ) async {
    final confirmed = await showDeleteConfirmDialog(
      context,
      title: '删除版本',
      content: '确认删除该测评版本吗？',
    );
    if (!confirmed) return;
    if (!context.mounted) return;
    context.read<HospitalAppState>().deleteTemplateVersion(diseaseId, versionId);
  }
}

class _TemplateHeroCard extends StatelessWidget {
  const _TemplateHeroCard({
    required this.diseaseCount,
    required this.versionCount,
  });

  final int diseaseCount;
  final int versionCount;

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
        child: Row(
          children: [
            Expanded(child: _MetricCard(label: '病种模板', value: '$diseaseCount')),
            const SizedBox(width: 8),
            Expanded(child: _MetricCard(label: '版本数量', value: '$versionCount')),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
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

class _DiseaseCard extends StatelessWidget {
  const _DiseaseCard({
    required this.state,
    required this.disease,
    required this.expanded,
    required this.onToggle,
    required this.onOpenVersion,
    required this.onAddVersion,
    required this.onEditDisease,
    required this.onDeleteDisease,
    required this.onEditVersion,
    required this.onDeleteVersion,
  });

  final HospitalAppState state;
  final TemplateDisease disease;
  final bool expanded;
  final VoidCallback onToggle;
  final ValueChanged<TemplateVersion> onOpenVersion;
  final VoidCallback onAddVersion;
  final VoidCallback onEditDisease;
  final VoidCallback onDeleteDisease;
  final ValueChanged<TemplateVersion> onEditVersion;
  final ValueChanged<TemplateVersion> onDeleteVersion;

  @override
  Widget build(BuildContext context) {
    final diseaseSchema = state.listSchemaOf('templateDisease');
    final diseaseValues = <String, dynamic>{
      for (final field in diseaseSchema)
        field.key: state.templateDiseaseFieldValue(disease, field.key),
    };

    return Card(
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          disease.diseaseName.isEmpty ? '未命名病种' : disease.diseaseName,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1F3149),
                          ),
                        ),
                      ),
                      _TinyAction(title: '编辑', color: const Color(0xFF2B88D8), onTap: onEditDisease),
                      _TinyAction(title: '删除', color: const Color(0xFFD34E66), onTap: onDeleteDisease),
                      SizedBox(
                        width: 20,
                        child: Icon(
                          expanded
                              ? Icons.keyboard_arrow_down_rounded
                              : Icons.keyboard_arrow_right_rounded,
                          color: const Color(0xFF7E95B3),
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                  if (diseaseSchema.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    FieldGrid(
                      schema: diseaseSchema,
                      values: diseaseValues,
                      compact: true,
                      columns: 2,
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              child: Container(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFD3E1F4), style: BorderStyle.solid),
                  color: const Color(0xFFF7FBFF),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            '版本列表',
                            style: TextStyle(
                              color: Color(0xFF5F738C),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        FilledButton.tonal(
                          onPressed: onAddVersion,
                          child: const Text('新增版本'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (disease.versions.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: Text(
                          '当前病种暂无版本，请先新增版本',
                          style: TextStyle(color: Color(0xFF7588A1)),
                        ),
                      ),
                    for (final version in disease.versions)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _VersionCard(
                          state: state,
                          version: version,
                          onOpen: () => onOpenVersion(version),
                          onEdit: () => onEditVersion(version),
                          onDelete: () => onDeleteVersion(version),
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _VersionCard extends StatelessWidget {
  const _VersionCard({
    required this.state,
    required this.version,
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
  });

  final HospitalAppState state;
  final TemplateVersion version;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final versionSchema = state.listSchemaOf('templateVersion');
    final versionValues = <String, dynamic>{
      for (final field in versionSchema)
        field.key: state.templateVersionFieldValue(version, field.key),
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDCE8F6)),
      ),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      version.versionName.isEmpty ? '未命名版本' : version.versionName,
                      style: const TextStyle(
                        color: Color(0xFF1F3149),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  _TinyAction(title: '编辑', color: const Color(0xFF2C88D8), onTap: onEdit),
                  _TinyAction(title: '删除', color: const Color(0xFFD34E66), onTap: onDelete),
                  const SizedBox(
                    width: 20,
                    child: Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: Color(0xFF7E95B3),
                    ),
                  ),
                ],
              ),
              if (versionSchema.isNotEmpty) ...[
                const SizedBox(height: 8),
                FieldGrid(
                  schema: versionSchema,
                  values: versionValues,
                  compact: true,
                  columns: 2,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TinyAction extends StatelessWidget {
  const _TinyAction({
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
