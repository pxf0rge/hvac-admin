import 'package:latlong2/latlong.dart';

abstract final class MapCoordinates {
  static bool isValid(double latitude, double longitude) {
    if (latitude == 0 && longitude == 0) return false;
    if (latitude < -90 || latitude > 90) return false;
    if (longitude < -180 || longitude > 180) return false;
    return true;
  }

  static LatLng? fromNullable(double latitude, double longitude) {
    return isValid(latitude, longitude) ? LatLng(latitude, longitude) : null;
  }

  static List<LatLng> fromPoints(Iterable<LatLng?> points) {
    return [for (final point in points) if (point != null) point];
  }
}
