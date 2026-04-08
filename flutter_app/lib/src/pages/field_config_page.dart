import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_models.dart';
import '../state/hospital_app_state.dart';
import '../widgets/app_back_button.dart';
import '../widgets/dialog_utils.dart';
import '../widgets/section_card.dart';

class FieldConfigPage extends StatefulWidget {
  const FieldConfigPage({super.key});

  @override
  State<FieldConfigPage> createState() => _FieldConfigPageState();
}

class _FieldConfigPageState extends State<FieldConfigPage> {
  bool _sortMode = false;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<HospitalAppState>();
    final module = state.fieldConfigModule;
    final schema = state.schemaOf(module);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leadingWidth: 56,
        leading: const Padding(
          padding: EdgeInsets.only(left: 12),
          child: AppBackButton(),
        ),
        title: const Text(
          '字段配置',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
        children: [
          SectionCard(
            title: '配置模块',
            child: DropdownButtonFormField<String>(
              value: module,
              items: const [
                DropdownMenuItem(value: 'patient', child: Text('病人信息')),
                DropdownMenuItem(value: 'admission', child: Text('入院记录')),
                DropdownMenuItem(value: 'daily', child: Text('日常记录')),
              ],
              onChanged: (value) {
                if (value == null) return;
                state.setFieldConfigModule(value);
              },
            ),
          ),
          SectionCard(
            title: '字段列表',
            action: Wrap(
              spacing: 8,
              children: [
                FilledButton.tonal(
                  onPressed: () {
                    setState(() {
                      _sortMode = !_sortMode;
                    });
                  },
                  child: Text(_sortMode ? '完成排序' : '调整顺序'),
                ),
                FilledButton(
                  onPressed: () => _openFieldDialog(context, module),
                  child: const Text('新增字段'),
                ),
              ],
            ),
            child: _sortMode
                ? ReorderableListView.builder(
                    shrinkWrap: true,
                    buildDefaultDragHandles: false,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: schema.length,
                    onReorder: (oldIndex, newIndex) {
                      state.reorderFields(module, oldIndex, newIndex);
                    },
                    itemBuilder: (context, index) {
                      final field = schema[index];
                      return _FieldRow(
                        key: ValueKey(field.key),
                        field: field,
                        sortMode: true,
                        canDelete: !state.isCoreRequiredField(module, field.key),
                        onDragHandle: ReorderableDragStartListener(
                          index: index,
                          child: const Icon(Icons.drag_indicator_rounded),
                        ),
                        onMoveUp: index > 0
                            ? () => state.reorderFields(module, index, index - 1)
                            : null,
                        onMoveDown: index < schema.length - 1
                            ? () => state.reorderFields(module, index, index + 1)
                            : null,
                        onEdit: () => _openFieldDialog(context, module, editing: field),
                        onToggleShow: field.key == 'admissionNo' && module == 'patient'
                            ? null
                            : () => state.toggleFieldVisibility(
                                  module,
                                  field.key,
                                  !field.showInList,
                                ),
                        onDelete: state.isCoreRequiredField(module, field.key)
                            ? null
                            : () => _deleteField(context, module, field.key),
                      );
                    },
                  )
                : Column(
                    children: [
                      for (final field in schema)
                        _FieldRow(
                          field: field,
                          sortMode: false,
                          canDelete: !state.isCoreRequiredField(module, field.key),
                          onEdit: () => _openFieldDialog(context, module, editing: field),
                          onToggleShow: field.key == 'admissionNo' && module == 'patient'
                              ? null
                              : () => state.toggleFieldVisibility(
                                    module,
                                    field.key,
                                    !field.showInList,
                                  ),
                          onDelete: state.isCoreRequiredField(module, field.key)
                              ? null
                              : () => _deleteField(context, module, field.key),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _openFieldDialog(
    BuildContext context,
    String module, {
    FieldSchema? editing,
  }) async {
    final state = context.read<HospitalAppState>();
    final keyController = TextEditingController(text: editing?.key ?? '');
    final labelController = TextEditingController(text: editing?.label ?? '');
    final optionsController = TextEditingController(
      text: (editing?.options ?? const <String>[]).join(','),
    );
    var type = editing?.type ?? FieldType.text;
    var required = editing?.required ?? false;
    var showInList = editing?.showInList ?? true;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final keyLocked = editing?.locked == true;
            final canToggleRequired = !(editing?.locked == true);
            return AlertDialog(
              title: Text(editing == null ? '新增字段' : '编辑字段'),
              content: SizedBox(
                width: 470,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: keyController,
                        enabled: !keyLocked,
                        decoration: const InputDecoration(
                          labelText: '字段键名 *',
                          hintText: '例如: bloodSugar',
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: labelController,
                        decoration: const InputDecoration(labelText: '字段名称 *'),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<FieldType>(
                        value: type,
                        decoration: const InputDecoration(labelText: '字段类型'),
                        items: const [
                          DropdownMenuItem(value: FieldType.text, child: Text('文本')),
                          DropdownMenuItem(value: FieldType.number, child: Text('数字')),
                          DropdownMenuItem(value: FieldType.date, child: Text('日期')),
                          DropdownMenuItem(value: FieldType.textarea, child: Text('多行文本')),
                          DropdownMenuItem(value: FieldType.select, child: Text('下拉选项')),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setDialogState(() {
                            type = value;
                          });
                        },
                      ),
                      if (type == FieldType.select) ...[
                        const SizedBox(height: 10),
                        TextField(
                          controller: optionsController,
                          decoration: const InputDecoration(
                            labelText: '下拉选项',
                            hintText: '用英文逗号分隔，例如: 在院,出院',
                          ),
                        ),
                      ],
                      const SizedBox(height: 10),
                      SwitchListTile(
                        value: required,
                        title: const Text('是否必填'),
                        onChanged: canToggleRequired
                            ? (value) {
                                setDialogState(() {
                                  required = value;
                                });
                              }
                            : null,
                      ),
                      SwitchListTile(
                        value: showInList,
                        title: const Text('是否列表展示'),
                        onChanged: (value) {
                          setDialogState(() {
                            showInList = value;
                          });
                        },
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
                    final key = keyController.text.trim();
                    final label = labelController.text.trim();
                    if (key.isEmpty || label.isEmpty) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(content: Text('字段键名和字段名称不能为空')),
                      );
                      return;
                    }
                    final options = type == FieldType.select
                        ? optionsController.text
                            .split(',')
                            .map((e) => e.trim())
                            .where((e) => e.isNotEmpty)
                            .toList()
                        : const <String>[];
                    final field = FieldSchema(
                      key: key,
                      label: label,
                      type: type,
                      required: required,
                      locked: editing?.locked ?? false,
                      showInList: showInList,
                      computed: editing?.computed ?? false,
                      options: options,
                    );

                    final ok = editing == null
                        ? state.addCustomField(module, field)
                        : state.updateField(module, editing.key, field);
                    if (ok) {
                      Navigator.of(dialogContext).pop();
                    } else {
                      final message = state.takeLastErrorMessage() ?? '保存失败';
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        SnackBar(content: Text(message)),
                      );
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

    keyController.dispose();
    labelController.dispose();
    optionsController.dispose();
  }

  Future<void> _deleteField(
    BuildContext context,
    String module,
    String key,
  ) async {
    final confirmed = await showDeleteConfirmDialog(
      context,
      title: '删除字段',
      content: '确认删除该字段吗？已写入该字段的数据将丢失。',
    );
    if (!confirmed) return;
    final state = context.read<HospitalAppState>();
    final ok = state.deleteField(module, key);
    if (!ok && context.mounted) {
      final message = state.takeLastErrorMessage() ?? '删除失败';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }
}

class _FieldRow extends StatelessWidget {
  const _FieldRow({
    super.key,
    required this.field,
    required this.sortMode,
    required this.canDelete,
    required this.onEdit,
    required this.onToggleShow,
    required this.onDelete,
    this.onDragHandle,
    this.onMoveUp,
    this.onMoveDown,
  });

  final FieldSchema field;
  final bool sortMode;
  final bool canDelete;
  final VoidCallback onEdit;
  final VoidCallback? onToggleShow;
  final VoidCallback? onDelete;
  final Widget? onDragHandle;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;

  @override
  Widget build(BuildContext context) {
    final tags = <String>[
      _fieldTypeLabel(field.type),
      if (field.required) '必填',
      if (field.locked) '锁定',
      if (field.computed) '计算字段',
      if (field.showInList) '列表展示',
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFF5F9FE),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFD8E3F3)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${field.label}  (${field.key})',
                      style: const TextStyle(
                        color: Color(0xFF22364E),
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  _RowAction(title: '编辑', color: const Color(0xFF2C88D8), onTap: onEdit),
                  _RowAction(
                    title: field.showInList ? '隐藏' : '显示',
                    color: const Color(0xFF637A97),
                    onTap: onToggleShow,
                  ),
                  _RowAction(
                    title: '删除',
                    color: const Color(0xFFD45067),
                    onTap: canDelete ? onDelete : null,
                  ),
                  if (sortMode)
                    IconButton(
                      onPressed: onMoveUp,
                      icon: const Icon(Icons.keyboard_arrow_up_rounded),
                    ),
                  if (sortMode)
                    IconButton(
                      onPressed: onMoveDown,
                      icon: const Icon(Icons.keyboard_arrow_down_rounded),
                    ),
                  if (sortMode) onDragHandle ?? const SizedBox.shrink(),
                ],
              ),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final tag in tags)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF1FA),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: const Color(0xFFD3E0F1)),
                        ),
                        child: Text(
                          tag,
                          style: const TextStyle(
                            color: Color(0xFF5E738E),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _fieldTypeLabel(FieldType type) {
    switch (type) {
      case FieldType.text:
        return '文本';
      case FieldType.number:
        return '数字';
      case FieldType.date:
        return '日期';
      case FieldType.textarea:
        return '多行';
      case FieldType.select:
        return '下拉';
      case FieldType.images:
        return '图片';
    }
  }
}

class _RowAction extends StatelessWidget {
  const _RowAction({
    required this.title,
    required this.color,
    required this.onTap,
  });

  final String title;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          child: Text(
            title,
            style: TextStyle(
              color: onTap == null ? const Color(0xFFB2BDCC) : color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
