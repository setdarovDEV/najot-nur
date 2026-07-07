import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import '../data/repositories.dart';
import '../providers/providers.dart';

/// Best-effort city detection: asks for location permission, reads the
/// device position and reverse-geocodes it to a city name on-device (no
/// server-side geocoding call needed), then saves it on the user's profile.
///
/// Every step is wrapped so a denied permission, disabled location service,
/// or unsupported platform (web) never blocks or breaks the app — it just
/// silently skips, exactly like [SecurityService]'s login-audio capture.
class LocationService {
  LocationService(this._authRepo);

  final AuthRepository _authRepo;

  bool _attempted = false;

  /// Call once after login (and again on cold start once the user is
  /// loaded). Idempotent per app session — city rarely changes mid-session,
  /// so we don't need to re-run this on every call.
  Future<void> captureCity() async {
    if (kIsWeb || _attempted) return;
    _attempted = true;
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        debugPrint('LocationService: location services disabled on device');
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        debugPrint('LocationService: permission denied ($permission)');
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
        ),
      );

      String? city;
      String? region;
      String? country;
      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          city = (p.locality?.isNotEmpty ?? false)
              ? p.locality
              : (p.subAdministrativeArea?.isNotEmpty ?? false)
                  ? p.subAdministrativeArea
                  : null;
          region = p.administrativeArea;
          country = p.country;
        }
      } catch (e) {
        debugPrint('LocationService: reverse geocoding failed ($e)');
      }

      await _authRepo.updateMe(
        city: city,
        region: region,
        country: country,
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } catch (e) {
      debugPrint('LocationService: captureCity failed ($e)');
    }
  }
}

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService(ref.watch(authRepositoryProvider));
});
