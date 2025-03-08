import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/search_provider.dart';
import '../models/track.dart';
import '../utils/app_theme.dart';
import 'track_editor_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.removeListener(_onFocusChange);
    _searchFocusNode.dispose();
    super.dispose();
  }

  // Handle focus change to show/hide suggestions
  void _onFocusChange() {
    if (_searchFocusNode.hasFocus) {
      final query = _searchController.text.trim();
      if (query.isNotEmpty) {
        Provider.of<SearchProvider>(context, listen: false).getSuggestions(query);
      }
    } else {
      Provider.of<SearchProvider>(context, listen: false).clearSuggestions();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<SearchProvider>(
        builder: (context, searchProvider, _) {
          return Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                        decoration: InputDecoration(
                          hintText: 'Search for tracks...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                    searchProvider.clearSearchResults();
                                    searchProvider.clearSuggestions();
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: AppColors.darkGray,
                        ),
                        onChanged: (query) {
                          if (query.trim().isNotEmpty) {
                            searchProvider.getSuggestions(query);
                          } else {
                            searchProvider.clearSuggestions();
                          }
                        },
                        onSubmitted: (query) {
                          if (query.trim().isNotEmpty) {
                            searchProvider.searchTracks(query);
                            searchProvider.clearSuggestions();
                            _searchFocusNode.unfocus();
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        final query = _searchController.text.trim();
                        if (query.isNotEmpty) {
                          searchProvider.searchTracks(query);
                          searchProvider.clearSuggestions();
                          _searchFocusNode.unfocus();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        shape: const CircleBorder(),
                        padding: const EdgeInsets.all(12),
                      ),
                      child: const Icon(Icons.search),
                    ),
                  ],
                ),
              ),

              // Suggestions popup
              if (searchProvider.suggestions.isNotEmpty && _searchFocusNode.hasFocus)
                _buildSuggestionsList(searchProvider.suggestions),

              // Results or loading indicator
              Expanded(
                child: _buildSearchResults(searchProvider),
              ),
            ],
          );
        },
      ),
    );
  }

  // Build search results or loading indicator
  Widget _buildSearchResults(SearchProvider searchProvider) {
    if (searchProvider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.spotifyGreen,
        ),
      );
    }

    if (searchProvider.error != null) {
      return Center(
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
              'Error: ${searchProvider.error}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.errorRed),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                searchProvider.clearError();
                searchProvider.searchTracks(_searchController.text.trim());
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (searchProvider.searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.search,
              color: AppColors.mediumGray,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              searchProvider.searchQuery.isEmpty
                  ? 'Search for tracks to add to your playlist'
                  : 'No tracks found for "${searchProvider.searchQuery}"',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.mediumGray),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: searchProvider.searchResults.length,
      itemBuilder: (context, index) {
        final track = searchProvider.searchResults[index];
        return _buildTrackItem(track);
      },
    );
  }

  // Build suggestions list
  Widget _buildSuggestionsList(List<Track> suggestions) {
    return Container(
      color: AppColors.darkGray,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Suggestions header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Suggestions',
                  style: TextStyle(
                    color: AppColors.lightGray,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.lightGray),
                  onPressed: () {
                    Provider.of<SearchProvider>(context, listen: false)
                        .clearSuggestions();
                    _searchFocusNode.unfocus();
                  },
                ),
              ],
            ),
          ),
          // Suggestion items
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: suggestions.length > 5 ? 5 : suggestions.length,
            itemBuilder: (context, index) {
              final track = suggestions[index];
              return ListTile(
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
                  style: const TextStyle(color: AppColors.spotifyWhite),
                ),
                subtitle: Text(
                  track.artistNames,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.mediumGray),
                ),
                onTap: () {
                  _searchController.text = '${track.name} ${track.artistNames}';
                  Provider.of<SearchProvider>(context, listen: false)
                      .searchTracks(_searchController.text);
                  Provider.of<SearchProvider>(context, listen: false)
                      .clearSuggestions();
                  _searchFocusNode.unfocus();
                },
              );
            },
          ),
        ],
      ),
    );
  }

  // Build track item
  Widget _buildTrackItem(Track track) {
    return Card(
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TrackEditorScreen(track: track),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // Album art
              track.album.thumbnailUrl.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        track.album.thumbnailUrl,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: AppColors.darkGray,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.music_note, color: AppColors.mediumGray),
                    ),
              const SizedBox(width: 16),
              // Track info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      track.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      track.artistNames,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.mediumGray,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      track.album.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.mediumGray,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              // Add button
              IconButton(
                icon: const Icon(
                  Icons.edit,
                  color: AppColors.spotifyGreen,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TrackEditorScreen(track: track),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}