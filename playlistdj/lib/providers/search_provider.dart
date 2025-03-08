import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/spotify_service.dart';
import '../models/track.dart';

class SearchProvider extends ChangeNotifier {
  final SpotifyService _spotifyService = SpotifyService();
  
  List<Track> _searchResults = [];
  List<Track> _suggestions = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String? _error;
  Timer? _debounceTimer;
  
  // Getters
  List<Track> get searchResults => _searchResults;
  List<Track> get suggestions => _suggestions;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  String? get error => _error;
  bool get hasResults => _searchResults.isNotEmpty;
  
  // Search for tracks
  Future<void> searchTracks(String query) async {
    if (query.isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }
    
    _searchQuery = query;
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      _searchResults = await _spotifyService.searchTracks(query);
    } catch (e) {
      _error = 'Search failed: $e';
      print(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Get suggestions as user types
  void getSuggestions(String query) {
    // Cancel any previous debounce timer
    _debounceTimer?.cancel();
    
    if (query.isEmpty) {
      _suggestions = [];
      notifyListeners();
      return;
    }
    
    // Debounce to avoid too many requests while typing
    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      if (query.length < 2) return; // Don't search for very short queries
      
      _isLoading = true;
      notifyListeners();
      
      try {
        _suggestions = await _spotifyService.searchTracks(query, limit: 5);
      } catch (e) {
        print('Error getting suggestions: $e');
        _suggestions = [];
      } finally {
        _isLoading = false;
        notifyListeners();
      }
    });
  }
  
  // Clear search results
  void clearSearchResults() {
    _searchResults = [];
    _searchQuery = '';
    notifyListeners();
  }
  
  // Clear suggestions
  void clearSuggestions() {
    _suggestions = [];
    notifyListeners();
  }
  
  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
  
  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}