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
    final optionCount = version?.items.fold<int>(0, (sum, item) => sum + item.options.length) ?? 0;
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
          _VersionOverviewCard(
            diseaseName: disease.diseaseName,
            versionName: version.versionName,
            itemCount: version.items.length,
            optionCount: optionCount,
            gradeCount: version.gradeRules.length,
          ),
          const SizedBox(height: 12),
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
                      '当前版本暂无测评项，请先新增',
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
    final quickController = TextEditingController();
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
                      TextField(
                        controller: quickController,
                        decoration: const InputDecoration(
                          labelText: '快速录入（可选）',
                          hintText: '示例：无症状:0,轻度:2,重度:5',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton.tonal(
                          onPressed: () {
                            final parsed = _parseQuickOptions(
                              quickController.text,
                              state: state,
                            );
                            if (parsed.isEmpty) {
                              ScaffoldMessenger.of(dialogContext).showSnackBar(
                                const SnackBar(content: Text('快速录入格式无效，请使用“名称:分数”')),
                              );
                              return;
                            }
                            for (final draft in drafts) {
                              draft.dispose();
                            }
                            drafts
                              ..clear()
                              ..addAll(parsed);
                            setDialogState(() {});
                          },
                          child: const Text('按快速录入生成'),
                        ),
                      ),
                      const SizedBox(height: 8),
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
                                  decoration: const InputDecoration(labelText: '分数'),
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
    quickController.dispose();
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

  List<_OptionDraft> _parseQuickOptions(
    String raw, {
    required HospitalAppState state,
  }) {
    final text = raw.trim();
    if (text.isEmpty) return const <_OptionDraft>[];
    final segments = text.split(',');
    final drafts = <_OptionDraft>[];
    for (final seg in segments) {
      final unit = seg.trim();
      if (unit.isEmpty) continue;
      final pair = unit.split(':');
      if (pair.length < 2) return const <_OptionDraft>[];
      final label = pair.first.trim();
      final scoreRaw = pair.sublist(1).join(':').trim();
      final score = double.tryParse(scoreRaw);
      if (label.isEmpty || score == null) return const <_OptionDraft>[];
      drafts.add(
        _OptionDraft(
          id: state.createRuntimeId('tplo'),
          labelController: TextEditingController(text: label),
          scoreController: TextEditingController(text: score.toString()),
        ),
      );
    }
    return drafts;
  }

  Future<void> _deleteItem(BuildContext context, String itemId) async {
    final confirmed = await showDeleteConfirmDialog(
      context,
      title: '删除测评项',
      content: '确认删除该测评项吗？',
    );
    if (!confirmed) return;
    if (!context.mounted) return;
    context.read<HospitalAppState>().deleteTemplateItem(diseaseId, versionId, itemId);
  }

  Future<void> _deleteRule(BuildContext context, String ruleId) async {
    final confirmed = await showDeleteConfirmDialog(
      context,
      title: '删除等级区间',
      content: '确认删除该分级区间吗？',
    );
    if (!confirmed) return;
    if (!context.mounted) return;
    context.read<HospitalAppState>().deleteTemplateGradeRule(diseaseId, versionId, ruleId);
  }
}

class _VersionOverviewCard extends StatelessWidget {
  const _VersionOverviewCard({
    required this.diseaseName,
    required this.versionName,
    required this.itemCount,
    required this.optionCount,
    required this.gradeCount,
  });

  final String diseaseName;
  final String versionName;
  final int itemCount;
  final int optionCount;
  final int gradeCount;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
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
              diseaseName,
              style: const TextStyle(
                color: Color(0xFF1F3149),
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              versionName,
              style: const TextStyle(
                color: Color(0xFF5F6F85),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _MetricTile(label: '测评项', value: '$itemCount')),
                const SizedBox(width: 8),
                Expanded(child: _MetricTile(label: '选项数', value: '$optionCount')),
                const SizedBox(width: 8),
                Expanded(child: _MetricTile(label: '分级区间', value: '$gradeCount')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF7FBFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5EEF9)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF5A6A7E),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: Color(0xFF1F3149),
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
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
    final optionCount = item.options.length;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFDFEFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDCE8F6)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    item.name,
                    style: const TextStyle(
                      color: Color(0xFF1F3149),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                _ActionText(title: '编辑', color: const Color(0xFF2D88D8), onTap: onEdit),
                _ActionText(title: '删除', color: const Color(0xFFD34E66), onTap: onDelete),
              ],
            ),
            const SizedBox(height: 7),
            Text(
              '选项数量 $optionCount',
              style: const TextStyle(
                color: Color(0xFF6E839C),
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 7),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                for (final option in item.options)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F9FF),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFD9E5F4)),
                    ),
                    child: Text(
                      '${option.label} · ${option.score}分',
                      style: const TextStyle(
                        color: Color(0xFF526A85),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
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
        color: const Color(0xFFFDFEFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDCE8F6)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    rule.level,
                    style: const TextStyle(
                      color: Color(0xFF1F3149),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F9FF),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0xFFD9E5F4)),
                  ),
                  child: Text(
                    '${rule.min.toInt()} - ${rule.max.toInt()} 分',
                    style: const TextStyle(
                      color: Color(0xFF4E627D),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
                _ActionText(title: '编辑', color: const Color(0xFF2D88D8), onTap: onEdit),
                _ActionText(title: '删除', color: const Color(0xFFD34E66), onTap: onDelete),
              ],
            ),
            if (rule.note.trim().isNotEmpty) ...[
              const SizedBox(height: 7),
              Text(
                rule.note,
                style: const TextStyle(
                  color: Color(0xFF5E738F),
                  height: 1.3,
                  fontSize: 12.5,
                ),
              ),
            ],
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
