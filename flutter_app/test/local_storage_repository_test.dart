import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hospital_record_flutter/src/data/local_storage_repository.dart';
import 'package:hospital_record_flutter/src/models/app_models.dart';
import 'package:hospital_record_flutter/src/models/default_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  Directory createTempDirectory() {
    final directory = Directory.systemTemp.createTempSync(
      'hospital_record_storage_test_',
    );
    addTearDown(() {
      if (directory.existsSync()) {
        directory.deleteSync(recursive: true);
      }
    });
    return directory;
  }

  AppData createData() {
    var index = 0;
    return buildDefaultAppData((prefix) {
      index += 1;
      return '${prefix}_$index';
    });
  }

  test('saves and loads app data from json files', () async {
    final directory = createTempDirectory();
    final repository = LocalStorageRepository(storageDirectory: directory);
    final data = createData();
    const security = SecuritySettings(
      passwordEnabled: true,
      passwordValue: 'hashed-value',
      biometricEnabled: true,
    );

    await repository.saveData(data);
    await repository.saveSecurity(security);

    final snapshot = await repository.load();

    expect(snapshot, isNotNull);
    expect(snapshot!.data.patients, hasLength(data.patients.length));
    expect(snapshot.data.templates, hasLength(data.templates.length));
    expect(snapshot.security.passwordValue, security.passwordValue);
    expect(snapshot.security.biometricEnabled, isTrue);
    expect(
      File(
        '${directory.path}${Platform.pathSeparator}'
        '${LocalStorageRepository.dataFileName}',
      ).existsSync(),
      isTrue,
    );
  });

  test('migrates legacy SharedPreferences data into json files', () async {
    final directory = createTempDirectory();
    final data = createData();
    const security = SecuritySettings(
      passwordEnabled: true,
      passwordValue: 'legacy-password',
      biometricEnabled: false,
    );
    SharedPreferences.setMockInitialValues(<String, Object>{
      LocalStorageRepository.dataKey: jsonEncode(data.toJson()),
      LocalStorageRepository.securityKey: jsonEncode(security.toJson()),
    });

    final repository = LocalStorageRepository(storageDirectory: directory);
    final snapshot = await repository.load();

    expect(snapshot, isNotNull);
    expect(snapshot!.data.patients, hasLength(data.patients.length));
    expect(snapshot.security.passwordValue, security.passwordValue);
    expect(
      File(
        '${directory.path}${Platform.pathSeparator}'
        '${LocalStorageRepository.dataFileName}',
      ).existsSync(),
      isTrue,
    );
    expect(
      File(
        '${directory.path}${Platform.pathSeparator}'
        '${LocalStorageRepository.securityFileName}',
      ).existsSync(),
      isTrue,
    );
  });
}
