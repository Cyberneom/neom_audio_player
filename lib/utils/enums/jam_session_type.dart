/// Type of Jam Session (collaborative listening room)
enum JamSessionType {
  /// Open session - anyone with link can join
  open('open', 'Open Session'),

  /// Private session - invite only
  private('private', 'Private Session'),

  /// Friends only - only friends can join
  friendsOnly('friends_only', 'Friends Only');

  final String value;
  final String displayName;

  const JamSessionType(this.value, this.displayName);
}

/// Role of a participant in a Jam Session
enum JamParticipantRole {
  /// Session host - full control
  host('host', 'Host'),

  /// Co-host - can add/remove songs, control playback
  coHost('co_host', 'Co-Host'),

  /// DJ - can add songs to queue
  dj('dj', 'DJ'),

  /// Listener - can only listen and vote
  listener('listener', 'Listener');

  final String value;
  final String displayName;

  const JamParticipantRole(this.value, this.displayName);

  bool get canControlPlayback => this == host || this == coHost;
  bool get canAddSongs => this != listener;
  bool get canRemoveSongs => this == host || this == coHost;
  bool get canKickUsers => this == host;
  bool get canPromoteUsers => this == host || this == coHost;
}

/// Status of a Jam Session
enum JamSessionStatus {
  /// Session is being created
  creating('creating'),

  /// Session is active and playing
  active('active'),

  /// Session is paused
  paused('paused'),

  /// Session has ended
  ended('ended');

  final String value;

  const JamSessionStatus(this.value);
}

/// Voting options for songs in Jam Session
enum JamVoteType {
  /// Upvote - want to hear this song
  upvote('upvote', 1),

  /// Downvote - skip this song
  downvote('downvote', -1),

  /// Super vote - really want to hear this (limited)
  superVote('super_vote', 3);

  final String value;
  final int weight;

  const JamVoteType(this.value, this.weight);
}
