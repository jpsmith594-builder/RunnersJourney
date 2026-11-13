import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'country_names.dart';
import 'place.dart';

/// Lower-cases and strips accents, so "zurich" finds "Zürich".
String foldName(String s) {
  final b = StringBuffer();
  for (final r in s.toLowerCase().runes) {
    final c = String.fromCharCode(r);
    b.write(_fold[c] ?? c);
  }
  return b.toString();
}

const _fold = {
  'à': 'a', 'á': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a', 'å': 'a', 'ā': 'a',
  'ă': 'a', 'ą': 'a', 'æ': 'ae', 'ç': 'c', 'ć': 'c', 'č': 'c', 'ď': 'd',
  'đ': 'd', 'è': 'e', 'é': 'e', 'ê': 'e', 'ë': 'e', 'ē': 'e', 'ė': 'e',
  'ę': 'e', 'ě': 'e', 'ğ': 'g', 'ì': 'i', 'í': 'i', 'î': 'i', 'ï': 'i',
  'ī': 'i', 'ı': 'i', 'ł': 'l', 'ĺ': 'l', 'ľ': 'l', 'ñ': 'n', 'ń': 'n',
  'ň': 'n', 'ò': 'o', 'ó': 'o', 'ô': 'o', 'õ': 'o', 'ö': 'o', 'ø': 'o',
  'ō': 'o', 'ő': 'o', 'œ': 'oe', 'ŕ': 'r', 'ř': 'r', 'ś': 's', 'š': 's',
  'ş': 's', 'ș': 's', 'ß': 'ss', 'ť': 't', 'ţ': 't', 'ț': 't', 'ù': 'u',
  'ú': 'u', 'û': 'u', 'ü': 'u', 'ū': 'u', 'ů': 'u', 'ű': 'u', 'ý': 'y',
  'ÿ': 'y', 'ź': 'z', 'ż': 'z', 'ž': 'z', '’': "'", '-': ' ',
};

const _zaProvinces = {
  '05': 'Eastern Cape',
  '03': 'Free State',
  '06': 'Gauteng',
  '02': 'KwaZulu-Natal',
  '09': 'Limpopo',
  '07': 'Mpumalanga',
  '10': 'North West',
  '08': 'Northern Cape',
  '11': 'Western Cape',
};

const _gbParts = {
  'ENG': 'England',
  'SCT': 'Scotland',
  'WLS': 'Wales',
  'NIR': 'Northern Ireland',
};

/// A searchable list of towns from around the world (GeoNames, CC BY 4.0),
/// biggest first. Searching runs on the phone: free, instant and private.
class WorldIndex {
  final List<String> _name = [];
  final List<String> _folded = [];
  final List<String> _cc = [];
  final List<String> _admin = [];
  final List<double> _lat = [];
  final List<double> _lng = [];
  final List<int> _pop = [];

  /// Parses lines of `name|country|admin|lat|lng|population`.
  WorldIndex.fromCsv(String csv) {
    for (final line in csv.split('\n')) {
      if (line.isEmpty) continue;
      final f = line.split('|');
      if (f.length < 6) continue;
      final lat = double.tryParse(f[3]);
      final lng = double.tryParse(f[4]);
      if (lat == null || lng == null) continue;
      _name.add(f[0]);
      _folded.add(foldName(f[0]));
      _cc.add(f[1]);
      _admin.add(f[2]);
      _lat.add(lat);
      _lng.add(lng);
      _pop.add(int.tryParse(f[5]) ?? 0);
    }
  }

  int get length => _name.length;

  String _province(int i) {
    final cc = _cc[i], a = _admin[i];
    if (cc == 'ZA') return _zaProvinces[a] ?? '';
    if (cc == 'GB') return _gbParts[a] ?? '';
    if (cc == 'US' && RegExp(r'^[A-Z]{2}$').hasMatch(a)) return a;
    return '';
  }

  Place _place(int i) => Place(_name[i], _province(i), _lat[i], _lng[i], 3,
      country: kCountryNames[_cc[i]] ?? _cc[i]);

  /// Towns whose name starts with, or has a word starting with, [query].
  /// Exact names first, then names that start with it, then later words;
  /// bigger towns first within each group, and South African towns a little
  /// ahead of equal matches elsewhere.
  List<Place> search(String query, {int limit = 6, String homeCountry = 'ZA'}) {
    final q = foldName(query.trim());
    if (q.length < 2) return const [];
    final hits = <(int rank, int i)>[];
    for (var i = 0; i < _folded.length; i++) {
      final n = _folded[i];
      int rank;
      if (n == q) {
        rank = 0;
      } else if (n.startsWith(q)) {
        rank = 1;
      } else if (n.contains(' $q')) {
        rank = 2;
      } else {
        continue;
      }
      hits.add((rank, i));
    }
    int score(int rank, int i) =>
        rank * 1000000000 -
        (_pop[i] + (_cc[i] == homeCountry ? 2000000 : 0)).clamp(0, 999999999);
    hits.sort((a, b) => score(a.$1, a.$2).compareTo(score(b.$1, b.$2)));
    return [for (final h in hits.take(limit)) _place(h.$2)];
  }
}

/// The app's copy of the world list, loaded the first time it is needed.
class WorldPlaces {
  static Future<WorldIndex>? _index;

  static Future<WorldIndex> _load() async {
    final csv = await rootBundle.loadString('assets/places/world.csv');
    return compute(_parse, csv);
  }

  static WorldIndex _parse(String csv) => WorldIndex.fromCsv(csv);

  /// Starts loading in the background, so the first search is quick.
  static void warmUp() => _index ??= _load();

  static Future<List<Place>> search(String query, {int limit = 6}) async {
    try {
      final index = await (_index ??= _load());
      return index.search(query, limit: limit);
    } catch (_) {
      _index = null;
      return const [];
    }
  }
}
