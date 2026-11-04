import 'dart:async';

import 'package:flutter/material.dart';

import 'places.dart';

/// Town or city box. Suggests the built-in towns straight away and, when a
/// MapTiler key is set, towns from anywhere in the world as the runner types.
class PlaceField extends StatefulWidget {
  final String initialText;
  final Place? place; // the currently picked place, for the helper text
  final String label;
  final IconData icon;
  final String emptyHelper;
  final ValueChanged<TextEditingController> onController;
  final ValueChanged<Place?> onPlace;

  const PlaceField({
    super.key,
    required this.initialText,
    required this.place,
    required this.onController,
    required this.onPlace,
    this.label = 'Town or city',
    this.icon = Icons.place_outlined,
    this.emptyHelper = 'Pick a town from the list to show it on the map',
  });

  @override
  State<PlaceField> createState() => _PlaceFieldState();
}

class _PlaceFieldState extends State<PlaceField> {
  int _seq = 0;

  Future<Iterable<Place>> _options(TextEditingValue v) async {
    final q = v.text.trim();
    final local = searchPlaces(q);
    if (q.length < 3 || !GeoSearch.enabled) return local;
    final mine = ++_seq;
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (mine != _seq) return local; // the runner kept typing
    final remote = await GeoSearch.search(q);
    return mergePlaces(local, remote);
  }

  @override
  Widget build(BuildContext context) {
    final place = widget.place;
    return LayoutBuilder(
      builder: (context, c) => RawAutocomplete<Place>(
        initialValue: TextEditingValue(text: widget.initialText),
        displayStringForOption: (p) => p.name,
        optionsBuilder: _options,
        onSelected: widget.onPlace,
        fieldViewBuilder: (context, controller, focusNode, onSubmit) {
          widget.onController(controller);
          return TextFormField(
            controller: controller,
            focusNode: focusNode,
            textCapitalization: TextCapitalization.words,
            onChanged: (t) => widget.onPlace(placeByName(t)),
            decoration: InputDecoration(
              labelText: widget.label,
              prefixIcon: Icon(widget.icon),
              border: const OutlineInputBorder(),
              helperText: place == null
                  ? widget.emptyHelper
                  : '${place.name}, ${place.where}',
            ),
          );
        },
        optionsViewBuilder: (context, onSelected, options) => Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            child: ConstrainedBox(
              constraints:
                  BoxConstraints(maxHeight: 260, maxWidth: c.maxWidth),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, i) {
                  final p = options.elementAt(i);
                  return ListTile(
                    dense: true,
                    leading: const Icon(Icons.place_outlined, size: 20),
                    title: Text(p.name),
                    subtitle: p.where.isEmpty ? null : Text(p.where),
                    onTap: () => onSelected(p),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
