import 'package:flutter_test/flutter_test.dart';
import 'package:notiqai/models/app_version.dart';

void main() {
  AppVersionConfig cfg({
    String latest = '2.0.0',
    String min = '1.5.0',
    bool force = false,
  }) =>
      AppVersionConfig(
        latestVersion: latest,
        minSupportedVersion: min,
        forceUpdate: force,
        updateUrl: 'u',
      );

  test('old version below min → forced', () {
    final c = cfg();
    expect(c.requiresUpdate('1.0.0+5'), isTrue);
    expect(c.hasOptionalUpdate('1.0.0+5'), isFalse);
  });

  test('supported but older than latest → optional only', () {
    final c = cfg();
    expect(c.requiresUpdate('1.6.0+10'), isFalse);
    expect(c.hasOptionalUpdate('1.6.0+10'), isTrue);
  });

  test('up to date → no update at all', () {
    final c = cfg();
    expect(c.requiresUpdate('2.0.0+1'), isFalse);
    expect(c.hasOptionalUpdate('2.0.0+1'), isFalse);
  });

  test('force_update flag overrides everything', () {
    final c = cfg(force: true);
    expect(c.requiresUpdate('1.0.0+5'), isTrue);
    expect(c.hasOptionalUpdate('1.0.0+5'), isFalse);
  });

  test('semver compare is numeric, not lexical', () {
    final c = cfg(latest: '1.10.0', min: '1.9.0');
    expect(c.requiresUpdate('1.9.0+1'), isFalse);
    expect(c.hasOptionalUpdate('1.9.0+1'), isTrue);
    expect(c.requiresUpdate('1.10.0+1'), isFalse);
    expect(c.hasOptionalUpdate('1.10.0+1'), isFalse);
  });

  test('handles missing patch segment', () {
    final c = cfg(min: '1.0');
    expect(c.requiresUpdate('1.0.0+1'), isFalse);
    expect(c.requiresUpdate('0.9.9+1'), isTrue);
  });
}
