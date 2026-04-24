import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_models.dart';

class LocalStorageRepository {
  LocalStorageRepository({Directory? storageDirectory})
      : _storageDirectory = storageDirectory;

  static const String dataKey = 'hospital_record_prototype_data_v1';
  static const String securityKey = 'hospital_record_prototype_security_v1';
  static const String dataFileName = 'hospital_record_data_v1.json';
  static const String securityFileName = 'hospital_record_security_v1.json';

  final Directory? _storageDirectory;

  Future<StorageSnapshot?> load() async {
    final prefs = await SharedPreferences.getInstance();

    final fileData = await _loadDataFromFile();
    final legacyData = fileData ?? _parseData(prefs.getString(dataKey));
    final loadedData = legacyData;

    final fileSecurity = await _loadSecurityFromFile();
    final legacySecurity = _parseSecurity(prefs.getString(securityKey));
    final loadedSecurity =
        fileSecurity ?? legacySecurity ?? SecuritySettings.empty;

    if (loadedData == null) return null;

    if (fileData == null) {
      await saveData(loadedData);
    }
    if (fileSecurity == null && legacySecurity != null) {
      await saveSecurity(loadedSecurity);
    }

    return StorageSnapshot(data: loadedData, security: loadedSecurity);
  }

  Future<void> saveData(AppData data) async {
    await _writeJsonFile(await _dataFile(), data.toJson());
  }

  Future<void> saveSecurity(SecuritySettings security) async {
    await _writeJsonFile(await _securityFile(), security.toJson());
  }

  Future<AppData?> _loadDataFromFile() async {
    final raw = await _readFileText(await _dataFile());
    return _parseData(raw);
  }

  Future<SecuritySettings?> _loadSecurityFromFile() async {
    final raw = await _readFileText(await _securityFile());
    return _parseSecurity(raw);
  }

  AppData? _parseData(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final parsed = jsonDecode(raw);
      if (parsed is Map) {
        final parsedMap = parsed.map(
          (key, value) => MapEntry(key.toString(), value),
        );
        final candidate = (parsedMap['data'] is Map)
            ? (parsedMap['data'] as Map)
                .map((key, value) => MapEntry(key.toString(), value))
            : parsedMap;
        return AppData.fromJson(candidate);
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  SecuritySettings? _parseSecurity(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final parsed = jsonDecode(raw);
      if (parsed is Map) {
        return SecuritySettings.fromJson(
          parsed.map((key, value) => MapEntry(key.toString(), value)),
        );
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  Future<File> _dataFile() async {
    final directory = await _resolveStorageDirectory();
    return File('${directory.path}${Platform.pathSeparator}$dataFileName');
  }

  Future<File> _securityFile() async {
    final directory = await _resolveStorageDirectory();
    return File('${directory.path}${Platform.pathSeparator}$securityFileName');
  }

  Future<Directory> _resolveStorageDirectory() async {
    final directory = _storageDirectory ??
        Directory(
          '${(await getApplicationSupportDirectory()).path}'
          '${Platform.pathSeparator}hospital_record',
        );
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory;
  }

  Future<String?> _readFileText(File file) async {
    try {
      if (!await file.exists()) return null;
      return file.readAsString();
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeJsonFile(File file, Object? value) async {
    await file.parent.create(recursive: true);
    final tempFile = File('${file.path}.tmp');
    await tempFile.writeAsString(jsonEncode(value), flush: true);
    if (await file.exists()) {
      await file.delete();
    }
    await tempFile.rename(file.path);
  }
}
