import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/playlist_provider.dart';
import '../providers/player_provider.dart';
import '../utils/app_theme.dart';

class SavedPlaylistsScreen extends StatefulWidget {
  const SavedPlaylistsScreen({Key? key}) : super(key: key);

  @override
  State<SavedPlaylistsScreen> createState() => _SavedPlaylistsScreenState();
}

class _SavedPlaylistsScreenState extends State<SavedPlaylistsScreen> {
  @override
  void initState() {
    super.initState();
    // Load the saved playlists
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PlaylistProvider>(context, listen: false).loadSavedPlaylists();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PlaylistProvider>(
      builder: (context, playlistProvider, _) {
        final savedPlaylists = playlistProvider.savedPlaylists;
        
        if (playlistProvider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        
        if (savedPlaylists.isEmpty) {
          return _buildEmptyState();
        }
        
        return Scaffold(
          body: RefreshIndicator(
            onRefresh: () => playlistProvider.loadSavedPlaylists(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: savedPlaylists.length,
              itemBuilder: (context, index) {
                final playlist = savedPlaylists[index];
                final dateFormat = DateFormat.yMMMd();
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 16.0),
                  child: InkWell(
                    onTap: () {
                      _showPlaylistOptions(context, playlist, playlistProvider);
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      playlist.name,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Created: ${dateFormat.format(playlist.createdAt)}',
                                      style: const TextStyle(
                                        color: AppColors.mediumGray,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Spotify icon if available on Spotify
                              if (playlist.spotifyId != null)
                                const Tooltip(
                                  message: 'Available on Spotify',
                                  child: Icon(
                                    Icons.public,
                                    color: AppColors.spotifyGreen,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
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
                                  // Play button
                                  IconButton(
                                    icon: const Icon(
                                      Icons.play_circle_outline,
                                      color: AppColors.spotifyGreen,
                                    ),
                                    onPressed: () {
                                      Provider.of<PlayerProvider>(context, listen: false)
                                          .playPlaylist(playlist);
                                    },
                                  ),
                                  // Edit button
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined),
                                    onPressed: () {
                                      playlistProvider.loadPlaylist(playlist.id);
                                      // Navigate to playlist tab
                                      DefaultTabController.of(context)?.animateTo(0);
                                    },
                                  ),
                                  // Delete button
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline),
                                    onPressed: () {
                                      _showDeleteConfirmation(context, playlist, playlistProvider);
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          floatingActionButton: FloatingActionButton(
            backgroundColor: AppColors.spotifyGreen,
            child: const Icon(Icons.add),
            onPressed: () {
              playlistProvider.createNewPlaylist();
              // Navigate to playlist tab
              DefaultTabController.of(context)?.animateTo(0);
            },
          ),
        );
      },
    );
  }

  // Build the empty state widget
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.library_music,
            size: 64,
            color: AppColors.mediumGray,
          ),
          const SizedBox(height: 16),
          const Text(
            'No saved playlists',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Create a playlist and save it to see it here',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.mediumGray),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('CREATE NEW PLAYLIST'),
            onPressed: () {
              Provider.of<PlaylistProvider>(context, listen: false).createNewPlaylist();
              // Navigate to playlist tab
              DefaultTabController.of(context)?.animateTo(0);
            },
          ),
        ],
      ),
    );
  }

  // Show playlist options
  void _showPlaylistOptions(
    BuildContext context, 
    playlist, 
    PlaylistProvider playlistProvider
  ) {
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
              Text(
                playlist.name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              if (playlist.description != null && playlist.description!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    playlist.description!,
                    style: const TextStyle(color: AppColors.mediumGray),
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 24),
              
              // Play
              ListTile(
                leading: const Icon(Icons.play_arrow, color: AppColors.spotifyGreen),
                title: const Text('Play'),
                onTap: () {
                  Navigator.pop(context);
                  Provider.of<PlayerProvider>(context, listen: false)
                      .playPlaylist(playlist);
                },
              ),
              
              // Edit
              ListTile(
                leading: const Icon(Icons.edit, color: AppColors.spotifyGreen),
                title: const Text('Edit'),
                onTap: () {
                  Navigator.pop(context);
                  playlistProvider.loadPlaylist(playlist.id);
                  // Navigate to playlist tab
                  DefaultTabController.of(context)?.animateTo(0);
                },
              ),
              
              // Duplicate
              ListTile(
                leading: const Icon(Icons.content_copy, color: AppColors.spotifyGreen),
                title: const Text('Duplicate'),
                onTap: () async {
                  Navigator.pop(context);
                  // Create a copy with a new ID and "-copy" appended to the name
                  final copy = playlist.copyWith(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: '${playlist.name} (copy)',
                    createdAt: DateTime.now(),
                  );
                  
                  await playlistProvider.savePlaylist(copy);
                  await playlistProvider.loadSavedPlaylists();
                  
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Playlist duplicated'),
                        backgroundColor: AppColors.spotifyGreen,
                      ),
                    );
                  }
                },
              ),
              
              // Export
              ListTile(
                leading: const Icon(Icons.download, color: AppColors.spotifyGreen),
                title: const Text('Export'),
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
              
              // Delete
              ListTile(
                leading: const Icon(Icons.delete, color: AppColors.errorRed),
                title: const Text('Delete'),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmation(context, playlist, playlistProvider);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Show delete confirmation
  void _showDeleteConfirmation(
    BuildContext context, 
    playlist, 
    PlaylistProvider playlistProvider
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Playlist'),
        content: Text(
          'Are you sure you want to delete "${playlist.name}"? This action cannot be undone.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await playlistProvider.deletePlaylist(playlist.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Playlist deleted'),
                    backgroundColor: AppColors.spotifyGreen,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.errorRed),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
  }
}