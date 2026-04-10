import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_models.dart';
import '../state/hospital_app_state.dart';
import '../widgets/app_back_button.dart';
import '../widgets/section_card.dart';

class MineMigrationPage extends StatefulWidget {
  const MineMigrationPage({super.key});

  @override
  State<MineMigrationPage> createState() => _MineMigrationPageState();
}

class _MineMigrationPageState extends State<MineMigrationPage> {
  bool _exporting = false;
  bool _importing = false;
  String? _lastExportPath;
  String? _lastImportName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leadingWidth: 56,
        leading: const Padding(
          padding: EdgeInsets.only(left: 12),
          child: AppBackButton(),
        ),
        title: const Text(
          '数据迁移',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
        children: [
          SectionCard(
            title: '导出备份文件',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '将当前离线数据导出为 JSON 文件，便于跨设备迁移与备份。',
                  style: TextStyle(color: Color(0xFF6E819A)),
                ),
                const SizedBox(height: 10),
                FilledButton.tonal(
                  onPressed: _exporting ? null : _exportToFile,
                  child: Text(_exporting ? '导出中...' : '选择位置并导出'),
                ),
                if (_lastExportPath != null) ...[
                  const SizedBox(height: 10),
                  _HintLine(label: '最近导出', value: _lastExportPath!),
                ],
              ],
            ),
          ),
          SectionCard(
            title: '导入备份文件',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '从 JSON 备份文件恢复数据，导入后会覆盖当前本地数据。',
                  style: TextStyle(color: Color(0xFF6E819A)),
                ),
                const SizedBox(height: 10),
                FilledButton(
                  onPressed: _importing ? null : _importFromFile,
                  child: Text(_importing ? '导入中...' : '选择文件并导入'),
                ),
                if (_lastImportName != null) ...[
                  const SizedBox(height: 10),
                  _HintLine(label: '最近导入', value: _lastImportName!),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportToFile() async {
    if (_exporting) return;
    setState(() {
      _exporting = true;
    });

    try {
      final jsonText = context.read<HospitalAppState>().exportDataJson();
      final bytes = Uint8List.fromList(utf8.encode(jsonText));
      final path = await FilePicker.platform.saveFile(
        dialogTitle: '选择备份文件保存位置',
        fileName: _defaultBackupFileName(),
        bytes: bytes,
        type: FileType.custom,
        allowedExtensions: const ['json'],
      );

      if (!mounted) return;
      if (path == null || path.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已取消导出')),
        );
        return;
      }

      setState(() {
        _lastExportPath = path;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('导出成功')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('导出失败，请重试')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _exporting = false;
        });
      }
    }
  }

  Future<void> _importFromFile() async {
    if (_importing) return;
    setState(() {
      _importing = true;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        dialogTitle: '选择备份文件',
        type: FileType.custom,
        allowedExtensions: const ['json'],
        allowMultiple: false,
        withData: true,
      );

      if (!mounted) return;
      if (result == null || result.files.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已取消导入')),
        );
        return;
      }

      final file = result.files.single;
      final bytes = file.bytes;
      if (bytes == null) {
        await _showValidationErrorDialog('读取文件失败，请重新选择文件后重试。');
        return;
      }

      late final String jsonText;
      try {
        jsonText = utf8.decode(bytes, allowMalformed: false);
      } on FormatException {
        await _showValidationErrorDialog('文件编码不是 UTF-8，无法读取为有效备份文件。');
        return;
      }

      final validation = _validateImportJson(jsonText);
      if (!validation.valid) {
        await _showValidationErrorDialog(validation.message);
        return;
      }

      final preview = validation.preview!;
      final confirmed = await _showImportConfirmDialog(
        fileName: file.name,
        fileSize: file.size,
        preview: preview,
      );
      if (!mounted) return;
      if (!confirmed) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已取消导入')),
        );
        return;
      }

      final state = context.read<HospitalAppState>();
      final ok = await state.importDataFromJson(jsonText);
      if (!mounted) return;
      if (ok) {
        setState(() {
          _lastImportName = file.name;
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ok ? '导入成功' : '导入失败，请检查备份文件格式')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('导入失败，请重试')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _importing = false;
        });
      }
    }
  }

  _ImportValidationResult _validateImportJson(String text) {
    final source = text.trim();
    if (source.isEmpty) {
      return const _ImportValidationResult.invalid('备份文件内容为空，无法导入。');
    }

    dynamic raw;
    try {
      raw = jsonDecode(source);
    } catch (_) {
      return const _ImportValidationResult.invalid('文件内容不是合法 JSON。');
    }

    if (raw is! Map) {
      return const _ImportValidationResult.invalid('JSON 顶层结构必须是对象。');
    }

    final root = _toStringMap(raw);
    final payload = root['data'] is Map ? _toStringMap(root['data']) : root;
    if (payload.isEmpty) {
      return const _ImportValidationResult.invalid('未找到可导入的数据对象。');
    }

    const knownKeys = <String>{
      'schemas',
      'patients',
      'admissions',
      'dailyRecords',
      'templates',
      'diagnosisTemplates',
      'admissionAssessments',
      'admissionImaging',
    };
    if (!payload.keys.any(knownKeys.contains)) {
      return const _ImportValidationResult.invalid('文件不是系统导出的备份文件。');
    }

    final typeError = _validatePayloadTypes(payload);
    if (typeError != null) {
      return _ImportValidationResult.invalid(typeError);
    }

    final AppData data;
    try {
      data = AppData.fromJson(payload);
    } catch (_) {
      return const _ImportValidationResult.invalid('文件结构异常，无法解析为系统数据。');
    }

    final assessmentCount = data.admissionAssessments.values.fold<int>(
      0,
      (sum, list) => sum + list.length,
    );
    final imagingCount = data.admissionImaging.values.fold<int>(
      0,
      (sum, list) => sum + list.length,
    );
    final total = data.schemas.length +
        data.patients.length +
        data.admissions.length +
        data.dailyRecords.length +
        data.templates.length +
        data.diagnosisTemplates.length +
        assessmentCount +
        imagingCount;
    if (total == 0) {
      return const _ImportValidationResult.invalid('备份文件中没有可导入数据。');
    }

    return _ImportValidationResult.valid(
      _ImportPreview(
        schemaCount: data.schemas.length,
        patientCount: data.patients.length,
        admissionCount: data.admissions.length,
        dailyCount: data.dailyRecords.length,
        templateCount: data.templates.length,
        diagnosisTemplateCount: data.diagnosisTemplates.length,
        assessmentCount: assessmentCount,
        imagingCount: imagingCount,
      ),
    );
  }

  String? _validatePayloadTypes(Map<String, dynamic> payload) {
    const listKeys = <String>{
      'patients',
      'admissions',
      'dailyRecords',
      'templates',
      'diagnosisTemplates',
    };
    for (final key in listKeys) {
      final value = payload[key];
      if (value != null && value is! List) {
        return '字段 "$key" 格式错误，应为数组。';
      }
    }

    const mapKeys = <String>{
      'schemas',
      'admissionAssessments',
      'admissionImaging',
    };
    for (final key in mapKeys) {
      final value = payload[key];
      if (value != null && value is! Map) {
        return '字段 "$key" 格式错误，应为对象。';
      }
    }
    return null;
  }

  Future<void> _showValidationErrorDialog(String message) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('文件校验失败'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('我知道了'),
            ),
          ],
        );
      },
    );
  }

  Future<bool> _showImportConfirmDialog({
    required String fileName,
    required int fileSize,
    required _ImportPreview preview,
  }) async {
    if (!mounted) return false;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('确认导入备份'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('文件名：$fileName'),
              const SizedBox(height: 4),
              Text('文件大小：${_formatFileSize(fileSize)}'),
              const SizedBox(height: 10),
              const Text(
                '导入后将覆盖当前本地数据，请确认是否继续。',
                style: TextStyle(
                  color: Color(0xFFB23B3B),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              _SummaryLine(label: '字段配置', value: '${preview.schemaCount}'),
              _SummaryLine(label: '病人', value: '${preview.patientCount}'),
              _SummaryLine(label: '入院记录', value: '${preview.admissionCount}'),
              _SummaryLine(label: '日常记录', value: '${preview.dailyCount}'),
              _SummaryLine(label: '病情评估模板', value: '${preview.templateCount}'),
              _SummaryLine(
                  label: '诊断模板', value: '${preview.diagnosisTemplateCount}'),
              _SummaryLine(label: '测评结果', value: '${preview.assessmentCount}'),
              _SummaryLine(label: '影像资料', value: '${preview.imagingCount}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('确认导入'),
            ),
          ],
        );
      },
    );
    return confirmed == true;
  }

  String _defaultBackupFileName() {
    final now = DateTime.now();
    String pad(int value) => value.toString().padLeft(2, '0');
    return 'hospital_record_backup_${now.year}${pad(now.month)}${pad(now.day)}_${pad(now.hour)}${pad(now.minute)}${pad(now.second)}.json';
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    final kb = bytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
    final mb = kb / 1024;
    return '${mb.toStringAsFixed(2)} MB';
  }

  Map<String, dynamic> _toStringMap(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      return Map<String, dynamic>.from(raw);
    }
    if (raw is Map) {
      return raw.map((key, value) => MapEntry(key.toString(), value));
    }
    return <String, dynamic>{};
  }
}

class _HintLine extends StatelessWidget {
  const _HintLine({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFDCE7F5)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF5F738E),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 3),
            SelectableText(
              value,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF2A405C),
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryLine extends StatelessWidget {
  const _SummaryLine({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF4F6076),
                fontSize: 12,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF2A3F58),
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _ImportValidationResult {
  const _ImportValidationResult._({
    required this.valid,
    required this.message,
    this.preview,
  });

  const _ImportValidationResult.valid(_ImportPreview value)
      : this._(
          valid: true,
          message: '',
          preview: value,
        );

  const _ImportValidationResult.invalid(String message)
      : this._(
          valid: false,
          message: message,
        );

  final bool valid;
  final String message;
  final _ImportPreview? preview;
}

class _ImportPreview {
  const _ImportPreview({
    required this.schemaCount,
    required this.patientCount,
    required this.admissionCount,
    required this.dailyCount,
    required this.templateCount,
    required this.diagnosisTemplateCount,
    required this.assessmentCount,
    required this.imagingCount,
  });

  final int schemaCount;
  final int patientCount;
  final int admissionCount;
  final int dailyCount;
  final int templateCount;
  final int diagnosisTemplateCount;
  final int assessmentCount;
  final int imagingCount;
}
