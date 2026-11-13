import 'dart:convert';

/// The English name of a place when the map has one, otherwise the local name.
const _englishFirst = [
  'coalesce',
  ['get', 'name:en'],
  ['get', 'name:latin'],
  ['get', 'name'],
];

/// Makes place names show in English where the map data has an English name
/// (so Tokyo is not shown in Japanese script), keeping the local name as the
/// fallback. Only name fields are touched; road numbers, house numbers and
/// anything else a label shows are left alone.
String localiseLabels(String styleJson) {
  final style = jsonDecode(styleJson) as Map<String, dynamic>;
  final layers = style['layers'];
  if (layers is List) {
    for (final layer in layers) {
      if (layer is! Map<String, dynamic>) continue;
      final layout = layer['layout'];
      if (layout is! Map<String, dynamic>) continue;
      final field = layout['text-field'];
      if (field == null) continue;
      layout['text-field'] = _localise(field);
    }
  }
  return jsonEncode(style);
}

final _nameToken = RegExp(r'^\{name(:latin)?\}([\s\n]*\{name:nonlatin\})?$');

dynamic _localise(dynamic field) {
  if (field is String) {
    return _nameToken.hasMatch(field.trim()) ? _englishFirst : field;
  }
  if (field is List) {
    if (field.length == 2 &&
        field[0] == 'get' &&
        (field[1] == 'name' || field[1] == 'name:latin')) {
      return _englishFirst;
    }
    return field.map(_localise).toList();
  }
  if (field is Map<String, dynamic>) {
    return field.map((k, v) => MapEntry(k, _localise(v)));
  }
  return field;
}
