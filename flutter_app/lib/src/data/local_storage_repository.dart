import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_models.dart';

class LocalStorageRepository {
  static const String dataKey = 'hospital_record_prototype_data_v1';
  static const String securityKey = 'hospital_record_prototype_security_v1';

  Future<StorageSnapshot?> load() async {
    final prefs = await SharedPreferences.getInstance();

    AppData? loadedData;
    SecuritySettings loadedSecurity = const SecuritySettings(
      passwordEnabled: false,
      passwordValue: '',
      biometricEnabled: false,
    );

    final dataRaw = prefs.getString(dataKey);
    if (dataRaw != null && dataRaw.isNotEmpty) {
      try {
        final parsed = jsonDecode(dataRaw);
        if (parsed is Map) {
          final parsedMap = parsed.map(
            (key, value) => MapEntry(key.toString(), value),
          );
          final candidate = (parsedMap['data'] is Map)
              ? (parsedMap['data'] as Map)
                  .map((key, value) => MapEntry(key.toString(), value))
              : parsedMap;
          loadedData = AppData.fromJson(candidate);
        }
      } catch (_) {
        loadedData = null;
      }
    }

    final securityRaw = prefs.getString(securityKey);
    if (securityRaw != null && securityRaw.isNotEmpty) {
      try {
        final parsed = jsonDecode(securityRaw);
        if (parsed is Map) {
          loadedSecurity = SecuritySettings.fromJson(
            parsed.map((key, value) => MapEntry(key.toString(), value)),
          );
        }
      } catch (_) {
        loadedSecurity = loadedSecurity;
      }
    }

    if (loadedData == null) return null;
    return StorageSnapshot(data: loadedData, security: loadedSecurity);
  }

  Future<void> saveData(AppData data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(dataKey, jsonEncode(data.toJson()));
  }

  Future<void> saveSecurity(SecuritySettings security) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(securityKey, jsonEncode(security.toJson()));
  }
}
