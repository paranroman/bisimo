import 'package:flutter/material.dart';

/// Navigation Provider for managing app navigation state
class NavigationProvider extends ChangeNotifier {
  int _currentIndex = 0;
  String _currentRoute = '/';

  // Getters
  int get currentIndex => _currentIndex;
  String get currentRoute => _currentRoute;

  /// Set bottom navigation index
  void setIndex(int index) {
    _currentIndex = index;
    notifyListeners();
  }

  /// Set current route
  void setRoute(String route) {
    _currentRoute = route;
    notifyListeners();
  }

  /// Reset navigation
  void reset() {
    _currentIndex = 0;
    _currentRoute = '/';
    notifyListeners();
  }
}
