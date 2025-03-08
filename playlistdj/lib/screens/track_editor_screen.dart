import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:just_audio/just_audio.dart';
import '../models/track.dart';
import '../providers/playlist_provider.dart';
import '../providers/player_provider.dart';
import '../utils/app_theme.dart';
import '../utils/format_utils.dart';

class TrackEditorScreen extends StatefulWidget {
  final Track track;
  final int? editIndex; // If editing an existing track in playlist

  const TrackEditorScreen({
    Key? key,
    required this.track,
    this.editIndex,
  }) : super(key: key);

  @override
  State<TrackEditorScreen> createState() => _TrackEditorScreenState();
}

class _TrackEditorScreenState extends State<TrackEditorScreen> {
  late Track _editedTrack;
  final AudioPlayer _previewPlayer = AudioPlayer();
  bool _isPlaying = false;
  Duration? _duration;
  Duration _position = Duration.zero;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _editedTrack = Track(
      id: widget.track.id,
      name: widget.track.name,
      artists: widget.track.artists,
      album: widget.track.album,
      uri: widget.track.uri,
      previewUrl: widget.track.previewUrl,
      startTime: widget.track.startTime,
      endTime: widget.track.endTime,
      fadeIn: widget.track.fadeIn,
      fadeOut: widget.track.fadeOut,
    );

    _initAudio();
  }

  @override
  void dispose() {
    _previewPlayer.dispose();
    super.dispose();
  }

  // Initialize audio preview
  Future<void> _initAudio() async {
    setState(() => _isLoading = true);

    if (_editedTrack.previewUrl.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Preview not available for this track';
      });
      return;
    }

    try {
      await _previewPlayer.setUrl(_editedTrack.previewUrl);
      _duration = _previewPlayer.duration;

      // Set up position stream listener
      _previewPlayer.positionStream.listen((position) {
        setState(() {
          _position = position;
        });
      });

      // Set up playing stream listener
      _previewPlayer.playingStream.listen((playing) {
        setState(() {
          _isPlaying = playing;
        });
      });

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load audio preview: $e';
      });
      print('Audio loading error: $e');
    }
  }

  // Play the preview from the start time
  void _playPreview() async {
    if (_duration == null) return;

    try {
      // Set the clip region based on start and end times
      final startTime = Duration(milliseconds: (_editedTrack.startTime * 1000).toInt());
      final endTime = Duration(milliseconds: (_editedTrack.endTime * 1000).toInt());

      // Make sure end time doesn't exceed track length
      final adjustedEndTime = endTime > _duration! ? _duration! : endTime;

      // Set clipping points
      await _previewPlayer.setClip(start: startTime, end: adjustedEndTime);

      // Set volume to 0 for fade-in effect
      if (_editedTrack.fadeIn > 0) {
        await _previewPlayer.setVolume(0);
      }

      // Start playback
      await _previewPlayer.seek(startTime);
      await _previewPlayer.play();

      // Apply fade-in effect
      if (_editedTrack.fadeIn > 0) {
        _applyFadeIn();
      }

      // Schedule fade-out effect
      if (_editedTrack.fadeOut > 0) {
        _scheduleFadeOut(adjustedEndTime);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error playing preview: $e')),
      );
    }
  }

  // Apply fade-in effect
  void _applyFadeIn() {
    final fadeInDuration = _editedTrack.fadeIn;
    double volume = 0;
    const step = 0.1;

    Future.doWhile(() async {
      if (!_isPlaying || volume >= 1.0) return false;

      volume += step;
      if (volume > 1.0) volume = 1.0;

      await _previewPlayer.setVolume(volume);

      await Future.delayed(
        Duration(milliseconds: (fadeInDuration * 1000 * step).toInt()),
      );

      return volume < 1.0 && _isPlaying;
    });
  }

  // Schedule fade-out effect
  void _scheduleFadeOut(Duration endTime) {
    final fadeOutMs = (_editedTrack.fadeOut * 1000).toInt();
    final fadeOutStartTime = endTime.inMilliseconds - fadeOutMs;

    _previewPlayer.positionStream.listen((position) {
      if (!_isPlaying) return;

      final positionMs = position.inMilliseconds;
      if (positionMs >= fadeOutStartTime) {
        final remainingMs = endTime.inMilliseconds - positionMs;
        final volume = remainingMs / fadeOutMs;
        _previewPlayer.setVolume(volume > 0 ? volume : 0);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Track'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _saveTrack,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: AppColors.errorRed,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.errorRed),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Go Back'),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Track info card
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              // Album art
                              _editedTrack.album.thumbnailUrl.isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        _editedTrack.album.thumbnailUrl,
                                        width: 80,
                                        height: 80,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        color: AppColors.darkGray,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(Icons.music_note,
                                          color: AppColors.mediumGray, size: 40),
                                    ),
                              const SizedBox(width: 16),
                              // Track details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _editedTrack.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _editedTrack.artistNames,
                                      style: const TextStyle(
                                        color: AppColors.mediumGray,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _editedTrack.album.name,
                                      style: const TextStyle(
                                        color: AppColors.mediumGray,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Time section controls
                      Text(
                        'Time Section',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Select the start and end times for this track in your playlist:',
                        style: TextStyle(color: AppColors.mediumGray),
                      ),
                      const SizedBox(height: 16),

                      // Start time slider
                      _buildTimeSlider(
                        label: 'Start Time',
                        value: _editedTrack.startTime,
                        min: 0,
                        max: _editedTrack.endTime,
                        displayValue: formatSecondsFromDouble(_editedTrack.startTime),
                        onChanged: (value) {
                          setState(() {
                            _editedTrack.startTime = value;
                            // Ensure start time is always less than end time
                            if (_editedTrack.startTime >= _editedTrack.endTime) {
                              _editedTrack.startTime = _editedTrack.endTime - 1.0;
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // End time slider
                      _buildTimeSlider(
                        label: 'End Time',
                        value: _editedTrack.endTime,
                        min: _editedTrack.startTime + 1.0,
                        max: _duration?.inSeconds.toDouble() ?? 30.0,
                        displayValue: formatSecondsFromDouble(_editedTrack.endTime),
                        onChanged: (value) {
                          setState(() {
                            _editedTrack.endTime = value;
                          });
                        },
                      ),
                      const SizedBox(height: 24),

                      // Fade controls
                      Text(
                        'Fades',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Add fade-in and fade-out effects to make transitions smoother:',
                        style: TextStyle(color: AppColors.mediumGray),
                      ),
                      const SizedBox(height: 16),

                      // Fade-in slider
                      _buildTimeSlider(
                        label: 'Fade In',
                        value: _editedTrack.fadeIn,
                        min: 0,
                        max: 10.0, // Max fade in of 10 seconds
                        displayValue: '${_editedTrack.fadeIn.toStringAsFixed(1)}s',
                        onChanged: (value) {
                          setState(() {
                            _editedTrack.fadeIn = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // Fade-out slider
                      _buildTimeSlider(
                        label: 'Fade Out',
                        value: _editedTrack.fadeOut,
                        min: 0,
                        max: 10.0, // Max fade out of 10 seconds
                        displayValue: '${_editedTrack.fadeOut.toStringAsFixed(1)}s',
                        onChanged: (value) {
                          setState(() {
                            _editedTrack.fadeOut = value;
                          });
                        },
                      ),
                      const SizedBox(height: 32),

                      // Preview controls
                      _buildPreviewPlayer(),
                      const SizedBox(height: 32),

                      // Save button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.add),
                          label: Text(widget.editIndex != null
                              ? 'UPDATE TRACK'
                              : 'ADD TO PLAYLIST'),
                          onPressed: _saveTrack,
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  // Build a time slider with label
  Widget _buildTimeSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required String displayValue,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Text(displayValue,
                style: const TextStyle(color: AppColors.spotifyGreen)),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: ((max - min) * 10).toInt(), // 0.1s increments
          onChanged: onChanged,
        ),
      ],
    );
  }

  // Build the preview player controls
  Widget _buildPreviewPlayer() {
    return Card(
      color: AppColors.darkGray,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Preview',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            // Progress bar
            LinearProgressIndicator(
              value: _duration != null && _duration!.inMilliseconds > 0
                  ? _position.inMilliseconds / _duration!.inMilliseconds
                  : 0.0,
              backgroundColor: AppColors.mediumGray,
              color: AppColors.spotifyGreen,
              minHeight: 4,
            ),
            const SizedBox(height: 8),
            // Time display
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(formatDurationFromDuration(_position)),
                Text(_duration != null
                    ? formatDurationFromDuration(_duration!)
                    : '0:00'),
              ],
            ),
            const SizedBox(height: 16),
            // Playback controls
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.replay_10),
                  onPressed: () {
                    final newPosition = _position - const Duration(seconds: 10);
                    _previewPlayer.seek(newPosition < Duration.zero
                        ? Duration.zero
                        : newPosition);
                  },
                ),
                IconButton(
                  icon: Icon(
                    _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                    color: AppColors.spotifyGreen,
                    size: 48,
                  ),
                  onPressed: () {
                    if (_isPlaying) {
                      _previewPlayer.pause();
                    } else {
                      _playPreview();
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.forward_10),
                  onPressed: () {
                    if (_duration != null) {
                      final newPosition = _position + const Duration(seconds: 10);
                      _previewPlayer.seek(newPosition > _duration!
                          ? _duration!
                          : newPosition);
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Save the track to the playlist
  void _saveTrack() {
    final playlistProvider =
        Provider.of<PlaylistProvider>(context, listen: false);

    if (widget.editIndex != null) {
      // Update existing track
      playlistProvider.updateTrack(widget.editIndex!, _editedTrack);
    } else {
      // Add new track
      playlistProvider.addTrack(_editedTrack);
    }

    // Stop playback before navigating
    _previewPlayer.stop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(widget.editIndex != null
            ? 'Track updated in playlist'
            : 'Track added to playlist'),
        backgroundColor: AppColors.spotifyGreen,
      ),
    );

    Navigator.pop(context);
  }
}