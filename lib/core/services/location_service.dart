import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationDataResult {
  final double latitude;
  final double longitude;
  final String address;

  LocationDataResult({
    required this.latitude,
    required this.longitude,
    required this.address,
  });
}

class LocationService {
  /// Fetches current GPS location or returns fallback location if permission denied
  Future<LocationDataResult> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return _getFallbackLocation('লোকেশন সার্ভিস সক্রিয় নয়');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return _getFallbackLocation('লোকেশন অনুমতি দেওয়া হয়নি');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return _getFallbackLocation('লোকেশন অনুমতি চিরতরে প্রত্যাখ্যাত');
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      );

      String address = 'মিরপুর, ঢাকা, বাংলাদেশ';
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          address = '${place.subLocality ?? place.locality ?? ''}, ${place.administrativeArea ?? 'ঢাকা'}';
        }
      } catch (_) {
        // Fallback address if reverse geocoding fails
      }

      return LocationDataResult(
        latitude: position.latitude,
        longitude: position.longitude,
        address: address.isEmpty ? 'ঢাকা, বাংলাদেশ' : address,
      );
    } catch (e) {
      return _getFallbackLocation('জিপিএস সিগন্যাল পাওয়া যায়নি');
    }
  }

  LocationDataResult _getFallbackLocation(String reason) {
    return LocationDataResult(
      latitude: 23.8103, // Mirpur 10, Dhaka coordinates
      longitude: 90.4125,
      address: 'মিরপুর ۱۰, ঢাকা (ডিফল্ট লোকেশন)',
    );
  }
}
