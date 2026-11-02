import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../map/places.dart';
import 'race.dart';
import 'race_repository.dart';

class RaceFormScreen extends StatefulWidget {
  final Race? race;

  /// Pre-selected town (used when adding a race from the map).
  final Place? initialPlace;
  const RaceFormScreen({super.key, this.race, this.initialPlace});

  @override
  State<RaceFormScreen> createState() => _RaceFormScreenState();
}

class _RaceFormScreenState extends State<RaceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repo = RaceRepository();

  late final _name = TextEditingController(text: widget.race?.name);
  late final _distance = TextEditingController(
      text: widget.race?.distanceKm?.toString() ?? '');
  late final _time = TextEditingController(
      text: widget.race?.finishTimeSeconds == null
          ? ''
          : formatDuration(widget.race!.finishTimeSeconds));
  late final _position = TextEditingController(
      text: widget.race?.overallPosition?.toString() ?? '');
  late final _ageGroup = TextEditingController(
      text: widget.race?.ageGroupPosition?.toString() ?? '');
  late final _notes = TextEditingController(text: widget.race?.notes ?? '');

  late DateTime _date = widget.race?.date ?? DateTime.now();
  late RaceStatus _status = widget.race?.status ??
      (DateTime.now().isAfter(_date) ? RaceStatus.completed : RaceStatus.planned);
  bool _saving = false;
  Place? _place;
  TextEditingController? _loc;

  @override
  void initState() {
    super.initState();
    _place = widget.initialPlace ?? placeByName(widget.race?.locationName);
  }

  @override
  void dispose() {
    for (final c in [_name, _distance, _time, _position, _ageGroup, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(1970),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  String? _optionalNumber(String? v, {bool decimal = false}) {
    if (v == null || v.trim().isEmpty) return null;
    final ok = decimal ? double.tryParse(v.trim()) != null : int.tryParse(v.trim()) != null;
    return ok ? null : 'Enter a number';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    String? clean(TextEditingController c) =>
        c.text.trim().isEmpty ? null : c.text.trim();
    final typed = (_loc?.text ?? '').trim();
    final place = placeByName(typed);
    final race = Race(
      id: widget.race?.id,
      name: _name.text.trim(),
      date: _date,
      status: _status,
      distanceKm: double.tryParse(_distance.text.trim()),
      finishTimeSeconds: parseDuration(_time.text),
      overallPosition: int.tryParse(_position.text.trim()),
      ageGroupPosition: int.tryParse(_ageGroup.text.trim()),
      locationName: place?.name ?? (typed.isEmpty ? null : typed),
      lat: place?.lat,
      lng: place?.lng,
      notes: clean(_notes),
    );
    try {
      if (race.id == null) {
        await _repo.add(race);
      } else {
        await _repo.update(race);
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not save: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.race != null;
    const gap = SizedBox(height: 12);
    return Scaffold(
      appBar: AppBar(title: Text(editing ? 'Edit race' : 'Add race')),
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
            InkWell(
              onTap: _pickDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                    labelText: 'Date', border: OutlineInputBorder()),
                child: Text(DateFormat.yMMMMd().format(_date)),
              ),
            ),
            gap,
            DropdownButtonFormField<RaceStatus>(
              // ignore: deprecated_member_use
              value: _status,
              decoration: const InputDecoration(
                  labelText: 'Status', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(
                    value: RaceStatus.planned, child: Text('Planned')),
                DropdownMenuItem(
                    value: RaceStatus.completed, child: Text('Completed')),
                DropdownMenuItem(
                    value: RaceStatus.dnf, child: Text('Did not finish')),
                DropdownMenuItem(
                    value: RaceStatus.dns, child: Text('Did not start')),
              ],
              onChanged: (v) => setState(() => _status = v!),
            ),
            gap,
            TextFormField(
              controller: _distance,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                  labelText: 'Distance (km)', border: OutlineInputBorder()),
              validator: (v) => _optionalNumber(v, decimal: true),
            ),
            gap,
            TextFormField(
              controller: _time,
              keyboardType: TextInputType.datetime,
              decoration: const InputDecoration(
                  labelText: 'Finish time (h:mm:ss or mm:ss)',
                  border: OutlineInputBorder()),
              validator: (v) => (v != null &&
                      v.trim().isNotEmpty &&
                      parseDuration(v) == null)
                  ? 'Use h:mm:ss or mm:ss'
                  : null,
            ),
            gap,
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _position,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: 'Overall position',
                        border: OutlineInputBorder()),
                    validator: _optionalNumber,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _ageGroup,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: 'Age group position',
                        border: OutlineInputBorder()),
                    validator: _optionalNumber,
                  ),
                ),
              ],
            ),
            gap,
            Autocomplete<Place>(
              initialValue: TextEditingValue(
                  text: widget.race?.locationName ??
                      widget.initialPlace?.name ??
                      ''),
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
                        ? 'Pick a town from the list to show this race on the map'
                        : '${_place!.name}, ${_place!.province}',
                  ),
                );
              },
            ),
            gap,
            TextFormField(
              controller: _notes,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                  labelText: 'Notes / memories',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder()),
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
