/// Allowed urls. Enum is safer than strings.
enum Url {
  home('/'),
  login('/login'),
  setting('/setting'),
  splash('/splash'),
  ;

  final String url;
  const Url(this.url);
}
