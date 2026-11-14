import 'package:flutter/material.dart';

import '../calendar/race_event.dart';
import '../map/place_field.dart';
import '../map/places.dart';
import 'bucket_item.dart';
import 'bucket_store.dart';

/// Add or edit a bucket-list race.
class BucketFormScreen extends StatefulWidget {
  final BucketStore store;
  final BucketItem? item;
  const BucketFormScreen({super.key, required this.store, this.item});

  @override
  State<BucketFormScreen> createState() => _BucketFormScreenState();
}

class _BucketFormScreenState extends State<BucketFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.item?.name);
  late final _distance =
      TextEditingController(text: widget.item?.distanceKm?.toString() ?? '');
  final _nameFocus = FocusNode();
  Place? _place;
  TextEditingController? _loc;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _place = widget.item == null ? null : placeForBucket(widget.item!);
  }

  @override
  void dispose() {
    _nameFocus.dispose();
    _name.dispose();
    _distance.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final typed = (_loc?.text ?? '').trim();
    final place = resolvePlace(typed, _place);
    final item = BucketItem(
      id: widget.item?.id,
      name: _name.text.trim(),
      locationName: place?.name ?? (typed.isEmpty ? null : typed),
      lat: place?.lat,
      lng: place?.lng,
      region: place?.province,
      country: place?.country,
      distanceKm: double.tryParse(_distance.text.trim()),
      done: widget.item?.done ?? false,
    );
    try {
      if (item.id == null) {
        await widget.store.add(item);
      } else {
        await widget.store.update(item);
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                'Could not save: $e\n(Have you run supabase/005_bucket_list.sql?)')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const gap = SizedBox(height: 12);
    return Scaffold(
      appBar: AppBar(
          title: Text(widget.item == null ? 'Add to bucket list' : 'Edit')),
      body: SafeArea(
        top: false,
        left: false,
        right: false,
        child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            RawAutocomplete<RaceEvent>(
              textEditingController: _name,
              focusNode: _nameFocus,
              displayStringForOption: (e) => e.name,
              optionsBuilder: (v) =>
                  widget.item == null ? searchEvents(v.text) : const [],
              onSelected: (e) {
                if (_distance.text.trim().isEmpty) {
                  _distance.text = e.distanceKm.toString();
                }
                final town = e.town;
                if (town != null && (_loc?.text ?? '').trim().isEmpty) {
                  _loc?.text = town;
                  setState(() => _place = placeByName(town));
                }
              },
              fieldViewBuilder: (context, controller, focusNode, onSubmit) =>
                  TextFormField(
                controller: controller,
                focusNode: focusNode,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                    labelText: 'Race name',
                    helperText: 'Start typing to search the race calendar',
                    border: OutlineInputBorder()),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              optionsViewBuilder: (context, onSelected, options) => Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(8),
                  child: ConstrainedBox(
                    constraints:
                        const BoxConstraints(maxHeight: 260, maxWidth: 420),
                    child: ListView(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      children: [
                        for (final e in options)
                          ListTile(
                            dense: true,
                            title: Text(e.name),
                            subtitle: Text([
                              if (e.town != null) e.town!,
                              e.distanceLabel,
                              e.when,
                            ].join(' \u00B7 ')),
                            onTap: () => onSelected(e),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            gap,
            PlaceField(
              initialText: widget.item?.locationName ?? '',
              place: _place,
              emptyHelper: 'Pick a town from the list to pin it on the map',
              onController: (c) => _loc = c,
              onPlace: (p) => setState(() => _place = p),
            ),
            gap,
            TextFormField(
              controller: _distance,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                  labelText: 'Distance (km, optional)',
                  border: OutlineInputBorder()),
              validator: (v) => (v == null ||
                      v.trim().isEmpty ||
                      double.tryParse(v.trim()) != null)
                  ? null
                  : 'Enter a number',
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Save'),
            ),
          ],
        ),
      ),
      ),
    );
  }
}
