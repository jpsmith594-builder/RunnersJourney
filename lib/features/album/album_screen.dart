import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../photos/photo_repository.dart';
import '../photos/photo_widgets.dart';
import '../photos/race_photo.dart';
import '../profile/share_card.dart';
import '../races/race.dart';
import '../races/race_list_screen.dart' show medalColor;
import '../races/race_store.dart';
import '../../core/brand.dart';
import '../../core/units.dart';

const _paper = Color(0xFFF6EFE2);
const _ink = Color(0xFF3B2F2F);
const _leather = Color(0xFF2A1B22);

/// Races shown in the album: finished ones, oldest first, optionally limited
/// to a year and to races that have photos. When the runner has no photos at
/// all every race is kept, so the album is never empty for lack of pictures.
List<Race> albumRaces(
  Iterable<Race> all, {
  int? year,
  bool onlyWithPhotos = true,
  Set<String>? photoRaceIds,
}) {
  final keepPhotoFilter =
      onlyWithPhotos && photoRaceIds != null && photoRaceIds.isNotEmpty;
  final list = all.where((r) {
    if (r.status != RaceStatus.completed) return false;
    if (year != null && r.date.year != year) return false;
    if (keepPhotoFilter && !photoRaceIds.contains(r.id)) return false;
    return true;
  }).toList()
    ..sort((a, b) => a.date.compareTo(b.date));
  return list;
}

/// An old-style photo album: cover, one page per race, then a closing page.
class AlbumScreen extends StatefulWidget {
  final RaceStore store;
  final String name;
  const AlbumScreen({super.key, required this.store, required this.name});

  @override
  State<AlbumScreen> createState() => _AlbumScreenState();
}

class _AlbumScreenState extends State<AlbumScreen> {
  PageController _pc = PageController();
  Timer? _timer;
  bool _playing = false;
  bool _onlyPhotos = true;
  int? _year;
  int _index = 0;
  Set<String>? _photoIds;
  final Map<int, GlobalKey> _keys = {};

  List<Race> get _races => albumRaces(
        widget.store.races,
        year: _year,
        onlyWithPhotos: _onlyPhotos,
        photoRaceIds: _photoIds,
      );

  @override
  void initState() {
    super.initState();
    PhotoRepository().raceIdsWithPhotos().then((ids) {
      if (mounted) setState(() => _photoIds = ids);
    }).catchError((_) {});
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pc.dispose();
    super.dispose();
  }

  void _togglePlay(int total) {
    if (_playing) {
      _timer?.cancel();
      setState(() => _playing = false);
      return;
    }
    if (_index >= total - 1) _pc.jumpToPage(0);
    setState(() => _playing = true);
    _timer = Timer.periodic(const Duration(seconds: 4), (t) {
      if (!mounted || _index >= total - 1) {
        t.cancel();
        if (mounted) setState(() => _playing = false);
        return;
      }
      _pc.nextPage(
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOutCubic);
    });
  }

  void _restart() {
    _timer?.cancel();
    _playing = false;
    _index = 0;
    _keys.clear();
    final old = _pc;
    _pc = PageController();
    WidgetsBinding.instance.addPostFrameCallback((_) => old.dispose());
  }

  @override
  Widget build(BuildContext context) {
    final races = _races;
    final total = races.length + 2;
    final years = {
      for (final r in widget.store.races)
        if (r.status == RaceStatus.completed) r.date.year
    }.toList()
      ..sort();
    final index = _index.clamp(0, total - 1);

    return Scaffold(
      backgroundColor: _leather,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: const TextStyle(
            color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
        title: const Text('Journey album'),
        actions: [
          IconButton(
            tooltip: _playing ? 'Pause' : 'Play',
            icon: Icon(_playing ? Icons.pause_circle : Icons.play_circle),
            onPressed: total > 2 ? () => _togglePlay(total) : null,
          ),
          IconButton(
            tooltip: 'Share this page',
            icon: const Icon(Icons.ios_share),
            onPressed: () => shareRunnerCard(
              context,
              _keys.putIfAbsent(index, GlobalKey.new),
              message: 'My Running Journal',
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (v) {
              setState(() {
                _restart();
                if (v == 'photos') {
                  _onlyPhotos = !_onlyPhotos;
                } else if (v == 'all') {
                  _year = null;
                } else {
                  _year = int.parse(v);
                }
              });
            },
            itemBuilder: (_) => [
              CheckedPopupMenuItem(
                value: 'photos',
                checked: _onlyPhotos,
                child: const Text('Only races with photos'),
              ),
              const PopupMenuDivider(),
              CheckedPopupMenuItem(
                value: 'all',
                checked: _year == null,
                child: const Text('All years'),
              ),
              for (final y in years.reversed)
                CheckedPopupMenuItem(
                  value: '$y',
                  checked: _year == y,
                  child: Text('$y'),
                ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 4, 18, 8),
                child: PageView.builder(
                  key: ValueKey('${_year}_$_onlyPhotos'),
                  controller: _pc,
                  itemCount: total,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemBuilder: (context, i) {
                    final Widget page;
                    if (i == 0) {
                      page = _CoverPage(name: widget.name, races: races);
                    } else if (i == total - 1) {
                      page = _EndPage(races: races);
                    } else {
                      page = _RacePage(race: races[i - 1]);
                    }
                    return _Flip(
                      controller: _pc,
                      index: i,
                      child: RepaintBoundary(
                        key: _keys.putIfAbsent(i, GlobalKey.new),
                        child: page,
                      ),
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                '${index + 1} / $total',
                style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Turns a page about its left edge, like a page of a book, as it is swiped.
class _Flip extends StatelessWidget {
  final PageController controller;
  final int index;
  final Widget child;
  const _Flip(
      {required this.controller, required this.index, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        double page = index.toDouble();
        if (controller.hasClients && controller.position.haveDimensions) {
          page = controller.page ?? page;
        } else if (controller.initialPage != 0) {
          page = controller.initialPage.toDouble();
        }
        final d = (page - index).clamp(-1.0, 1.0);
        final angle = d > 0 ? d * 3.14159 * 0.45 : d * 3.14159 * 0.12;
        final m = Matrix4.identity()
          ..setEntry(3, 2, 0.0012)
          ..rotateY(angle);
        return Opacity(
          opacity: (1 - d.abs() * 0.5).clamp(0.0, 1.0),
          child: Transform(
            alignment: Alignment.centerLeft,
            transform: m,
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

/// Cream paper with a shaded spine and a fine double-line border.
class _Paper extends StatelessWidget {
  final Widget child;
  final Color color;
  final Gradient? gradient;
  final bool border;
  const _Paper(
      {required this.child,
      this.color = _paper,
      this.gradient,
      this.border = true});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        gradient: gradient,
        borderRadius: const BorderRadius.horizontal(
            left: Radius.circular(4), right: Radius.circular(14)),
        boxShadow: const [
          BoxShadow(color: Colors.black54, blurRadius: 14, offset: Offset(2, 6))
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          if (border)
            const Positioned(
              left: 36,
              top: 10,
              right: 10,
              bottom: 10,
              child: CustomPaint(painter: _PageBorderPainter(_ink)),
            ),
          Positioned.fill(
            child: Padding(
              padding: border
                  ? const EdgeInsets.fromLTRB(50, 28, 26, 28)
                  : const EdgeInsets.fromLTRB(30, 22, 20, 22),
              child: child,
            ),
          ),
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 30,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  Colors.black.withValues(alpha: 0.28),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A fine outer line, a thinner inner line and a dot in each corner.
class _PageBorderPainter extends CustomPainter {
  final Color color;
  const _PageBorderPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final outer = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..color = color.withValues(alpha: 0.5);
    final inner = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7
      ..color = color.withValues(alpha: 0.32);
    final dot = Paint()..color = color.withValues(alpha: 0.5);
    final r = Offset.zero & size;
    canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(3)), outer);
    final i = r.deflate(5);
    canvas.drawRect(i, inner);
    for (final c in [i.topLeft, i.topRight, i.bottomLeft, i.bottomRight]) {
      canvas.drawCircle(c, 2.2, dot);
    }
  }

  @override
  bool shouldRepaint(_PageBorderPainter old) => old.color != color;
}

const _serif = 'serif';

class _CoverPage extends StatelessWidget {
  final String name;
  final List<Race> races;
  const _CoverPage({required this.name, required this.races});

  @override
  Widget build(BuildContext context) {
    final years = races.map((r) => r.date.year).toSet().toList()..sort();
    final span = years.isEmpty
        ? ''
        : years.length == 1
            ? '${years.first}'
            : '${years.first} – ${years.last}';
    final km = races.fold<double>(0, (a, r) => a + (r.distanceKm ?? 0));
    const gold = Color(0xFFE2B857);
    const goldLight = Color(0xFFFFE9A8);
    Widget stat(String big, String small) => Column(children: [
          Text(big,
              style: const TextStyle(
                  color: goldLight,
                  fontFamily: _serif,
                  fontSize: 22,
                  fontWeight: FontWeight.w700)),
          Text(small.toUpperCase(),
              style: const TextStyle(
                  color: Colors.white60, fontSize: 10, letterSpacing: 2)),
        ]);
    return _Paper(
      border: false,
      color: const Color(0xFF4A2A3A),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF6B2F55), Color(0xFF3E2038), Color(0xFF241326)],
      ),
      child: CustomPaint(
        painter: _CoverPainter(gold),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
          child: LayoutBuilder(
            builder: (context, box) => FittedBox(
              fit: BoxFit.scaleDown,
              child: SizedBox(
                width: box.maxWidth,
                child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: gold, width: 2),
                  gradient: const RadialGradient(
                      colors: [Color(0x55E2B857), Color(0x00E2B857)]),
                ),
                child: const Icon(Icons.place, color: goldLight, size: 52),
              ),
              const SizedBox(height: 24),
              ShaderMask(
                shaderCallback: (r) => const LinearGradient(
                  colors: [Color(0xFFFFF1C2), Color(0xFFE2B857), Color(0xFFB98A2E)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ).createShader(r),
                child: const Text('MY RUNNING\nJOURNAL',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white,
                        fontFamily: _serif,
                        fontSize: 32,
                        height: 1.15,
                        letterSpacing: 4,
                        fontWeight: FontWeight.w800)),
              ),
              const SizedBox(height: 16),
              Row(mainAxisSize: MainAxisSize.min, children: [
                Container(height: 1.5, width: 34, color: gold),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.diamond, color: gold, size: 12),
                ),
                Container(height: 1.5, width: 34, color: gold),
              ]),
              const SizedBox(height: 16),
              if (name.trim().isNotEmpty)
                Text(name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Colors.white,
                        fontFamily: _serif,
                        fontStyle: FontStyle.italic,
                        fontSize: 24)),
              const SizedBox(height: 8),
              Text(span,
                  style: const TextStyle(
                      color: Colors.white70, letterSpacing: 3, fontSize: 14)),
              if (races.isNotEmpty) ...[
                const SizedBox(height: 26),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    stat('${races.length}', 'races'),
                    stat(formatNumber(toUnit(km)), unitWord()),
                  ],
                ),
              ],
              const SizedBox(height: 28),
              const Text('Swipe to turn the page',
                  style: TextStyle(color: Colors.white54, fontSize: 12)),
            ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The cover's artwork: a faint map grid, a dotted route with pins, and a
/// gold double border with diamonds in the corners.
class _CoverPainter extends CustomPainter {
  final Color gold;
  const _CoverPainter(this.gold);

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = gold.withValues(alpha: 0.07)
      ..strokeWidth = 1;
    for (double x = 30; x < size.width; x += 38) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (double y = 30; y < size.height; y += 38) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    final pts = [
      Offset(size.width * 0.14, size.height * 0.88),
      Offset(size.width * 0.38, size.height * 0.80),
      Offset(size.width * 0.58, size.height * 0.87),
      Offset(size.width * 0.86, size.height * 0.76),
    ];
    final route = Path()..moveTo(pts[0].dx, pts[0].dy);
    route.cubicTo(pts[0].dx + 30, pts[0].dy - 36, pts[1].dx - 30, pts[1].dy + 30,
        pts[1].dx, pts[1].dy);
    route.cubicTo(pts[1].dx + 30, pts[1].dy - 26, pts[2].dx - 26, pts[2].dy - 30,
        pts[2].dx, pts[2].dy);
    route.cubicTo(pts[2].dx + 30, pts[2].dy + 26, pts[3].dx - 30, pts[3].dy + 30,
        pts[3].dx, pts[3].dy);
    final dots = Paint()..color = gold.withValues(alpha: 0.4);
    for (final m in route.computeMetrics()) {
      for (double d = 0; d < m.length; d += 9) {
        canvas.drawCircle(m.getTangentForOffset(d)!.position, 1.6, dots);
      }
    }
    final pin = Paint()..color = gold.withValues(alpha: 0.65);
    for (final p in pts) {
      canvas.drawCircle(p, 4.5, pin);
      canvas.drawCircle(
          p,
          8,
          Paint()
            ..style = PaintingStyle.stroke
            ..color = gold.withValues(alpha: 0.35));
    }

    final outer = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..color = gold;
    final inner = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9
      ..color = gold.withValues(alpha: 0.75);
    final r = (Offset.zero & size).deflate(8);
    canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(6)), outer);
    final i = r.deflate(6);
    canvas.drawRect(i, inner);
    final fill = Paint()..color = gold;
    for (final c in [i.topLeft, i.topRight, i.bottomLeft, i.bottomRight]) {
      final d = Path()
        ..moveTo(c.dx, c.dy - 6)
        ..lineTo(c.dx + 6, c.dy)
        ..lineTo(c.dx, c.dy + 6)
        ..lineTo(c.dx - 6, c.dy)
        ..close();
      canvas.drawPath(d, fill);
    }
  }

  @override
  bool shouldRepaint(_CoverPainter old) => old.gold != gold;
}

class _EndPage extends StatelessWidget {
  final List<Race> races;
  const _EndPage({required this.races});

  @override
  Widget build(BuildContext context) {
    final km = races.fold<double>(0, (a, r) => a + (r.distanceKm ?? 0));
    final medals = races.where((r) => r.medal != null).length;
    Widget line(String big, String small) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(children: [
            Text(big,
                style: const TextStyle(
                    color: _ink,
                    fontFamily: _serif,
                    fontSize: 38,
                    fontWeight: FontWeight.w700)),
            Text(small.toUpperCase(),
                style: TextStyle(
                    color: _ink.withValues(alpha: 0.6),
                    fontSize: 12,
                    letterSpacing: 2)),
          ]),
        );
    return _Paper(
      child: LayoutBuilder(
        builder: (context, box) => FittedBox(
          fit: BoxFit.scaleDown,
          child: SizedBox(
            width: box.maxWidth,
            child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('The story so far',
              style: TextStyle(
                  color: _ink,
                  fontFamily: _serif,
                  fontStyle: FontStyle.italic,
                  fontSize: 24)),
          const SizedBox(height: 14),
          line('${races.length}', 'races'),
          line(formatNumber(toUnit(km)), unitWord()),
          line('$medals', 'medals'),
          const SizedBox(height: 10),
          Text(brandMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: _ink.withValues(alpha: 0.75),
                  fontFamily: _serif,
                  fontStyle: FontStyle.italic,
                  fontSize: 12.5,
                  height: 1.4)),
          const SizedBox(height: 12),
          Text('To be continued…',
              style: TextStyle(
                  color: _ink.withValues(alpha: 0.6),
                  fontFamily: _serif,
                  fontStyle: FontStyle.italic)),
        ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RacePage extends StatefulWidget {
  final Race race;
  const _RacePage({required this.race});

  @override
  State<_RacePage> createState() => _RacePageState();
}

class _RacePageState extends State<_RacePage>
    with AutomaticKeepAliveClientMixin {
  List<RacePhoto>? _photos;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    final id = widget.race.id;
    if (id == null) {
      _photos = const [];
    } else {
      PhotoRepository().list(id).then((p) {
        if (mounted) setState(() => _photos = p);
      }).catchError((_) {
        if (mounted) setState(() => _photos = const []);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final r = widget.race;
    final photos = _photos;
    final where = [
      if ((r.locationName ?? '').isNotEmpty) r.locationName!,
      if ((r.country ?? '').isNotEmpty) r.country!,
    ].join(', ');
    final stats = <String>[
      if (r.distanceKm != null) formatDistance(r.distanceKm!),
      if (r.finishTimeSeconds != null) r.formattedTime,
      if (r.pace != null) r.pace!,
      if (r.overallPosition != null) 'Position ${r.overallPosition}',
    ];
    return _Paper(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: photos == null
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                : photos.isEmpty
                    ? Center(
                        child: Icon(Icons.directions_run,
                            size: 90, color: _ink.withValues(alpha: 0.18)))
                    : _Collage(photos: photos),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(r.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: _ink,
                        fontFamily: _serif,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w700,
                        fontSize: 22)),
              ),
              if (r.medal != null)
                Icon(Icons.workspace_premium, color: medalColor(r.medal!)),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            [DateFormat.yMMMMd().format(r.date), if (where.isNotEmpty) where]
                .join('  ·  '),
            style: TextStyle(color: _ink.withValues(alpha: 0.65), fontSize: 13),
          ),
          if (stats.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                for (final s in stats)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(
                      color: _ink.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(s,
                        style: const TextStyle(
                            color: _ink,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Photos stuck onto the page: one big, two on a slant, or a grid of four.
class _Collage extends StatelessWidget {
  final List<RacePhoto> photos;
  const _Collage({required this.photos});

  void _open(BuildContext c, int i) => openPhotoViewer(c, photos, i);

  @override
  Widget build(BuildContext context) {
    final n = photos.length;
    if (n == 1) {
      return Center(
        child: FractionallySizedBox(
          widthFactor: 0.88,
          child: _Frame(
              photo: photos[0], angle: -0.03, onTap: () => _open(context, 0)),
        ),
      );
    }
    if (n == 2) {
      return Column(
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: 0.78,
                child: _Frame(
                    photo: photos[0],
                    angle: -0.04,
                    onTap: () => _open(context, 0)),
              ),
            ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: FractionallySizedBox(
                widthFactor: 0.78,
                child: _Frame(
                    photo: photos[1],
                    angle: 0.035,
                    onTap: () => _open(context, 1)),
              ),
            ),
          ),
        ],
      );
    }
    const angles = [-0.03, 0.025, 0.02, -0.025];
    Widget cell(int i) {
      final more = i == 3 && n > 4 ? n - 3 : 0;
      return Expanded(
        child: Stack(
          fit: StackFit.expand,
          children: [
            _Frame(
                photo: photos[i],
                angle: angles[i],
                onTap: () => _open(context, i)),
            if (more > 0)
              Center(
                child: IgnorePointer(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('+$more',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 18)),
                  ),
                ),
              ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(child: Row(children: [cell(0), cell(1)])),
        Expanded(
            child: Row(children: [
          cell(2),
          if (n >= 4) cell(3) else const Expanded(child: SizedBox()),
        ])),
      ],
    );
  }
}

class _Frame extends StatelessWidget {
  final RacePhoto photo;
  final double angle;
  final VoidCallback onTap;
  const _Frame(
      {required this.photo, required this.angle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Transform.rotate(
          angle: angle,
          child: Stack(
            clipBehavior: Clip.none,
            fit: StackFit.expand,
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 5,
                        offset: const Offset(1, 3))
                  ],
                ),
                child: Image.network(
                  photo.url,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const ColoredBox(
                    color: Color(0xFFE5DECF),
                    child: Icon(Icons.broken_image, color: Colors.black26),
                  ),
                ),
              ),
              Positioned(
                top: -6,
                left: 0,
                right: 0,
                child: Center(
                  child: Transform.rotate(
                    angle: -0.08,
                    child: Container(
                      width: 46,
                      height: 14,
                      color: const Color(0xAAE8D9A0),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
