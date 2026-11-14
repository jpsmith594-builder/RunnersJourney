import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:image_picker/image_picker.dart';

import '../calendar/race_event.dart';
import '../map/place_field.dart';
import '../map/places.dart';
import '../photos/photo_repository.dart';
import '../photos/photo_widgets.dart';
import '../subscription/limits.dart';
import 'race.dart';
import 'race_repository.dart';
import '../../core/units.dart';
import '../../core/errors.dart';

class RaceFormScreen extends StatefulWidget {
  final Race? race;

  /// Pre-selected town (used when adding a race from the map).
  final Place? initialPlace;

  /// A calendar race to start from (name, town and distance are filled in and
  /// the race is set to "planned").
  final RaceEvent? prefill;

  /// A race name to start with (e.g. what was searched for in the calendar).
  final String? initialName;
  const RaceFormScreen(
      {super.key, this.race, this.initialPlace, this.prefill, this.initialName});

  @override
  State<RaceFormScreen> createState() => _RaceFormScreenState();
}

class _RaceFormScreenState extends State<RaceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repo = RaceRepository();

  final _nameFocus = FocusNode();

  /// The typed distance in km (what is stored), whatever unit was typed.
  double? _typedKm() {
    final v = double.tryParse(_distance.text.trim().replaceAll(',', '.'));
    return v == null ? null : tidyKm(fromUnit(v));
  }

  late final _name = TextEditingController(
      text: widget.race?.name ?? widget.prefill?.name ?? widget.initialName);
  late final _distance = TextEditingController(
      text: widget.race?.distanceKm != null
          ? formatNumber(toUnit(widget.race!.distanceKm!))
          : (widget.prefill == null
              ? ''
              : formatNumber(toUnit(widget.prefill!.distanceKm))));
  late final _hours = TextEditingController(
      text: widget.race?.finishTimeSeconds == null
          ? ''
          : (widget.race!.finishTimeSeconds! ~/ 3600).toString());
  late final _mins = TextEditingController(
      text: widget.race?.finishTimeSeconds == null
          ? ''
          : ((widget.race!.finishTimeSeconds! % 3600) ~/ 60).toString());
  late final _secs = TextEditingController(
      text: widget.race?.finishTimeSeconds == null
          ? ''
          : (widget.race!.finishTimeSeconds! % 60).toString());
  late final _position = TextEditingController(
      text: widget.race?.overallPosition?.toString() ?? '');
  late final _ageGroup = TextEditingController(
      text: widget.race?.ageGroupPosition?.toString() ?? '');
  late final _notes = TextEditingController(text: widget.race?.notes ?? '');

  late DateTime _date = widget.race?.date ??
      widget.prefill?.nextDate() ??
      DateTime.now();
  late RaceStatus _status = widget.race?.status ??
      (widget.prefill != null
          ? RaceStatus.planned
          : (DateTime.now().isAfter(_date)
              ? RaceStatus.completed
              : RaceStatus.planned));
  bool _saving = false;
  late String? _medal = widget.race?.medal;
  final List<XFile> _pendingPhotos = [];
  Place? _place;
  TextEditingController? _loc;

  @override
  void initState() {
    super.initState();
    _place = widget.initialPlace ??
        (widget.race == null ? null : placeForRace(widget.race!)) ??
        placeByName(widget.prefill?.town);
  }

  @override
  void dispose() {
    _nameFocus.dispose();
    for (final c in [_name, _distance, _hours, _mins, _secs, _position, _ageGroup, _notes]) {
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

  /// Finish time from the three boxes, or null when all are empty.
  int? get _finishSeconds {
    final h = int.tryParse(_hours.text.trim()) ?? 0;
    final m = int.tryParse(_mins.text.trim()) ?? 0;
    final s = int.tryParse(_secs.text.trim()) ?? 0;
    final total = h * 3600 + m * 60 + s;
    return total > 0 ? total : null;
  }

  String? _timePart(String? v, {int max = 59}) {
    if (v == null || v.trim().isEmpty) return null;
    final n = int.tryParse(v.trim());
    if (n == null || n < 0 || n > max) return '0-$max';
    return null;
  }

  Widget _timeBox(TextEditingController c, String label, {int max = 59}) {
    return Expanded(
      child: TextFormField(
        controller: c,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
        ),
        validator: (v) => _timePart(v, max: max),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    String? clean(TextEditingController c) =>
        c.text.trim().isEmpty ? null : c.text.trim();
    final typed = (_loc?.text ?? '').trim();
    final place = resolvePlace(typed, _place);
    final race = Race(
      id: widget.race?.id,
      name: _name.text.trim(),
      date: _date,
      status: _status,
      distanceKm: _typedKm(),
      finishTimeSeconds: _finishSeconds,
      overallPosition: int.tryParse(_position.text.trim()),
      ageGroupPosition: int.tryParse(_ageGroup.text.trim()),
      locationName: place?.name ?? (typed.isEmpty ? null : typed),
      lat: place?.lat,
      lng: place?.lng,
      region: place?.province,
      country: place?.country,
      medal: _status == RaceStatus.completed ? _medal : null,
      notes: clean(_notes),
    );
    try {
      if (race.id == null) {
        final newId = await _repo.add(race);
        // Photos picked before the race existed upload now.
        var failed = 0;
        for (final f in _pendingPhotos) {
          try {
            await PhotoRepository().add(newId, f);
          } catch (_) {
            failed++;
          }
        }
        if (failed > 0 && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(
                  '$failed photo(s) did not upload (the free plan holds 1 photo per race). Open the race to add them again.')));
        }
      } else {
        await _repo.update(race);
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        if (!handleLimitError(context, e)) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(failMessage('Could not save', e))));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.race != null;
    const gap = SizedBox(height: 12);
    return Scaffold(
      appBar: AppBar(title: Text(editing ? 'Edit race' : 'Add race')),
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
                  widget.race == null ? searchEvents(v.text) : const [],
              onSelected: (e) {
                // Fill in what we know, without overwriting what is typed.
                if (_distance.text.trim().isEmpty) {
                  _distance.text = formatNumber(toUnit(e.distanceKm));
                }
                final town = e.town;
                if (town != null && (_loc?.text ?? '').trim().isEmpty) {
                  _loc?.text = town;
                  setState(() => _place = placeByName(town));
                }
                final d = e.nextDate();
                if (d != null && widget.race == null) {
                  setState(() {
                    _date = d;
                    _status = RaceStatus.planned;
                  });
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
              decoration: InputDecoration(
                  labelText: 'Distance (${unitLabel()})',
                  border: const OutlineInputBorder()),
              validator: (v) => _optionalNumber(v, decimal: true),
            ),
            gap,
            Text('Finish time', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 6),
            Row(
              children: [
                _timeBox(_hours, 'Hours', max: 99),
                const SizedBox(width: 8),
                _timeBox(_mins, 'Mins'),
                const SizedBox(width: 8),
                _timeBox(_secs, 'Secs'),
              ],
            ),
            const SizedBox(height: 8),
            ListenableBuilder(
              listenable: Listenable.merge([_distance, _hours, _mins, _secs]),
              builder: (context, _) {
                final pace =
                    formatPace(_typedKm(), _finishSeconds);
                return InputDecorator(
                  decoration: const InputDecoration(
                      labelText: 'Pace (calculated)',
                      prefixIcon: Icon(Icons.speed),
                      border: OutlineInputBorder()),
                  child: Text(pace ?? 'Enter distance and time'),
                );
              },
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
            if (_status == RaceStatus.completed) ...[
              DropdownButtonFormField<String?>(
                // ignore: deprecated_member_use
                value: _medal,
                decoration: const InputDecoration(
                    labelText: 'Medal collected',
                    prefixIcon: Icon(Icons.emoji_events_outlined),
                    border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: null, child: Text('No medal')),
                  DropdownMenuItem(value: 'gold', child: Text('Gold')),
                  DropdownMenuItem(value: 'silver', child: Text('Silver')),
                  DropdownMenuItem(value: 'bronze', child: Text('Bronze')),
                ],
                onChanged: (v) => setState(() => _medal = v),
              ),
              gap,
            ],
            PlaceField(
              initialText: widget.race?.locationName ??
                  widget.initialPlace?.name ??
                  widget.prefill?.town ??
                  '',
              place: _place,
              onController: (c) => _loc = c,
              onPlace: (p) => setState(() => _place = p),
            ),
            gap,
            PhotosEditor(
              raceId: widget.race?.id,
              pending: _pendingPhotos,
              onPendingChanged: () => setState(() {}),
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
      ),
    );
  }
}
