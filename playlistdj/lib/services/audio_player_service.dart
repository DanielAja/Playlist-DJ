import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import '../models/track.dart';

class AudioPlayerService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  Track? _currentTrack;
  
  // Constructor
  AudioPlayerService() {
    _initAudioSession();
  }
  
  // Initialize audio session
  Future<void> _initAudioSession() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
  }
  
  // Get current track
  Track? get currentTrack => _currentTrack;
  
  // Get duration
  Duration? get duration => _audioPlayer.duration;
  
  // Get current position
  Stream<Duration> get positionStream => _audioPlayer.positionStream;
  
  // Get playing state
  Stream<bool> get playingStream => _audioPlayer.playingStream;
  
  // Load and play a track
  Future<void> playTrack(Track track) async {
    _currentTrack = track;
    
    try {
      // Check if the track has a preview URL
      if (track.previewUrl.isEmpty) {
        throw Exception('This track does not have a preview URL');
      }
      
      // Set volume to 0 for fade-in
      _audioPlayer.setVolume(0.0);
      
      // Load the audio file
      await _audioPlayer.setUrl(track.previewUrl);
      
      // Set the start position
      await _audioPlayer.seek(Duration(seconds: track.startTime.toInt()));
      
      // Calculate the end time for playing
      Duration? totalDuration = _audioPlayer.duration;
      if (totalDuration != null) {
        // Ensure end time doesn't exceed track length
        double endTime = track.endTime;
        if (endTime > totalDuration.inSeconds) {
          endTime = totalDuration.inSeconds.toDouble();
        }
        
        // Set clip duration
        _audioPlayer.setClip(
          start: Duration(seconds: track.startTime.toInt()),
          end: Duration(seconds: endTime.toInt()),
        );
      }
      
      // Play the track
      await _audioPlayer.play();
      
      // Apply fade-in
      if (track.fadeIn > 0) {
        _applyFadeIn(track.fadeIn);
      } else {
        _audioPlayer.setVolume(1.0);
      }
      
      // Apply fade-out
      if (track.fadeOut > 0) {
        _scheduleFadeOut(track);
      }
    } catch (e) {
      print('Error playing track: $e');
      rethrow;
    }
  }
  
  // Apply fade-in effect
  void _applyFadeIn(double fadeInDuration) {
    // Start with volume 0
    double volume = 0.0;
    // Increase every 100ms
    const step = 0.1;
    
    Future.doWhile(() async {
      if (volume >= 1.0) return false;
      
      volume += step;
      if (volume > 1.0) volume = 1.0;
      
      _audioPlayer.setVolume(volume);
      
      await Future.delayed(
        Duration(milliseconds: (fadeInDuration * 1000 * step).toInt()),
      );
      
      return volume < 1.0;
    });
  }
  
  // Schedule fade-out
  void _scheduleFadeOut(Track track) {
    if (_audioPlayer.duration == null) return;
    
    final trackDuration = _audioPlayer.duration!.inMilliseconds;
    final fadeOutMs = (track.fadeOut * 1000).toInt();
    final startFadeOutAt = trackDuration - fadeOutMs;
    
    _audioPlayer.positionStream.listen((position) {
      final remainingMs = trackDuration - position.inMilliseconds;
      
      if (remainingMs <= fadeOutMs) {
        final volume = remainingMs / fadeOutMs;
        _audioPlayer.setVolume(volume);
      }
    });
  }
  
  // Pause the player
  Future<void> pause() async {
    await _audioPlayer.pause();
  }
  
  // Resume playback
  Future<void> resume() async {
    await _audioPlayer.play();
  }
  
  // Stop playback
  Future<void> stop() async {
    await _audioPlayer.stop();
    _currentTrack = null;
  }
  
  // Seek to position
  Future<void> seekTo(Duration position) async {
    await _audioPlayer.seek(position);
  }
  
  // Dispose the player
  Future<void> dispose() async {
    await _audioPlayer.dispose();
  }
  
  // Get current position
  Duration? get position => _audioPlayer.position;
  
  // Check if it's playing
  bool get isPlaying => _audioPlayer.playing;
}