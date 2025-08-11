/// Servicio de validación para formularios de autenticación
/// Contiene funciones puras para validar diferentes tipos de entrada
class ValidationService {
  /// Valida el formato de un email
  /// Retorna null si es válido, mensaje de error si no
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'El email es requerido';
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Ingresa un email válido';
    }

    return null;
  }

  /// Valida el username según las reglas de negocio
  /// Debe tener al menos 3 caracteres y solo caracteres alfanuméricos
  static String? validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'El username es requerido';
    }

    if (value.length < 3) {
      return 'El username debe tener al menos 3 caracteres';
    }

    if (value.length > 20) {
      return 'El username no puede tener más de 20 caracteres';
    }

    final usernameRegex = RegExp(r'^[a-zA-Z0-9_]+$');
    if (!usernameRegex.hasMatch(value)) {
      return 'Solo letras, números y guiones bajos permitidos';
    }

    return null;
  }

  /// Valida la contraseña según las políticas de seguridad
  /// Debe cumplir con requisitos de longitud y complejidad
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'La contraseña es requerida';
    }

    if (value.length < 8) {
      return 'La contraseña debe tener al menos 8 caracteres';
    }

    // Verificar que contenga al menos una mayúscula
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Debe contener al menos una mayúscula';
    }

    // Verificar que contenga al menos una minúscula
    if (!value.contains(RegExp(r'[a-z]'))) {
      return 'Debe contener al menos una minúscula';
    }

    // Verificar que contenga al menos un número
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Debe contener al menos un número';
    }

    return null;
  }

  /// Valida que la confirmación de contraseña coincida
  /// Compara con la contraseña original
  static String? validatePasswordConfirm(String? value, String? password) {
    if (value == null || value.isEmpty) {
      return 'Confirma tu contraseña';
    }

    if (value != password) {
      return 'Las contraseñas no coinciden';
    }

    return null;
  }

  /// Validador genérico para campos requeridos
  /// Acepta el nombre del campo para personalizar el mensaje
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName es requerido';
    }
    return null;
  }

  /// Valida campo de login que acepta tanto email como username
  /// Para login, permitimos mayor flexibilidad
  static String? validateLoginField(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email o username es requerido';
    }

    if (value.length < 3) {
      return 'Debe tener al menos 3 caracteres';
    }

    // Si contiene @, validar como email
    if (value.contains('@')) {
      return validateEmail(value);
    }

    // Si no contiene @, validar como username (pero sin límite de 20 chars)
    if (value.length > 50) {
      return 'Máximo 50 caracteres permitidos';
    }

    return null;
  }

  static bool isValidForm(List<String?> validationResults) {
    return validationResults.every((result) => result == null);
  }
}
