import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_models.dart';
import '../state/hospital_app_state.dart';
import '../widgets/app_add_button.dart';
import '../widgets/app_back_button.dart';
import '../widgets/app_dropdown_form_field.dart';
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
            child: AppDropdownFormField<String>(
              selectedValue: module,
              items: const [
                AppDropdownOption(value: 'patient', label: '病人信息'),
                AppDropdownOption(value: 'admission', label: '入院记录'),
                AppDropdownOption(value: 'daily', label: '日常记录'),
                AppDropdownOption(value: 'templateDisease', label: '病种模板'),
                AppDropdownOption(value: 'templateVersion', label: '版本列表'),
              ],
              onChanged: (value) {
                if (value == null) return;
                state.setFieldConfigModule(value);
              },
            ),
          ),
          SectionCard(
            title: '字段列表',
            action: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                AppToneIconButton(
                  tooltip: _sortMode ? '完成排序' : '调整顺序',
                  icon:
                      _sortMode ? Icons.check_rounded : Icons.swap_vert_rounded,
                  onPressed: () {
                    setState(() {
                      _sortMode = !_sortMode;
                    });
                  },
                  size: 40,
                  iconSize: 20,
                  borderRadius: 11,
                ),
                const SizedBox(width: 8),
                AppAddIconButton(
                  tooltip: '新增字段',
                  onPressed: () => _openFieldDialog(context, module),
                  size: 40,
                  iconSize: 20,
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
                        onToggleShow: () => state.toggleFieldVisibility(
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
                          onToggleShow: () => state.toggleFieldVisibility(
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
  static const List<String> _presetColors = <String>[
    '#F5C3CC',
    '#FFD9A6',
    '#FFEFB5',
    '#DDF4CC',
    '#CBE8FF',
    '#DCCFFF',
    '#BFE7E1',
    '#FAD2E1',
    '#FFD6B2',
    '#E2F0CB',
    '#C9E4DE',
    '#E8DFF5',
  ];

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _keyController;
  late final TextEditingController _labelController;

  late FieldType _type;
  late bool _required;
  late bool _showInList;
  late List<_SelectOptionEditorData> _selectOptions;
  String? _errorText;

  bool get _isNursingLevelField {
    final key = (widget.editing?.key ?? _keyController.text).trim();
    return key == 'nursingLevel';
  }

  @override
  void initState() {
    super.initState();
    _keyController = TextEditingController(text: widget.editing?.key ?? '');
    _labelController = TextEditingController(text: widget.editing?.label ?? '');
    _type = widget.editing?.type ?? FieldType.text;
    _required = widget.editing?.required ?? false;
    _showInList = widget.editing?.showInList ?? true;

    final options = widget.editing?.options ?? const <String>[];
    final optionColors =
        widget.editing?.optionColors ?? const <String, String>{};
    _selectOptions = options
        .map(
          (label) => _SelectOptionEditorData(
            label: label,
            colorHex: optionColors[label],
          ),
        )
        .toList();
    if (_selectOptions.isEmpty) {
      _selectOptions = <_SelectOptionEditorData>[
        _SelectOptionEditorData(
          label: '',
          colorHex: _isNursingLevelField ? _presetColors.first : null,
        ),
      ];
    }
    if (_isNursingLevelField) {
      for (var i = 0; i < _selectOptions.length; i += 1) {
        _selectOptions[i].colorHex ??= _presetColors[i % _presetColors.length];
      }
    }
  }

  @override
  void dispose() {
    _keyController.dispose();
    _labelController.dispose();
    for (final option in _selectOptions) {
      option.dispose();
    }
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
                  _buildInlineInputRow(
                    label: '字段键名 *',
                    child: TextFormField(
                      controller: _keyController,
                      enabled: !keyLocked,
                      decoration: const InputDecoration(
                        hintText: '例如: bloodSugar',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return '请填写字段键名';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildInlineInputRow(
                    label: '字段名称 *',
                    child: TextFormField(
                      controller: _labelController,
                      decoration: const InputDecoration(
                        hintText: '例如: 血型',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return '请填写字段名称';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            EditorPanel(
              title: '字段类型',
              child: _buildInlineInputRow(
                label: '字段类型',
                child: AppDropdownFormField<FieldType>(
                  selectedValue: _type,
                  hintText: '选择字段类型',
                  isEnabled: !typeLocked,
                  items: const [
                    AppDropdownOption(value: FieldType.text, label: '文本'),
                    AppDropdownOption(value: FieldType.number, label: '数字'),
                    AppDropdownOption(value: FieldType.date, label: '日期'),
                    AppDropdownOption(value: FieldType.textarea, label: '多行文本'),
                    AppDropdownOption(value: FieldType.select, label: '下拉选项'),
                    AppDropdownOption(value: FieldType.images, label: '图片上传'),
                  ],
                  onChanged: (value) {
                    if (value == null || typeLocked) return;
                    setState(() {
                      _type = value;
                      _errorText = null;
                    });
                  },
                ),
              ),
            ),
            if (_type == FieldType.select) ...[
              const SizedBox(height: 10),
              _buildSelectOptionEditor(),
            ],
            const SizedBox(height: 10),
            EditorPanel(
              title: '显示与校验',
              child: Column(
                children: [
                  _buildToggleRow(
                    title: '是否必填',
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
    final options = <String>[];
    var optionColors = <String, String>{};

    if (fixedType == FieldType.select) {
      for (final option in _selectOptions) {
        final value = option.labelController.text.trim();
        if (value.isNotEmpty) {
          options.add(value);
        }
      }
      if (options.isEmpty) {
        setState(() {
          _errorText = '下拉类型至少配置一个可选项';
        });
        return;
      }

      final seen = <String>{};
      final duplicates = <String>{};
      for (final option in options) {
        if (!seen.add(option)) {
          duplicates.add(option);
        }
      }
      if (duplicates.isNotEmpty) {
        setState(() {
          _errorText = '存在重复选项：${duplicates.join('、')}';
        });
        return;
      }

      optionColors = <String, String>{};
      for (final option in _selectOptions) {
        final name = option.labelController.text.trim();
        if (name.isEmpty) continue;
        final colorHex = option.colorHex?.trim();
        if (colorHex == null || colorHex.isEmpty) {
          if (_isNursingLevelField) {
            setState(() {
              _errorText = '护理等级的每个选项都需要配置颜色';
            });
            return;
          }
          continue;
        }
        if (!_isValidHexColor(colorHex)) {
          setState(() {
            _errorText = '颜色格式不正确，请使用 #RRGGBB 或 #AARRGGBB';
          });
          return;
        }
        optionColors[name] = colorHex.toUpperCase();
      }
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

  Widget _buildSelectOptionEditor() {
    final isNursing = _isNursingLevelField;
    return EditorPanel(
      title: isNursing ? '护理等级配置' : '下拉选项配置',
      child: Column(
        children: [
          for (var i = 0; i < _selectOptions.length; i += 1) ...[
            _buildOptionRow(i),
            if (i < _selectOptions.length - 1) const SizedBox(height: 8),
          ],
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: AppAddTextButton(
              onPressed: _addOption,
              label: '新增选项',
              iconSize: 16,
              height: 34,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionRow(int index) {
    final item = _selectOptions[index];
    final isNursing = _isNursingLevelField;
    final color = _parseHexColor(item.colorHex) ?? const Color(0xFFDCE7F5);

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FBFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDCE8F6)),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: isNursing ? 50 : 58,
                child: Text(
                  '选项${index + 1}',
                  style: const TextStyle(
                    color: Color(0xFF244161),
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: TextFormField(
                  controller: item.labelController,
                  decoration: const InputDecoration(
                    hintText: '请输入选项名称',
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 11, vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              InkWell(
                onTap: () => _pickOptionColor(index),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFC7D6EA)),
                  ),
                  child: const Icon(
                    Icons.color_lens_rounded,
                    size: 20,
                    color: Color(0xFF344A66),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              if (!isNursing)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: IconButton(
                    onPressed: item.colorHex == null
                        ? null
                        : () {
                            setState(() {
                              item.colorHex = null;
                            });
                          },
                    icon: const Icon(Icons.restart_alt_rounded),
                    tooltip: '清空颜色',
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              AppToneIconButton(
                icon: Icons.delete_outline_rounded,
                tooltip: '删除选项',
                onPressed: _selectOptions.length <= 1
                    ? null
                    : () => _removeOption(index),
                size: 38,
                iconSize: 19,
                borderRadius: 11,
                backgroundColor: const Color(0xFFFFF4F6),
                backgroundPressedColor: const Color(0xFFFCE3E7),
                backgroundDisabledColor: const Color(0xFFF7F1F2),
                foregroundColor: const Color(0xFFC94A59),
                foregroundDisabledColor: const Color(0xFFB4A4A8),
                borderColor: const Color(0xFFF0CDD3),
                borderPressedColor: const Color(0xFFEAB4BC),
                shadowColor: const Color(0x22C36A79),
                overlayPressedColor: const Color(0x12B74757),
                overlayHoverColor: const Color(0x0DB74757),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              item.colorHex == null ? '未设置颜色' : '颜色：${item.colorHex}',
              style: const TextStyle(
                color: Color(0xFF6A809D),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _addOption() {
    setState(() {
      final color = _isNursingLevelField
          ? _presetColors[_selectOptions.length % _presetColors.length]
          : null;
      _selectOptions.add(_SelectOptionEditorData(label: '', colorHex: color));
    });
  }

  void _removeOption(int index) {
    if (_selectOptions.length <= 1) return;
    setState(() {
      final target = _selectOptions.removeAt(index);
      target.dispose();
    });
  }

  Future<void> _pickOptionColor(int index) async {
    final current = _selectOptions[index].colorHex;
    final selected = await showDialog<String>(
      context: context,
      builder: (dialogContext) => _ColorPickerDialog(
        initialHex: current,
        presets: _presetColors,
      ),
    );
    if (!mounted || selected == null) return;
    setState(() {
      _selectOptions[index].colorHex = selected;
    });
  }

  bool _isValidHexColor(String value) {
    final reg = RegExp(r'^#([0-9a-fA-F]{6}|[0-9a-fA-F]{8})$');
    return reg.hasMatch(value);
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

  Widget _buildInlineInputRow({
    required String label,
    required Widget child,
    bool alignTop = false,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final labelWidth = constraints.maxWidth < 430 ? 88.0 : 108.0;
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

  Widget _buildToggleRow({
    required String title,
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
              child: Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF213852),
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
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

class _ColorPickerDialog extends StatefulWidget {
  const _ColorPickerDialog({
    required this.initialHex,
    required this.presets,
  });

  final String? initialHex;
  final List<String> presets;

  @override
  State<_ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<_ColorPickerDialog> {
  late final TextEditingController _controller;
  late Color _selectedColor;
  late double _red;
  late double _green;
  late double _blue;
  String? _error;

  @override
  void initState() {
    super.initState();
    _selectedColor = _hexToColor(
      widget.initialHex ??
          (widget.presets.isNotEmpty ? widget.presets.first : '#DCE7F5'),
    );
    _red = _to255(_selectedColor.r).toDouble();
    _green = _to255(_selectedColor.g).toDouble();
    _blue = _to255(_selectedColor.b).toDouble();
    _controller = TextEditingController(text: _colorToHex(_selectedColor));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('颜色选色盘'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _selectedColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFC7D6EA)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '当前颜色：${_colorToHex(_selectedColor)}',
                    style: const TextStyle(
                      color: Color(0xFF445A76),
                      fontWeight: FontWeight.w600,
                      fontSize: 12.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _buildColorSlider(
              label: 'R',
              value: _red,
              activeColor: Colors.red,
              onChanged: (value) {
                setState(() {
                  _red = value;
                  _syncSelectedColor();
                });
              },
            ),
            _buildColorSlider(
              label: 'G',
              value: _green,
              activeColor: Colors.green,
              onChanged: (value) {
                setState(() {
                  _green = value;
                  _syncSelectedColor();
                });
              },
            ),
            _buildColorSlider(
              label: 'B',
              value: _blue,
              activeColor: Colors.blue,
              onChanged: (value) {
                setState(() {
                  _blue = value;
                  _syncSelectedColor();
                });
              },
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final hex in widget.presets)
                  InkWell(
                    onTap: () {
                      setState(() {
                        _selectedColor = _hexToColor(hex);
                        _red = _to255(_selectedColor.r).toDouble();
                        _green = _to255(_selectedColor.g).toDouble();
                        _blue = _to255(_selectedColor.b).toDouble();
                        _controller.text = _colorToHex(_selectedColor);
                        _error = null;
                      });
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: _hexToColor(hex),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFC7D6EA)),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: '颜色值',
                hintText: '#FFD9A6',
                errorText: _error,
              ),
              onChanged: (value) {
                final reg = RegExp(r'^#([0-9a-fA-F]{6}|[0-9a-fA-F]{8})$');
                if (!reg.hasMatch(value.trim())) return;
                final color = _hexToColor(value.trim());
                setState(() {
                  _selectedColor = color;
                  _red = _to255(color.r).toDouble();
                  _green = _to255(color.g).toDouble();
                  _blue = _to255(color.b).toDouble();
                  _error = null;
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () {
            final value = _controller.text.trim().toUpperCase();
            final reg = RegExp(r'^#([0-9A-F]{6}|[0-9A-F]{8})$');
            if (!reg.hasMatch(value)) {
              setState(() {
                _error = '请输入有效的十六进制颜色';
              });
              return;
            }
            Navigator.of(context).pop(_colorToHex(_hexToColor(value)));
          },
          child: const Text('确定'),
        ),
      ],
    );
  }

  Widget _buildColorSlider({
    required String label,
    required double value,
    required Color activeColor,
    required ValueChanged<double> onChanged,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 20,
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF60748E),
              fontWeight: FontWeight.w700,
              fontSize: 12.5,
            ),
          ),
        ),
        Expanded(
          child: Slider(
            value: value,
            max: 255,
            min: 0,
            activeColor: activeColor,
            inactiveColor: const Color(0xFFDCE7F5),
            onChanged: onChanged,
          ),
        ),
        SizedBox(
          width: 34,
          child: Text(
            value.round().toString(),
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: Color(0xFF60748E),
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  void _syncSelectedColor() {
    _selectedColor = Color.fromRGBO(
      _red.round().clamp(0, 255),
      _green.round().clamp(0, 255),
      _blue.round().clamp(0, 255),
      1,
    );
    _controller.text = _colorToHex(_selectedColor);
    _error = null;
  }

  String _colorToHex(Color color) {
    final red = _to255(color.r).toRadixString(16).padLeft(2, '0').toUpperCase();
    final green =
        _to255(color.g).toRadixString(16).padLeft(2, '0').toUpperCase();
    final blue =
        _to255(color.b).toRadixString(16).padLeft(2, '0').toUpperCase();
    return '#$red$green$blue';
  }

  int _to255(double channel) {
    return (channel * 255.0).round().clamp(0, 255);
  }

  Color _hexToColor(String hexValue) {
    var hex = hexValue.replaceAll('#', '');
    if (hex.length == 6) {
      hex = 'FF$hex';
    }
    final value = int.tryParse(hex, radix: 16) ?? 0xFFDCE7F5;
    return Color(value);
  }
}

class _SelectOptionEditorData {
  _SelectOptionEditorData({
    required String label,
    this.colorHex,
  }) : labelController = TextEditingController(text: label);

  final TextEditingController labelController;
  String? colorHex;

  void dispose() {
    labelController.dispose();
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
                    title: '编辑字段',
                    icon: Icons.edit_rounded,
                    color: const Color(0xFF2C88D8),
                    onTap: onEdit,
                  ),
                  _RowAction(
                    title: field.showInList ? '当前可见（点击设为隐藏）' : '当前隐藏（点击设为显示）',
                    icon: field.showInList
                        ? Icons.visibility_rounded
                        : Icons.visibility_off_rounded,
                    color: const Color(0xFF637A97),
                    onTap: onToggleShow,
                  ),
                  _RowAction(
                    title: '删除字段',
                    icon: Icons.delete_outline_rounded,
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
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: title,
      child: IconButton(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        visualDensity: VisualDensity.compact,
        color: onTap == null ? const Color(0xFFB2BDCC) : color,
      ),
    );
  }
}
