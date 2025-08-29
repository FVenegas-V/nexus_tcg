/// Configuración para diferentes entornos
/// Permite cambiar entre desarrollo, staging y producción
class EnvironmentConfig {
  static const String _environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'development',
  );

  /// Configuración para DESARROLLO (actual)
  static const _developmentConfig = {
    'baseUrl': 'http://127.0.0.1:8000',
    'apiTimeout': 30000,
    'enableLogging': true,
    'enableDebugFeatures': true,
    'crashlyticsEnabled': false,
  };

  /// Configuración para STAGING (pre-producción)
  static const _stagingConfig = {
    'baseUrl': 'https://staging-api.nexustcg.com',
    'apiTimeout': 15000,
    'enableLogging': true,
    'enableDebugFeatures': false,
    'crashlyticsEnabled': true,
  };

  /// Configuración para PRODUCCIÓN (usuarios reales)
  static const _productionConfig = {
    'baseUrl': 'https://api.nexustcg.com',
    'apiTimeout': 10000,
    'enableLogging': false,
    'enableDebugFeatures': false,
    'crashlyticsEnabled': true,
  };

  /// Obtener configuración actual según entorno
  static Map<String, dynamic> get _currentConfig {
    switch (_environment) {
      case 'staging':
        return _stagingConfig;
      case 'production':
        return _productionConfig;
      default:
        return _developmentConfig;
    }
  }

  // Getters para configuración
  static String get baseUrl => _currentConfig['baseUrl'] as String;
  static int get apiTimeout => _currentConfig['apiTimeout'] as int;
  static bool get enableLogging => _currentConfig['enableLogging'] as bool;
  static bool get enableDebugFeatures =>
      _currentConfig['enableDebugFeatures'] as bool;
  static bool get crashlyticsEnabled =>
      _currentConfig['crashlyticsEnabled'] as bool;

  // Helper para saber en qué entorno estamos
  static bool get isDevelopment => _environment == 'development';
  static bool get isStaging => _environment == 'staging';
  static bool get isProduction => _environment == 'production';

  static String get environmentName => _environment;
}
