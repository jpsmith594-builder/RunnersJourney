import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'race.dart';
import 'race_store.dart';
import '../../core/units.dart';

enum _SortBy { date, time, pace, distance, name }

/// A distance bucket for filtering (e.g. 10K = 9.5 to 10.5 km).
class _DistanceBand {
  final String label;
  final double min, max;
  const _DistanceBand(this.label, this.min, this.max);
  bool matches(double? km) => km != null && km >= min && km <= max;
}

const _bands = [
  _DistanceBand('5K', 4.5, 5.5),
  _DistanceBand('10K', 9.5, 10.5),
  _DistanceBand('15K', 14.5, 16.5),
  _DistanceBand('21K', 20.0, 22.0),
  _DistanceBand('32K', 30.0, 34.0),
  _DistanceBand('42K', 41.0, 43.0),
  _DistanceBand('Ultra', 43.5, 10000),
];

/// A sortable, filterable table of the runner's completed races.
class ResultsScreen extends StatefulWidget {
  final RaceStore store;
  const ResultsScreen({super.key, required this.store});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  _DistanceBand? _band; // null = all distances
  int? _year; // null = all years
  _SortBy _sort = _SortBy.date;
  bool _ascending = false;

  double? _paceSeconds(Race r) {
    final km = r.distanceKm, t = r.finishTimeSeconds;
    if (km == null || t == null || km <= 0 || t <= 0) return null;
    return t / km;
  }

  List<Race> _rows() {
    var rows = widget.store.races
        .where((r) => r.status == RaceStatus.completed)
        .where((r) => _band == null || _band!.matches(r.distanceKm))
        .where((r) => _year == null || r.date.year == _year)
        .toList();
    int cmpNullable(num? a, num? b) {
      if (a == null && b == null) return 0;
      if (a == null) return 1; // missing values always last
      if (b == null) return -1;
      return a.compareTo(b);
    }

    rows.sort((a, b) {
      int c;
      switch (_sort) {
        case _SortBy.date:
          c = a.date.compareTo(b.date);
        case _SortBy.time:
          c = cmpNullable(a.finishTimeSeconds, b.finishTimeSeconds);
        case _SortBy.pace:
          c = cmpNullable(_paceSeconds(a), _paceSeconds(b));
        case _SortBy.distance:
          c = cmpNullable(a.distanceKm, b.distanceKm);
        case _SortBy.name:
          c = a.name.toLowerCase().compareTo(b.name.toLowerCase());
      }
      return _ascending ? c : -c;
    });
    return rows;
  }

  void _setSort(_SortBy s) {
    setState(() {
      if (_sort == s) {
        _ascending = !_ascending;
      } else {
        _sort = s;
        // Sensible defaults: fastest first for time/pace, newest first for date.
        _ascending = s == _SortBy.time || s == _SortBy.pace || s == _SortBy.name;
      }
    });
  }

  int get _sortColumn {
    switch (_sort) {
      case _SortBy.date:
        return 0;
      case _SortBy.name:
        return 1;
      case _SortBy.distance:
        return 2;
      case _SortBy.time:
        return 3;
      case _SortBy.pace:
        return 4;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My results')),
      body: SafeArea(
        top: false,
        left: false,
        right: false,
        child: ListenableBuilder(
        listenable: widget.store,
        builder: (context, _) {
          final all = widget.store.races
              .where((r) => r.status == RaceStatus.completed)
              .toList();
          final years = {for (final r in all) r.date.year}.toList()
            ..sort((a, b) => b.compareTo(a));
          if (_year != null && !years.contains(_year)) _year = null;
          final rows = _rows();
          final km = rows.fold<double>(0, (s, r) => s + (r.distanceKm ?? 0));

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: Row(
                  children: [
                    ChoiceChip(
                      label: const Text('All distances'),
                      selected: _band == null,
                      onSelected: (_) => setState(() => _band = null),
                    ),
                    for (final b in _bands) ...[
                      const SizedBox(width: 6),
                      ChoiceChip(
                        label: Text(b.label),
                        selected: _band == b,
                        onSelected: (_) => setState(() => _band = b),
                      ),
                    ],
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int?>(
                        // ignore: deprecated_member_use
                        value: _year,
                        isDense: true,
                        decoration: const InputDecoration(
                            labelText: 'Year', border: OutlineInputBorder()),
                        items: [
                          const DropdownMenuItem(
                              value: null, child: Text('All years')),
                          for (final y in years)
                            DropdownMenuItem(value: y, child: Text('$y')),
                        ],
                        onChanged: (v) => setState(() => _year = v),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<_SortBy>(
                        // ignore: deprecated_member_use
                        value: _sort,
                        isDense: true,
                        decoration: const InputDecoration(
                            labelText: 'Sort by', border: OutlineInputBorder()),
                        items: const [
                          DropdownMenuItem(
                              value: _SortBy.date, child: Text('Date')),
                          DropdownMenuItem(
                              value: _SortBy.time, child: Text('Time')),
                          DropdownMenuItem(
                              value: _SortBy.pace, child: Text('Pace')),
                          DropdownMenuItem(
                              value: _SortBy.distance,
                              child: Text('Distance')),
                          DropdownMenuItem(
                              value: _SortBy.name, child: Text('Name')),
                        ],
                        onChanged: (v) {
                          if (v != null && v != _sort) _setSort(v);
                        },
                      ),
                    ),
                    IconButton(
                      tooltip: _ascending ? 'Ascending' : 'Descending',
                      icon: Icon(_ascending
                          ? Icons.arrow_upward
                          : Icons.arrow_downward),
                      onPressed: () =>
                          setState(() => _ascending = !_ascending),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Text(
                  '${rows.length} race${rows.length == 1 ? '' : 's'}'
                  '${km > 0 ? ' · ${formatDistance(km)}' : ''}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              Expanded(
                child: rows.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                              'No completed races match these filters.',
                              textAlign: TextAlign.center),
                        ),
                      )
                    : SingleChildScrollView(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            sortColumnIndex: _sortColumn,
                            sortAscending: _ascending,
                            columnSpacing: 20,
                            columns: [
                              DataColumn(
                                  label: const Text('Date'),
                                  onSort: (_, __) => _setSort(_SortBy.date)),
                              DataColumn(
                                  label: const Text('Race'),
                                  onSort: (_, __) => _setSort(_SortBy.name)),
                              DataColumn(
                                  numeric: true,
                                  label: Text(unitLabel()),
                                  onSort: (_, __) =>
                                      _setSort(_SortBy.distance)),
                              DataColumn(
                                  numeric: true,
                                  label: const Text('Time'),
                                  onSort: (_, __) => _setSort(_SortBy.time)),
                              DataColumn(
                                  numeric: true,
                                  label: const Text('Pace'),
                                  onSort: (_, __) => _setSort(_SortBy.pace)),
                              const DataColumn(
                                  numeric: true, label: Text('Pos')),
                            ],
                            rows: [
                              for (final r in rows)
                                DataRow(cells: [
                                  DataCell(Text(
                                      DateFormat('d MMM yyyy').format(r.date))),
                                  DataCell(ConstrainedBox(
                                    constraints:
                                        const BoxConstraints(maxWidth: 180),
                                    child: Text(r.name,
                                        overflow: TextOverflow.ellipsis),
                                  )),
                                  DataCell(Text(r.distanceKm == null
                                      ? '-'
                                      : formatNumber(toUnit(r.distanceKm!)))),
                                  DataCell(Text(r.finishTimeSeconds == null
                                      ? '-'
                                      : r.formattedTime)),
                                  DataCell(Text(r.pace == null
                                      ? '-'
                                        : r.pace!.replaceAll(RegExp(r' /(km|mi)'), ''))),
                                  DataCell(Text(
                                      r.overallPosition?.toString() ?? '-')),
                                ]),
                            ],
                          ),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
      ),
    );
  }
}
