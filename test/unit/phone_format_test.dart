import 'package:flutter_test/flutter_test.dart';

/// Mirrors _formatPhoneNumber from login_screen.dart:91-104
/// for white-box branch coverage testing.
String? formatPhoneNumber(String input) {
  String digits = input.replaceAll(RegExp(r'\D'), '');
  if (digits.startsWith('880')) {
    digits = '0${digits.substring(3)}';
  } else if (digits.startsWith('0')) {
    // already starts with 0
  } else {
    digits = '0$digits';
  }
  if (digits.length == 11 && digits.startsWith('01')) {
    return digits;
  }
  return null;
}

void main() {
  group('formatPhoneNumber - White Box Branch Coverage', () {
    group('Branch 1: starts with 880 prefix', () {
      test('removes 880 and prepends 0', () {
        expect(formatPhoneNumber('8801712345678'), '01712345678');
      });

      test('handles 880 with dashes', () {
        expect(formatPhoneNumber('880-1712-345678'), '01712345678');
      });

      test('handles 880 with spaces', () {
        expect(formatPhoneNumber('880 1712 345678'), '01712345678');
      });
    });

    group('Branch 2: starts with 0 (already formatted)', () {
      test('keeps 0 prefix intact', () {
        expect(formatPhoneNumber('01712345678'), '01712345678');
      });

      test('handles 0 prefix with dashes', () {
        expect(formatPhoneNumber('017-1234-5678'), '01712345678');
      });
    });

    group('Branch 3: other number (no 0 or 880 prefix)', () {
      test('prepends 0 to bare number', () {
        expect(formatPhoneNumber('1712345678'), '01712345678');
      });

      test('prepends 0 and strips non-digits', () {
        expect(formatPhoneNumber('1712-345-678'), '01712345678');
      });
    });

    group('Branch 4: validation (length and prefix check)', () {
      test('returns null for too-short number', () {
        expect(formatPhoneNumber('0171234567'), null);
      });

      test('returns null for too-long number', () {
        expect(formatPhoneNumber('017123456789'), null);
      });

      test('returns null when not starting with 01', () {
        expect(formatPhoneNumber('02123456789'), null);
      });

      test('returns null for empty input', () {
        expect(formatPhoneNumber(''), null);
      });

      test('returns null for alphabetic input', () {
        expect(formatPhoneNumber('abcdefghijk'), null);
      });
    });

    group('Edge cases', () {
      test('minimum valid: 01000000000', () {
        expect(formatPhoneNumber('01000000000'), '01000000000');
      });

      test('maximum valid: 01999999999', () {
        expect(formatPhoneNumber('01999999999'), '01999999999');
      });

      test('all zeros after 01: 01000000000', () {
        expect(formatPhoneNumber('01000000000'), '01000000000');
      });
    });
  });
}
