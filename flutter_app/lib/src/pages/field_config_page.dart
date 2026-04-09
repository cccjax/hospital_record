import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_models.dart';
import '../state/hospital_app_state.dart';
import '../widgets/app_back_button.dart';
import '../widgets/dialog_utils.dart';
import '../widgets/editor_dialog.dart';
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
    final visibleCount = schema.where((field) => field.showInList).length;

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
          _FieldStatsCard(
            moduleName: _moduleLabel(module),
            visibleCount: visibleCount,
            totalCount: schema.length,
          ),
          const SizedBox(height: 10),
          SectionCard(
            title: '配置模块',
            child: DropdownButtonFormField<String>(
              initialValue: module,
              items: const [
                DropdownMenuItem(value: 'patient', child: Text('病人信息')),
                DropdownMenuItem(value: 'admission', child: Text('入院记录')),
                DropdownMenuItem(value: 'daily', child: Text('日常记录')),
                DropdownMenuItem(value: 'templateDisease', child: Text('病种模板')),
                DropdownMenuItem(value: 'templateVersion', child: Text('版本列表')),
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
                        canDelete:
                            !state.isCoreRequiredField(module, field.key),
                        onDragHandle: ReorderableDragStartListener(
                          index: index,
                          child: const Icon(Icons.drag_indicator_rounded),
                        ),
                        onMoveUp: index > 0
                            ? () =>
                                state.reorderFields(module, index, index - 1)
                            : null,
                        onMoveDown: index < schema.length - 1
                            ? () =>
                                state.reorderFields(module, index, index + 2)
                            : null,
                        onEdit: () =>
                            _openFieldDialog(context, module, editing: field),
                        onToggleShow:
                            field.key == 'admissionNo' && module == 'patient'
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
                          canDelete:
                              !state.isCoreRequiredField(module, field.key),
                          onEdit: () =>
                              _openFieldDialog(context, module, editing: field),
                          onToggleShow:
                              field.key == 'admissionNo' && module == 'patient'
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

  String _moduleLabel(String moduleKey) {
    switch (moduleKey) {
      case 'patient':
        return '病人信息';
      case 'admission':
        return '入院记录';
      case 'daily':
        return '日常记录';
      case 'templateDisease':
        return '病种模板';
      case 'templateVersion':
        return '版本列表';
      default:
        return moduleKey;
    }
  }

  Future<void> _openFieldDialog(
    BuildContext context,
    String module, {
    FieldSchema? editing,
  }) async {
    final result = await showDialog<FieldSchema>(
      context: context,
      builder: (dialogContext) => _FieldEditorDialog(editing: editing),
    );

    if (!context.mounted || result == null) return;

    // The popup route may still be in teardown in this frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final latestState = context.read<HospitalAppState>();
      final ok = editing == null
          ? latestState.addCustomField(module, result)
          : latestState.updateField(module, editing.key, result);
      if (!ok && mounted) {
        final message = latestState.takeLastErrorMessage() ?? '保存失败';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    });
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
    if (!context.mounted) return;
    final state = context.read<HospitalAppState>();
    final ok = state.deleteField(module, key);
    if (!ok && context.mounted) {
      final message = state.takeLastErrorMessage() ?? '删除失败';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }
}

class _FieldEditorDialog extends StatefulWidget {
  const _FieldEditorDialog({
    required this.editing,
  });

  final FieldSchema? editing;

  @override
  State<_FieldEditorDialog> createState() => _FieldEditorDialogState();
}

class _FieldEditorDialogState extends State<_FieldEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _keyController;
  late final TextEditingController _labelController;
  late final TextEditingController _optionsController;

  late FieldType _type;
  late bool _required;
  late bool _showInList;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _keyController = TextEditingController(text: widget.editing?.key ?? '');
    _labelController = TextEditingController(text: widget.editing?.label ?? '');
    _optionsController = TextEditingController(
      text: (widget.editing?.options ?? const <String>[]).join(','),
    );
    _type = widget.editing?.type ?? FieldType.text;
    _required = widget.editing?.required ?? false;
    _showInList = widget.editing?.showInList ?? true;
  }

  @override
  void dispose() {
    _keyController.dispose();
    _labelController.dispose();
    _optionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.editing;
    final keyLocked = editing != null;
    final typeLocked = editing != null;
    final canToggleRequired = !(editing?.locked == true);

    return EditorDialog(
      title: editing == null ? '新增字段' : '编辑字段',
      subtitle: '统一配置字段的录入规则与列表展示方式',
      icon: Icons.tune_rounded,
      maxWidth: 560,
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton.icon(
          onPressed: _onSubmit,
          icon: const Icon(Icons.check_rounded),
          label: const Text('保存'),
        ),
      ],
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            EditorPanel(
              title: '基本信息',
              child: Column(
                children: [
                  TextFormField(
                    controller: _keyController,
                    enabled: !keyLocked,
                    decoration: const InputDecoration(
                      labelText: '字段键名 *',
                      hintText: '例如: bloodSugar',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return '请填写字段键名';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _labelController,
                    decoration: const InputDecoration(
                      labelText: '字段名称 *',
                      hintText: '例如: 血糖',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return '请填写字段名称';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            EditorPanel(
              title: '字段类型',
              description: typeLocked ? '系统字段类型不可修改' : '不同类型将影响录入控件样式',
              child: DropdownButtonFormField<FieldType>(
                initialValue: _type,
                decoration: const InputDecoration(labelText: '选择字段类型'),
                items: const [
                  DropdownMenuItem(value: FieldType.text, child: Text('文本')),
                  DropdownMenuItem(value: FieldType.number, child: Text('数字')),
                  DropdownMenuItem(value: FieldType.date, child: Text('日期')),
                  DropdownMenuItem(
                      value: FieldType.textarea, child: Text('多行文本')),
                  DropdownMenuItem(
                      value: FieldType.select, child: Text('下拉选项')),
                  DropdownMenuItem(
                      value: FieldType.images, child: Text('图片上传')),
                ],
                onChanged: typeLocked
                    ? null
                    : (value) {
                        if (value == null) return;
                        setState(() {
                          _type = value;
                          _errorText = null;
                        });
                      },
              ),
            ),
            if (_type == FieldType.select) ...[
              const SizedBox(height: 10),
              EditorPanel(
                title: '下拉选项',
                description: '用英文逗号分隔，例如：在院,出院',
                child: TextFormField(
                  controller: _optionsController,
                  decoration: const InputDecoration(
                    labelText: '选项内容',
                    hintText: '例如：高风险,中风险,低风险',
                  ),
                ),
              ),
            ],
            const SizedBox(height: 10),
            EditorPanel(
              title: '显示与校验',
              child: Column(
                children: [
                  _buildToggleRow(
                    title: '是否必填',
                    subtitle: canToggleRequired ? '开启后录入时必须填写' : '系统字段，不可修改',
                    value: _required,
                    onChanged: canToggleRequired
                        ? (value) {
                            setState(() {
                              _required = value;
                            });
                          }
                        : null,
                  ),
                  const SizedBox(height: 8),
                  _buildToggleRow(
                    title: '是否列表展示',
                    subtitle: '关闭后仅在详情页显示',
                    value: _showInList,
                    onChanged: (value) {
                      setState(() {
                        _showInList = value;
                      });
                    },
                  ),
                ],
              ),
            ),
            if (_errorText != null) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF2F3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFF0C8CF)),
                ),
                child: Text(
                  _errorText!,
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
      ),
    );
  }

  void _onSubmit() {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _errorText = null;
    });
    final key = widget.editing?.key ?? _keyController.text.trim();
    final label = _labelController.text.trim();
    final fixedType = widget.editing?.type ?? _type;
    final options = fixedType == FieldType.select
        ? _optionsController.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList()
        : const <String>[];
    if (fixedType == FieldType.select && options.isEmpty) {
      setState(() {
        _errorText = '下拉类型至少配置一个可选项';
      });
      return;
    }
    final field = FieldSchema(
      key: key,
      label: label,
      type: fixedType,
      required: _required,
      locked: widget.editing?.locked ?? false,
      showInList: _showInList,
      computed: widget.editing?.computed ?? false,
      options: options,
    );
    Navigator.of(context).pop(field);
  }

  Widget _buildToggleRow({
    required String title,
    required String subtitle,
    required bool value,
    ValueChanged<bool>? onChanged,
  }) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD8E3F2)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF213852),
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF6A809D),
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldStatsCard extends StatelessWidget {
  const _FieldStatsCard({
    required this.moduleName,
    required this.visibleCount,
    required this.totalCount,
  });

  final String moduleName;
  final int visibleCount;
  final int totalCount;

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
            Expanded(
              child: _StatCell(
                label: '当前模块',
                value: moduleName,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatCell(
                label: '列表显示',
                value: '$visibleCount/$totalCount',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({
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
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
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
      if (field.locked) '系统字段',
      if (field.computed) '计算字段',
      if (field.showInList) '列表显示',
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFF9FBFF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFDCE8F6)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      field.label,
                      style: const TextStyle(
                        color: Color(0xFF1F3149),
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  _RowAction(
                      title: '编辑',
                      color: const Color(0xFF2C88D8),
                      onTap: onEdit),
                  _RowAction(
                    title: field.showInList ? '设为隐藏' : '设为显示',
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
                      visualDensity: VisualDensity.compact,
                    ),
                  if (sortMode)
                    IconButton(
                      onPressed: onMoveDown,
                      icon: const Icon(Icons.keyboard_arrow_down_rounded),
                      visualDensity: VisualDensity.compact,
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F9FF),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: const Color(0xFFD9E5F4)),
                        ),
                        child: Text(
                          tag,
                          style: const TextStyle(
                            color: Color(0xFF5E738E),
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
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
        return '图片上传';
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
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}
