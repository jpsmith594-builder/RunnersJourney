import 'dart:convert';
import 'dart:math' as math;

import '../spike/style_recolour.dart';

/// What a colour in the map style is used for. Each is darkened differently:
/// fills and lines go dark, labels go light, label outlines go dark.
enum DarkRole { fill, label, halo }

/// Turns a light vector map style into a dark one, colour by colour.
///
/// A plain colour inversion would put roads darker than the land, so the
/// brightness of fills is remapped instead: land stays a little lighter than
/// water and parks, roads a little lighter than land. Greys and beiges become
/// a cool slate, real colours (water, parks) keep their hue.
String darkenStyle(String styleJson) {
  final style = jsonDecode(styleJson) as Map<String, dynamic>;
  final layers = style['layers'];
  if (layers is List) {
    for (final layer in layers) {
      if (layer is! Map<String, dynamic>) continue;
      final paint = layer['paint'];
      if (paint is! Map<String, dynamic>) continue;
      for (final key in paint.keys.toList()) {
        if (key.endsWith('color')) {
          paint[key] = _walk(paint[key], _roleFor(key));
        }
      }
    }
  }
  return jsonEncode(style);
}

DarkRole _roleFor(String key) {
  if (key.startsWith('text-halo') || key.startsWith('icon-halo')) {
    return DarkRole.halo;
  }
  if (key == 'text-color' || key == 'icon-color') return DarkRole.label;
  return DarkRole.fill;
}

dynamic _walk(dynamic v, DarkRole role) {
  if (v is String) {
    final c = parseCssColour(v);
    return c == null ? v : formatCssColour(darkenColour(c, role));
  }
  if (v is List) return v.map((e) => _walk(e, role)).toList();
  if (v is Map<String, dynamic>) {
    return v.map((k, e) => MapEntry(k, _walk(e, role)));
  }
  return v;
}

/// The dark version of one colour. Transparency is kept.
Rgba darkenColour(Rgba c, DarkRole role) {
  final r = c.r / 255, g = c.g / 255, b = c.b / 255;
  final mx = math.max(r, math.max(g, b));
  final mn = math.min(r, math.min(g, b));
  final chroma = mx - mn;
  final l = (mx + mn) / 2;
  var h = 0.0, s = 0.0;
  if (chroma > 0) {
    final denom = 1 - (2 * l - 1).abs();
    s = denom < 1e-6 ? 0 : (chroma / denom).clamp(0.0, 1.0).toDouble();
    if (mx == r) {
      h = 60 * (((g - b) / chroma) % 6);
    } else if (mx == g) {
      h = 60 * ((b - r) / chroma + 2);
    } else {
      h = 60 * ((r - g) / chroma + 4);
    }
  }
  final neutral = chroma < 0.08;
  final double nl, ns;
  switch (role) {
    case DarkRole.fill:
      nl = 0.04 + 0.20 * math.pow(l, 6);
      ns = neutral ? 0.18 : math.min(1.0, s * 0.85);
    case DarkRole.label:
      nl = 1 - 0.78 * l;
      ns = neutral ? 0.12 : s * 0.7;
    case DarkRole.halo:
      nl = 0.08 + 0.10 * l;
      ns = neutral ? 0.2 : s * 0.8;
  }
  final nh = neutral ? 220.0 : h;
  return _fromHsl(nh, ns, nl, c.a);
}

Rgba _fromHsl(double h, double s, double l, double a) {
  final c = (1 - (2 * l - 1).abs()) * s;
  final x = c * (1 - ((h / 60) % 2 - 1).abs());
  final m = l - c / 2;
  final double r, g, b;
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
  double ch(double v) => ((v + m) * 255).clamp(0.0, 255.0).toDouble();
  return Rgba(ch(r), ch(g), ch(b), a);
}
