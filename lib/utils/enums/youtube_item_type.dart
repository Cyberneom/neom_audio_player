enum YoutubeItemType {
  artist('artist'),
  playlist('playlist'),
  song('song'),
  video('video'),
  album('album'),
  single('single');

  final String value;
  const YoutubeItemType(this.value);

}
