import 'package:flutter/foundation.dart';

/// Provider para manejar la navegación entre tabs del BottomNavigationBar
class TabNavigationProvider extends ChangeNotifier {
  int _currentIndex = 1; // Iniciamos en el tab de Inicio (HomeScreen)

  int get currentIndex => _currentIndex;

  /// Navega al tab especificado
  void navigateToTab(int index) {
    if (index != _currentIndex && index >= 0 && index <= 2) {
      _currentIndex = index;
      notifyListeners();
    }
  }

  /// Navega al tab de Comunidades (índice 0)
  void goToCommunities() {
    navigateToTab(0);
  }

  /// Navega al tab de Inicio (índice 1)
  void goToHome() {
    navigateToTab(1);
  }

  /// Navega al tab de Perfil (índice 2)
  void goToProfile() {
    navigateToTab(2);
  }
}
