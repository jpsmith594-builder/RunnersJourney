import 'dart:convert';
import 'dart:math' as math;

/// Applies a 4 x 5 colour matrix (the same one the flutter_map filter uses) to
/// every colour in a MapLibre style, so season and vivid colours can be baked
/// into the vector map. Part of the OpenFreeMap spike.
String recolourStyle(String styleJson, List<double> m) {
  final style = jsonDecode(styleJson) as Map<String, dynamic>;
  final layers = style['layers'];
  if (layers is List) {
    for (final layer in layers) {
      if (layer is! Map<String, dynamic>) continue;
      final paint = layer['paint'];
      if (paint is! Map<String, dynamic>) continue;
      for (final key in paint.keys.toList()) {
        if (key.endsWith('color')) {
          paint[key] = _walk(paint[key], m);
        }
      }
    }
  }
  return jsonEncode(style);
}

dynamic _walk(dynamic v, List<double> m) {
  if (v is String) {
    final c = parseCssColour(v);
    return c == null ? v : _format(_apply(c, m));
  }
  if (v is List) return v.map((e) => _walk(e, m)).toList();
  if (v is Map<String, dynamic>) {
    return v.map((k, e) => MapEntry(k, _walk(e, m)));
  }
  return v;
}

/// red, green, blue (0 to 255) and alpha (0 to 1).
class Rgba {
  final double r, g, b, a;
  const Rgba(this.r, this.g, this.b, this.a);
}

Rgba _apply(Rgba c, List<double> m) {
  double ch(int row) => (m[row * 5] * c.r +
          m[row * 5 + 1] * c.g +
          m[row * 5 + 2] * c.b +
          m[row * 5 + 4])
      .clamp(0, 255)
      .toDouble();
  return Rgba(ch(0), ch(1), ch(2), c.a);
}

String _format(Rgba c) =>
    'rgba(${c.r.round()},${c.g.round()},${c.b.round()},${_trim(c.a)})';

String _trim(double a) {
  final s = a.toStringAsFixed(3);
  return s.replaceFirst(RegExp(r'\.?0+$'), '');
}

/// Reads #rgb, #rrggbb, #rrggbbaa, rgb(), rgba(), hsl() and hsla(). Returns
/// null for anything else (expression words such as "get" or "linear").
Rgba? parseCssColour(String input) {
  final s = input.trim().toLowerCase();
  if (s.startsWith('#')) {
    var h = s.substring(1);
    if (h.length == 3 || h.length == 4) {
      h = h.split('').map((c) => '$c$c').join();
    }
    if (h.length != 6 && h.length != 8) return null;
    final n = int.tryParse(h, radix: 16);
    if (n == null) return null;
    if (h.length == 6) {
      return Rgba(((n >> 16) & 255).toDouble(), ((n >> 8) & 255).toDouble(),
          (n & 255).toDouble(), 1);
    }
    return Rgba(((n >> 24) & 255).toDouble(), ((n >> 16) & 255).toDouble(),
        ((n >> 8) & 255).toDouble(), (n & 255) / 255);
  }
  final fn = RegExp(r'^(rgba?|hsla?)\(([^)]*)\)$').firstMatch(s);
  if (fn == null) return null;
  final parts = fn
      .group(2)!
      .split(RegExp(r'[,\s/]+'))
      .where((p) => p.isNotEmpty)
      .toList();
  if (parts.length < 3) return null;
  double? parseNum(String p) => double.tryParse(p.replaceAll('%', '').replaceAll('deg', ''));
  final a = parts.length > 3
      ? (parts[3].endsWith('%')
          ? (parseNum(parts[3]) ?? 100) / 100
          : (parseNum(parts[3]) ?? 1))
      : 1.0;
  final x = parseNum(parts[0]);
  final y = parseNum(parts[1]);
  final z = parseNum(parts[2]);
  if (x == null || y == null || z == null) return null;
  if (fn.group(1)!.startsWith('rgb')) {
    final pct = parts[0].endsWith('%');
    double c(double v) => (pct ? v * 2.55 : v).clamp(0, 255).toDouble();
    return Rgba(c(x), c(y), c(z), a.clamp(0, 1).toDouble());
  }
  return _hsl(x, y / 100, z / 100, a.clamp(0, 1).toDouble());
}

Rgba _hsl(double h, double s, double l, double a) {
  h = ((h % 360) + 360) % 360;
  final c = (1 - (2 * l - 1).abs()) * s;
  final x = c * (1 - ((h / 60) % 2 - 1).abs());
  final mm = l - c / 2;
  double r, g, b;
  if (h < 60) {
    r = c;
    g = x;
    b = 0;
  } else if (h < 120) {
    r = x;
    g = c;
    b = 0;
  } else if (h < 180) {
    r = 0;
    g = c;
    b = x;
  } else if (h < 240) {
    r = 0;
    g = x;
    b = c;
  } else if (h < 300) {
    r = x;
    g = 0;
    b = c;
  } else {
    r = c;
    g = 0;
    b = x;
  }
  return Rgba(math.max(0, (r + mm) * 255), math.max(0, (g + mm) * 255),
      math.max(0, (b + mm) * 255), a);
}
