class AudioPlayerConstants {

  static const int minCaseteSeconds = 8; // Minimum duration for casete session.
  static const int guestTrialDuration = 300; // 5 minutes in seconds
  static const int trialDuration = 3000; // 50 minutes in seconds
  static const int rewindSeconds = 5;
  static const int externalDuration = 30;

  static const List<String> musicLanguages = [
    'English',
    'Español',
    'French',
    'Deutsch',
    'Hindi',
    'Japanese',
    'Chinese',
    'Arabic',
    'Russian',
    'Portuguese',
    'Bengali',
    'Urdu',
    'Indonesian',
    'Italian',
    'Turkish',
    'Dutch',
    'Korean',
    'Polish',
    'Ukrainian',
    'Vietnamese',
  ];

  static const double miniPlayerHeight = 30;
  static const double miniPlayerWidth = 30;
  static const double audioPlayerHeight = 65;
  static const double audioPlayerWidth = 65;

  static const List<String> defaultControlButtons = ['Like', 'Play/Pause', 'Next'];
  static const List<String> defaultMiniButtonsOrder = ['Like', 'Previous', 'Play/Pause', 'Next'];
  static const List<String> defaultSpotifyButtons = ['Spotify', 'Play/Pause', 'Next'];
  static const List<int> preferredCompactNotificationButtons = [1, 2, 3];

}
