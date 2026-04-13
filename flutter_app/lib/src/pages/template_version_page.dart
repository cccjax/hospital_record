import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_models.dart';
import '../state/hospital_app_state.dart';
import '../widgets/app_back_button.dart';
import '../widgets/dialog_utils.dart';
import '../widgets/editor_dialog.dart';
import '../widgets/field_grid.dart';
import '../widgets/section_card.dart';

class TemplateVersionPage extends StatelessWidget {
  const TemplateVersionPage({
    super.key,
    required this.diseaseId,
    required this.versionId,
    this.catalog = TemplateCatalogType.assessment,
  });

  final String diseaseId;
  final String versionId;
  final TemplateCatalogType catalog;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<HospitalAppState>();
    final disease = state.findDisease(diseaseId, catalog: catalog);
    final version = state.findVersion(diseaseId, versionId, catalog: catalog);
    final versionListSchema = state
        .listSchemaOf('templateVersion')
        .where((field) => field.key != 'versionName')
        .toList();
    final versionValues = <String, dynamic>{
      for (final field in versionListSchema)
        field.key: version == null
            ? ''
            : state.templateVersionFieldValue(version, field.key),
    };
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
          if (versionListSchema.isNotEmpty)
            SectionCard(
              title: '版本信息',
              child: FieldGrid(
                schema: versionListSchema,
                values: versionValues,
                compact: true,
                columns: 3,
              ),
            ),
          SectionCard(
            title: '测评项配置',
            action: Tooltip(
              message: '新增测评项',
              child: FilledButton.tonal(
                onPressed: () => _openItemDialog(context),
                child: const Icon(Icons.add_rounded),
              ),
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
            action: Tooltip(
              message: '新增区间',
              child: FilledButton.tonal(
                onPressed: () => _openRuleDialog(context),
                child: const Icon(Icons.add_rounded),
              ),
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
    String? errorText;
    final nameController = TextEditingController(text: editing?.name ?? '');
    final quickController = TextEditingController();
    final drafts = (editing?.options ?? const <TemplateOption>[])
        .map(
          (option) => _OptionDraft(
            id: option.id,
            labelController: TextEditingController(text: option.label),
            scoreController:
                TextEditingController(text: option.score.toString()),
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
            return EditorDialog(
              title: editing == null ? '新增测评项' : '编辑测评项',
              subtitle: '支持手动录入与快速批量生成选项',
              icon: Icons.rule_rounded,
              maxWidth: 640,
              actions: [
                OutlinedButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('取消'),
                ),
                FilledButton.icon(
                  onPressed: () {
                    setDialogState(() {
                      errorText = null;
                    });
                    final name = nameController.text.trim();
                    if (name.isEmpty) {
                      setDialogState(() {
                        errorText = '请填写测评项名称';
                      });
                      return;
                    }

                    final options = <TemplateOption>[];
                    for (final draft in drafts) {
                      final label = draft.labelController.text.trim();
                      final score =
                          double.tryParse(draft.scoreController.text.trim()) ??
                              0;
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
                      setDialogState(() {
                        errorText = '至少保留一个选项';
                      });
                      return;
                    }

                    final ok = state.upsertTemplateItem(
                      catalog: catalog,
                      diseaseId: diseaseId,
                      versionId: versionId,
                      editingId: editing?.id,
                      name: name,
                      options: options,
                    );
                    if (ok) {
                      Navigator.of(dialogContext).pop();
                      return;
                    }
                    setDialogState(() {
                      errorText = state.takeLastErrorMessage() ?? '保存失败，请稍后重试';
                    });
                  },
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('保存'),
                ),
              ],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  EditorPanel(
                    title: '基础信息',
                    child: Column(
                      children: [
                        TextField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            labelText: '测评项名称 *',
                            hintText: '例如：疼痛程度',
                          ),
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
                          child: OutlinedButton.icon(
                            onPressed: () {
                              final parsed = _parseQuickOptions(
                                quickController.text,
                                state: state,
                              );
                              if (parsed.isEmpty) {
                                setDialogState(() {
                                  errorText = '快速录入格式无效，请使用“名称:分数”';
                                });
                                return;
                              }
                              drafts
                                ..clear()
                                ..addAll(parsed);
                              setDialogState(() {
                                errorText = null;
                              });
                            },
                            icon: const Icon(Icons.auto_fix_high_rounded,
                                size: 16),
                            label: const Text('按快速录入生成'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  EditorPanel(
                    title: '选项与分值',
                    description: '每个选项都将参与评分计算',
                    child: Column(
                      children: [
                        for (var i = 0; i < drafts.length; i++) ...[
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFFFFF),
                              borderRadius: BorderRadius.circular(12),
                              border:
                                  Border.all(color: const Color(0xFFD8E4F3)),
                            ),
                            padding: const EdgeInsets.fromLTRB(10, 9, 8, 9),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: drafts[i].labelController,
                                    decoration: InputDecoration(
                                      labelText: '选项 ${i + 1}',
                                      hintText: '请输入选项名称',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  width: 110,
                                  child: TextField(
                                    controller: drafts[i].scoreController,
                                    decoration:
                                        const InputDecoration(labelText: '分数'),
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                IconButton(
                                  onPressed: drafts.length <= 1
                                      ? null
                                      : () {
                                          drafts.removeAt(i);
                                          setDialogState(() {
                                            errorText = null;
                                          });
                                        },
                                  icon:
                                      const Icon(Icons.delete_outline_rounded),
                                ),
                              ],
                            ),
                          ),
                          if (i != drafts.length - 1) const SizedBox(height: 8),
                        ],
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              drafts.add(_OptionDraft.empty(
                                  state.createRuntimeId('tplo')));
                              setDialogState(() {
                                errorText = null;
                              });
                            },
                            icon: const Icon(Icons.add_rounded, size: 16),
                            label: const Text('新增选项'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (errorText != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF2F3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFF0C7CD)),
                      ),
                      child: Text(
                        errorText!,
                        style: const TextStyle(
                          color: Color(0xFFB63A49),
                          fontWeight: FontWeight.w600,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );

    // Controllers are intentionally not disposed here.
    // Dialog route reverse animation may still be rebuilding TextFields
    // after showDialog() completes, and early dispose can trigger
    // "TextEditingController was used after being disposed".
  }

  Future<void> _openRuleDialog(
    BuildContext context, {
    TemplateGradeRule? editing,
  }) async {
    final state = context.read<HospitalAppState>();
    String? errorText;
    final levelController = TextEditingController(text: editing?.level ?? '');
    final minController =
        TextEditingController(text: editing?.min.toString() ?? '');
    final maxController =
        TextEditingController(text: editing?.max.toString() ?? '');
    final noteController = TextEditingController(text: editing?.note ?? '');

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return EditorDialog(
              title: editing == null ? '新增等级区间' : '编辑等级区间',
              subtitle: '用于自动判断评分结果所在等级',
              icon: Icons.ssid_chart_rounded,
              maxWidth: 540,
              actions: [
                OutlinedButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('取消'),
                ),
                FilledButton.icon(
                  onPressed: () {
                    setDialogState(() {
                      errorText = null;
                    });
                    final level = levelController.text.trim();
                    final min = double.tryParse(minController.text.trim()) ?? 0;
                    final max = double.tryParse(maxController.text.trim()) ?? 0;
                    if (level.isEmpty) {
                      setDialogState(() {
                        errorText = '请填写区间名称';
                      });
                      return;
                    }
                    if (min > max) {
                      setDialogState(() {
                        errorText = '最小值不能大于最大值';
                      });
                      return;
                    }
                    final overlapRule = _findOverlappingRule(
                      state: state,
                      min: min,
                      max: max,
                      excludeId: editing?.id,
                    );
                    if (overlapRule != null) {
                      setDialogState(() {
                        errorText =
                            '与「${overlapRule.level}（${overlapRule.min}-${overlapRule.max}）」区间重叠，请调整分数范围';
                      });
                      return;
                    }
                    final ok = state.upsertTemplateGradeRule(
                      catalog: catalog,
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
                      return;
                    }
                    setDialogState(() {
                      errorText = state.takeLastErrorMessage() ?? '保存失败，请稍后重试';
                    });
                  },
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('保存'),
                ),
              ],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  EditorPanel(
                    title: '区间配置',
                    child: Column(
                      children: [
                        TextField(
                          controller: levelController,
                          decoration: const InputDecoration(
                            labelText: '区间名称 *',
                            hintText: '例如：中度风险',
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: minController,
                                decoration:
                                    const InputDecoration(labelText: '最小值'),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: maxController,
                                decoration:
                                    const InputDecoration(labelText: '最大值'),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  EditorPanel(
                    title: '区间说明',
                    description: '可选，用于解释该评分区间的临床含义',
                    child: TextField(
                      controller: noteController,
                      decoration: const InputDecoration(
                        labelText: '说明',
                        hintText: '例如：建议48小时内复评并重点观察',
                      ),
                      minLines: 2,
                      maxLines: 3,
                    ),
                  ),
                  if (errorText != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF2F3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFF0C7CD)),
                      ),
                      child: Text(
                        errorText!,
                        style: const TextStyle(
                          color: Color(0xFFB63A49),
                          fontWeight: FontWeight.w600,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );

    // Same reason as _openItemDialog: avoid disposing controllers here
    // to prevent dispose-race during dialog pop animation.
  }

  TemplateGradeRule? _findOverlappingRule({
    required HospitalAppState state,
    required double min,
    required double max,
    required String? excludeId,
  }) {
    final version = state.findVersion(diseaseId, versionId, catalog: catalog);
    if (version == null) return null;
    for (final rule in version.gradeRules) {
      if (rule.id == excludeId) continue;
      final hasOverlap = !(max < rule.min || min > rule.max);
      if (hasOverlap) {
        return rule;
      }
    }
    return null;
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
    context.read<HospitalAppState>().deleteTemplateItem(
          diseaseId,
          versionId,
          itemId,
          catalog: catalog,
        );
  }

  Future<void> _deleteRule(BuildContext context, String ruleId) async {
    final confirmed = await showDeleteConfirmDialog(
      context,
      title: '删除等级区间',
      content: '确认删除该分级区间吗？',
    );
    if (!confirmed) return;
    if (!context.mounted) return;
    context.read<HospitalAppState>().deleteTemplateGradeRule(
          diseaseId,
          versionId,
          ruleId,
          catalog: catalog,
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
                _ActionText(
                  title: '编辑测评项',
                  icon: Icons.edit_rounded,
                  color: const Color(0xFF2D88D8),
                  onTap: onEdit,
                ),
                _ActionText(
                  title: '删除测评项',
                  icon: Icons.delete_outline_rounded,
                  color: const Color(0xFFD34E66),
                  onTap: onDelete,
                ),
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                _ActionText(
                  title: '编辑区间',
                  icon: Icons.edit_rounded,
                  color: const Color(0xFF2D88D8),
                  onTap: onEdit,
                ),
                _ActionText(
                  title: '删除区间',
                  icon: Icons.delete_outline_rounded,
                  color: const Color(0xFFD34E66),
                  onTap: onDelete,
                ),
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
