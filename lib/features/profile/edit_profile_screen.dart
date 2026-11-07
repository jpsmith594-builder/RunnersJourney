import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../subscription/subscription_store.dart';
import '../clubs/club.dart';
import '../clubs/club_field.dart';
import '../clubs/club_repository.dart';
import '../map/place_field.dart';
import 'account_repository.dart';
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
  TextEditingController? _clubCtl; // owned by the ClubField widget
  Club? _clubPick; // the club picked from the suggestions, if any
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

  Future<void> _confirmDelete() async {
    final typed = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Delete your account?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                  'This permanently deletes your profile, races, photos, bucket list and friend '
                  'connections. It cannot be undone.\n\n'
                  'It does not cancel a Google Play subscription. Cancel that in Google Play '
                  'first if you have one.'),
              const SizedBox(height: 12),
              TextField(
                controller: typed,
                autofocus: true,
                onChanged: (_) => setLocal(() {}),
                decoration: const InputDecoration(
                    labelText: 'Type DELETE to confirm',
                    border: OutlineInputBorder()),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: typed.text.trim().toUpperCase() == 'DELETE'
                  ? () => Navigator.pop(ctx, true)
                  : null,
              child: const Text('Delete everything'),
            ),
          ],
        ),
      ),
    );
    typed.dispose();
    if (ok != true || !mounted) return;
    setState(() => _saving = true);
    try {
      await AccountRepository().deleteAccount();
      await subscription.reset();
      if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not delete the account: $e')));
      }
    }
  }

  /// The club to save: the one picked, the one already linked, or what was
  /// typed matched against the club list (asking before adding a lookalike).
  Future<({String? name, String? id})> _resolveClub() async {
    final typed = _clean(_clubCtl?.text);
    if (typed == null) return (name: null, id: null);
    final picked = _clubPick;
    if (picked != null && picked.id != null && picked.name == typed) {
      return (name: picked.name, id: picked.id);
    }
    final current = widget.store.profile;
    if (current.clubId != null && current.club == typed) {
      return (name: typed, id: current.clubId);
    }
    try {
      final repo = ClubRepository();
      final d = decideClub(typed, await repo.search(typed));
      final near = d.club;
      switch (d.decision) {
        case ClubDecision.useExisting:
          return (name: near!.name, id: near.id);
        case ClubDecision.askDidYouMean:
          if (!mounted) break;
          final use = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Did you mean this club?'),
              content: Text(
                  '"$typed" looks like ${near!.name}'
                  '${near.area.isEmpty ? '' : ' (${near.area})'}. '
                  'Using the same club puts you with your club-mates.'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('No, add mine')),
                FilledButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: Text('Use ${near.name}')),
              ],
            ),
          );
          if (use == true) return (name: near!.name, id: near.id);
        case ClubDecision.createNew:
        case ClubDecision.none:
          break;
      }
      final created = await repo.findOrCreate(typed);
      return (name: created.name, id: created.id);
    } catch (_) {
      // For example before the club list has been set up: keep the text.
      return (name: typed, id: null);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final club = await _resolveClub();
    final typedHome = _clean(_home?.text);
    final home = typedHome == null
        ? null
        : (resolvePlace(typedHome, _homePlace)?.name ?? typedHome);
    final age = int.tryParse(_age.text.trim());
    try {
      await widget.store.save(
        RunnerProfile(
          displayName: _name.text.trim(),
          club: club.name,
          clubId: club.id,
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
            ClubField(
              initialText: widget.store.profile.club ?? '',
              onController: (c) => _clubCtl = c,
              onClub: (c) => _clubPick = c,
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
            const SizedBox(height: 32),
            Center(
              child: TextButton.icon(
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                onPressed: _saving ? null : _confirmDelete,
                icon: const Icon(Icons.delete_forever_outlined),
                label: const Text('Delete my account'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
