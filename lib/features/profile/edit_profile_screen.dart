import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../map/place_field.dart';
import '../map/places.dart';
import 'profile.dart';
import 'profile_store.dart';

/// Create or edit the runner profile: name, age, gender, club, home town,
/// favourite distance and profile photo.
class EditProfileScreen extends StatefulWidget {
  final ProfileStore store;
  const EditProfileScreen({super.key, required this.store});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  late final _name =
      TextEditingController(text: widget.store.profile.displayName ?? '');
  late final _club =
      TextEditingController(text: widget.store.profile.club ?? '');
  late final _age =
      TextEditingController(text: widget.store.profile.age?.toString() ?? '');
  TextEditingController? _home; // owned by the PlaceField widget
  Place? _homePlace;
  String? _favourite;
  Gender? _gender;

  XFile? _picked;
  Uint8List? _preview;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _favourite = widget.store.profile.favouriteDistance;
    _gender = widget.store.profile.gender;
  }

  @override
  void dispose() {
    _name.dispose();
    _club.dispose();
    _age.dispose();
    super.dispose();
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _pick(ImageSource source) async {
    try {
      final file = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() {
        _picked = file;
        _preview = bytes;
      });
    } catch (e) {
      _toast('Could not open the photo: $e');
    }
  }

  String? _clean(String? s) {
    final t = (s ?? '').trim();
    return t.isEmpty ? null : t;
  }

  String? _validateAge(String? v) {
    final t = (v ?? '').trim();
    if (t.isEmpty) return null; // optional
    final n = int.tryParse(t);
    if (n == null || n < 10 || n > 100) return 'Enter an age between 10 and 100';
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final typedHome = _clean(_home?.text);
    final home = typedHome == null
        ? null
        : (resolvePlace(typedHome, _homePlace)?.name ?? typedHome);
    final age = int.tryParse(_age.text.trim());
    try {
      await widget.store.save(
        RunnerProfile(
          displayName: _name.text.trim(),
          club: _clean(_club.text),
          homeTown: home,
          favouriteDistance: _favourite,
          avatarPath: widget.store.profile.avatarPath,
          gender: _gender,
          birthYear: age == null ? null : DateTime.now().year - age,
        ),
        newAvatar: _picked,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) setState(() => _saving = false);
      _toast('Could not save your profile: $e\n'
          'If this mentions a missing column or bucket, run '
          'supabase/003_profile_card.sql and supabase/004_gender_age.sql.');
    }
  }

  @override
  Widget build(BuildContext context) {
    const gap = SizedBox(height: 14);
    ImageProvider? photo;
    if (_preview != null) {
      photo = MemoryImage(_preview!);
    } else if (widget.store.avatarUrl != null) {
      photo = NetworkImage(widget.store.avatarUrl!);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Runner profile')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: CircleAvatar(
                radius: 56,
                backgroundImage: photo,
                child: photo == null
                    ? const Icon(Icons.person, size: 56)
                    : null,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _pick(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Choose photo'),
                ),
                if (!kIsWeb)
                  OutlinedButton.icon(
                    onPressed: () => _pick(ImageSource.camera),
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: const Text('Take photo'),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                  labelText: 'Name on your card',
                  border: OutlineInputBorder()),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            gap,
            TextFormField(
              controller: _age,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Age (optional)',
                prefixIcon: Icon(Icons.cake_outlined),
                border: OutlineInputBorder(),
              ),
              validator: _validateAge,
            ),
            gap,
            Text('Gender', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final g in Gender.values)
                  ChoiceChip(
                    label: Text(g.label),
                    selected: _gender == g,
                    onSelected: (on) => setState(() => _gender = on ? g : null),
                  ),
              ],
            ),
            gap,
            TextFormField(
              controller: _club,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                  labelText: 'Running club (optional)',
                  border: OutlineInputBorder()),
            ),
            gap,
            PlaceField(
              initialText: widget.store.profile.homeTown ?? '',
              place: _homePlace,
              label: 'Home town',
              icon: Icons.home_outlined,
              emptyHelper: 'Optional',
              onController: (c) => _home = c,
              onPlace: (p) => setState(() => _homePlace = p),
            ),
            gap,
            Text('Favourite distance',
                style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final d in kFavouriteDistances)
                  ChoiceChip(
                    label: Text(d),
                    selected: _favourite == d,
                    onSelected: (on) =>
                        setState(() => _favourite = on ? d : null),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Save profile'),
            ),
          ],
        ),
      ),
    );
  }
}
