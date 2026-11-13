import 'dart:async';

import 'package:flutter/material.dart';

import 'places.dart';

/// Town or city box. Suggests towns from the built-in South African list and
/// the world town list as the runner types, and also asks the online search
/// while a MapTiler key is set.
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

  @override
  void initState() {
    super.initState();
    WorldPlaces.warmUp();
  }

  Future<Iterable<Place>> _options(TextEditingValue v) async {
    final q = v.text.trim();
    final local = searchPlaces(q);
    if (q.length < 2) return local;
    final mine = ++_seq;
    // Built-in South African list first, then towns from the world list on
    // the phone, then (while a MapTiler key is set) the online search.
    final found = mergePlaces(local, await WorldPlaces.search(q));
    if (mine != _seq || q.length < 3 || !GeoSearch.enabled) return found;
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (mine != _seq) return found; // the runner kept typing
    return mergePlaces(found, await GeoSearch.search(q));
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
