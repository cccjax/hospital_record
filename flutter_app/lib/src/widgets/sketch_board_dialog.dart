import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'app_add_button.dart';
import 'editor_dialog.dart';

class SketchBoardResult {
  const SketchBoardResult({
    required this.imageDataUri,
    required this.sketchData,
  });

  final String imageDataUri;
  final Map<String, dynamic> sketchData;
}

Future<SketchBoardResult?> showSketchBoardDialog(
  BuildContext context, {
  String title = '速记白板',
  Map<String, dynamic>? initialSketchData,
}) {
  return showDialog<SketchBoardResult>(
    context: context,
    builder: (_) => _SketchBoardDialog(
      title: title,
      initialSketchData: initialSketchData,
    ),
  );
}

class _SketchBoardDialog extends StatefulWidget {
  const _SketchBoardDialog({
    required this.title,
    this.initialSketchData,
  });

  final String title;
  final Map<String, dynamic>? initialSketchData;

  @override
  State<_SketchBoardDialog> createState() => _SketchBoardDialogState();
}

class _SketchBoardDialogState extends State<_SketchBoardDialog> {
  static const Color _canvasBackground = Color(0xFFFCFEFF);

  static const List<_PenPreset> _defaultPresets = <_PenPreset>[
    _PenPreset(color: Color(0xFF1C2D42), width: 2.6),
    _PenPreset(color: Color(0xFF12736A), width: 3.0),
    _PenPreset(color: Color(0xFF2F6DB2), width: 2.4),
    _PenPreset(color: Color(0xFF9C5228), width: 3.2),
    _PenPreset(color: Color(0xFF8F3442), width: 2.8),
    _PenPreset(color: Color(0xFF6D5AAE), width: 2.5),
  ];

  final List<_SketchStroke> _strokes = <_SketchStroke>[];
  late final List<_PenPreset> _presets;

  int _selectedPresetIndex = 0;
  bool _eraser = false;
  bool _showGrid = false;
  bool _saving = false;
  String? _errorText;
  Size _canvasSize = Size.zero;

  Color get _selectedColor => _presets[_selectedPresetIndex].color;
  double get _selectedWidth => _presets[_selectedPresetIndex].width;

  @override
  void initState() {
    super.initState();
    _presets = _defaultPresets.toList(growable: false);
    _restoreInitialSketch();
  }

  @override
  Widget build(BuildContext context) {
    return EditorDialog(
      title: widget.title,
      subtitle: '长按色块可自定义颜色和粗细',
      icon: Icons.draw_rounded,
      maxWidth: 1400,
      maxHeightFactor: 0.96,
      insetPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      bodyPadding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      scrollableBody: false,
      actions: [
        AppCancelButton(
          label: '取消',
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
        ),
        AppSaveButton(
          onPressed: _saving ? null : _saveSketch,
          icon: _saving ? Icons.hourglass_top_rounded : Icons.image_rounded,
          label: _saving ? '保存中...' : '保存白板',
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildToolbar(),
          const SizedBox(height: 8),
          const Text(
            '提示：网格线位于底层，擦除后会透出网格线',
            style: TextStyle(
              color: Color(0xFF5E7592),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (_errorText != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                _errorText!,
                style: const TextStyle(
                  color: Color(0xFFB74857),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          const SizedBox(height: 8),
          Expanded(
            child: _buildCanvas(),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (var i = 0; i < _presets.length; i++)
          _ColorChip(
            color: _presets[i].color,
            selected: !_eraser && i == _selectedPresetIndex,
            onTap: () {
              setState(() {
                _eraser = false;
                _selectedPresetIndex = i;
              });
            },
            onLongPress: () => _editPreset(i),
          ),
        AppToneTextButton(
          label: '编辑当前色',
          icon: Icons.palette_outlined,
          onPressed: () => _editPreset(_selectedPresetIndex),
          minWidth: 92,
          height: 32,
          fontSize: 11.6,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        ),
        AppToneTextButton(
          label: _eraser ? '橡皮开启' : '橡皮擦',
          icon: Icons.auto_fix_off_rounded,
          onPressed: () {
            setState(() {
              _eraser = !_eraser;
            });
          },
          minWidth: 88,
          height: 32,
          fontSize: 11.8,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          backgroundColor:
              _eraser ? const Color(0xFFFFEFE9) : const Color(0xFFF2F7FF),
          backgroundPressedColor:
              _eraser ? const Color(0xFFFFE3D8) : const Color(0xFFE8F1FE),
          borderColor: _eraser ? const Color(0xFFF2C7B8) : null,
          borderPressedColor: _eraser ? const Color(0xFFE3B39D) : null,
          foregroundColor: _eraser ? const Color(0xFFB25B33) : null,
        ),
        _WidthSelector(
          value: _selectedWidth,
          onChanged: (next) {
            setState(() {
              final current = _presets[_selectedPresetIndex];
              _presets[_selectedPresetIndex] = current.copyWith(width: next);
            });
          },
        ),
        AppToneTextButton(
          label: '撤销',
          icon: Icons.undo_rounded,
          onPressed: _strokes.isEmpty
              ? null
              : () {
                  setState(() {
                    _strokes.removeLast();
                  });
                },
          minWidth: 64,
          height: 32,
          fontSize: 11.8,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        ),
        AppToneTextButton(
          label: '清空',
          icon: Icons.layers_clear_rounded,
          onPressed: _strokes.isEmpty ? null : _clearBoard,
          minWidth: 64,
          height: 32,
          fontSize: 11.8,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          backgroundColor: const Color(0xFFFFF3F4),
          backgroundPressedColor: const Color(0xFFFFE9EC),
          borderColor: const Color(0xFFF6CBD1),
          borderPressedColor: const Color(0xFFE9B5BE),
          foregroundColor: const Color(0xFFB24D5C),
          foregroundDisabledColor: const Color(0xFFCAA3AA),
          shadowColor: const Color(0x24CB7481),
        ),
        AppToneTextButton(
          label: _showGrid ? '隐藏网格' : '显示网格',
          icon: Icons.grid_on_rounded,
          onPressed: () {
            setState(() {
              _showGrid = !_showGrid;
            });
          },
          minWidth: 82,
          height: 32,
          fontSize: 11.8,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        ),
      ],
    );
  }

  Widget _buildCanvas() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth <= 0 ? 1.0 : constraints.maxWidth;
        final height = constraints.maxHeight <= 0 ? 1.0 : constraints.maxHeight;
        _canvasSize = Size(width, height);

        return ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: _canvasBackground,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFD4E2F2)),
            ),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanStart: (details) => _startStroke(details.localPosition),
              onPanUpdate: (details) => _appendPoint(details.localPosition),
              onPanEnd: (_) => _finishStroke(),
              child: SizedBox(
                width: width,
                height: height,
                child: CustomPaint(
                  painter: _SketchPainter(
                    strokes: _strokes,
                    showGrid: _showGrid,
                    backgroundColor: _canvasBackground,
                    gridColor: const Color(0xCFD6E4F5),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _clearBoard() async {
    final confirmed = await _confirmAction(
      title: '清空白板',
      content: '确认清空当前所有手写内容吗？',
      confirmLabel: '确认清空',
    );
    if (!mounted || !confirmed) return;
    setState(() {
      _strokes.clear();
    });
  }

  Future<void> _editPreset(int index) async {
    final current = _presets[index];
    final edited = await showDialog<_PenPreset>(
      context: context,
      builder: (dialogContext) {
        var hsv = HSVColor.fromColor(current.color);
        var width = current.width;
        return StatefulBuilder(
          builder: (context, setInnerState) {
            final sample = hsv.toColor();
            return Dialog(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '编辑预置画笔',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF223D5B),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F8FF),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFD7E5F6)),
                      ),
                      child: Center(
                        child: Text(
                          '示例笔触',
                          style: TextStyle(
                            color: sample,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _LabeledSlider(
                      label: '色相',
                      value: hsv.hue,
                      min: 0,
                      max: 360,
                      onChanged: (value) {
                        setInnerState(() {
                          hsv = hsv.withHue(value);
                        });
                      },
                    ),
                    _LabeledSlider(
                      label: '饱和度',
                      value: hsv.saturation,
                      min: 0,
                      max: 1,
                      onChanged: (value) {
                        setInnerState(() {
                          hsv = hsv.withSaturation(value);
                        });
                      },
                    ),
                    _LabeledSlider(
                      label: '明度',
                      value: hsv.value,
                      min: 0,
                      max: 1,
                      onChanged: (value) {
                        setInnerState(() {
                          hsv = hsv.withValue(value);
                        });
                      },
                    ),
                    _LabeledSlider(
                      label: '粗细',
                      value: width,
                      min: 1.8,
                      max: 10,
                      onChanged: (value) {
                        setInnerState(() {
                          width = value;
                        });
                      },
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          child: const Text('取消'),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: () {
                            Navigator.of(dialogContext).pop(
                              _PenPreset(
                                color: hsv.toColor(),
                                width: width,
                              ),
                            );
                          },
                          child: const Text('应用'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    if (!mounted || edited == null) return;
    setState(() {
      _presets[index] = edited;
      _selectedPresetIndex = index;
      _eraser = false;
    });
  }

  void _restoreInitialSketch() {
    final raw = widget.initialSketchData;
    if (raw == null) return;
    final strokes = raw['strokes'];
    if (strokes is! List) return;

    final parsed = <_SketchStroke>[];
    for (final item in strokes) {
      if (item is! Map) continue;
      final color = _parseColor(item['color']);
      final width = _parseWidth(item['width']);
      final eraser = item['eraser'] == true;
      final points = _parsePoints(item['points']);
      if (points.isEmpty) continue;
      parsed.add(
        _SketchStroke(
          color: color,
          width: width,
          points: points,
          isEraser: eraser,
        ),
      );
    }
    if (parsed.isEmpty) return;
    _strokes
      ..clear()
      ..addAll(parsed);
  }

  Color _parseColor(dynamic raw) {
    if (raw is String) {
      var hex = raw.trim().replaceAll('#', '');
      if (hex.length == 6) {
        hex = 'FF$hex';
      }
      if (hex.length == 8) {
        final value = int.tryParse(hex, radix: 16);
        if (value != null) return Color(value);
      }
    }
    if (raw is int) {
      return Color(raw);
    }
    return _defaultPresets.first.color;
  }

  double _parseWidth(dynamic raw) {
    if (raw is num) {
      return raw.toDouble().clamp(1.2, 16.0);
    }
    final text = raw?.toString() ?? '';
    final parsed = double.tryParse(text);
    if (parsed == null) return 2.6;
    return parsed.clamp(1.2, 16.0);
  }

  List<Offset> _parsePoints(dynamic raw) {
    if (raw is! List) return const <Offset>[];
    final points = <Offset>[];
    for (final item in raw) {
      if (item is List && item.length >= 2) {
        final x = _parseUnit(item[0]);
        final y = _parseUnit(item[1]);
        if (x != null && y != null) {
          points.add(Offset(x, y));
        }
      }
    }
    return points;
  }

  double? _parseUnit(dynamic raw) {
    if (raw is num) {
      return raw.toDouble().clamp(0.0, 1.0);
    }
    final text = raw?.toString() ?? '';
    final parsed = double.tryParse(text);
    if (parsed == null) return null;
    return parsed.clamp(0.0, 1.0);
  }

  void _startStroke(Offset point) {
    if (_canvasSize.width <= 0 || _canvasSize.height <= 0) return;
    setState(() {
      _errorText = null;
      _strokes.add(
        _SketchStroke(
          color: _eraser ? const Color(0x00000000) : _selectedColor,
          width: _eraser ? (_selectedWidth + 4.0) : _selectedWidth,
          points: <Offset>[_normalize(point)],
          isEraser: _eraser,
        ),
      );
    });
  }

  void _appendPoint(Offset point) {
    if (_strokes.isEmpty) return;
    final normalized = _normalize(point);
    final points = _strokes.last.points;
    if (points.isNotEmpty) {
      const minDistance = 0.0007;
      if ((normalized - points.last).distanceSquared <
          (minDistance * minDistance)) {
        return;
      }
    }
    setState(() {
      points.add(normalized);
    });
  }

  void _finishStroke() {
    if (_strokes.isEmpty) return;
    final stroke = _strokes.last;
    if (stroke.points.length == 1) {
      stroke.points.add(stroke.points.first);
    }
  }

  Offset _normalize(Offset point) {
    final w = _canvasSize.width <= 0 ? 1.0 : _canvasSize.width;
    final h = _canvasSize.height <= 0 ? 1.0 : _canvasSize.height;
    final x = (point.dx / w).clamp(0.0, 1.0);
    final y = (point.dy / h).clamp(0.0, 1.0);
    return Offset(x, y);
  }

  Future<void> _saveSketch() async {
    if (_strokes.isEmpty) {
      setState(() {
        _errorText = '请先在白板上书写后再保存';
      });
      return;
    }
    setState(() {
      _saving = true;
      _errorText = null;
    });

    try {
      final pngBytes = await _exportPngBytes();
      if (!mounted) return;
      final confirmed = await _confirmSavePreview(pngBytes);
      if (!mounted) return;
      if (!confirmed) {
        setState(() {
          _saving = false;
        });
        return;
      }

      final sketchData = _buildSketchData();
      final dataUri = 'data:image/png;base64,${base64Encode(pngBytes)}';
      Navigator.of(context).pop(
        SketchBoardResult(
          imageDataUri: dataUri,
          sketchData: sketchData,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _errorText = '保存失败，请重试';
      });
    }
  }

  Future<Uint8List> _exportPngBytes() async {
    const exportSize = Size(2048, 1320);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromLTWH(0, 0, exportSize.width, exportSize.height),
    );
    final painter = _SketchPainter(
      strokes: _strokes,
      showGrid: false,
      backgroundColor: Colors.white,
      gridColor: const Color(0x00000000),
    );
    painter.paint(canvas, exportSize);
    final image = await recorder
        .endRecording()
        .toImage(exportSize.width.toInt(), exportSize.height.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      throw StateError('failed-to-export');
    }
    return byteData.buffer.asUint8List();
  }

  Map<String, dynamic> _buildSketchData() {
    return <String, dynamic>{
      'version': 2,
      'strokes': _strokes.map(_strokeToJson).toList(growable: false),
    };
  }

  Map<String, dynamic> _strokeToJson(_SketchStroke stroke) {
    final argbHex = stroke.color.toARGB32().toRadixString(16).padLeft(8, '0');
    return <String, dynamic>{
      'color': '#$argbHex',
      'width': double.parse(stroke.width.toStringAsFixed(2)),
      'eraser': stroke.isEraser,
      'points': stroke.points
          .map((point) => <double>[
                double.parse(point.dx.toStringAsFixed(4)),
                double.parse(point.dy.toStringAsFixed(4)),
              ])
          .toList(growable: false),
    };
  }

  Future<bool> _confirmSavePreview(Uint8List bytes) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: const Color(0xCC091423),
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFFF7FBFF),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFD2E2F4)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(14, 11, 14, 10),
                    decoration: const BoxDecoration(
                      color: Color(0xFFEFF6FF),
                      border: Border(
                        bottom: BorderSide(color: Color(0xFFD6E4F5)),
                      ),
                    ),
                    child: const Text(
                      '保存前预览',
                      style: TextStyle(
                        color: Color(0xFF233C5B),
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Flexible(
                    child: Container(
                      constraints: BoxConstraints(
                        maxHeight:
                            MediaQuery.of(dialogContext).size.height * 0.72,
                      ),
                      color: Colors.white,
                      child: InteractiveViewer(
                        minScale: 0.8,
                        maxScale: 4.5,
                        child: Image.memory(
                          bytes,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF9FCFF),
                      border: Border(
                        top: BorderSide(color: Color(0xFFD8E6F6)),
                      ),
                    ),
                    child: Wrap(
                      alignment: WrapAlignment.end,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        AppCancelButton(
                          label: '继续修改',
                          onPressed: () =>
                              Navigator.of(dialogContext).pop(false),
                        ),
                        AppSaveButton(
                          icon: Icons.check_rounded,
                          label: '确认保存',
                          onPressed: () =>
                              Navigator.of(dialogContext).pop(true),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    return result == true;
  }

  Future<bool> _confirmAction({
    required String title,
    required String content,
    required String confirmLabel,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(confirmLabel),
            ),
          ],
        );
      },
    );
    return result == true;
  }
}

class _SketchStroke {
  _SketchStroke({
    required this.color,
    required this.width,
    required this.points,
    required this.isEraser,
  });

  final Color color;
  final double width;
  final List<Offset> points;
  final bool isEraser;
}

class _SketchPainter extends CustomPainter {
  _SketchPainter({
    required this.strokes,
    required this.showGrid,
    required this.backgroundColor,
    required this.gridColor,
  });

  final List<_SketchStroke> strokes;
  final bool showGrid;
  final Color backgroundColor;
  final Color gridColor;

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint = Paint()..color = backgroundColor;
    canvas.drawRect(Offset.zero & size, backgroundPaint);

    if (showGrid) {
      final gridPaint = Paint()
        ..color = gridColor
        ..strokeWidth = 0.9
        ..style = PaintingStyle.stroke;
      const grid = 24.0;
      for (double x = grid; x < size.width; x += grid) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
      }
      for (double y = grid; y < size.height; y += grid) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
      }
    }

    final layerRect = Offset.zero & size;
    canvas.saveLayer(layerRect, Paint());

    for (final stroke in strokes) {
      if (stroke.points.isEmpty) continue;
      final paint = Paint()
        ..color = stroke.isEraser ? const Color(0x00000000) : stroke.color
        ..strokeWidth = stroke.width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke
        ..isAntiAlias = true;
      if (stroke.isEraser) {
        paint.blendMode = BlendMode.clear;
      } else {
        paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.25);
      }
      if (stroke.points.length == 1) {
        final point = _denormalize(stroke.points.first, size);
        canvas.drawCircle(point, stroke.width * 0.5, paint);
        continue;
      }
      final path = Path();
      final first = _denormalize(stroke.points.first, size);
      path.moveTo(first.dx, first.dy);
      for (var i = 1; i < stroke.points.length - 1; i++) {
        final p1 = _denormalize(stroke.points[i], size);
        final p2 = _denormalize(stroke.points[i + 1], size);
        final mid = Offset((p1.dx + p2.dx) / 2, (p1.dy + p2.dy) / 2);
        path.quadraticBezierTo(p1.dx, p1.dy, mid.dx, mid.dy);
      }
      final last = _denormalize(stroke.points.last, size);
      path.lineTo(last.dx, last.dy);
      canvas.drawPath(path, paint);
    }
    canvas.restore();
  }

  Offset _denormalize(Offset point, Size size) {
    return Offset(point.dx * size.width, point.dy * size.height);
  }

  @override
  bool shouldRepaint(covariant _SketchPainter oldDelegate) {
    return oldDelegate.strokes != strokes ||
        oldDelegate.showGrid != showGrid ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.gridColor != gridColor;
  }
}

class _WidthSelector extends StatelessWidget {
  const _WidthSelector({
    required this.value,
    required this.onChanged,
  });

  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF6FAFF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFD8E6F7)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.line_weight_rounded,
              size: 14,
              color: Color(0xFF58769A),
            ),
            const SizedBox(width: 4),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 2.6,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
              ),
              child: SizedBox(
                width: 110,
                child: Slider(
                  value: value,
                  min: 1.8,
                  max: 10,
                  divisions: 41,
                  onChanged: onChanged,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ColorChip extends StatelessWidget {
  const _ColorChip({
    required this.color,
    required this.selected,
    required this.onTap,
    required this.onLongPress,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? const Color(0xFF1A3450) : Colors.white,
              width: selected ? 2.4 : 1.4,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x220D2B4B),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PenPreset {
  const _PenPreset({
    required this.color,
    required this.width,
  });

  final Color color;
  final double width;

  _PenPreset copyWith({
    Color? color,
    double? width,
  }) {
    return _PenPreset(
      color: color ?? this.color,
      width: width ?? this.width,
    );
  }
}

class _LabeledSlider extends StatelessWidget {
  const _LabeledSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 54,
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF4F6783),
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Slider(
            value: value,
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
