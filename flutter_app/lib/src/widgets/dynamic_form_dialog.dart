import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../models/app_models.dart';
import 'app_add_button.dart';
import 'app_dropdown_form_field.dart';
import 'dialog_utils.dart';
import 'editor_dialog.dart';
import 'sketch_board_dialog.dart';

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
  static const int _maxImagesPerField = 12;
  static const int _maxSingleImageChars = 6 * 1024 * 1024;
  static const int _maxTotalImageChars = 24 * 1024 * 1024;

  final _formKey = GlobalKey<FormState>();
  final ImagePicker _imagePicker = ImagePicker();
  bool _submitting = false;
  String? _errorText;
  late final Map<String, TextEditingController> _controllers;
  late final Map<String, String> _selectValues;
  late final Map<String, List<_ImageFieldEntry>> _imageValues;
  final Map<String, Uint8List?> _imageBytesCache = <String, Uint8List?>{};

  @override
  void initState() {
    super.initState();
    _controllers = <String, TextEditingController>{};
    _selectValues = <String, String>{};
    _imageValues = <String, List<_ImageFieldEntry>>{};

    for (final field in widget.schema) {
      final raw = widget.initialValues[field.key];
      final value = raw == null ? '' : raw.toString();
      if (field.type == FieldType.images) {
        _imageValues[field.key] = _normalizeImageValues(raw);
      } else if (field.type == FieldType.select) {
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
      icon: Icons.edit_note_rounded,
      maxWidth: 700,
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
              )
            else
              _FormSurface(
                children: [
                  for (var i = 0; i < widget.schema.length; i++)
                    _FormSurfaceRow(
                      showDivider: i != widget.schema.length - 1,
                      child: _buildFieldCard(widget.schema[i]),
                    ),
                ],
              ),
            if (_errorText != null) _buildErrorBanner(),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldCard(FieldSchema field) {
    final editable = !field.locked || _canEditLockedField(field);
    final isStackField =
        field.type == FieldType.textarea || field.type == FieldType.images;
    final labelText = field.required ? '${field.label} *' : field.label;
    return LayoutBuilder(
      builder: (context, constraints) {
        final labelWidth = constraints.maxWidth < 430 ? 88.0 : 116.0;
        return Row(
          crossAxisAlignment: isStackField
              ? CrossAxisAlignment.start
              : CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: labelWidth,
              child: Padding(
                padding: EdgeInsets.only(
                  top: isStackField ? 11 : 0,
                ),
                child: Text(
                  labelText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF203A59),
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                    letterSpacing: 0.1,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildFieldInput(
                field,
                editable: editable,
              ),
            ),
            if (!editable) ...[
              const SizedBox(width: 7),
              const Icon(
                Icons.lock_outline_rounded,
                size: 15,
                color: Color(0xFF7890AB),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildFieldInput(
    FieldSchema field, {
    required bool editable,
  }) {
    if (field.type == FieldType.images) {
      final images =
          _imageValues.putIfAbsent(field.key, () => <_ImageFieldEntry>[]);
      return _buildImageField(field, images, editable: editable);
    }

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

  Widget _buildImageField(
    FieldSchema field,
    List<_ImageFieldEntry> images, {
    required bool editable,
  }) {
    final isQuickSketch = field.key == 'quickSketches';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            AppToneTextButton(
              label: isQuickSketch ? '新增速记白板' : '新增手写白板',
              icon: Icons.draw_rounded,
              onPressed: !editable
                  ? null
                  : () => _addSketchToField(
                        fieldKey: field.key,
                      ),
              minWidth: 126,
              height: 34,
              fontSize: 12,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            AppToneTextButton(
              label: '从相册添加',
              icon: Icons.photo_library_outlined,
              onPressed: !editable
                  ? null
                  : () => _addPickedImagesToField(
                        fieldKey: field.key,
                      ),
              minWidth: 104,
              height: 34,
              fontSize: 12,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            if (images.isNotEmpty)
              AppToneTextButton(
                label: '清空',
                icon: Icons.delete_sweep_rounded,
                onPressed: !editable
                    ? null
                    : () => _clearFieldImages(
                          fieldKey: field.key,
                          label: field.label,
                        ),
                minWidth: 74,
                height: 34,
                fontSize: 12,
                padding:
                    const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
                backgroundColor: const Color(0xFFFFF3F4),
                backgroundPressedColor: const Color(0xFFFFE8EB),
                borderColor: const Color(0xFFF5C8D0),
                borderPressedColor: const Color(0xFFEAB0BB),
                foregroundColor: const Color(0xFFBA4A5A),
                foregroundDisabledColor: const Color(0xFFD4A1AA),
                shadowColor: const Color(0x22CC7280),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (images.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FCFF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFDCE7F5)),
            ),
            child: Text(
              isQuickSketch
                  ? '暂无速记白板图片（最多 $_maxImagesPerField 张）'
                  : '暂无图片（最多 $_maxImagesPerField 张）',
              style: const TextStyle(
                color: Color(0xFF7088A3),
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var index = 0; index < images.length; index++)
                _buildImageThumb(
                  src: images[index].src,
                  onDelete: !editable
                      ? null
                      : () => _deleteFieldImage(
                            fieldKey: field.key,
                            index: index,
                          ),
                  onEdit: !editable || !images[index].canEditSketch
                      ? null
                      : () => _editSketchAt(
                            fieldKey: field.key,
                            index: index,
                          ),
                ),
            ],
          ),
      ],
    );
  }

  Widget _buildImageThumb({
    required String src,
    required VoidCallback? onDelete,
    required VoidCallback? onEdit,
  }) {
    final bytes = _decodeImageSourceCached(src);
    return SizedBox(
      width: 86,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Stack(
              children: [
                Material(
                  color: const Color(0xFFF2F7FF),
                  child: InkWell(
                    onTap: () => _previewImage(src),
                    child: SizedBox(
                      width: 86,
                      height: 62,
                      child: bytes == null
                          ? const Center(
                              child: Icon(
                                Icons.broken_image_outlined,
                                size: 18,
                                color: Color(0xFF8CA3BF),
                              ),
                            )
                          : Image.memory(
                              bytes,
                              fit: BoxFit.cover,
                              filterQuality: FilterQuality.medium,
                            ),
                    ),
                  ),
                ),
                if (onEdit != null)
                  Positioned(
                    top: 4,
                    left: 4,
                    child: Material(
                      color: const Color(0x8A13253C),
                      borderRadius: BorderRadius.circular(999),
                      child: InkWell(
                        onTap: onEdit,
                        borderRadius: BorderRadius.circular(999),
                        child: const SizedBox(
                          width: 18,
                          height: 18,
                          child: Icon(
                            Icons.edit_rounded,
                            size: 12,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                if (onDelete != null)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Material(
                      color: const Color(0x9216253C),
                      borderRadius: BorderRadius.circular(999),
                      child: InkWell(
                        onTap: onDelete,
                        borderRadius: BorderRadius.circular(999),
                        child: const SizedBox(
                          width: 18,
                          height: 18,
                          child: Icon(
                            Icons.close_rounded,
                            size: 13,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            '点击预览',
            style: TextStyle(
              color: Color(0xFF6E85A1),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addSketchToField({
    required String fieldKey,
  }) async {
    final sketch = await showSketchBoardDialog(
      context,
      title: '新增速记白板',
    );
    if (!mounted || sketch == null) return;
    final entry = _ImageFieldEntry(
      src: sketch.imageDataUri,
      sketchData: sketch.sketchData,
    );
    final err = _validateCanApplyImages(
      fieldKey: fieldKey,
      adding: <_ImageFieldEntry>[entry],
    );
    if (err != null) {
      setState(() {
        _errorText = err;
      });
      return;
    }
    setState(() {
      final list =
          _imageValues.putIfAbsent(fieldKey, () => <_ImageFieldEntry>[]);
      list.add(entry);
      _errorText = null;
    });
  }

  Future<void> _addPickedImagesToField({
    required String fieldKey,
  }) async {
    final existing = _imageValues[fieldKey] ?? const <_ImageFieldEntry>[];
    final leftSlots = _maxImagesPerField - existing.length;
    if (leftSlots <= 0) {
      setState(() {
        _errorText = '最多可添加 $_maxImagesPerField 张图片，请先删除部分内容';
      });
      return;
    }

    final files = await _imagePicker.pickMultiImage(
      imageQuality: 78,
      maxWidth: 1920,
    );
    if (!mounted || files.isEmpty) return;
    final next = <_ImageFieldEntry>[];
    var limitReached = false;
    for (final file in files) {
      if (next.length >= leftSlots) {
        limitReached = true;
        break;
      }
      try {
        final bytes = await file.readAsBytes();
        final ext = file.path.toLowerCase().endsWith('.png') ? 'png' : 'jpeg';
        final dataUri = 'data:image/$ext;base64,${base64Encode(bytes)}';
        next.add(_ImageFieldEntry(src: dataUri));
      } catch (_) {
        // Skip unreadable files to avoid interrupting the workflow.
      }
    }
    if (!mounted || next.isEmpty) return;

    final err = _validateCanApplyImages(fieldKey: fieldKey, adding: next);
    if (err != null) {
      setState(() {
        _errorText = err;
      });
      return;
    }

    setState(() {
      final list =
          _imageValues.putIfAbsent(fieldKey, () => <_ImageFieldEntry>[]);
      list.addAll(next);
      _errorText = limitReached ? '已达到单条记录图片上限，超出部分未导入' : null;
    });
  }

  Future<void> _previewImage(String src) async {
    final bytes = _decodeImageSourceCached(src);
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

  List<_ImageFieldEntry> _normalizeImageValues(dynamic raw) {
    if (raw is! List) return <_ImageFieldEntry>[];
    final list = <_ImageFieldEntry>[];
    for (final item in raw) {
      if (item is String) {
        final text = item.trim();
        if (text.isNotEmpty) {
          list.add(_ImageFieldEntry(src: text));
        }
        continue;
      }
      if (item is Map) {
        final src = item['src'];
        if (src is! String || src.trim().isEmpty) {
          continue;
        }
        final sketchData = _extractSketchData(item);
        list.add(
          _ImageFieldEntry(
            src: src.trim(),
            sketchData: sketchData,
          ),
        );
      }
    }
    return list;
  }

  Map<String, dynamic>? _extractSketchData(Map<dynamic, dynamic> raw) {
    final value = raw['sketch'];
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map(
        (key, val) => MapEntry(key.toString(), val),
      );
    }
    if (value is String) {
      final text = value.trim();
      if (text.isEmpty) return null;
      try {
        final decoded = jsonDecode(text);
        if (decoded is Map<String, dynamic>) return decoded;
        if (decoded is Map) {
          return decoded.map(
            (key, val) => MapEntry(key.toString(), val),
          );
        }
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  Uint8List? _decodeImageSourceCached(String src) {
    return _imageBytesCache.putIfAbsent(src, () {
      final raw = src.trim();
      if (raw.isEmpty) return null;
      try {
        final payload = _payloadOnly(raw);
        return base64Decode(payload);
      } catch (_) {
        return null;
      }
    });
  }

  String _payloadOnly(String src) {
    final index = src.indexOf(',');
    if (index >= 0 && index < src.length - 1) {
      return src.substring(index + 1);
    }
    return src;
  }

  int _payloadLength(String src) {
    return _payloadOnly(src).length;
  }

  int _totalPayloadLength(List<_ImageFieldEntry> entries) {
    return entries.fold<int>(
        0, (sum, entry) => sum + _payloadLength(entry.src));
  }

  String? _validateCanApplyImages({
    required String fieldKey,
    required List<_ImageFieldEntry> adding,
    int? replaceIndex,
  }) {
    final current =
        List<_ImageFieldEntry>.from(_imageValues[fieldKey] ?? const []);
    if (replaceIndex != null &&
        replaceIndex >= 0 &&
        replaceIndex < current.length) {
      current.removeAt(replaceIndex);
    }
    if (current.length + adding.length > _maxImagesPerField) {
      return '最多可添加 $_maxImagesPerField 张图片，请先删除部分内容';
    }
    for (final entry in adding) {
      if (_payloadLength(entry.src) > _maxSingleImageChars) {
        return '单张图片过大，请更换或压缩后再试';
      }
    }
    final total = _totalPayloadLength(current) + _totalPayloadLength(adding);
    if (total > _maxTotalImageChars) {
      return '当前日常记录图片总量过大，请删除部分图片后再保存';
    }
    return null;
  }

  Future<void> _clearFieldImages({
    required String fieldKey,
    required String label,
  }) async {
    final confirmed = await showDeleteConfirmDialog(
      context,
      title: '清空$label',
      content: '确认清空该字段下的全部图片吗？',
    );
    if (!mounted || !confirmed) return;
    setState(() {
      final list =
          _imageValues.putIfAbsent(fieldKey, () => <_ImageFieldEntry>[]);
      for (final entry in list) {
        _imageBytesCache.remove(entry.src);
      }
      list.clear();
      _errorText = null;
    });
  }

  Future<void> _deleteFieldImage({
    required String fieldKey,
    required int index,
  }) async {
    final confirmed = await showDeleteConfirmDialog(
      context,
      title: '删除图片',
      content: '确认删除这张白板/图片吗？',
    );
    if (!mounted || !confirmed) return;
    setState(() {
      final list =
          _imageValues.putIfAbsent(fieldKey, () => <_ImageFieldEntry>[]);
      if (index < 0 || index >= list.length) return;
      final removed = list.removeAt(index);
      _imageBytesCache.remove(removed.src);
      _errorText = null;
    });
  }

  Future<void> _editSketchAt({
    required String fieldKey,
    required int index,
  }) async {
    final list = _imageValues[fieldKey];
    if (list == null || index < 0 || index >= list.length) return;
    final entry = list[index];
    if (!entry.canEditSketch) return;

    final result = await showSketchBoardDialog(
      context,
      title: '编辑速记白板',
      initialSketchData: entry.sketchData,
    );
    if (!mounted || result == null) return;
    final updated = _ImageFieldEntry(
      src: result.imageDataUri,
      sketchData: result.sketchData,
    );
    final err = _validateCanApplyImages(
      fieldKey: fieldKey,
      adding: <_ImageFieldEntry>[updated],
      replaceIndex: index,
    );
    if (err != null) {
      setState(() {
        _errorText = err;
      });
      return;
    }
    setState(() {
      final fieldList =
          _imageValues.putIfAbsent(fieldKey, () => <_ImageFieldEntry>[]);
      if (index < 0 || index >= fieldList.length) return;
      final old = fieldList[index];
      fieldList[index] = updated;
      _imageBytesCache.remove(old.src);
      _errorText = null;
    });
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
        field.key == 'diseaseCode' ||
        field.key == 'quickSketches') {
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
      if (field.type == FieldType.images) {
        final images = List<_ImageFieldEntry>.from(
          _imageValues[field.key] ?? const <_ImageFieldEntry>[],
        );
        if (field.required && images.isEmpty) {
          setState(() {
            _errorText = '请添加${field.label}';
          });
          return;
        }
        final totalChars = _totalPayloadLength(images);
        if (totalChars > _maxTotalImageChars) {
          setState(() {
            _errorText = '${field.label}图片数据过大，请删除部分图片后再保存';
          });
          return;
        }
        payload[field.key] =
            images.map((entry) => entry.toStorageValue()).toList();
      } else if (field.type == FieldType.select) {
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

class _FormSurface extends StatelessWidget {
  const _FormSurface({
    required this.children,
  });

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD8E5F4)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C173B5D),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }
}

class _FormSurfaceRow extends StatelessWidget {
  const _FormSurfaceRow({
    required this.child,
    required this.showDivider,
  });

  final Widget child;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 11, 14, 11),
          child: child,
        ),
        if (showDivider)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 14),
            child: Divider(
              height: 1,
              thickness: 1,
              color: Color(0xFFE7EFF8),
            ),
          ),
      ],
    );
  }
}

class _ImageFieldEntry {
  const _ImageFieldEntry({
    required this.src,
    this.sketchData,
  });

  final String src;
  final Map<String, dynamic>? sketchData;

  bool get canEditSketch => sketchData != null;

  dynamic toStorageValue() {
    if (sketchData == null) {
      return src;
    }
    return <String, dynamic>{
      'src': src,
      'type': 'sketch',
      'sketch': sketchData,
    };
  }
}
