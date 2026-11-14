import 'package:flutter/material.dart';

/// Race distance groups used to colour pins on the journey map.
enum DistanceBand { fiveK, tenK, half, full, ultra }

extension DistanceBandX on DistanceBand {
  /// Short name used in the legend.
  String get label => switch (this) {
        DistanceBand.fiveK => '5K',
        DistanceBand.tenK => '10K',
        DistanceBand.half => '21K',
        DistanceBand.full => '42K',
        DistanceBand.ultra => '50K+',
      };

  /// The distances that fall in this group.
  String get range => switch (this) {
        DistanceBand.fiveK => 'up to 8 km',
        DistanceBand.tenK => '8 to 15 km',
        DistanceBand.half => '15 to 30 km',
        DistanceBand.full => '30 to 43 km',
        DistanceBand.ultra => 'over 43 km',
      };

  Color get color => switch (this) {
        DistanceBand.fiveK => const Color(0xFFF28C28),
        DistanceBand.tenK => const Color(0xFF2E9E5B),
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
  if (km < 15) return DistanceBand.tenK;
  if (km < 30) return DistanceBand.half;
  if (km <= 43) return DistanceBand.full;
  return DistanceBand.ultra;
}

/// Pin colour for a race distance, or null when the distance is unknown.
Color? distanceColour(double? km) => distanceBand(km)?.color;

/// A compact card that explains the pin colours.
class DistanceLegend extends StatelessWidget {
  const DistanceLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Pin colours by race distance',
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
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
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 11,
                      height: 11,
                      decoration: BoxDecoration(
                        color: b.color,
                        shape: BoxShape.circle,
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
          ],
        ),
      ),
    );
  }
}
