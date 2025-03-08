import 'track.dart';

class Playlist {
  String id;
  String name;
  String? spotifyId;
  String? description;
  List<Track> tracks;
  DateTime createdAt;
  
  Playlist({
    required this.id,
    required this.name,
    this.spotifyId,
    this.description,
    required this.tracks,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
  
  factory Playlist.empty() {
    return Playlist(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: 'My Custom Playlist',
      tracks: [],
    );
  }
  
  factory Playlist.fromJson(Map<String, dynamic> json) {
    return Playlist(
      id: json['id'],
      name: json['name'],
      spotifyId: json['spotify_id'],
      description: json['description'],
      tracks: (json['tracks'] as List).map((t) => Track.fromJson(t)).toList(),
      createdAt: DateTime.parse(json['created_at']),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'spotify_id': spotifyId,
      'description': description,
      'tracks': tracks.map((t) => t.toJson()).toList(),
      'created_at': createdAt.toIso8601String(),
    };
  }
  
  Playlist copyWith({
    String? id,
    String? name,
    String? spotifyId,
    String? description,
    List<Track>? tracks,
    DateTime? createdAt,
  }) {
    return Playlist(
      id: id ?? this.id,
      name: name ?? this.name,
      spotifyId: spotifyId ?? this.spotifyId,
      description: description ?? this.description,
      tracks: tracks ?? this.tracks,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}