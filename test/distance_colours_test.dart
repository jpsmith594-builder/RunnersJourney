import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runners_journey/features/map/distance_colours.dart';

void main() {
  test('common race distances land in the right colour group', () {
    expect(distanceBand(5), DistanceBand.fiveK);
    expect(distanceBand(10), DistanceBand.tenK);
    expect(distanceBand(15), DistanceBand.fifteenK);
    expect(distanceBand(16.1), DistanceBand.fifteenK);
    expect(distanceBand(21.1), DistanceBand.half);
    expect(distanceBand(42.2), DistanceBand.full);
    expect(distanceBand(56), DistanceBand.ultra);
    expect(distanceBand(89), DistanceBand.ultra);
  });

  test('in-between distances fall into the nearest group below', () {
    expect(distanceBand(7.9), DistanceBand.fiveK);
    expect(distanceBand(8), DistanceBand.tenK);
    expect(distanceBand(12.9), DistanceBand.tenK);
    expect(distanceBand(13), DistanceBand.fifteenK);
    expect(distanceBand(18.9), DistanceBand.fifteenK);
    expect(distanceBand(19), DistanceBand.half);
    expect(distanceBand(20), DistanceBand.half);
    expect(distanceBand(29.9), DistanceBand.half);
    expect(distanceBand(30), DistanceBand.full);
    expect(distanceBand(43), DistanceBand.full);
    expect(distanceBand(43.1), DistanceBand.ultra);
  });

  test('unknown or zero distance has no colour', () {
    expect(distanceBand(null), isNull);
    expect(distanceBand(0), isNull);
    expect(distanceColour(null), isNull);
  });

  test('every group has its own colour', () {
    final colours = DistanceBand.values.map((b) => b.color.toARGB32()).toSet();
    expect(colours.length, DistanceBand.values.length);
  });

  testWidgets('tapping a legend colour picks it; tapping again clears it',
      (tester) async {
    DistanceBand? picked;
    await tester.pumpWidget(MaterialApp(
      home: StatefulBuilder(
        builder: (context, setState) => Scaffold(
          body: DistanceLegend(
            selected: picked,
            onSelect: (b) => setState(() => picked = b),
          ),
        ),
      ),
    ));
    expect(find.text('15K'), findsOneWidget);
    await tester.tap(find.text('21K'));
    await tester.pump();
    expect(picked, DistanceBand.half);
    expect(find.text('Show all'), findsOneWidget);
    await tester.tap(find.text('Show all'));
    await tester.pump();
    expect(picked, isNull);
  });
}
