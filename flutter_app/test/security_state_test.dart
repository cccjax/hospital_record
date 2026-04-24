import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hospital_record_flutter/src/data/local_storage_repository.dart';
import 'package:hospital_record_flutter/src/state/hospital_app_state.dart';
import 'package:hospital_record_flutter/src/utils/password_codec.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  Directory createTempDirectory() {
    final directory = Directory.systemTemp.createTempSync(
      'hospital_record_security_state_test_',
    );
    addTearDown(() {
      if (directory.existsSync()) {
        directory.deleteSync(recursive: true);
      }
    });
    return directory;
  }

  test('first initialization persists default data and security files',
      () async {
    final directory = createTempDirectory();
    final state = HospitalAppState(
      repository: LocalStorageRepository(storageDirectory: directory),
    );

    await state.initialize();

    expect(state.initialized, isTrue);
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

  test('enabled passwords are stored as hashes and can be verified', () async {
    final directory = createTempDirectory();

    final state = HospitalAppState(
      repository: LocalStorageRepository(storageDirectory: directory),
    );

    await state.enableOrChangePassword('123456');

    expect(state.security.passwordValue, isNot('123456'));
    expect(PasswordCodec.isHashed(state.security.passwordValue), isTrue);
    expect(state.verifyPassword('wrong'), isFalse);
    expect(state.verifyPassword('123456'), isTrue);
  });
}
