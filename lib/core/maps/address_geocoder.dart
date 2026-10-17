import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class ResolvedAddress {
  const ResolvedAddress({
    required this.address,
    required this.city,
    required this.state,
    required this.zip,
    required this.displayName,
  });

  final String address;
  final String city;
  final String state;
  final String zip;
  final String displayName;
}

abstract final class AddressGeocoder {
  static const _headers = {'User-Agent': 'HVACPro/1.0 (office-admin)'};
  static final Map<String, LatLng> _forwardCache = {};
  static final Map<String, ResolvedAddress> _reverseCache = {};

  static Future<LatLng?> lookup(String query) async {
    final text = query.trim();
    if (text.isEmpty) return null;
    final cached = _forwardCache[text];
    if (cached != null) return cached;

    final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
      'q': text,
      'format': 'json',
      'limit': '1',
    });
    final response = await http.get(uri, headers: _headers);
    if (response.statusCode != 200) return null;

    final rows = jsonDecode(response.body);
    if (rows is! List || rows.isEmpty) return null;
    final row = rows.first;
    if (row is! Map<String, dynamic>) return null;

    final lat = double.tryParse(row['lat']?.toString() ?? '');
    final lon = double.tryParse(row['lon']?.toString() ?? '');
    if (lat == null || lon == null) return null;

    final point = LatLng(lat, lon);
    _forwardCache[text] = point;
    return point;
  }

  static Future<ResolvedAddress?> reverse(LatLng point) async {
    final key = '${point.latitude.toStringAsFixed(5)},${point.longitude.toStringAsFixed(5)}';
    final cached = _reverseCache[key];
    if (cached != null) return cached;

    final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
      'lat': point.latitude.toString(),
      'lon': point.longitude.toString(),
      'format': 'json',
      'addressdetails': '1',
    });
    final response = await http.get(uri, headers: _headers);
    if (response.statusCode != 200) return null;

    final body = jsonDecode(response.body);
    if (body is! Map<String, dynamic>) return null;
    final resolved = _parseAddress(body);
    if (resolved != null) _reverseCache[key] = resolved;
    return resolved;
  }

  static ResolvedAddress? _parseAddress(Map<String, dynamic> body) {
    final displayName = body['display_name']?.toString() ?? '';
    final raw = body['address'];
    if (raw is! Map) {
      if (displayName.isEmpty) return null;
      return ResolvedAddress(
        address: displayName.split(',').first.trim(),
        city: '',
        state: '',
        zip: '',
        displayName: displayName,
      );
    }

    final house = raw['house_number']?.toString() ?? '';
    final road = raw['road']?.toString() ??
        raw['pedestrian']?.toString() ??
        raw['residential']?.toString() ??
        raw['neighbourhood']?.toString() ??
        '';
    var street = [house, road].where((part) => part.isNotEmpty).join(' ').trim();
    if (street.isEmpty && displayName.isNotEmpty) {
      street = displayName.split(',').first.trim();
    }

    final city = raw['city']?.toString() ??
        raw['town']?.toString() ??
        raw['village']?.toString() ??
        raw['county']?.toString() ??
        '';
    final state = raw['state']?.toString() ?? raw['region']?.toString() ?? '';
    final zip = raw['postcode']?.toString() ?? '';

    if (street.isEmpty && city.isEmpty) return null;
    return ResolvedAddress(
      address: street,
      city: city,
      state: state,
      zip: zip,
      displayName: displayName.isEmpty ? '$street, $city' : displayName,
    );
  }
}
