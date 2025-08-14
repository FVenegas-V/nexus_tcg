import 'package:flutter_test/flutter_test.dart';
import '../lib/features/profile/services/user_service.dart';

void main() {
  group('UserService Validation Tests', () {
    test('Email validation works correctly', () {
      // Valid emails
      expect(UserService.isValidEmail('test@example.com'), true);
      expect(UserService.isValidEmail('user.name@domain.co.uk'), true);
      expect(UserService.isValidEmail('test+tag@example.com'), true);

      // Invalid emails
      expect(UserService.isValidEmail(''), false);
      expect(UserService.isValidEmail('test'), false);
      expect(UserService.isValidEmail('test@'), false);
      expect(UserService.isValidEmail('@example.com'), false);
      expect(UserService.isValidEmail('test.example.com'), false);
    });

    test('Password validation works correctly', () {
      // Valid passwords (≥8 characters)
      expect(UserService.isValidPassword('12345678'), true);
      expect(UserService.isValidPassword('password123'), true);
      expect(UserService.isValidPassword('MyStrongP@ss!'), true);

      // Invalid passwords (<8 characters)
      expect(UserService.isValidPassword(''), false);
      expect(UserService.isValidPassword('123'), false);
      expect(UserService.isValidPassword('1234567'), false);
    });

    test('Name validation works correctly', () {
      // Valid names
      expect(UserService.isValidName(''), true); // Empty allowed
      expect(UserService.isValidName('Juan'), true);
      expect(UserService.isValidName('María José'), true);
      expect(UserService.isValidName('José-Luis'), true);
      expect(UserService.isValidName('Ñoño'), true);

      // Invalid names
      expect(UserService.isValidName('123'), false);
      expect(UserService.isValidName('User123'), false);
      expect(UserService.isValidName('Juan@test'), false);
    });
  });
}
