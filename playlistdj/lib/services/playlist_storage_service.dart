import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/playlist.dart';

class PlaylistStorageService {
  static const String _playlistsKey = 'local_playlists';
  
  // Save playlist to local storage
  Future<void> savePlaylist(Playlist playlist) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get existing playlists
      final playlistsJson = prefs.getStringList(_playlistsKey) ?? [];
      
      // Check if this playlist already exists (update if it does)
      bool updated = false;
      final updatedPlaylists = playlistsJson.map((json) {
        final existingPlaylist = Playlist.fromJson(jsonDecode(json));
        if (existingPlaylist.id == playlist.id) {
          updated = true;
          return jsonEncode(playlist.toJson());
        }
        return json;
      }).toList();
      
      // Add new playlist if it's not an update
      if (!updated) {
        updatedPlaylists.add(jsonEncode(playlist.toJson()));
      }
      
      // Save back to preferences
      await prefs.setStringList(_playlistsKey, updatedPlaylists);
    } catch (e) {
      throw Exception('Failed to save playlist: $e');
    }
  }
  
  // Get all playlists
  Future<List<Playlist>> getPlaylists() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final playlistsJson = prefs.getStringList(_playlistsKey) ?? [];
      
      return playlistsJson
          .map((json) => Playlist.fromJson(jsonDecode(json)))
          .toList();
    } catch (e) {
      throw Exception('Failed to get playlists: $e');
    }
  }
  
  // Get playlist by ID
  Future<Playlist?> getPlaylistById(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final playlistsJson = prefs.getStringList(_playlistsKey) ?? [];
      
      for (final json in playlistsJson) {
        final playlist = Playlist.fromJson(jsonDecode(json));
        if (playlist.id == id) {
          return playlist;
        }
      }
      
      return null;
    } catch (e) {
      throw Exception('Failed to get playlist: $e');
    }
  }
  
  // Delete playlist
  Future<void> deletePlaylist(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final playlistsJson = prefs.getStringList(_playlistsKey) ?? [];
      
      final updatedPlaylists = playlistsJson.where((json) {
        final playlist = Playlist.fromJson(jsonDecode(json));
        return playlist.id != id;
      }).toList();
      
      await prefs.setStringList(_playlistsKey, updatedPlaylists);
    } catch (e) {
      throw Exception('Failed to delete playlist: $e');
    }
  }
  
  // Export playlist to JSON file
  Future<String> exportPlaylistToFile(Playlist playlist) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/${playlist.name.replaceAll(' ', '_')}_playlist.json');
      
      await file.writeAsString(jsonEncode(playlist.toJson()));
      
      return file.path;
    } catch (e) {
      throw Exception('Failed to export playlist: $e');
    }
  }
  
  // Import playlist from JSON file
  Future<Playlist> importPlaylistFromFile(String filePath) async {
    try {
      final file = File(filePath);
      final jsonString = await file.readAsString();
      
      final playlist = Playlist.fromJson(jsonDecode(jsonString));
      
      // Save the imported playlist
      await savePlaylist(playlist);
      
      return playlist;
    } catch (e) {
      throw Exception('Failed to import playlist: $e');
    }
  }
}