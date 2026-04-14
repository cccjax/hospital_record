import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/app_models.dart';

enum FieldGridVariant {
  card,
  list,
  table,
}

class FieldGrid extends StatelessWidget {
  const FieldGrid({
    super.key,
    required this.schema,
    required this.values,
    this.hiddenKeys = const <String>{},
    this.columns = 3,
    this.compact = false,
    this.variant = FieldGridVariant.card,
    this.showColumnDivider = true,
  });

  final List<FieldSchema> schema;
  final Map<String, dynamic> values;
  final Set<String> hiddenKeys;
  final int columns;
  final bool compact;
  final FieldGridVariant variant;
  final bool showColumnDivider;

  @override
  Widget build(BuildContext context) {
    final visible =
        schema.where((field) => !hiddenKeys.contains(field.key)).toList();
    if (visible.isEmpty) {
      return const SizedBox.shrink();
    }

    if (variant == FieldGridVariant.list) {
      return _FieldList(
        fields: visible,
        values: values,
        compact: compact,
        displayValue: _displayValue,
      );
    }
    if (variant == FieldGridVariant.table) {
      return _FieldTable(
        fields: visible,
        values: values,
        compact: compact,
        showColumnDivider: showColumnDivider,
        displayValue: _displayValue,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 10.0;
        final col = math.max(1, columns);
        final hasBoundedWidth =
            constraints.hasBoundedWidth && constraints.maxWidth.isFinite;
        final itemWidth = hasBoundedWidth
            ? (constraints.maxWidth - gap * (col - 1)) / col
            : 180.0;

        final wrap = Wrap(
          spacing: gap,
          runSpacing: gap,
          alignment: WrapAlignment.start,
          children: [
            for (final field in visible)
              SizedBox(
                width: !hasBoundedWidth
                    ? null
                    : (field.type == FieldType.textarea
                        ? constraints.maxWidth
                        : itemWidth),
                child: _FieldCell(
                  label: field.label,
                  value: _displayValue(field, values[field.key]),
                  compact: compact,
                ),
              ),
          ],
        );

        // Force occupying full row width so partial rows stay left-aligned
        // even when parent uses center alignment.
        if (hasBoundedWidth) {
          return SizedBox(
            width: constraints.maxWidth,
            child: wrap,
          );
        }
        return wrap;
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

class _FieldTable extends StatelessWidget {
  const _FieldTable({
    required this.fields,
    required this.values,
    required this.compact,
    required this.showColumnDivider,
    required this.displayValue,
  });

  final List<FieldSchema> fields;
  final Map<String, dynamic> values;
  final bool compact;
  final bool showColumnDivider;
  final String Function(FieldSchema field, dynamic raw) displayValue;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columnCount = constraints.maxWidth >= 700 ? 2 : 1;
        final rows = <Widget>[];
        final pending = <FieldSchema>[];

        void flushPending() {
          if (pending.isEmpty) return;
          for (var i = 0; i < pending.length; i += columnCount) {
            final chunk = pending.sublist(
              i,
              math.min(i + columnCount, pending.length),
            );
            rows.add(
              _TableNormalRow(
                fields: chunk,
                values: values,
                compact: compact,
                showColumnDivider: showColumnDivider,
                displayValue: displayValue,
                columnCount: columnCount,
              ),
            );
          }
          pending.clear();
        }

        for (final field in fields) {
          if (field.type == FieldType.textarea) {
            flushPending();
            rows.add(
              _TableTextareaRow(
                field: field,
                value: displayValue(field, values[field.key]),
                compact: compact,
              ),
            );
            continue;
          }
          pending.add(field);
        }
        flushPending();

        return DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFFF7FBFF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFDCE7F5)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            child: Column(
              children: [
                for (var i = 0; i < rows.length; i++) ...[
                  rows[i],
                  if (i < rows.length - 1)
                    const Divider(
                      height: 1,
                      thickness: 1,
                      color: Color(0xFFE3EBF7),
                    ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TableNormalRow extends StatelessWidget {
  const _TableNormalRow({
    required this.fields,
    required this.values,
    required this.compact,
    required this.showColumnDivider,
    required this.displayValue,
    required this.columnCount,
  });

  final List<FieldSchema> fields;
  final Map<String, dynamic> values;
  final bool compact;
  final bool showColumnDivider;
  final String Function(FieldSchema field, dynamic raw) displayValue;
  final int columnCount;

  @override
  Widget build(BuildContext context) {
    if (columnCount == 1 || fields.length == 1) {
      final field = fields.first;
      return _TableCell(
        label: field.label,
        value: displayValue(field, values[field.key]),
        compact: compact,
      );
    }

    return IntrinsicHeight(
      child: Row(
        children: [
          Expanded(
            child: _TableCell(
              label: fields[0].label,
              value: displayValue(fields[0], values[fields[0].key]),
              compact: compact,
            ),
          ),
          showColumnDivider
              ? const VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: Color(0xFFE3EBF7),
                )
              : const SizedBox(width: 8),
          Expanded(
            child: _TableCell(
              label: fields[1].label,
              value: displayValue(fields[1], values[fields[1].key]),
              compact: compact,
            ),
          ),
        ],
      ),
    );
  }
}

class _TableTextareaRow extends StatelessWidget {
  const _TableTextareaRow({
    required this.field,
    required this.value,
    required this.compact,
  });

  final FieldSchema field;
  final String value;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final labelWidth = compact ? 70.0 : 82.0;
    final labelStyle = TextStyle(
      color: const Color(0xFF5F738D),
      fontSize: compact ? 12 : 12.5,
      fontWeight: FontWeight.w600,
      height: 1.25,
    );
    final valueStyle = TextStyle(
      color: const Color(0xFF20364E),
      fontSize: compact ? 13.5 : 14.5,
      fontWeight: FontWeight.w600,
      height: 1.35,
    );

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: compact ? 8 : 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: labelWidth,
            child: Text(
              field.label,
              style: labelStyle,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.left,
              style: valueStyle,
            ),
          ),
        ],
      ),
    );
  }
}

class _TableCell extends StatelessWidget {
  const _TableCell({
    required this.label,
    required this.value,
    required this.compact,
  });

  final String label;
  final String value;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final labelWidth = compact ? 70.0 : 82.0;
    final labelStyle = TextStyle(
      color: const Color(0xFF5F738D),
      fontSize: compact ? 12 : 12.5,
      fontWeight: FontWeight.w600,
      height: 1.25,
    );
    final valueStyle = TextStyle(
      color: const Color(0xFF20364E),
      fontSize: compact ? 13.5 : 14.5,
      fontWeight: FontWeight.w600,
      height: 1.3,
    );

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: compact ? 8 : 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: labelWidth,
            child: Text(
              label,
              style: labelStyle,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.left,
              style: valueStyle,
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldList extends StatelessWidget {
  const _FieldList({
    required this.fields,
    required this.values,
    required this.compact,
    required this.displayValue,
  });

  final List<FieldSchema> fields;
  final Map<String, dynamic> values;
  final bool compact;
  final String Function(FieldSchema field, dynamic raw) displayValue;

  @override
  Widget build(BuildContext context) {
    final labelWidth = compact ? 68.0 : 78.0;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF7FBFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDCE7F5)),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 10 : 11,
          vertical: compact ? 8 : 9,
        ),
        child: Column(
          children: [
            for (var i = 0; i < fields.length; i++) ...[
              _FieldListRow(
                field: fields[i],
                labelWidth: labelWidth,
                value: displayValue(fields[i], values[fields[i].key]),
                compact: compact,
              ),
              if (i < fields.length - 1)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 7),
                  child: Divider(
                    height: 1,
                    thickness: 1,
                    color: Color(0xFFE3EBF7),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FieldListRow extends StatelessWidget {
  const _FieldListRow({
    required this.field,
    required this.labelWidth,
    required this.value,
    required this.compact,
  });

  final FieldSchema field;
  final double labelWidth;
  final String value;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final labelStyle = TextStyle(
      color: const Color(0xFF5F738D),
      fontSize: compact ? 12 : 12.5,
      fontWeight: FontWeight.w600,
      height: 1.25,
    );
    final valueStyle = TextStyle(
      color: const Color(0xFF20364E),
      fontSize: compact ? 13.5 : 14.5,
      fontWeight: FontWeight.w600,
      height: 1.35,
    );

    if (field.type == FieldType.textarea) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(field.label, style: labelStyle),
          const SizedBox(height: 5),
          Text(value, style: valueStyle),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: labelWidth,
          child: Text(
            field.label,
            style: labelStyle,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            style: valueStyle,
          ),
        ),
      ],
    );
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
        color: const Color(0xFFF3F8FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDCE7F5)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0E1A3B5D),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 9 : 10,
          vertical: compact ? 8 : 10,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: compact ? 12 : 12.5,
                color: const Color(0xFF5F738D),
                height: 1.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: compact ? 14 : 15,
                color: const Color(0xFF213750),
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
