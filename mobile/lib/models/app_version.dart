/// Backend-driven mobile app version config.
///
/// The server exposes these via `GET /api/v1/app/version` and the client
/// uses them on launch to decide whether to show a forced-update dialog.
/// Values are non-sensitive — the Play Store URL is public anyway.
class AppVersionConfig {
  const AppVersionConfig({
    required this.latestVersion,
    required this.minSupportedVersion,
    required this.forceUpdate,
    required this.updateUrl,
    this.message = '',
  });

  factory AppVersionConfig.fromJson(Map<String, dynamic> json) =>
      AppVersionConfig(
        latestVersion: (json['latest_version'] as String?) ?? '0.0.0',
        minSupportedVersion:
            (json['min_supported_version'] as String?) ?? '0.0.0',
        forceUpdate: json['force_update'] as bool? ?? false,
        updateUrl: (json['update_url'] as String?) ?? '',
        message: (json['message'] as String?) ?? '',
      );

  /// Newest build that's live on the Play Store (e.g. "1.2.0").
  final String latestVersion;

  /// Oldest build the server is willing to serve. Anything below this
  /// gets a non-dismissible update dialog.
  final String minSupportedVersion;

  /// Global kill switch — when true, every active build is told to
  /// update regardless of [minSupportedVersion].
  final bool forceUpdate;

  /// Play Store URL the dialog opens when the user taps "Update".
  final String updateUrl;

  /// Optional server-provided, already-localised message to show
  /// inside the dialog.
  final String message;

  /// Returns true when [current] (e.g. "1.0.0+5") is below the minimum
  /// supported version OR the server is forcing everyone to update.
  ///
  /// Trailing `+buildNumber` is stripped before comparison so the
  /// `package_info_plus` format ("1.0.0+5") compares against a pure
  /// semver ("1.0.0").
  bool requiresUpdate(String current) {
    if (forceUpdate) return true;
    final bare = current.split('+').first;
    return _compareVersions(bare, minSupportedVersion) < 0;
  }

  /// True when [current] is on a supported build but a newer one is
  /// available. This is a *soft* prompt — the user can dismiss it.
  /// Forced updates ([forceUpdate] or below [minSupportedVersion]) are
  /// never considered optional.
  bool hasOptionalUpdate(String current) {
    if (requiresUpdate(current)) return false;
    final bare = current.split('+').first;
    return _compareVersions(bare, latestVersion) < 0;
  }

  /// Compares two dot-separated version strings ("1.2.3" < "1.10.0").
  /// Returns negative if [a] < [b], zero if equal, positive if [a] > [b].
  /// Missing segments default to 0 so "1.2" == "1.2.0".
  static int _compareVersions(String a, String b) {
    final pa = a.split('.').map(int.tryParse).toList();
    final pb = b.split('.').map(int.tryParse).toList();
    final len = pa.length > pb.length ? pa.length : pb.length;
    for (var i = 0; i < len; i++) {
      final na = i < pa.length ? (pa[i] ?? 0) : 0;
      final nb = i < pb.length ? (pb[i] ?? 0) : 0;
      if (na != nb) return na - nb;
    }
    return 0;
  }
}
