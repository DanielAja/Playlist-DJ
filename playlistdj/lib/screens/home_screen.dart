import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/playlist_provider.dart';
import '../utils/app_theme.dart';
import 'search_screen.dart';
import 'playlist_screen.dart';
import 'saved_playlists_screen.dart';

class HomeScreen extends StatefulWidget {
  final int initialTab;
  
  const HomeScreen({Key? key, this.initialTab = 0}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  
  // List of screens for the bottom navigation
  final List<Widget> _screens = const [
    PlaylistScreen(),
    SearchScreen(),
    SavedPlaylistsScreen(),
  ];
  
  @override
  void initState() {
    super.initState();
    // Set initial tab from widget parameter
    _currentIndex = widget.initialTab;
    
    // Initialize playlist provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PlaylistProvider>(context, listen: false).initialize();
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Playlist DJ'),
        actions: [
          // User profile button
          Consumer<AuthProvider>(
            builder: (context, authProvider, _) {
              return IconButton(
                icon: const Icon(Icons.person),
                onPressed: () {
                  _showUserProfileModal(context, authProvider);
                },
              );
            },
          ),
        ],
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        backgroundColor: AppColors.background,
        selectedItemColor: AppColors.spotifyGreen,
        unselectedItemColor: AppColors.mediumGray,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.playlist_play),
            label: 'Current Playlist',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.library_music),
            label: 'My Playlists',
          ),
        ],
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              backgroundColor: AppColors.spotifyGreen,
              child: const Icon(Icons.add),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SearchScreen()),
                );
              },
            )
          : null,
    );
  }
  
  // Show user profile modal
  void _showUserProfileModal(BuildContext context, AuthProvider authProvider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        final user = authProvider.currentUser;
        
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // User avatar
              if (user?.imageUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(50),
                  child: Image.network(
                    user!.imageUrl!,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                  ),
                )
              else
                const CircleAvatar(
                  radius: 40,
                  backgroundColor: AppColors.darkGray,
                  child: Icon(
                    Icons.person,
                    size: 40,
                    color: AppColors.spotifyWhite,
                  ),
                ),
              const SizedBox(height: 16),
              // Display name
              Text(
                user?.displayName ?? 'User',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              // Email
              Text(
                user?.email ?? '',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              // Account type
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: user?.isPremium == true
                      ? AppColors.spotifyGreen.withOpacity(0.2)
                      : AppColors.darkGray,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  user?.isPremium == true ? 'Premium' : 'Free',
                  style: TextStyle(
                    color: user?.isPremium == true
                        ? AppColors.spotifyGreen
                        : AppColors.lightGray,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Logout button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () async {
                    await authProvider.logout();
                    Navigator.pop(context);
                  },
                  child: const Text('LOGOUT'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}