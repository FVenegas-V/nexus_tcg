import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  print('=== TEST CONNECTIVITY FROM FLUTTER ===');

  // Test 1: Verificar conectividad básica
  try {
    final response = await http
        .get(
          Uri.parse('http://127.0.0.1:8000/api/auth/login/'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        )
        .timeout(Duration(seconds: 5));

    print('🌐 GET Status: ${response.statusCode}');
    print('📋 Headers: ${response.headers}');
  } catch (e) {
    print('❌ GET Error: $e');
  }

  // Test 2: Probar login real
  try {
    final response = await http
        .post(
          Uri.parse('http://127.0.0.1:8000/api/auth/login/'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({'username': 'test1', 'password': 'password123'}),
        )
        .timeout(Duration(seconds: 10));

    print('🔐 POST Status: ${response.statusCode}');
    print('📊 Response: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print('✅ Login exitoso desde Flutter!');
      print('🎫 Token: ${data['access']?.toString().substring(0, 20)}...');
    } else {
      print('❌ Login falló: ${response.statusCode}');
    }
  } catch (e) {
    print('❌ POST Error: $e');
  }
}
