import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter/foundation.dart';

class LocationService {
  Future<String?> getCurrentLocationName() async {
    try {
      // 1. Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      // 2. Check permission status - DO NOT request permission here to avoid blocking main() thread startup!
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        debugPrint("Location permission not granted. Returning null.");
        return null;
      }
      LocationSettings locationSettings = const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      );
      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(locationSettings: locationSettings);
      } catch (e) {
        debugPrint("Fresh location request failed/timed out: $e");
        return null;
      }      // 6. Log the actual GPS coordinates retrieved
      debugPrint("📍 LocationService GPS: Lat: ${position.latitude}, Lng: ${position.longitude}");

      // 7. Reverse geocode coordinates to human-readable address
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        String locality = place.locality ?? "";
        String subLocality = place.subLocality ?? "";
        String administrativeArea = place.administrativeArea ?? "";

        if (subLocality.isNotEmpty && locality.isNotEmpty) {
          return "$subLocality, $locality";
        } else if (locality.isNotEmpty) {
          return "$locality, $administrativeArea";
        } else {
          return place.name;
        }
      }

      return null;
    } catch (e) {
      debugPrint("⚠️ Location Tracking Error: $e");
      return null;
    }
  }
}
