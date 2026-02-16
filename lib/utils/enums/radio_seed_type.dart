/// Type of seed used to generate a radio station
enum RadioSeedType {
  /// Based on a specific song
  song('song', 'Based on this song'),

  /// Based on an artist
  artist('artist', 'Based on this artist'),

  /// Based on a genre
  genre('genre', 'Based on this genre'),

  /// Based on user's listening history
  personalMix('personal_mix', 'Your personal mix'),

  /// Based on mood/activity
  mood('mood', 'Based on mood'),

  /// Based on an album
  album('album', 'Based on this album'),

  /// Based on a playlist
  playlist('playlist', 'Based on this playlist'),

  /// Based on release year/decade
  decade('decade', 'From this era'),

  /// Discovery - new music for you
  discovery('discovery', 'Discover new music'),

  /// Similar to liked songs
  liked('liked', 'Based on your likes');

  final String value;
  final String displayName;

  const RadioSeedType(this.value, this.displayName);
}

/// Radio station mood/vibe
enum RadioMood {
  energetic('energetic', 'Energetic', 0.8),
  relaxed('relaxed', 'Relaxed', 0.3),
  happy('happy', 'Happy', 0.7),
  melancholic('melancholic', 'Melancholic', 0.4),
  focus('focus', 'Focus', 0.5),
  workout('workout', 'Workout', 0.9),
  party('party', 'Party', 0.85),
  sleep('sleep', 'Sleep', 0.1),
  romantic('romantic', 'Romantic', 0.5),
  chill('chill', 'Chill', 0.35);

  final String value;
  final String displayName;
  final double energyLevel;

  const RadioMood(this.value, this.displayName, this.energyLevel);
}
