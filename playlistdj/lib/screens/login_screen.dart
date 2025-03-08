import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/app_theme.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo or app title
                  const Icon(
                    Icons.music_note,
                    size: 80,
                    color: AppColors.spotifyGreen,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Playlist DJ',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create custom playlists with custom time sections and fades',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 48),
                  // Login button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: authProvider.isLoading
                          ? null
                          : () async {
                              final success = await authProvider.login();
                              if (!success && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(authProvider.error ?? 'Login failed'),
                                    backgroundColor: AppColors.errorRed,
                                  ),
                                );
                              }
                            },
                      child: authProvider.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: AppColors.spotifyWhite,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('LOGIN WITH SPOTIFY'),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Error message
                  if (authProvider.error != null)
                    Text(
                      authProvider.error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.errorRed,
                        fontSize: 14,
                      ),
                    ),
                  const SizedBox(height: 48),
                  // Footer text
                  const Text(
                    'Note: Premium Spotify account required for full track playback',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.mediumGray,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}