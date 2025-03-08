class Track {
  final String id;
  final String name;
  final List<Artist> artists;
  final Album album;
  final String uri;
  final String previewUrl;
  double startTime;
  double endTime;
  double fadeIn;
  double fadeOut;

  Track({
    required this.id,
    required this.name,
    required this.artists,
    required this.album,
    required this.uri,
    required this.previewUrl,
    this.startTime = 0.0,
    this.endTime = 30.0, // Default preview length
    this.fadeIn = 0.0,
    this.fadeOut = 0.0,
  });

  factory Track.fromJson(Map<String, dynamic> json) {
    return Track(
      id: json['id'],
      name: json['name'],
      artists: (json['artists'] as List).map((a) => Artist.fromJson(a)).toList(),
      album: Album.fromJson(json['album']),
      uri: json['uri'],
      previewUrl: json['preview_url'] ?? '',
      startTime: json['start_time']?.toDouble() ?? 0.0,
      endTime: json['end_time']?.toDouble() ?? 30.0,
      fadeIn: json['fade_in']?.toDouble() ?? 0.0,
      fadeOut: json['fade_out']?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'artists': artists.map((a) => a.toJson()).toList(),
      'album': album.toJson(),
      'uri': uri,
      'preview_url': previewUrl,
      'start_time': startTime,
      'end_time': endTime,
      'fade_in': fadeIn,
      'fade_out': fadeOut,
    };
  }

  // Helper method to get primary artist name
  String get artistNames => artists.map((a) => a.name).join(', ');
}

class Artist {
  final String id;
  final String name;

  Artist({required this.id, required this.name});

  factory Artist.fromJson(Map<String, dynamic> json) {
    return Artist(
      id: json['id'],
      name: json['name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}

class Album {
  final String id;
  final String name;
  final List<String> images;

  Album({required this.id, required this.name, required this.images});

  factory Album.fromJson(Map<String, dynamic> json) {
    final images = (json['images'] as List?)
          ?.map((img) => img['url'] as String)
          .toList() ??
        [];
        
    return Album(
      id: json['id'],
      name: json['name'],
      images: images,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'images': images,
    };
  }

  String get thumbnailUrl {
    // Return smallest image or empty string
    return images.isNotEmpty ? images.last : '';
  }

  String get largeImageUrl {
    // Return largest image or empty string
    return images.isNotEmpty ? images.first : '';
  }
}