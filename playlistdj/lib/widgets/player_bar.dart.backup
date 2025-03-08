import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/player_provider.dart';
import '../utils/app_theme.dart';
import '../utils/format_utils.dart';

class PlayerBar extends StatelessWidget {
  const PlayerBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerProvider>(
      builder: (context, playerProvider, _) {
        final track = playerProvider.currentTrack;
        
        // If no track is playing, don't show the player bar
        if (track == null) {
          return const SizedBox.shrink();
        }
        
        return Container(
          color: AppColors.cardBackground,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Progress bar
              LinearProgressIndicator(
                value: playerProvider.progress,
                backgroundColor: AppColors.darkGray,
                color: AppColors.spotifyGreen,
                minHeight: 2,
              ),
              
              // Track info and controls
              Row(
                children: [
                  // Album art
                  track.album.thumbnailUrl.isNotEmpty
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
                          color: AppColors.darkGray,
                          child: const Icon(Icons.music_note, color: AppColors.mediumGray),
                        ),
                  const SizedBox(width: 12),
                  
                  // Track info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          track.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          track.artistNames,
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
                  
                  // Controls
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Previous button
                      IconButton(
                        icon: const Icon(Icons.skip_previous),
                        iconSize: 24,
                        onPressed: playerProvider.playPreviousTrack,
                      ),
                      
                      // Play/Pause button
                      IconButton(
                        icon: Icon(
                          playerProvider.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                          color: AppColors.spotifyGreen,
                        ),
                        iconSize: 36,
                        onPressed: playerProvider.togglePlayPause,
                      ),
                      
                      // Next button
                      IconButton(
                        icon: const Icon(Icons.skip_next),
                        iconSize: 24,
                        onPressed: playerProvider.playNextTrack,
                      ),
                    ],
                  ),
                ],
              ),
              
              // Time display
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      formatDurationFromDuration(playerProvider.position),
                      style: const TextStyle(
                        color: AppColors.mediumGray,
                        fontSize: 10,
                      ),
                    ),
                    Text(
                      playerProvider.duration != null
                          ? formatDurationFromDuration(playerProvider.duration!)
                          : '0:00',
                      style: const TextStyle(
                        color: AppColors.mediumGray,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}