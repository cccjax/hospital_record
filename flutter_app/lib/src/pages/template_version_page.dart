import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_models.dart';
import '../state/hospital_app_state.dart';
import '../widgets/app_add_button.dart';
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
                variant: FieldGridVariant.table,
                showColumnDivider: false,
              ),
            ),
          SectionCard(
            title: '测评项配置',
            action: AppAddIconButton(
              tooltip: '新增测评项',
              onPressed: () => _openItemDialog(context),
              size: 38,
              iconSize: 19,
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
            action: AppAddIconButton(
              tooltip: '新增区间',
              onPressed: () => _openRuleDialog(context),
              size: 38,
              iconSize: 19,
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
    var deletePicking = false;
    final selectedDraftIds = <String>{};
    final nameController = TextEditingController(text: editing?.name ?? '');
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
        void nudgeScore(_OptionDraft draft, double delta) {
          final current =
              double.tryParse(draft.scoreController.text.trim()) ?? 0;
          final next = current + delta;
          final text = _formatScore(next);
          draft.scoreController.text = text;
          draft.scoreController.selection =
              TextSelection.collapsed(offset: text.length);
        }

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return EditorDialog(
              title: editing == null ? '新增测评项' : '编辑测评项',
              subtitle: '请录入测评项及其评分选项',
              icon: Icons.rule_rounded,
              maxWidth: 640,
              actions: [
                AppCancelButton(
                  label: '取消',
                  onPressed: () => Navigator.of(dialogContext).pop(),
                ),
                AppSaveButton(
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
                  label: '保存',
                ),
              ],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  EditorPanel(
                    title: '基础信息',
                    child: Column(
                      children: [
                        _DialogInlineRow(
                          label: '测评项名称 *',
                          child: TextField(
                            controller: nameController,
                            decoration: const InputDecoration(
                              hintText: '例如：疼痛程度',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  EditorPanel(
                    title: null,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Text(
                              '选项与分值',
                              style: TextStyle(
                                color: Color(0xFF244161),
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                            if (deletePicking) ...[
                              const SizedBox(width: 8),
                              Text(
                                selectedDraftIds.isEmpty
                                    ? '请选择要删除的选项'
                                    : '已选中 ${selectedDraftIds.length} 项',
                                style: TextStyle(
                                  color: selectedDraftIds.isEmpty
                                      ? const Color(0xFF7B8FA9)
                                      : const Color(0xFFD34E66),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                            const Spacer(),
                            AppToneIconButton(
                              icon: Icons.add_rounded,
                              tooltip: '新增选项',
                              size: 32,
                              iconSize: 18,
                              borderRadius: 10,
                              onPressed: deletePicking
                                  ? null
                                  : () {
                                      drafts.add(_OptionDraft.empty(
                                          state.createRuntimeId('tplo')));
                                      setDialogState(() {
                                        errorText = null;
                                      });
                                    },
                            ),
                            const SizedBox(width: 6),
                            Tooltip(
                              message: deletePicking
                                  ? (selectedDraftIds.isEmpty
                                      ? '取消删除'
                                      : '确认删除已选')
                                  : '删除选项',
                              child: SizedBox(
                                width: 32,
                                height: 32,
                                child: IconButton(
                                  onPressed: () async {
                                    if (!deletePicking) {
                                      setDialogState(() {
                                        deletePicking = true;
                                        selectedDraftIds.clear();
                                        errorText = null;
                                      });
                                      return;
                                    }
                                    if (selectedDraftIds.isEmpty) {
                                      setDialogState(() {
                                        deletePicking = false;
                                        errorText = null;
                                      });
                                      return;
                                    }
                                    final confirmed =
                                        await showDeleteConfirmDialog(
                                      dialogContext,
                                      title: '删除选项',
                                      content:
                                          '确认删除已选中的 ${selectedDraftIds.length} 个选项吗？',
                                    );
                                    if (!confirmed) return;
                                    setDialogState(() {
                                      drafts.removeWhere((d) =>
                                          selectedDraftIds.contains(d.id));
                                      if (drafts.isEmpty) {
                                        drafts.add(_OptionDraft.empty(
                                            state.createRuntimeId('tplo')));
                                      }
                                      selectedDraftIds.clear();
                                      deletePicking = false;
                                      errorText = null;
                                    });
                                  },
                                  icon: Icon(
                                    deletePicking
                                        ? Icons.delete_forever_rounded
                                        : Icons.delete_outline_rounded,
                                    size: 18,
                                  ),
                                  style: IconButton.styleFrom(
                                    visualDensity: VisualDensity.compact,
                                    backgroundColor: const Color(0xFFFFF2F4),
                                    foregroundColor: const Color(0xFFD34E66),
                                    side: const BorderSide(
                                        color: Color(0xFFF2CAD1)),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        for (var i = 0; i < drafts.length; i++) ...[
                          Builder(
                            builder: (context) {
                              final draft = drafts[i];
                              final selected =
                                  selectedDraftIds.contains(draft.id);
                              return Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: !deletePicking
                                      ? null
                                      : () {
                                          setDialogState(() {
                                            if (selected) {
                                              selectedDraftIds.remove(draft.id);
                                            } else {
                                              selectedDraftIds.add(draft.id);
                                            }
                                          });
                                        },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: deletePicking && selected
                                          ? const Color(0xFFFFF2F4)
                                          : const Color(0xFFFFFFFF),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: deletePicking && selected
                                            ? const Color(0xFFF0C8CF)
                                            : const Color(0xFFD8E4F3),
                                      ),
                                    ),
                                    padding:
                                        const EdgeInsets.fromLTRB(10, 9, 10, 9),
                                    child: Row(
                                      children: [
                                        if (deletePicking) ...[
                                          Icon(
                                            selected
                                                ? Icons.check_circle_rounded
                                                : Icons
                                                    .radio_button_unchecked_rounded,
                                            size: 18,
                                            color: selected
                                                ? const Color(0xFFD34E66)
                                                : const Color(0xFF8BA0B7),
                                          ),
                                          const SizedBox(width: 6),
                                        ],
                                        SizedBox(
                                          width: 46,
                                          child: Text(
                                            '选项${i + 1}',
                                            style: const TextStyle(
                                              color: Color(0xFF244161),
                                              fontWeight: FontWeight.w700,
                                              fontSize: 12.5,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: TextField(
                                            enabled: !deletePicking,
                                            controller: draft.labelController,
                                            decoration: const InputDecoration(
                                              hintText: '选项内容',
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        SizedBox(
                                          width: 116,
                                          child: Container(
                                            height: 42,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFFFFFFF),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                  color:
                                                      const Color(0xFFD3E0F1)),
                                            ),
                                            child: Row(
                                              children: [
                                                SizedBox(
                                                  width: 28,
                                                  child: IconButton(
                                                    onPressed: deletePicking
                                                        ? null
                                                        : () {
                                                            nudgeScore(
                                                                draft, -1);
                                                            setDialogState(() {
                                                              errorText = null;
                                                            });
                                                          },
                                                    icon: const Icon(
                                                        Icons.remove_rounded,
                                                        size: 16),
                                                    visualDensity:
                                                        VisualDensity.compact,
                                                    color:
                                                        const Color(0xFF5A7090),
                                                  ),
                                                ),
                                                Expanded(
                                                  child: TextField(
                                                    enabled: !deletePicking,
                                                    controller:
                                                        draft.scoreController,
                                                    textAlign: TextAlign.center,
                                                    decoration:
                                                        const InputDecoration(
                                                      hintText: '分数',
                                                      border: InputBorder.none,
                                                      enabledBorder:
                                                          InputBorder.none,
                                                      focusedBorder:
                                                          InputBorder.none,
                                                      isDense: true,
                                                      contentPadding:
                                                          EdgeInsets.symmetric(
                                                              horizontal: 0,
                                                              vertical: 10),
                                                    ),
                                                    keyboardType:
                                                        const TextInputType
                                                            .numberWithOptions(
                                                      decimal: true,
                                                      signed: true,
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(
                                                  width: 28,
                                                  child: IconButton(
                                                    onPressed: deletePicking
                                                        ? null
                                                        : () {
                                                            nudgeScore(
                                                                draft, 1);
                                                            setDialogState(() {
                                                              errorText = null;
                                                            });
                                                          },
                                                    icon: const Icon(
                                                        Icons.add_rounded,
                                                        size: 16),
                                                    visualDensity:
                                                        VisualDensity.compact,
                                                    color:
                                                        const Color(0xFF5A7090),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          if (i != drafts.length - 1) const SizedBox(height: 8),
                        ],
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
                AppCancelButton(
                  label: '取消',
                  onPressed: () => Navigator.of(dialogContext).pop(),
                ),
                AppSaveButton(
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
                  label: '保存',
                ),
              ],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  EditorPanel(
                    title: '区间配置',
                    child: Column(
                      children: [
                        _DialogInlineRow(
                          label: '区间名称 *',
                          child: TextField(
                            controller: levelController,
                            decoration: const InputDecoration(
                              hintText: '例如：中度风险',
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        _DialogInlineRow(
                          label: '最小值',
                          child: TextField(
                            controller: minController,
                            decoration: const InputDecoration(
                              hintText: '请输入',
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _DialogInlineRow(
                          label: '最大值',
                          child: TextField(
                            controller: maxController,
                            decoration: const InputDecoration(
                              hintText: '请输入',
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  EditorPanel(
                    title: '区间说明',
                    child: _DialogInlineRow(
                      label: '说明',
                      alignTop: true,
                      child: TextField(
                        controller: noteController,
                        decoration: const InputDecoration(
                          hintText: '例如：建议48小时内复评并重点观察',
                        ),
                        minLines: 2,
                        maxLines: 3,
                      ),
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

  String _formatScore(double value) {
    final roundedInt = value.roundToDouble();
    if ((value - roundedInt).abs() < 0.000001) {
      return roundedInt.toInt().toString();
    }
    return value.toStringAsFixed(1);
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

class _DialogInlineRow extends StatelessWidget {
  const _DialogInlineRow({
    required this.label,
    required this.child,
    this.alignTop = false,
  });

  final String label;
  final Widget child;
  final bool alignTop;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final labelWidth = constraints.maxWidth < 430 ? 86.0 : 104.0;
        return Row(
          crossAxisAlignment:
              alignTop ? CrossAxisAlignment.start : CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: labelWidth,
              child: Padding(
                padding: EdgeInsets.only(top: alignTop ? 8 : 0),
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF244161),
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(child: child),
          ],
        );
      },
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
