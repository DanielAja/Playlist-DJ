import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/playlist_provider.dart';
import '../providers/auth_provider.dart';
import '../utils/app_theme.dart';
import '../utils/format_utils.dart';
import 'track_editor_screen.dart';

class PlaylistScreen extends StatefulWidget {
  const PlaylistScreen({Key? key}) : super(key: key);

  @override
  State<PlaylistScreen> createState() => _PlaylistScreenState();
}

class _PlaylistScreenState extends State<PlaylistScreen> {
  final _playlistNameController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final playlist = Provider.of<PlaylistProvider>(context, listen: false).currentPlaylist;
      _playlistNameController.text = playlist.name;
      _descriptionController.text = playlist.description ?? '';
    });
  }

  @override
  void dispose() {
    _playlistNameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PlaylistProvider>(
      builder: (context, playlistProvider, _) {
        final playlist = playlistProvider.currentPlaylist;
        
        return Scaffold(
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Playlist info card
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Playlist name field
                        TextField(
                          controller: _playlistNameController,
                          decoration: const InputDecoration(
                            labelText: 'Playlist Name',
                            hintText: 'Enter playlist name',
                          ),
                          onChanged: (value) {
                            playlistProvider.updatePlaylistName(value);
                          },
                        ),
                        const SizedBox(height: 8),
                        // Description field (optional)
                        TextField(
                          controller: _descriptionController,
                          decoration: const InputDecoration(
                            labelText: 'Description (optional)',
                            hintText: 'Add a description',
                          ),
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Track count and controls
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${playlist.tracks.length} tracks',
                      style: const TextStyle(
                        color: AppColors.mediumGray,
                      ),
                    ),
                    Row(
                      children: [
                        // Save button
                        ElevatedButton.icon(
                          icon: const Icon(Icons.save),
                          label: const Text('Save'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                          onPressed: playlist.tracks.isEmpty
                              ? null
                              : () {
                                  _showSaveOptions(context, playlistProvider);
                                },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Playlist tracks
              Expanded(
                child: playlist.tracks.isEmpty
                    ? _buildEmptyPlaylist()
                    : _buildTracksList(playlist, playlistProvider),
              ),
            ],
          ),
        );
      },
    );
  }

  // Build empty playlist placeholder
  Widget _buildEmptyPlaylist() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.playlist_add,
            size: 64,
            color: AppColors.mediumGray,
          ),
          const SizedBox(height: 16),
          const Text(
            'Your playlist is empty',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Search for tracks to add to your playlist',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.mediumGray),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.search),
            label: const Text('SEARCH TRACKS'),
            onPressed: () {
              // Navigate to search tab
              DefaultTabController.of(context)?.animateTo(1);
            },
          ),
        ],
      ),
    );
  }

  // Build tracks list
  Widget _buildTracksList(
    playlist, 
    PlaylistProvider playlistProvider
  ) {
    return ReorderableListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: playlist.tracks.length,
      onReorder: (oldIndex, newIndex) {
        setState(() {
          if (newIndex > oldIndex) {
            newIndex -= 1;
          }
          final track = playlist.tracks.removeAt(oldIndex);
          playlist.tracks.insert(newIndex, track);
        });
      },
      itemBuilder: (context, index) {
        final track = playlist.tracks[index];
        
        return Card(
          key: Key('track_$index'),
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
          child: ListTile(
            leading: track.album.thumbnailUrl.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.network(
                      track.album.thumbnailUrl,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                    ),
                  )
                : Container(
                    width: 40,
                    height: 40,
                    color: AppColors.mediumGray,
                    child: const Icon(Icons.music_note, color: AppColors.darkGray),
                  ),
            title: Text(
              track.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.normal,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  track.artistNames,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Added to playlist',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.mediumGray,
                  ),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // View button
                IconButton(
                  icon: const Icon(Icons.visibility),
                  onPressed: () {
                    Navigator.push(
                      context, 
                      MaterialPageRoute(
                        builder: (context) => TrackEditorScreen(
                          track: track,
                          editIndex: index,
                        ),
                      ),
                    );
                  },
                ),
                // Edit button
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TrackEditorScreen(
                          track: track,
                          editIndex: index,
                        ),
                      ),
                    );
                  },
                ),
                // Remove button
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () {
                    _showDeleteConfirmation(context, index, playlistProvider);
                  },
                ),
              ],
            ),
            isThreeLine: true,
            onTap: () {
              // Navigate to track editor
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TrackEditorScreen(
                    track: track,
                    editIndex: index,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // Show delete confirmation
  void _showDeleteConfirmation(
    BuildContext context, 
    int index, 
    PlaylistProvider playlistProvider
  ) {
    final track = playlistProvider.currentPlaylist.tracks[index];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Track'),
        content: Text(
          'Are you sure you want to remove "${track.name}" from your playlist?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              playlistProvider.removeTrack(index);
              Navigator.pop(context);
            },
            child: const Text('REMOVE'),
          ),
        ],
      ),
    );
  }

  // Show save options
  void _showSaveOptions(BuildContext context, PlaylistProvider playlistProvider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Save Options',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              
              // Save locally
              ListTile(
                leading: const Icon(Icons.save, color: AppColors.spotifyGreen),
                title: const Text('Save locally'),
                subtitle: const Text('Save the playlist to your device'),
                onTap: () async {
                  Navigator.pop(context);
                  await playlistProvider.saveCurrentPlaylist();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Playlist saved'),
                        backgroundColor: AppColors.spotifyGreen,
                      ),
                    );
                  }
                },
              ),
              
              // Save to Spotify
              Consumer<AuthProvider>(
                builder: (context, authProvider, _) {
                  return ListTile(
                    leading: const Icon(Icons.cloud_upload, color: AppColors.spotifyGreen),
                    title: const Text('Save to Spotify'),
                    subtitle: const Text(
                      'Upload the playlist to your Spotify account',
                    ),
                    enabled: authProvider.isAuthenticated,
                    onTap: authProvider.isAuthenticated
                        ? () async {
                            Navigator.pop(context);
                            final success = await playlistProvider.saveToSpotify(
                              authProvider.currentUser!,
                            );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    success
                                        ? 'Playlist saved to Spotify'
                                        : 'Failed to save to Spotify: ${playlistProvider.error}',
                                  ),
                                  backgroundColor: success
                                      ? AppColors.spotifyGreen
                                      : AppColors.errorRed,
                                ),
                              );
                            }
                          }
                        : null,
                  );
                },
              ),
              
              // Export to file
              ListTile(
                leading: const Icon(Icons.file_download, color: AppColors.spotifyGreen),
                title: const Text('Export to file'),
                subtitle: const Text('Export as a JSON file'),
                onTap: () async {
                  Navigator.pop(context);
                  final filePath = await playlistProvider.exportPlaylist();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          filePath != null
                              ? 'Playlist exported to $filePath'
                              : 'Failed to export playlist: ${playlistProvider.error}',
                        ),
                        backgroundColor: filePath != null
                            ? AppColors.spotifyGreen
                            : AppColors.errorRed,
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }
}