import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_models.dart';
import '../state/hospital_app_state.dart';
import '../widgets/dialog_utils.dart';
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
          SectionCard(
            title: '病种模板',
            action: FilledButton(
              onPressed: () => _openDiseaseDialog(context),
              child: const Text('新增病种'),
            ),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: '按病种名称或编码搜索',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
          ),
          for (final disease in diseases)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _DiseaseCard(
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
    final nameController = TextEditingController(text: editing?.diseaseName ?? '');
    final codeController = TextEditingController(text: editing?.diseaseCode ?? '');
    final descController = TextEditingController(text: editing?.description ?? '');
    final formKey = GlobalKey<FormState>();
    final state = context.read<HospitalAppState>();

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(editing == null ? '新增病种' : '编辑病种'),
          content: SizedBox(
            width: 420,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: '病种名称 *'),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return '请输入病种名称';
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: codeController,
                    decoration: const InputDecoration(labelText: '病种编码'),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: descController,
                    decoration: const InputDecoration(labelText: '说明'),
                    minLines: 3,
                    maxLines: 4,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) return;
                final ok = state.upsertTemplateDisease(
                  editingId: editing?.id,
                  diseaseName: nameController.text,
                  diseaseCode: codeController.text,
                  description: descController.text,
                );
                if (ok) {
                  Navigator.of(context).pop();
                }
              },
              child: const Text('保存'),
            ),
          ],
        );
      },
    );

    nameController.dispose();
    codeController.dispose();
    descController.dispose();
  }

  Future<void> _openVersionDialog(
    BuildContext context, {
    required String diseaseId,
    TemplateVersion? editing,
  }) async {
    final nameController = TextEditingController(text: editing?.versionName ?? '');
    final yearController = TextEditingController(text: editing?.year ?? '');
    final descController = TextEditingController(text: editing?.description ?? '');
    final formKey = GlobalKey<FormState>();
    final state = context.read<HospitalAppState>();

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(editing == null ? '新增版本' : '编辑版本'),
          content: SizedBox(
            width: 420,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: '版本名称 *'),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return '请输入版本名称';
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: yearController,
                    decoration: const InputDecoration(labelText: '年份'),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: descController,
                    decoration: const InputDecoration(labelText: '说明'),
                    minLines: 3,
                    maxLines: 4,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) return;
                final ok = state.upsertTemplateVersion(
                  diseaseId: diseaseId,
                  editingId: editing?.id,
                  versionName: nameController.text,
                  year: yearController.text,
                  description: descController.text,
                );
                if (ok) {
                  Navigator.of(context).pop();
                }
              },
              child: const Text('保存'),
            ),
          ],
        );
      },
    );

    nameController.dispose();
    yearController.dispose();
    descController.dispose();
  }

  Future<void> _deleteDisease(BuildContext context, String diseaseId) async {
    final confirmed = await showDeleteConfirmDialog(
      context,
      title: '删除病种',
      content: '确认删除该病种及其所有版本、测评项和分级规则吗？',
    );
    if (!confirmed) return;
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
    context.read<HospitalAppState>().deleteTemplateVersion(diseaseId, versionId);
  }
}

class _DiseaseCard extends StatelessWidget {
  const _DiseaseCard({
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
    return Card(
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          disease.diseaseName,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF22364E),
                          ),
                        ),
                        if (disease.diseaseCode.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            disease.diseaseCode,
                            style: const TextStyle(
                              color: Color(0xFF6A7D95),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  _TinyAction(title: '编辑', color: const Color(0xFF2B88D8), onTap: onEditDisease),
                  _TinyAction(title: '删除', color: const Color(0xFFD34E66), onTap: onDeleteDisease),
                  Icon(
                    expanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    color: const Color(0xFF607A98),
                    size: 26,
                  ),
                ],
              ),
            ),
          ),
          if (expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.tonal(
                      onPressed: onAddVersion,
                      child: const Text('新增版本'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (disease.versions.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Text(
                        '暂无版本，点击右上角新增',
                        style: TextStyle(color: Color(0xFF7588A1)),
                      ),
                    ),
                  for (final version in disease.versions)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4F8FD),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFD9E4F3)),
                        ),
                        child: InkWell(
                          onTap: () => onOpenVersion(version),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(10, 8, 6, 8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${version.versionName}${version.year.isEmpty ? '' : ' · ${version.year}'}',
                                    style: const TextStyle(
                                      color: Color(0xFF263D59),
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                _TinyAction(
                                  title: '编辑',
                                  color: const Color(0xFF2C88D8),
                                  onTap: () => onEditVersion(version),
                                ),
                                _TinyAction(
                                  title: '删除',
                                  color: const Color(0xFFD34E66),
                                  onTap: () => onDeleteVersion(version),
                                ),
                                const Icon(
                                  Icons.chevron_right_rounded,
                                  size: 25,
                                  color: Color(0xFF607A98),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
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
