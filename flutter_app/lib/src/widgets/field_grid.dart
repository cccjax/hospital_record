import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/app_models.dart';

class FieldGrid extends StatelessWidget {
  const FieldGrid({
    super.key,
    required this.schema,
    required this.values,
    this.hiddenKeys = const <String>{},
    this.columns = 3,
    this.compact = false,
  });

  final List<FieldSchema> schema;
  final Map<String, dynamic> values;
  final Set<String> hiddenKeys;
  final int columns;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final visible = schema.where((field) => !hiddenKeys.contains(field.key)).toList();
    if (visible.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 8.0;
        final col = math.max(1, columns);
        final itemWidth = (constraints.maxWidth - gap * (col - 1)) / col;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final field in visible)
              SizedBox(
                width: field.type == FieldType.textarea ? constraints.maxWidth : itemWidth,
                child: _FieldCell(
                  label: field.label,
                  value: _displayValue(field, values[field.key]),
                  compact: compact,
                ),
              ),
          ],
        );
      },
    );
  }

  String _displayValue(FieldSchema field, dynamic raw) {
    if (raw == null) return '-';
    if (field.type == FieldType.images && raw is List) {
      return '共 ${raw.length} 张';
    }
    final value = raw.toString().trim();
    return value.isEmpty ? '-' : value;
  }
}

class _FieldCell extends StatelessWidget {
  const _FieldCell({
    required this.label,
    required this.value,
    required this.compact,
  });

  final String label;
  final String value;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF9FBFF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEBF1FA)),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 8,
          vertical: compact ? 7 : 8,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: compact ? 11.5 : 12,
                color: const Color(0xFF66778F),
                height: 1.2,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              value,
              style: TextStyle(
                fontSize: compact ? 13 : 13.5,
                color: const Color(0xFF1F3149),
                fontWeight: FontWeight.w600,
                height: 1.25,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
