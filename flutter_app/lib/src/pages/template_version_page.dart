import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_models.dart';
import '../state/hospital_app_state.dart';
import '../widgets/app_back_button.dart';
import '../widgets/dialog_utils.dart';
import '../widgets/section_card.dart';

class TemplateVersionPage extends StatelessWidget {
  const TemplateVersionPage({
    super.key,
    required this.diseaseId,
    required this.versionId,
  });

  final String diseaseId;
  final String versionId;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<HospitalAppState>();
    final disease = state.findDisease(diseaseId);
    final version = state.findVersion(diseaseId, versionId);
    if (disease == null || version == null) {
      return Scaffold(
        appBar: _buildAppBar(),
        body: const Center(child: Text('模板版本不存在')),
      );
    }

    return Scaffold(
      appBar: _buildAppBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
        children: [
          Text(
            '${disease.diseaseName} · ${version.versionName}',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF24405D),
            ),
          ),
          const SizedBox(height: 10),
          SectionCard(
            title: '测评项配置',
            action: FilledButton.tonal(
              onPressed: () => _openItemDialog(context),
              child: const Text('新增测评项'),
            ),
            child: Column(
              children: [
                for (final item in version.items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _ItemCard(
                      item: item,
                      onEdit: () => _openItemDialog(context, editing: item),
                      onDelete: () => _deleteItem(context, item.id),
                    ),
                  ),
                if (version.items.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      '暂无测评项',
                      style: TextStyle(color: Color(0xFF7588A1)),
                    ),
                  ),
              ],
            ),
          ),
          SectionCard(
            title: '患病等级区间',
            action: FilledButton.tonal(
              onPressed: () => _openRuleDialog(context),
              child: const Text('新增区间'),
            ),
            child: Column(
              children: [
                for (final rule in version.gradeRules)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _RuleCard(
                      rule: rule,
                      onEdit: () => _openRuleDialog(context, editing: rule),
                      onDelete: () => _deleteRule(context, rule.id),
                    ),
                  ),
                if (version.gradeRules.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      '暂无分级区间',
                      style: TextStyle(color: Color(0xFF7588A1)),
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
        '测评项配置',
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
    );
  }

  Future<void> _openItemDialog(
    BuildContext context, {
    TemplateItem? editing,
  }) async {
    final state = context.read<HospitalAppState>();
    final nameController = TextEditingController(text: editing?.name ?? '');
    final drafts = (editing?.options ?? const <TemplateOption>[])
        .map(
          (option) => _OptionDraft(
            id: option.id,
            labelController: TextEditingController(text: option.label),
            scoreController: TextEditingController(text: option.score.toString()),
          ),
        )
        .toList();
    if (drafts.isEmpty) {
      drafts.add(_OptionDraft.empty(state.createRuntimeId('tplo')));
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(editing == null ? '新增测评项' : '编辑测评项'),
              content: SizedBox(
                width: 520,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(labelText: '测评项名称 *'),
                      ),
                      const SizedBox(height: 10),
                      for (var i = 0; i < drafts.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: drafts[i].labelController,
                                  decoration: InputDecoration(labelText: '选项 ${i + 1}'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 110,
                                child: TextField(
                                  controller: drafts[i].scoreController,
                                  decoration: const InputDecoration(labelText: '分值'),
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                              const SizedBox(width: 6),
                              IconButton(
                                onPressed: drafts.length <= 1
                                    ? null
                                    : () {
                                        final target = drafts.removeAt(i);
                                        target.dispose();
                                        setDialogState(() {});
                                      },
                                icon: const Icon(Icons.delete_outline_rounded),
                              ),
                            ],
                          ),
                        ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: FilledButton.tonal(
                          onPressed: () {
                            drafts.add(_OptionDraft.empty(state.createRuntimeId('tplo')));
                            setDialogState(() {});
                          },
                          child: const Text('新增选项'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('取消'),
                ),
                FilledButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    if (name.isEmpty) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(content: Text('请填写测评项名称')),
                      );
                      return;
                    }

                    final options = <TemplateOption>[];
                    for (final draft in drafts) {
                      final label = draft.labelController.text.trim();
                      final score = double.tryParse(draft.scoreController.text.trim()) ?? 0;
                      if (label.isEmpty) continue;
                      options.add(
                        TemplateOption(
                          id: draft.id,
                          label: label,
                          score: score,
                        ),
                      );
                    }
                    if (options.isEmpty) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(content: Text('至少保留一个选项')),
                      );
                      return;
                    }

                    final ok = state.upsertTemplateItem(
                      diseaseId: diseaseId,
                      versionId: versionId,
                      editingId: editing?.id,
                      name: name,
                      options: options,
                    );
                    if (ok) {
                      Navigator.of(dialogContext).pop();
                    }
                  },
                  child: const Text('保存'),
                ),
              ],
            );
          },
        );
      },
    );

    nameController.dispose();
    for (final draft in drafts) {
      draft.dispose();
    }
  }

  Future<void> _openRuleDialog(
    BuildContext context, {
    TemplateGradeRule? editing,
  }) async {
    final state = context.read<HospitalAppState>();
    final levelController = TextEditingController(text: editing?.level ?? '');
    final minController = TextEditingController(text: editing?.min.toString() ?? '');
    final maxController = TextEditingController(text: editing?.max.toString() ?? '');
    final noteController = TextEditingController(text: editing?.note ?? '');

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(editing == null ? '新增等级区间' : '编辑等级区间'),
          content: SizedBox(
            width: 440,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: levelController,
                  decoration: const InputDecoration(labelText: '区间名称 *'),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: minController,
                        decoration: const InputDecoration(labelText: '最小值'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: maxController,
                        decoration: const InputDecoration(labelText: '最大值'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: noteController,
                  decoration: const InputDecoration(labelText: '说明'),
                  minLines: 2,
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () {
                final level = levelController.text.trim();
                final min = double.tryParse(minController.text.trim()) ?? 0;
                final max = double.tryParse(maxController.text.trim()) ?? 0;
                if (level.isEmpty) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(content: Text('请填写区间名称')),
                  );
                  return;
                }
                final ok = state.upsertTemplateGradeRule(
                  diseaseId: diseaseId,
                  versionId: versionId,
                  editingId: editing?.id,
                  min: min,
                  max: max,
                  level: level,
                  note: noteController.text,
                );
                if (ok) {
                  Navigator.of(dialogContext).pop();
                }
              },
              child: const Text('保存'),
            ),
          ],
        );
      },
    );

    levelController.dispose();
    minController.dispose();
    maxController.dispose();
    noteController.dispose();
  }

  Future<void> _deleteItem(BuildContext context, String itemId) async {
    final confirmed = await showDeleteConfirmDialog(
      context,
      title: '删除测评项',
      content: '确认删除该测评项吗？',
    );
    if (!confirmed) return;
    context.read<HospitalAppState>().deleteTemplateItem(diseaseId, versionId, itemId);
  }

  Future<void> _deleteRule(BuildContext context, String ruleId) async {
    final confirmed = await showDeleteConfirmDialog(
      context,
      title: '删除等级区间',
      content: '确认删除该分级区间吗？',
    );
    if (!confirmed) return;
    context.read<HospitalAppState>().deleteTemplateGradeRule(diseaseId, versionId, ruleId);
  }
}

class _ItemCard extends StatelessWidget {
  const _ItemCard({
    required this.item,
    required this.onEdit,
    required this.onDelete,
  });

  final TemplateItem item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F9FE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD9E4F3)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.name,
                    style: const TextStyle(
                      color: Color(0xFF243A56),
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                _ActionText(title: '编辑', color: const Color(0xFF2D88D8), onTap: onEdit),
                _ActionText(title: '删除', color: const Color(0xFFD34E66), onTap: onDelete),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              item.options.map((option) => '${option.label}:${option.score}').join('  ·  '),
              style: const TextStyle(color: Color(0xFF5D728D)),
            ),
          ],
        ),
      ),
    );
  }
}

class _RuleCard extends StatelessWidget {
  const _RuleCard({
    required this.rule,
    required this.onEdit,
    required this.onDelete,
  });

  final TemplateGradeRule rule;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F9FE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD9E4F3)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${rule.level}  (${rule.min.toInt()}-${rule.max.toInt()})',
                    style: const TextStyle(
                      color: Color(0xFF243A56),
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (rule.note.trim().isNotEmpty)
                    Text(
                      rule.note,
                      style: const TextStyle(color: Color(0xFF5E738F)),
                    ),
                ],
              ),
            ),
            _ActionText(title: '编辑', color: const Color(0xFF2D88D8), onTap: onEdit),
            _ActionText(title: '删除', color: const Color(0xFFD34E66), onTap: onDelete),
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
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _OptionDraft {
  _OptionDraft({
    required this.id,
    required this.labelController,
    required this.scoreController,
  });

  factory _OptionDraft.empty(String id) {
    return _OptionDraft(
      id: id,
      labelController: TextEditingController(),
      scoreController: TextEditingController(text: '0'),
    );
  }

  final String id;
  final TextEditingController labelController;
  final TextEditingController scoreController;

  void dispose() {
    labelController.dispose();
    scoreController.dispose();
  }
}
