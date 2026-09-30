import 'package:flutter_test/flutter_test.dart';
import 'package:chronomed/core/utils/rut_validator.dart';

void main() {
  group('ChronoMed Chilean RUT Validator & Formatter Suite', () {
    test('Validates correctly formed Chilean RUTs across multiple formats', () {
      // Standard Chilean IDs
      expect(RutValidator.isValid('11.111.111-1'), isTrue);
      expect(RutValidator.isValid('11111111-1'), isTrue);
      expect(RutValidator.isValid('111111111'), isTrue);

      expect(RutValidator.isValid('12.345.678-5'), isTrue);
      expect(RutValidator.isValid('12345678-5'), isTrue);
      expect(RutValidator.isValid('123456785'), isTrue);

      // RUT ending in 0 (remainder == 11)
      expect(RutValidator.isValid('14.567.890-0'), isTrue);
      expect(RutValidator.isValid('14567890-0'), isTrue);

      // RUT ending in K (remainder == 10) - lowercase and uppercase
      expect(RutValidator.isValid('5.456.789-K'), isTrue);
      expect(RutValidator.isValid('5456789-k'), isTrue);
      expect(RutValidator.isValid('5456789K'), isTrue);
      expect(RutValidator.isValid('5456789k'), isTrue);
    });

    test('Rejects invalid RUTs with incorrect verification digits or malformed input', () {
      // Wrong check digit
      expect(RutValidator.isValid('11.111.111-2'), isFalse);
      expect(RutValidator.isValid('12.345.678-9'), isFalse);
      expect(RutValidator.isValid('14.567.890-K'), isFalse);

      // Malformed / non-numeric
      expect(RutValidator.isValid(''), isFalse);
      expect(RutValidator.isValid('1'), isFalse);
      expect(RutValidator.isValid('K'), isFalse);
      expect(RutValidator.isValid('ABCDEFGH-K'), isFalse);
      expect(RutValidator.isValid('12.34A.678-5'), isFalse);

      // Out of bounds (< 1.000.000 or > 99.999.999)
      expect(RutValidator.isValid('999-9'), isFalse);
      expect(RutValidator.isValid('999999999-9'), isFalse);
    });

    test('Formats clean digits into Chilean dotted-dash notation XX.XXX.XXX-Y', () {
      expect(RutValidator.format('111111111'), equals('11.111.111-1'));
      expect(RutValidator.format('123456785'), equals('12.345.678-5'));
      expect(RutValidator.format('12.345.678-5'), equals('12.345.678-5'));
      expect(RutValidator.format('5456789k'), equals('5.456.789-K'));
      expect(RutValidator.format('145678900'), equals('14.567.890-0'));

      // Too short to format
      expect(RutValidator.format('1'), equals('1'));
    });

    test('Form field validator provides helpful feedback messages', () {
      expect(RutValidator.validate(null), equals('Ingresa el RUT'));
      expect(RutValidator.validate(''), equals('Ingresa el RUT'));
      expect(RutValidator.validate('   '), equals('Ingresa el RUT'));
      expect(RutValidator.validate('12.345.678-9'), equals('RUT inválido (ej: 14.567.890-K)'));
      expect(RutValidator.validate('12.345.678-5'), isNull);
    });
  });
}
