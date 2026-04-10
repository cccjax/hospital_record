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
          '瀛楁閰嶇疆',
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
            title: '閰嶇疆妯″潡',
            child: DropdownButtonFormField<String>(
              initialValue: module,
              items: const [
                DropdownMenuItem(value: 'patient', child: Text('鐥呬汉淇℃伅')),
                DropdownMenuItem(value: 'admission', child: Text('鍏ラ櫌璁板綍')),
                DropdownMenuItem(value: 'daily', child: Text('鏃ュ父璁板綍')),
                DropdownMenuItem(
                    value: 'templateDisease', child: Text('鐥呯妯℃澘')),
                DropdownMenuItem(
                    value: 'templateVersion', child: Text('鐗堟湰鍒楄〃')),
              ],
              onChanged: (value) {
                if (value == null) return;
                state.setFieldConfigModule(value);
              },
            ),
          ),
          SectionCard(
            title: '瀛楁鍒楄〃',
            action: Wrap(
              spacing: 8,
              children: [
                FilledButton.tonal(
                  onPressed: () {
                    setState(() {
                      _sortMode = !_sortMode;
                    });
                  },
                  child: Text(_sortMode ? '瀹屾垚鎺掑簭' : '璋冩暣椤哄簭'),
                ),
                FilledButton(
                  onPressed: () => _openFieldDialog(context, module),
                  child: const Text('鏂板瀛楁'),
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
        return '鐥呬汉淇℃伅';
      case 'admission':
        return '鍏ラ櫌璁板綍';
      case 'daily':
        return '鏃ュ父璁板綍';
      case 'templateDisease':
        return '鐥呯妯℃澘';
      case 'templateVersion':
        return '鐗堟湰鍒楄〃';
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
        final message = latestState.takeLastErrorMessage() ?? '淇濆瓨澶辫触';
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
      final message = state.takeLastErrorMessage() ?? '鍒犻櫎澶辫触';
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
  late final TextEditingController _optionColorsController;

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
    _optionColorsController = TextEditingController(
      text: (widget.editing?.optionColors ?? const <String, String>{})
          .entries
          .map((entry) => '${entry.key}:${entry.value}')
          .join(','),
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
    _optionColorsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.editing;
    final keyLocked = editing != null;
    final typeLocked = editing != null;
    final canToggleRequired = !(editing?.locked == true);

    return EditorDialog(
      title: editing == null ? '鏂板瀛楁' : '缂栬緫瀛楁',
      subtitle: '缁熶竴閰嶇疆瀛楁鐨勫綍鍏ヨ鍒欎笌鍒楄〃灞曠ず鏂瑰紡',
      icon: Icons.tune_rounded,
      maxWidth: 560,
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('鍙栨秷'),
        ),
        FilledButton.icon(
          onPressed: _onSubmit,
          icon: const Icon(Icons.check_rounded),
          label: const Text('淇濆瓨'),
        ),
      ],
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            EditorPanel(
              title: '鍩烘湰淇℃伅',
              child: Column(
                children: [
                  TextFormField(
                    controller: _keyController,
                    enabled: !keyLocked,
                    decoration: const InputDecoration(
                      labelText: '瀛楁閿悕 *',
                      hintText: '渚嬪: bloodSugar',
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
                      labelText: '瀛楁鍚嶇О *',
                      hintText: '例如: 血型',
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
              description: typeLocked ? '系统字段类型不可修改' : '不同类型会影响录入控件样式',
              child: DropdownButtonFormField<FieldType>(
                initialValue: _type,
                decoration: const InputDecoration(labelText: '閫夋嫨瀛楁绫诲瀷'),
                items: const [
                  DropdownMenuItem(value: FieldType.text, child: Text('鏂囨湰')),
                  DropdownMenuItem(value: FieldType.number, child: Text('鏁板瓧')),
                  DropdownMenuItem(value: FieldType.date, child: Text('鏃ユ湡')),
                  DropdownMenuItem(
                      value: FieldType.textarea, child: Text('澶氳鏂囨湰')),
                  DropdownMenuItem(
                      value: FieldType.select, child: Text('涓嬫媺閫夐」')),
                  DropdownMenuItem(
                      value: FieldType.images, child: Text('鍥剧墖涓婁紶')),
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
                    hintText: '例如：特级护理,一级护理,二级护理',
                  ),
                ),
              ),
              const SizedBox(height: 10),
              EditorPanel(
                title: '选项颜色（可选）',
                description: '格式：选项:颜色，用逗号分隔，例如 一级护理:#FFD9A6,二级护理:#FFEFB5',
                child: TextFormField(
                  controller: _optionColorsController,
                  decoration: const InputDecoration(
                    labelText: '颜色映射',
                    hintText: '支持 #RRGGBB 或 #AARRGGBB',
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
                    title: '鏄惁蹇呭～',
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
                    title: '鏄惁鍒楄〃灞曠ず',
                    subtitle: '鍏抽棴鍚庝粎鍦ㄨ鎯呴〉鏄剧ず',
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

    var optionColors = <String, String>{};
    if (fixedType == FieldType.select) {
      final parsed = _parseOptionColors(_optionColorsController.text);
      if (parsed == null) {
        setState(() {
          _errorText = '颜色映射格式不正确，请使用 选项:#RRGGBB';
        });
        return;
      }
      optionColors = <String, String>{
        for (final entry in parsed.entries)
          if (options.contains(entry.key)) entry.key: entry.value,
      };
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
      optionColors: optionColors,
    );
    Navigator.of(context).pop(field);
  }

  Map<String, String>? _parseOptionColors(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return <String, String>{};
    final map = <String, String>{};
    final rows = text.split(',');
    final reg = RegExp(r'^#([0-9a-fA-F]{6}|[0-9a-fA-F]{8})$');
    for (final row in rows) {
      final part = row.trim();
      if (part.isEmpty) continue;
      final idx = part.indexOf(':');
      if (idx <= 0 || idx >= part.length - 1) {
        return null;
      }
      final name = part.substring(0, idx).trim();
      final color = part.substring(idx + 1).trim();
      if (name.isEmpty || !reg.hasMatch(color)) {
        return null;
      }
      map[name] = color.toUpperCase();
    }
    return map;
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
                label: '褰撳墠妯″潡',
                value: moduleName,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatCell(
                label: '鍒楄〃鏄剧ず',
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
      if (field.required) '蹇呭～',
      if (field.locked) '绯荤粺瀛楁',
      if (field.computed) '璁＄畻瀛楁',
      if (field.showInList) '鍒楄〃鏄剧ず',
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
                      title: '缂栬緫',
                      color: const Color(0xFF2C88D8),
                      onTap: onEdit),
                  _RowAction(
                    title: field.showInList ? '璁句负闅愯棌' : '璁句负鏄剧ず',
                    color: const Color(0xFF637A97),
                    onTap: onToggleShow,
                  ),
                  _RowAction(
                    title: '鍒犻櫎',
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
        return '鏂囨湰';
      case FieldType.number:
        return '鏁板瓧';
      case FieldType.date:
        return '鏃ユ湡';
      case FieldType.textarea:
        return '澶氳';
      case FieldType.select:
        return '涓嬫媺';
      case FieldType.images:
        return '鍥剧墖涓婁紶';
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
