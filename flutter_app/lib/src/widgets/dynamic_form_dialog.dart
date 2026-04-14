import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/app_models.dart';
import 'app_add_button.dart';
import 'app_dropdown_form_field.dart';
import 'editor_dialog.dart';

typedef DynamicFormSubmit = FutureOr<String?> Function(
    Map<String, dynamic> values);

class DynamicFormDialog extends StatefulWidget {
  const DynamicFormDialog({
    super.key,
    required this.title,
    required this.schema,
    required this.initialValues,
    required this.onSubmit,
    this.submitLabel = '保存',
  });

  final String title;
  final List<FieldSchema> schema;
  final Map<String, dynamic> initialValues;
  final DynamicFormSubmit onSubmit;
  final String submitLabel;

  @override
  State<DynamicFormDialog> createState() => _DynamicFormDialogState();
}

class _DynamicFormDialogState extends State<DynamicFormDialog> {
  final _formKey = GlobalKey<FormState>();
  bool _submitting = false;
  String? _errorText;
  late final Map<String, TextEditingController> _controllers;
  late final Map<String, String> _selectValues;

  @override
  void initState() {
    super.initState();
    _controllers = <String, TextEditingController>{};
    _selectValues = <String, String>{};

    for (final field in widget.schema) {
      final raw = widget.initialValues[field.key];
      final value = raw == null ? '' : raw.toString();
      if (field.type == FieldType.select) {
        if (field.options.isEmpty) {
          _controllers[field.key] = TextEditingController(text: value);
        } else {
          final safeValue =
              field.options.contains(value) ? value : field.options.first;
          _selectValues[field.key] = safeValue;
        }
      } else {
        _controllers[field.key] = TextEditingController(text: value);
      }
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return EditorDialog(
      title: widget.title,
      subtitle: '带 * 为必填，请核对后保存',
      icon: Icons.edit_note_rounded,
      maxWidth: 620,
      actions: [
        AppCancelButton(
          label: '取消',
          onPressed:
              _submitting ? null : () => Navigator.of(context).pop(false),
        ),
        AppSaveButton(
          onPressed: _submitting ? null : _handleSubmit,
          icon: _submitting ? Icons.hourglass_top_rounded : Icons.check_rounded,
          label: _submitting ? '保存中...' : widget.submitLabel,
        ),
      ],
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.schema.isEmpty)
              const EditorPanel(
                title: '暂无可编辑字段',
                description: '请先在字段配置中新增字段。',
                child: SizedBox.shrink(),
              ),
            for (final field in widget.schema) ...[
              _buildFieldCard(field),
              const SizedBox(height: 10),
            ],
            if (_errorText != null) _buildErrorBanner(),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldCard(FieldSchema field) {
    final editable = !field.locked || _canEditLockedField(field);
    final labelText = field.required ? '${field.label} *' : field.label;
    return EditorPanel(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final labelWidth = constraints.maxWidth < 430 ? 86.0 : 108.0;
          return Row(
            crossAxisAlignment: field.type == FieldType.textarea
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: labelWidth,
                child: Padding(
                  padding: EdgeInsets.only(
                    top: field.type == FieldType.textarea ? 10 : 0,
                  ),
                  child: Text(
                    labelText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF244161),
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildFieldInput(
                  field,
                  editable: editable,
                ),
              ),
              if (!editable) ...[
                const SizedBox(width: 6),
                const Icon(
                  Icons.lock_outline_rounded,
                  size: 14,
                  color: Color(0xFF7890AB),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildFieldInput(
    FieldSchema field, {
    required bool editable,
  }) {
    if (field.type == FieldType.select) {
      if (field.options.isEmpty) {
        final controller = _controllers.putIfAbsent(
          field.key,
          () => TextEditingController(),
        );
        return TextFormField(
          controller: controller,
          enabled: editable,
          decoration: const InputDecoration(
            hintText: '请输入内容',
          ),
          validator: (value) {
            if (field.required && (value == null || value.trim().isEmpty)) {
              return '请填写${field.label}';
            }
            return null;
          },
        );
      }
      final current = _selectValues[field.key];
      final safeValue = current != null && field.options.contains(current)
          ? current
          : field.options.first;
      _selectValues[field.key] = safeValue;
      return AppDropdownFormField<String>(
        selectedValue: safeValue,
        hintText: '请选择',
        isEnabled: editable,
        items: field.options
            .map(
              (option) => AppDropdownOption<String>(
                value: option,
                label: option,
              ),
            )
            .toList(),
        validator: (value) {
          if (field.required && (value == null || value.isEmpty)) {
            return '请选择${field.label}';
          }
          return null;
        },
        onChanged: (value) {
          if (!editable) return;
          setState(() {
            _selectValues[field.key] = value ?? '';
          });
        },
      );
    }

    final controller = _controllers[field.key]!;
    final isTextarea = field.type == FieldType.textarea;
    if (field.type == FieldType.date) {
      return TextFormField(
        controller: controller,
        enabled: editable,
        readOnly: true,
        keyboardType: TextInputType.none,
        decoration: const InputDecoration(
          hintText: '请选择日期',
          suffixIcon: Icon(Icons.calendar_month_rounded, size: 18),
        ),
        onTap: !editable
            ? null
            : () async {
                final selected = await _pickDate(controller.text);
                if (selected == null) {
                  return;
                }
                controller.text = DateFormat('yyyy-MM-dd').format(selected);
              },
        validator: (value) {
          if (field.required && (value == null || value.trim().isEmpty)) {
            return '请填写${field.label}';
          }
          return null;
        },
      );
    }

    return TextFormField(
      controller: controller,
      enabled: editable,
      minLines: isTextarea ? 3 : 1,
      maxLines: isTextarea ? null : 1,
      keyboardType: switch (field.type) {
        FieldType.number => TextInputType.number,
        FieldType.textarea => TextInputType.multiline,
        _ => TextInputType.text,
      },
      textInputAction:
          isTextarea ? TextInputAction.newline : TextInputAction.done,
      decoration: InputDecoration(
        hintText: switch (field.type) {
          FieldType.number => '请输入数字',
          FieldType.textarea => '请输入内容（支持换行）',
          _ => '请输入内容',
        },
      ),
      validator: (value) {
        if (field.required && (value == null || value.trim().isEmpty)) {
          return '请填写${field.label}';
        }
        return null;
      },
    );
  }

  Future<DateTime?> _pickDate(String rawValue) async {
    final initialDate = _parseDate(rawValue) ?? DateTime.now();
    final firstDate = DateTime(1900, 1, 1);
    final lastDate = DateTime(2100, 12, 31);
    final safeInitialDate = initialDate.isBefore(firstDate)
        ? firstDate
        : initialDate.isAfter(lastDate)
            ? lastDate
            : initialDate;
    return showDatePicker(
      context: context,
      locale: const Locale('zh', 'CN'),
      initialDate: safeInitialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: '选择日期',
      cancelText: '取消',
      confirmText: '确定',
      initialEntryMode: DatePickerEntryMode.calendarOnly,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            datePickerTheme: const DatePickerThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(20)),
              ),
              headerBackgroundColor: Color(0xFFEAF4FF),
              headerForegroundColor: Color(0xFF1F456E),
              surfaceTintColor: Colors.transparent,
            ),
          ),
          child: child!,
        );
      },
    );
  }

  DateTime? _parseDate(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      return null;
    }
    final parsed = DateTime.tryParse(normalized);
    if (parsed != null) {
      return parsed;
    }
    try {
      return DateFormat('yyyy-MM-dd').parseStrict(normalized);
    } catch (_) {
      return null;
    }
  }

  Widget _buildErrorBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 2),
      padding: const EdgeInsets.fromLTRB(11, 10, 11, 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF2F3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF1C7CC)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: Color(0xFFB63A49),
            size: 16,
          ),
          const SizedBox(width: 6),
          Expanded(
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
      ),
    );
  }

  bool _canEditLockedField(FieldSchema field) {
    if (field.key == 'nursingLevel' ||
        field.key == 'name' ||
        field.key == 'diseaseCode') {
      return true;
    }
    if (field.key == 'admissionNo') {
      final current = (widget.initialValues[field.key] ?? '').toString().trim();
      return current.isEmpty;
    }
    return false;
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final payload = <String, dynamic>{};
    for (final field in widget.schema) {
      if (field.type == FieldType.select) {
        if (field.options.isEmpty) {
          payload[field.key] = _controllers[field.key]?.text.trim() ?? '';
        } else {
          payload[field.key] = _selectValues[field.key] ?? '';
        }
      } else {
        payload[field.key] = _controllers[field.key]!.text.trim();
      }
    }

    setState(() {
      _submitting = true;
      _errorText = null;
    });

    final message = await widget.onSubmit(payload);
    if (!mounted) return;

    if (message == null) {
      Navigator.of(context).pop(true);
      return;
    }

    setState(() {
      _submitting = false;
      _errorText = message;
    });
  }
}
