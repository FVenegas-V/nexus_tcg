// Test manual para UserService - Para ejecutar en un archivo temporal
// Este código verifica la configuración del UserService

import 'package:flutter_test/flutter_test.dart';
import 'lib/features/profile/services/user_service.dart';

void main() {
  group('UserService Tests', () {
    test('Validación de email funciona correctamente', () {
      // Emails válidos
      expect(UserService.isValidEmail('test@example.com'), true);
      expect(UserService.isValidEmail('user.name@domain.co.uk'), true);
      expect(UserService.isValidEmail('test+tag@example.com'), true);

      // Emails inválidos
      expect(UserService.isValidEmail(''), false);
      expect(UserService.isValidEmail('test'), false);
      expect(UserService.isValidEmail('test@'), false);
      expect(UserService.isValidEmail('@example.com'), false);
      expect(UserService.isValidEmail('test.example.com'), false);
    });

    test('Validación de contraseña funciona correctamente', () {
      // Contraseñas válidas (≥8 caracteres)
      expect(UserService.isValidPassword('12345678'), true);
      expect(UserService.isValidPassword('password123'), true);
      expect(UserService.isValidPassword('MyStrongP@ss!'), true);

      // Contraseñas inválidas (<8 caracteres)
      expect(UserService.isValidPassword(''), false);
      expect(UserService.isValidPassword('123'), false);
      expect(UserService.isValidPassword('1234567'), false);
    });

    test('Validación de nombres funciona correctamente', () {
      // Nombres válidos
      expect(UserService.isValidName(''), true); // Vacío permitido
      expect(UserService.isValidName('Juan'), true);
      expect(UserService.isValidName('María José'), true);
      expect(UserService.isValidName('José-Luis'), true);
      expect(UserService.isValidName('Ñoño'), true);

      // Nombres inválidos
      expect(UserService.isValidName('123'), false);
      expect(UserService.isValidName('User123'), false);
      expect(UserService.isValidName('Juan@test'), false);
    });
  });
}
