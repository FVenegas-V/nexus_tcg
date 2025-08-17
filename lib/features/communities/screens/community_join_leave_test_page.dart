import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../providers/communities_provider_new.dart';
import '../screens/communities_screen_complete.dart';

/// Pantalla de prueba para verificar la funcionalidad de join/leave
class CommunityJoinLeaveTestPage extends StatefulWidget {
  const CommunityJoinLeaveTestPage({super.key});

  @override
  State<CommunityJoinLeaveTestPage> createState() =>
      _CommunityJoinLeaveTestPageState();
}

class _CommunityJoinLeaveTestPageState
    extends State<CommunityJoinLeaveTestPage> {
  bool _isLoggedIn = false;
  String _statusMessage = 'Verificando autenticación...';

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    try {
      // Simulamos verificación de auth - puedes reemplazar con tu lógica real
      await Future.delayed(const Duration(seconds: 1));

      setState(() {
        _isLoggedIn = true; // Para testing, asumimos que está logueado
        _statusMessage = '✅ Usuario autenticado - Join/Leave habilitado';
      });
    } catch (e) {
      setState(() {
        _statusMessage = '⚠️ Error verificando autenticación: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🧪 Test Join/Leave Communities'),
        centerTitle: true,
        backgroundColor: AppColors.primaryRed,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Status banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: _isLoggedIn ? Colors.green.shade50 : Colors.orange.shade50,
            child: Column(
              children: [
                Icon(
                  _isLoggedIn ? Icons.check_circle : Icons.warning_rounded,
                  color: _isLoggedIn ? Colors.green : Colors.orange,
                  size: 32,
                ),
                const SizedBox(height: 8),
                Text(
                  _statusMessage,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _isLoggedIn
                        ? Colors.green.shade700
                        : Colors.orange.shade700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  _isLoggedIn
                      ? 'Puedes unirte y salir de comunidades'
                      : 'Inicia sesión para acceder a la funcionalidad completa',
                  style: TextStyle(
                    fontSize: 14,
                    color: _isLoggedIn
                        ? Colors.green.shade600
                        : Colors.orange.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          // Instrucciones
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.blue.shade50,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700),
                    const SizedBox(width: 8),
                    Text(
                      'Instrucciones de prueba:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '1. Los botones "Unirse/Unido" deberían estar funcionales\n'
                  '2. Los estados de loading deberían aparecer durante las operaciones\n'
                  '3. Los SnackBars deberían mostrar confirmaciones\n'
                  '4. Los contadores de miembros deberían actualizarse\n'
                  '5. Los cambios deberían persistir al refrescar',
                  style: TextStyle(fontSize: 14, color: Colors.blue.shade600),
                ),
              ],
            ),
          ),

          // Lista de comunidades con funcionalidad join/leave
          Expanded(
            child: ChangeNotifierProvider(
              create: (context) => CommunitiesProvider(),
              child: const CommunitiesScreen(),
            ),
          ),
        ],
      ),

      // Botón flotante para refrescar
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Refrescar la página
          setState(() {
            _statusMessage = 'Refrescando...';
          });
          _checkAuthStatus();
        },
        icon: const Icon(Icons.refresh),
        label: const Text('Refrescar'),
        backgroundColor: AppColors.primaryRed,
      ),
    );
  }
}
