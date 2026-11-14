import 'package:flutter/material.dart';

/// Race distance groups used to colour pins on the journey map.
enum DistanceBand { fiveK, tenK, fifteenK, half, full, ultra }

extension DistanceBandX on DistanceBand {
  /// Short name used in the legend.
  String get label => switch (this) {
        DistanceBand.fiveK => '5K',
        DistanceBand.tenK => '10K',
        DistanceBand.fifteenK => '15K',
        DistanceBand.half => '21K',
        DistanceBand.full => '42K',
        DistanceBand.ultra => '50K+',
      };

  /// The distances that fall in this group.
  String get range => switch (this) {
        DistanceBand.fiveK => 'up to 8 km',
        DistanceBand.tenK => '8 to 13 km',
        DistanceBand.fifteenK => '13 to 19 km',
        DistanceBand.half => '19 to 30 km',
        DistanceBand.full => '30 to 43 km',
        DistanceBand.ultra => 'over 43 km',
      };

  Color get color => switch (this) {
        DistanceBand.fiveK => const Color(0xFFF28C28),
        DistanceBand.tenK => const Color(0xFF2E9E5B),
        DistanceBand.fifteenK => const Color(0xFF0E9AA7),
        DistanceBand.half => const Color(0xFF7B3FBF),
        DistanceBand.full => const Color(0xFF8E1B3A),
        DistanceBand.ultra => const Color(0xFF1F63D6),
      };
}

/// The group a race of [km] kilometres belongs to, or null when the distance
/// is not known. A full marathon (42.2 km) is in the 42K group; anything
/// longer is an ultra.
DistanceBand? distanceBand(double? km) {
  if (km == null || km <= 0) return null;
  if (km < 8) return DistanceBand.fiveK;
  if (km < 13) return DistanceBand.tenK;
  if (km < 19) return DistanceBand.fifteenK;
  if (km < 30) return DistanceBand.half;
  if (km <= 43) return DistanceBand.full;
  return DistanceBand.ultra;
}

/// Pin colour for a race distance, or null when the distance is unknown.
Color? distanceColour(double? km) => distanceBand(km)?.color;

/// A compact card that explains the pin colours. Tapping a colour shows only
/// the races in that group; tapping it again (or "Show all") brings them back.
class DistanceLegend extends StatelessWidget {
  final DistanceBand? selected;
  final ValueChanged<DistanceBand?> onSelect;

  const DistanceLegend({super.key, this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Pin colours by race distance. Tap one to show only those races.',
      child: Container(
        padding: const EdgeInsets.fromLTRB(4, 4, 6, 2),
        decoration: BoxDecoration(
          color: const Color(0xE6FFFFFF),
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(color: Color(0x22000000), blurRadius: 6),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final b in DistanceBand.values)
              Semantics(
                button: true,
                selected: selected == b,
                label: selected == b
                    ? 'Showing only ${b.label}. Tap to show all.'
                    : 'Show only ${b.label} races',
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => onSelect(selected == b ? null : b),
                  child: Opacity(
                    opacity: selected == null || selected == b ? 1 : 0.4,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 3),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 11,
                            height: 11,
                            decoration: BoxDecoration(
                              color: b.color,
                              shape: BoxShape.circle,
                              border: selected == b
                                  ? Border.all(color: Colors.black87, width: 2)
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            b.label,
                            style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Colors.black87),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            b.range,
                            style: const TextStyle(
                                fontSize: 10.5, color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            if (selected != null)
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => onSelect(null),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Text('Show all',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF5B2D8A))),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
