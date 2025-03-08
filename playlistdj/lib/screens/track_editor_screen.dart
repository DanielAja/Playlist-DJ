import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/track.dart';
import '../providers/playlist_provider.dart';
import '../utils/app_theme.dart';

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

  @override
  void initState() {
    super.initState();
    _editedTrack = Track(
      id: widget.track.id,
      name: widget.track.name,
      artists: widget.track.artists,
      album: widget.track.album,
      uri: widget.track.uri,
    );
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Track Info Card
            Card(
              margin: const EdgeInsets.only(bottom: 24),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    // Album artwork
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: _editedTrack.album.thumbnailUrl.isNotEmpty
                          ? Image.network(
                              _editedTrack.album.thumbnailUrl,
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              width: 80,
                              height: 80,
                              color: AppColors.darkGray,
                              child: const Icon(Icons.music_note, size: 40),
                            ),
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
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _editedTrack.artistNames,
                            style: const TextStyle(
                              color: AppColors.mediumGray,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _editedTrack.album.name,
                            style: const TextStyle(
                              color: AppColors.mediumGray,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            Center(
              child: Text(
                'Track details saved to playlist',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.spotifyGreen,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _saveTrack() {
    // Get the playlist provider
    final playlistProvider = Provider.of<PlaylistProvider>(context, listen: false);
    
    // If we're editing an existing track
    if (widget.editIndex != null) {
      playlistProvider.updateTrack(widget.editIndex!, _editedTrack);
    } else {
      // Adding a new track
      playlistProvider.addTrack(_editedTrack);
    }
    
    // Go back to playlist screen
    Navigator.pop(context);
  }
}