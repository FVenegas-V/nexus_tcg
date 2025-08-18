import 'package:flutter/material.dart';
import 'lib/core/services/http_service.dart';
import 'lib/core/config/api_config.dart';
import 'lib/features/auth/services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print('=== FLUTTER LOGIN TEST ===');

  // Inicializar servicios
  HttpService().initialize();

  print('🌐 Base URL: ${ApiConfig.baseUrl}');
  print('🔗 Login Endpoint: ${ApiConfig.loginEndpoint}');
  print('🔗 Full URL: ${ApiConfig.baseUrl}${ApiConfig.loginEndpoint}');

  try {
    // Probar login usando AuthService
    final result = await AuthService.login(
      username: 'test1',
      password: 'password123',
    );

    print('📊 Result: $result');

    if (result['success'] == true) {
      print('✅ Login exitoso desde Flutter!');
      print('🎫 Token: ${result['token']?.toString().substring(0, 20)}...');
      print('👤 User: ${result['user']}');
    } else {
      print('❌ Login falló: ${result['message']}');
    }
  } catch (e) {
    print('🚨 Exception: $e');
  }
}
