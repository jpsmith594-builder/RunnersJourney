import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config.dart';
import 'place.dart';

/// Finds towns anywhere in the world with the MapTiler geocoding API.
/// Needs MAPTILER_KEY; without it only the built-in South African list works.
class GeoSearch {
  static bool get enabled => AppConfig.mapTilerKey.isNotEmpty;

  static Future<List<Place>> search(String query, {int limit = 8}) async {
    final q = query.trim();
    if (!enabled || q.length < 2) return const [];
    try {
      final uri = Uri.https('api.maptiler.com', '/geocoding/${Uri.encodeComponent(q)}.json', {
        'key': AppConfig.mapTilerKey,
        'limit': '$limit',
        'autocomplete': 'true',
      });
      final res = await http.get(uri).timeout(const Duration(seconds: 6));
      if (res.statusCode != 200) return const [];
      return parseFeatures(jsonDecode(res.body) as Map<String, dynamic>);
    } catch (_) {
      return const [];
    }
  }

  /// Turns a geocoding response into places. Streets, shops and postcodes are
  /// skipped, because a race belongs to a town.
  static List<Place> parseFeatures(Map<String, dynamic> json) {
    const skip = {'address', 'poi', 'postal_code', 'country', 'region'};
    final out = <Place>[];
    for (final f in (json['features'] as List? ?? const [])) {
      final m = f as Map<String, dynamic>;
      final types = ((m['place_type'] as List?) ?? const []).cast<String>();
      if (types.any(skip.contains)) continue;
      final center = (m['center'] as List?)?.cast<num>();
      final name = (m['text'] as String?)?.trim();
      if (center == null || center.length < 2 || name == null || name.isEmpty) {
        continue;
      }
      var region = '';
      var country = '';
      for (final c in (m['context'] as List? ?? const [])) {
        final id = (c['id'] as String?) ?? '';
        final text = (c['text'] as String?) ?? '';
        if (id.startsWith('country') && country.isEmpty) country = text;
        if (id.startsWith('region') && region.isEmpty) region = text;
        if (id.startsWith('subregion') && region.isEmpty) region = text;
      }
      out.add(Place(name, region, center[1].toDouble(), center[0].toDouble(), 3,
          country: country));
    }
    return out;
  }
}
