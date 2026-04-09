import 'dart:async';

import 'package:flutter/material.dart';

import '../models/app_models.dart';

typedef DynamicFormSubmit = FutureOr<String?> Function(Map<String, dynamic> values);

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
          final fallback = field.options.first;
          _selectValues[field.key] = value.isEmpty ? fallback : value;
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
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final field in widget.schema) ...[
                  _buildField(field),
                  const SizedBox(height: 10),
                ],
                if (_errorText != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2, bottom: 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _errorText!,
                        style: const TextStyle(
                          color: Color(0xFFB63A49),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(false),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _submitting ? null : _handleSubmit,
          child: Text(_submitting ? '保存中...' : widget.submitLabel),
        ),
      ],
    );
  }

  Widget _buildField(FieldSchema field) {
    final label = field.required ? '${field.label} *' : field.label;
    if (field.type == FieldType.select) {
      if (field.options.isEmpty) {
        final controller = _controllers.putIfAbsent(
          field.key,
          () => TextEditingController(),
        );
        return TextFormField(
          controller: controller,
          enabled: !field.locked,
          decoration: InputDecoration(labelText: label),
          validator: (value) {
            if (field.required && (value == null || value.trim().isEmpty)) {
              return '请填写${field.label}';
            }
            return null;
          },
        );
      }
      return DropdownButtonFormField<String>(
        initialValue: _selectValues[field.key],
        decoration: InputDecoration(labelText: label),
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
        labelText: label,
        hintText: field.type == FieldType.date ? 'YYYY-MM-DD' : null,
      ),
      validator: (value) {
        if (field.required && (value == null || value.trim().isEmpty)) {
          return '请填写${field.label}';
        }
        return null;
      },
    );
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
