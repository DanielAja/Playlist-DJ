import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_web_auth/flutter_web_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user.dart';
import '../models/track.dart';

class SpotifyService {
  static const String _baseUrl = 'https://api.spotify.com/v1';
  static const String _authUrl = 'https://accounts.spotify.com/authorize';
  static const String _tokenUrl = 'https://accounts.spotify.com/api/token';
  
  final storage = const FlutterSecureStorage();
  String? _accessToken;
  
  // Get client ID from .env file
  String get clientId => dotenv.env['SPOTIFY_CLIENT_ID'] ?? '';
  
  // Get redirect URI from .env file or use default for GitHub Pages
  String get redirectUri => dotenv.env['SPOTIFY_REDIRECT_URI'] ?? 'https://danielaja.github.io/Playlist-DJ/';
  
  // Spotify scopes needed for the app
  final String _scope = 'user-read-private user-read-email playlist-modify-public playlist-modify-private streaming user-read-playback-state user-modify-playback-state user-read-currently-playing';
  
  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    _accessToken = await storage.read(key: 'spotify_access_token');
    return _accessToken != null;
  }
  
  // Authenticate with Spotify
  Future<bool> authenticate() async {
    try {
      // Construct the authorization URL
      final authorizeUrl = Uri.parse('$_authUrl'
          '?client_id=$clientId'
          '&response_type=token'
          '&redirect_uri=${Uri.encodeComponent(redirectUri)}'
          '&scope=${Uri.encodeComponent(_scope)}');
      
      // For web redirect URI, use more flexible approach with callbackUrlScheme
      final result = await FlutterWebAuth.authenticate(
        url: authorizeUrl.toString(),
        callbackUrlScheme: 'https',
      );
      
      // Extract the access token from the redirect URL
      String accessToken;
      try {
        accessToken = Uri.parse(result).fragment
            .split('&')
            .firstWhere((element) => element.startsWith('access_token='))
            .split('=')[1];
      } catch (e) {
        print('Failed to extract access token: $e');
        return false;
      }
      
      // Save the access token
      await storage.write(key: 'spotify_access_token', value: accessToken);
      _accessToken = accessToken;
      
      return true;
    } catch (e) {
      print('Authentication error: $e');
      return false;
    }
  }
  
  // Logout
  Future<void> logout() async {
    await storage.delete(key: 'spotify_access_token');
    _accessToken = null;
  }
  
  // Get current user profile
  Future<User> getCurrentUser() async {
    final response = await _get('/me');
    return User.fromJson(response);
  }
  
  // Search for tracks
  Future<List<Track>> searchTracks(String query, {int limit = 20}) async {
    if (query.isEmpty) {
      return [];
    }
    
    final response = await _get(
      '/search?q=${Uri.encodeComponent(query)}&type=track&limit=$limit',
    );
    
    return (response['tracks']['items'] as List)
        .map((json) => Track.fromJson(json))
        .toList();
  }
  
  // Create a playlist
  Future<Map<String, dynamic>> createPlaylist(String userId, String name, String description) async {
    final response = await _post(
      '/users/$userId/playlists',
      body: {
        'name': name,
        'description': description,
        'public': false,
      },
    );
    
    return response;
  }
  
  // Add tracks to a playlist
  Future<Map<String, dynamic>> addTracksToPlaylist(String playlistId, List<String> trackUris) async {
    final response = await _post(
      '/playlists/$playlistId/tracks',
      body: {
        'uris': trackUris,
      },
    );
    
    return response;
  }
  
  // Helper method for GET requests
  Future<dynamic> _get(String endpoint) async {
    await _ensureAccessToken();
    
    final response = await http.get(
      Uri.parse('$_baseUrl$endpoint'),
      headers: {
        'Authorization': 'Bearer $_accessToken',
        'Content-Type': 'application/json',
      },
    );
    
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to perform GET request: ${response.statusCode}');
    }
  }
  
  // Helper method for POST requests
  Future<dynamic> _post(String endpoint, {Map<String, dynamic>? body}) async {
    await _ensureAccessToken();
    
    final response = await http.post(
      Uri.parse('$_baseUrl$endpoint'),
      headers: {
        'Authorization': 'Bearer $_accessToken',
        'Content-Type': 'application/json',
      },
      body: body != null ? json.encode(body) : null,
    );
    
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isNotEmpty) {
        return json.decode(response.body);
      }
      return {};
    } else {
      throw Exception('Failed to perform POST request: ${response.statusCode}');
    }
  }
  
  // Ensure we have a valid access token
  Future<void> _ensureAccessToken() async {
    if (_accessToken == null) {
      _accessToken = await storage.read(key: 'spotify_access_token');
      if (_accessToken == null) {
        throw Exception('Not authenticated with Spotify');
      }
    }
  }
}