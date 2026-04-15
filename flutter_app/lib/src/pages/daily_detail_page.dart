import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_models.dart';
import '../state/hospital_app_state.dart';
import '../widgets/app_back_button.dart';
import '../widgets/field_grid.dart';
import '../widgets/section_card.dart';

class DailyDetailPage extends StatelessWidget {
  const DailyDetailPage({
    super.key,
    required this.dailyId,
  });

  final String dailyId;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<HospitalAppState>();
    final daily = state.findDaily(dailyId);
    if (daily == null) {
      return Scaffold(
        appBar: _buildAppBar(),
        body: const Center(child: Text('日常记录不存在')),
      );
    }
    final admission = state.findAdmission(daily.admissionId);
    final patient =
        admission == null ? null : state.findPatient(admission.admissionNo);
    final schema = state.schemaOf('daily');
    final detailSchema =
        schema.where((field) => field.type != FieldType.images).toList();
    final imageSchema =
        schema.where((field) => field.type == FieldType.images).toList();
    final patientName = (patient?.values['name'] ?? '-').toString().trim();
    final admissionNo = admission?.admissionNo ?? '-';
    final admitDate = (admission?.values['admitDate'] ?? '-').toString().trim();

    return Scaffold(
      appBar: _buildAppBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
        children: [
          _HeroSummary(
            patientName: patientName.isEmpty ? '-' : patientName,
            admissionNo: admissionNo,
            admitDate: admitDate.isEmpty ? '-' : admitDate,
          ),
          const SizedBox(height: 10),
          SectionCard(
            title: '日常记录详情',
            child: FieldGrid(
              schema: detailSchema,
              values: daily.values,
              variant: FieldGridVariant.table,
              compact: true,
              showColumnDivider: false,
            ),
          ),
          if (imageSchema.isNotEmpty) ...[
            const SizedBox(height: 10),
            SectionCard(
              title: '速记白板',
              child: _ImageFieldSection(
                schema: imageSchema,
                values: daily.values,
              ),
            ),
          ],
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
        '日常详情',
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _ImageFieldSection extends StatelessWidget {
  const _ImageFieldSection({
    required this.schema,
    required this.values,
  });

  final List<FieldSchema> schema;
  final Map<String, dynamic> values;

  @override
  Widget build(BuildContext context) {
    final groups = <_ImageFieldGroup>[];
    for (final field in schema) {
      final images = _normalizeImageValues(values[field.key]);
      groups.add(
        _ImageFieldGroup(
          label: field.label,
          images: images,
        ),
      );
    }

    final hasAnyImage = groups.any((group) => group.images.isNotEmpty);
    if (!hasAnyImage) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text(
          '暂无速记白板内容',
          style: TextStyle(
            color: Color(0xFF6F859F),
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final group in groups) ...[
          if (group.images.isNotEmpty) ...[
            if (schema.length > 1)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  group.label,
                  style: const TextStyle(
                    color: Color(0xFF294666),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final src in group.images)
                  _ImageThumb(
                    src: src,
                    onOpen: () => _showImagePreview(context, src),
                  ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ],
      ],
    );
  }

  List<String> _normalizeImageValues(dynamic raw) {
    if (raw is! List) return const <String>[];
    final list = <String>[];
    for (final item in raw) {
      if (item is String) {
        final text = item.trim();
        if (text.isNotEmpty) list.add(text);
        continue;
      }
      if (item is Map) {
        final src = item['src'];
        if (src is String && src.trim().isNotEmpty) {
          list.add(src.trim());
        }
      }
    }
    return list;
  }

  Future<void> _showImagePreview(BuildContext context, String src) async {
    final bytes = _decodeImage(src);
    if (bytes == null) return;
    await showDialog<void>(
      context: context,
      barrierColor: const Color(0xCC091423),
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(14),
          child: Stack(
            children: [
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.88),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: InteractiveViewer(
                      minScale: 0.8,
                      maxScale: 4.5,
                      child: Center(
                        child: Image.memory(
                          bytes,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: Material(
                  color: const Color(0x80111F32),
                  borderRadius: BorderRadius.circular(999),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: () => Navigator.of(dialogContext).pop(),
                    child: const SizedBox(
                      width: 32,
                      height: 32,
                      child: Icon(
                        Icons.close_rounded,
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Uint8List? _decodeImage(String src) {
    final raw = src.trim();
    if (raw.isEmpty) return null;
    try {
      final payload = raw.contains(',') ? raw.split(',').last : raw;
      return base64Decode(payload);
    } catch (_) {
      return null;
    }
  }
}

class _ImageFieldGroup {
  const _ImageFieldGroup({
    required this.label,
    required this.images,
  });

  final String label;
  final List<String> images;
}

class _ImageThumb extends StatefulWidget {
  const _ImageThumb({
    required this.src,
    required this.onOpen,
  });

  final String src;
  final VoidCallback onOpen;

  @override
  State<_ImageThumb> createState() => _ImageThumbState();
}

class _ImageThumbState extends State<_ImageThumb> {
  static final Map<String, Uint8List?> _bytesCache = <String, Uint8List?>{};

  late Uint8List? _bytes;

  @override
  void initState() {
    super.initState();
    _bytes = _decodeImage(widget.src);
  }

  @override
  void didUpdateWidget(covariant _ImageThumb oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.src != widget.src) {
      _bytes = _decodeImage(widget.src);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Material(
        color: const Color(0xFFF1F7FF),
        child: InkWell(
          onTap: widget.onOpen,
          child: SizedBox(
            width: 102,
            height: 74,
            child: _bytes == null
                ? const Center(
                    child: Icon(
                      Icons.broken_image_outlined,
                      size: 18,
                      color: Color(0xFF8BA2BE),
                    ),
                  )
                : Image.memory(
                    _bytes!,
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.medium,
                  ),
          ),
        ),
      ),
    );
  }

  Uint8List? _decodeImage(String src) {
    return _bytesCache.putIfAbsent(src, () {
      final raw = src.trim();
      if (raw.isEmpty) return null;
      try {
        final payload = raw.contains(',') ? raw.split(',').last : raw;
        return base64Decode(payload);
      } catch (_) {
        return null;
      }
    });
  }
}

class _HeroSummary extends StatelessWidget {
  const _HeroSummary({
    required this.patientName,
    required this.admissionNo,
    required this.admitDate,
  });

  final String patientName;
  final String admissionNo;
  final String admitDate;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xFFF8FBFF),
        border: Border.all(color: const Color(0xFFE7EEF8)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120F2744),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(13, 12, 13, 13),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(
              Icons.person_rounded,
              size: 18,
              color: Color(0xFF3F6E9F),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    patientName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1F3149),
                    ),
                  ),
                  _HeroChip(
                    icon: Icons.badge_outlined,
                    text: '住院号 $admissionNo',
                  ),
                  _HeroChip(
                    icon: Icons.calendar_month_outlined,
                    text: '住院日期 $admitDate',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F9FF),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFD9E5F4)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: const Color(0xFF5A7091)),
            const SizedBox(width: 5),
            Text(
              text,
              style: const TextStyle(
                color: Color(0xFF4E627D),
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
