import 'dart:async';

import 'package:flutter/material.dart';

import 'club.dart';
import 'club_repository.dart';

/// Club box with suggestions from the shared club list as the runner types, so
/// the same club is picked instead of typed a different way each time.
class ClubField extends StatefulWidget {
  final String initialText;
  final ValueChanged<TextEditingController> onController;
  final ValueChanged<Club?> onClub; // null when the text no longer matches

  const ClubField({
    super.key,
    required this.initialText,
    required this.onController,
    required this.onClub,
  });

  @override
  State<ClubField> createState() => _ClubFieldState();
}

class _ClubFieldState extends State<ClubField> {
  final ClubRepository _repo = ClubRepository();
  int _seq = 0;
  bool _failed = false;

  Future<Iterable<Club>> _options(TextEditingValue v) async {
    final q = v.text.trim();
    if (q.length < 2) return const [];
    final mine = ++_seq;
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (mine != _seq) return const []; // the runner kept typing
    try {
      final found = await _repo.search(q);
      if (_failed && mounted) setState(() => _failed = false);
      return found;
    } catch (_) {
      // For example before the database update has been run.
      if (!_failed && mounted) setState(() => _failed = true);
      return const [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) => RawAutocomplete<Club>(
        initialValue: TextEditingValue(text: widget.initialText),
        displayStringForOption: (club) => club.name,
        optionsBuilder: _options,
        onSelected: widget.onClub,
        fieldViewBuilder: (context, controller, focusNode, onSubmit) {
          widget.onController(controller);
          return TextFormField(
            controller: controller,
            focusNode: focusNode,
            textCapitalization: TextCapitalization.words,
            onChanged: (_) => widget.onClub(null),
            decoration: InputDecoration(
              labelText: 'Running club (optional)',
              prefixIcon: const Icon(Icons.groups_outlined),
              border: const OutlineInputBorder(),
              helperText: _failed
                  ? 'Club suggestions are not available right now'
                  : 'Pick your club from the list so your club-mates match',
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
                  final club = options.elementAt(i);
                  return ListTile(
                    dense: true,
                    leading: const Icon(Icons.groups_outlined, size: 20),
                    title: Text(club.name),
                    subtitle:
                        club.subtitle.isEmpty ? null : Text(club.subtitle),
                    onTap: () => onSelected(club),
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
