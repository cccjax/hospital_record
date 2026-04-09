import 'dart:async';

import 'package:flutter/material.dart';

import '../models/app_models.dart';
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
        OutlinedButton(
          onPressed:
              _submitting ? null : () => Navigator.of(context).pop(false),
          child: const Text('取消'),
        ),
        FilledButton.icon(
          onPressed: _submitting ? null : _handleSubmit,
          icon: Icon(
              _submitting ? Icons.hourglass_top_rounded : Icons.check_rounded),
          label: Text(_submitting ? '保存中...' : widget.submitLabel),
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
    return EditorPanel(
      title: field.required ? '${field.label} *' : field.label,
      description: _fieldDescription(field),
      child: _buildFieldInput(field),
    );
  }

  Widget _buildFieldInput(FieldSchema field) {
    if (field.type == FieldType.select) {
      if (field.options.isEmpty) {
        final controller = _controllers.putIfAbsent(
          field.key,
          () => TextEditingController(),
        );
        return TextFormField(
          controller: controller,
          enabled: !field.locked,
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
      return DropdownButtonFormField<String>(
        initialValue: safeValue,
        decoration: const InputDecoration(
          hintText: '请选择',
        ),
        items: field.options
            .map(
              (option) => DropdownMenuItem<String>(
                value: option,
                child: Text(option),
              ),
            )
            .toList(),
        validator: (value) {
          if (field.required && (value == null || value.isEmpty)) {
            return '请选择${field.label}';
          }
          return null;
        },
        onChanged: field.locked
            ? null
            : (value) {
                setState(() {
                  _selectValues[field.key] = value ?? '';
                });
              },
      );
    }

    final controller = _controllers[field.key]!;
    return TextFormField(
      controller: controller,
      enabled: !field.locked,
      maxLines: field.type == FieldType.textarea ? 4 : 1,
      keyboardType: switch (field.type) {
        FieldType.number => TextInputType.number,
        FieldType.date => TextInputType.datetime,
        _ => TextInputType.text,
      },
      decoration: InputDecoration(
        hintText: switch (field.type) {
          FieldType.date => 'YYYY-MM-DD',
          FieldType.number => '请输入数字',
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

  String _fieldDescription(FieldSchema field) {
    if (field.locked) return '系统字段，当前仅支持查看。';
    return switch (field.type) {
      FieldType.number => '仅支持数字录入',
      FieldType.date => '建议使用 YYYY-MM-DD 格式',
      FieldType.textarea => '支持多行文本',
      FieldType.select => '从备选项中选择',
      FieldType.images => '支持拍照与相册多图上传',
      FieldType.text => '请输入文本内容',
    };
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
