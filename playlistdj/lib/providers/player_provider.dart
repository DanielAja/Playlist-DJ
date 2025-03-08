import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/audio_player_service.dart';
import '../models/track.dart';
import '../models/playlist.dart';

class PlayerProvider extends ChangeNotifier {
  final AudioPlayerService _audioPlayerService = AudioPlayerService();
  
  Playlist? _currentPlaylist;
  int _currentIndex = -1;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration? _duration;
  String? _error;
  
  // Stream subscriptions
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<bool>? _playingSubscription;
  
  // Constructor
  PlayerProvider() {
    _initStreams();
  }
  
  // Initialize position and playing state streams
  void _initStreams() {
    _positionSubscription = _audioPlayerService.positionStream.listen((p) {
      _position = p;
      notifyListeners();
    });
    
    _playingSubscription = _audioPlayerService.playingStream.listen((playing) {
      _isPlaying = playing;
      notifyListeners();
      
      // Handle automatic track transition
      if (!playing && _currentPlaylist != null && _currentIndex >= 0) {
        _handleTrackCompletion();
      }
    });
  }
  
  // Getters
  Playlist? get currentPlaylist => _currentPlaylist;
  int get currentIndex => _currentIndex;
  Track? get currentTrack => _currentIndex >= 0 && _currentPlaylist != null && _currentIndex < _currentPlaylist!.tracks.length
      ? _currentPlaylist!.tracks[_currentIndex]
      : null;
  bool get isPlaying => _isPlaying;
  Duration get position => _position;
  Duration? get duration => _duration;
  String? get error => _error;
  double get progress => _duration != null && _duration!.inMilliseconds > 0
      ? _position.inMilliseconds / _duration!.inMilliseconds
      : 0.0;
  
  // Load and play a playlist
  Future<void> playPlaylist(Playlist playlist, {int startIndex = 0}) async {
    if (playlist.tracks.isEmpty) {
      _error = 'Playlist is empty';
      notifyListeners();
      return;
    }
    
    if (startIndex < 0 || startIndex >= playlist.tracks.length) {
      startIndex = 0;
    }
    
    _currentPlaylist = playlist;
    await playTrackAtIndex(startIndex);
  }
  
  // Play a specific track from the current playlist
  Future<void> playTrackAtIndex(int index) async {
    if (_currentPlaylist == null || _currentPlaylist!.tracks.isEmpty) {
      _error = 'No playlist loaded';
      notifyListeners();
      return;
    }
    
    if (index < 0 || index >= _currentPlaylist!.tracks.length) {
      _error = 'Invalid track index';
      notifyListeners();
      return;
    }
    
    _error = null;
    _currentIndex = index;
    
    try {
      final track = _currentPlaylist!.tracks[index];
      await _audioPlayerService.playTrack(track);
      _isPlaying = true;
      _duration = _audioPlayerService.duration;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to play track: $e';
      print(_error);
      notifyListeners();
    }
  }
  
  // Play a single track (not part of playlist)
  Future<void> playSingleTrack(Track track) async {
    _error = null;
    _currentPlaylist = null;
    _currentIndex = -1;
    
    try {
      await _audioPlayerService.playTrack(track);
      _isPlaying = true;
      _duration = _audioPlayerService.duration;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to play track: $e';
      print(_error);
      notifyListeners();
    }
  }
  
  // Play the next track
  Future<void> playNextTrack() async {
    if (_currentPlaylist == null || _currentIndex < 0) return;
    
    int nextIndex = _currentIndex + 1;
    if (nextIndex >= _currentPlaylist!.tracks.length) {
      nextIndex = 0; // Loop back to the beginning
    }
    
    await playTrackAtIndex(nextIndex);
  }
  
  // Play the previous track
  Future<void> playPreviousTrack() async {
    if (_currentPlaylist == null || _currentIndex < 0) return;
    
    int prevIndex = _currentIndex - 1;
    if (prevIndex < 0) {
      prevIndex = _currentPlaylist!.tracks.length - 1; // Loop to the end
    }
    
    await playTrackAtIndex(prevIndex);
  }
  
  // Toggle play/pause
  Future<void> togglePlayPause() async {
    if (_isPlaying) {
      await _audioPlayerService.pause();
    } else {
      if (_audioPlayerService.currentTrack != null) {
        await _audioPlayerService.resume();
      } else if (_currentPlaylist != null && _currentIndex >= 0) {
        await playTrackAtIndex(_currentIndex);
      }
    }
  }
  
  // Seek to position
  Future<void> seekTo(Duration position) async {
    await _audioPlayerService.seekTo(position);
  }
  
  // Stop playback
  Future<void> stop() async {
    await _audioPlayerService.stop();
    _isPlaying = false;
    _position = Duration.zero;
    notifyListeners();
  }
  
  // Handle track completion
  void _handleTrackCompletion() {
    // Auto-play next track if available
    if (_currentPlaylist != null && _currentPlaylist!.tracks.isNotEmpty) {
      playNextTrack();
    }
  }
  
  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
  
  @override
  void dispose() {
    _positionSubscription?.cancel();
    _playingSubscription?.cancel();
    _audioPlayerService.dispose();
    super.dispose();
  }
}