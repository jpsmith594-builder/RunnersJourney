import 'package:flutter/material.dart';

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
  Place? _place;
  TextEditingController? _loc;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _place = placeByName(widget.item?.locationName);
  }

  @override
  void dispose() {
    _name.dispose();
    _distance.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final typed = (_loc?.text ?? '').trim();
    final place = placeByName(typed);
    final item = BucketItem(
      id: widget.item?.id,
      name: _name.text.trim(),
      locationName: place?.name ?? (typed.isEmpty ? null : typed),
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
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                  labelText: 'Race name', border: OutlineInputBorder()),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            gap,
            Autocomplete<Place>(
              initialValue:
                  TextEditingValue(text: widget.item?.locationName ?? ''),
              displayStringForOption: (p) => p.name,
              optionsBuilder: (v) => searchPlaces(v.text),
              onSelected: (p) => setState(() => _place = p),
              fieldViewBuilder: (context, controller, focusNode, onSubmit) {
                _loc = controller;
                return TextFormField(
                  controller: controller,
                  focusNode: focusNode,
                  textCapitalization: TextCapitalization.words,
                  onChanged: (t) => setState(() => _place = placeByName(t)),
                  decoration: InputDecoration(
                    labelText: 'Town or city',
                    prefixIcon: const Icon(Icons.place_outlined),
                    border: const OutlineInputBorder(),
                    helperText: _place == null
                        ? 'Pick a town from the list to pin it on the map'
                        : '${_place!.name}, ${_place!.province}',
                  ),
                );
              },
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
    );
  }
}
