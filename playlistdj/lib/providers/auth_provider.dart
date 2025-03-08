import 'package:flutter/foundation.dart';
import '../services/spotify_service.dart';
import '../models/user.dart';

class AuthProvider extends ChangeNotifier {
  final SpotifyService _spotifyService = SpotifyService();
  User? _currentUser;
  bool _isLoading = false;
  String? _error;
  
  // Getters
  User? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  // Initialize and check if user is already logged in
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final isLoggedIn = await _spotifyService.isLoggedIn();
      
      if (isLoggedIn) {
        await _fetchUserProfile();
      }
    } catch (e) {
      _error = 'Failed to initialize: $e';
      print(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Login with Spotify
  Future<bool> login() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final success = await _spotifyService.authenticate();
      
      if (success) {
        await _fetchUserProfile();
        return true;
      } else {
        _error = 'Authentication failed';
        return false;
      }
    } catch (e) {
      _error = 'Login error: $e';
      print(_error);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Logout
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      await _spotifyService.logout();
      _currentUser = null;
    } catch (e) {
      _error = 'Logout error: $e';
      print(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Fetch user profile
  Future<void> _fetchUserProfile() async {
    try {
      _currentUser = await _spotifyService.getCurrentUser();
    } catch (e) {
      _error = 'Failed to fetch user profile: $e';
      print(_error);
    }
  }
  
  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}