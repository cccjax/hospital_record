import 'package:flutter_test/flutter_test.dart';
import 'package:hospital_record_flutter/src/utils/password_codec.dart';

void main() {
  test('creates salted hashes and verifies passwords', () {
    final firstHash = PasswordCodec.createHash('safe-password');
    final secondHash = PasswordCodec.createHash('safe-password');

    expect(firstHash, isNot('safe-password'));
    expect(firstHash, isNot(secondHash));
    expect(PasswordCodec.isHashed(firstHash), isTrue);
    expect(PasswordCodec.verify('safe-password', firstHash), isTrue);
    expect(PasswordCodec.verify('wrong-password', firstHash), isFalse);
  });

  test('recognizes legacy plaintext values for migration', () {
    expect(PasswordCodec.verify('123456', '123456'), isTrue);
    expect(PasswordCodec.shouldUpgrade('123456'), isTrue);
    expect(PasswordCodec.shouldUpgrade(''), isFalse);
  });
}
