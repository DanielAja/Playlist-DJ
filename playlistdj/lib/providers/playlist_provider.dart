import 'package:flutter/foundation.dart';
import '../services/playlist_storage_service.dart';
import '../services/spotify_service.dart';
import '../models/playlist.dart';
import '../models/track.dart';
import '../models/user.dart';

class PlaylistProvider extends ChangeNotifier {
  final PlaylistStorageService _storageService = PlaylistStorageService();
  final SpotifyService _spotifyService = SpotifyService();
  
  Playlist _currentPlaylist = Playlist.empty();
  List<Playlist> _savedPlaylists = [];
  bool _isLoading = false;
  String? _error;
  
  // Getters
  Playlist get currentPlaylist => _currentPlaylist;
  List<Playlist> get savedPlaylists => _savedPlaylists;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  // Initialize and load saved playlists
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      await loadSavedPlaylists();
    } catch (e) {
      _error = 'Failed to initialize playlist provider: $e';
      print(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Load all saved playlists
  Future<void> loadSavedPlaylists() async {
    try {
      _savedPlaylists = await _storageService.getPlaylists();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load playlists: $e';
      print(_error);
    }
  }
  
  // Create a new playlist
  void createNewPlaylist({String? name}) {
    _currentPlaylist = Playlist.empty();
    if (name != null) {
      _currentPlaylist.name = name;
    }
    notifyListeners();
  }
  
  // Load a playlist by ID
  Future<void> loadPlaylist(String id) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final playlist = await _storageService.getPlaylistById(id);
      if (playlist != null) {
        _currentPlaylist = playlist;
      } else {
        _error = 'Playlist not found';
      }
    } catch (e) {
      _error = 'Failed to load playlist: $e';
      print(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Add track to current playlist
  void addTrack(Track track) {
    _currentPlaylist.tracks.add(track);
    notifyListeners();
  }
  
  // Remove track from current playlist
  void removeTrack(int index) {
    if (index >= 0 && index < _currentPlaylist.tracks.length) {
      _currentPlaylist.tracks.removeAt(index);
      notifyListeners();
    }
  }
  
  // Update track in current playlist
  void updateTrack(int index, Track updatedTrack) {
    if (index >= 0 && index < _currentPlaylist.tracks.length) {
      _currentPlaylist.tracks[index] = updatedTrack;
      notifyListeners();
    }
  }
  
  // Save current playlist locally
  Future<void> saveCurrentPlaylist() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      await _storageService.savePlaylist(_currentPlaylist);
      await loadSavedPlaylists(); // Refresh the list
    } catch (e) {
      _error = 'Failed to save playlist: $e';
      print(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Save any playlist
  Future<void> savePlaylist(playlist) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      await _storageService.savePlaylist(playlist);
      await loadSavedPlaylists(); // Refresh the list
    } catch (e) {
      _error = 'Failed to save playlist: $e';
      print(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Delete a playlist
  Future<void> deletePlaylist(String id) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      await _storageService.deletePlaylist(id);
      await loadSavedPlaylists(); // Refresh the list
    } catch (e) {
      _error = 'Failed to delete playlist: $e';
      print(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Save current playlist to Spotify
  Future<bool> saveToSpotify(User user) async {
    if (_currentPlaylist.tracks.isEmpty) {
      _error = 'Cannot save an empty playlist';
      notifyListeners();
      return false;
    }
    
    _isLoading = true;
    notifyListeners();
    
    try {
      // Create a new playlist on Spotify
      final response = await _spotifyService.createPlaylist(
        user.id,
        _currentPlaylist.name,
        'Created with PlaylistDJ - Custom time sections and transitions',
      );
      
      // Get the Spotify playlist ID
      final spotifyPlaylistId = response['id'];
      
      // Add tracks to the playlist
      final trackUris = _currentPlaylist.tracks.map((t) => t.uri).toList();
      await _spotifyService.addTracksToPlaylist(spotifyPlaylistId, trackUris);
      
      // Update our playlist with the Spotify ID
      _currentPlaylist.spotifyId = spotifyPlaylistId;
      
      // Save the updated playlist locally
      await _storageService.savePlaylist(_currentPlaylist);
      await loadSavedPlaylists(); // Refresh the list
      
      return true;
    } catch (e) {
      _error = 'Failed to save playlist to Spotify: $e';
      print(_error);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Export playlist to file
  Future<String?> exportPlaylist() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final filePath = await _storageService.exportPlaylistToFile(_currentPlaylist);
      return filePath;
    } catch (e) {
      _error = 'Failed to export playlist: $e';
      print(_error);
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Import playlist from file
  Future<bool> importPlaylist(String filePath) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final playlist = await _storageService.importPlaylistFromFile(filePath);
      _currentPlaylist = playlist;
      await loadSavedPlaylists(); // Refresh the list
      return true;
    } catch (e) {
      _error = 'Failed to import playlist: $e';
      print(_error);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Update current playlist name
  void updatePlaylistName(String name) {
    _currentPlaylist.name = name;
    notifyListeners();
  }
  
  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}