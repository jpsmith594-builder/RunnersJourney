import 'package:flutter/material.dart';

import 'map_tiles.dart';

/// The map is 9 wide by 19 tall.
const double kMapHeightOverWidth = 19 / 9;

/// Chooses the tile level that is just sharp enough for [neededWidth] screen
/// pixels across the whole map. Falls back to the sharpest level.
TileLevel pickLevel(List<TileLevel> levels, double neededWidth) {
  for (final l in levels) {
    if (l.wFull >= neededWidth) return l;
  }
  return levels.last;
}

/// Column / row of one tile in a level.
class TileRef {
  final int col, row;
  const TileRef(this.col, this.row);

  @override
  bool operator ==(Object other) =>
      other is TileRef && other.col == col && other.row == row;

  @override
  int get hashCode => Object.hash(col, row);
}

/// Tiles of [level] that touch the part of the map given as fractions
/// ([fx0],[fy0])-([fx1],[fy1]) of the whole map.
List<TileRef> visibleTiles(
    TileLevel level, double fx0, double fy0, double fx1, double fy1) {
  final w = level.wFull.toDouble();
  final h = w * kMapHeightOverWidth;
  final ox = (level.fx0 * w).round();
  final oy = (level.fy0 * h).round();
  final a = (fx0 * w - ox).clamp(0.0, level.pxW.toDouble());
  final b = (fx1 * w - ox).clamp(0.0, level.pxW.toDouble());
  final c = (fy0 * h - oy).clamp(0.0, level.pxH.toDouble());
  final d = (fy1 * h - oy).clamp(0.0, level.pxH.toDouble());
  if (b <= a || d <= c) return const [];
  final c0 = (a / kMapTile).floor();
  final c1 = (b / kMapTile).ceil() - 1;
  final r0 = (c / kMapTile).floor();
  final r1 = (d / kMapTile).ceil() - 1;
  return [
    for (var r = r0; r <= r1 && r < level.rows; r++)
      for (var col = c0; col <= c1 && col < level.cols; col++) TileRef(col, r),
  ];
}

/// Where a tile sits in map content coordinates (the map is [contentW] wide).
Rect tileRect(TileLevel level, TileRef t, double contentW) {
  final k = contentW / level.wFull;
  final ox = (level.fx0 * level.wFull).round();
  final oy = (level.fy0 * level.wFull * kMapHeightOverWidth).round();
  final x = t.col * kMapTile;
  final y = t.row * kMapTile;
  final tw = (level.pxW - x).clamp(0, kMapTile).toInt();
  final th = (level.pxH - y).clamp(0, kMapTile).toInt();
  return Rect.fromLTWH((ox + x) * k, (oy + y) * k, tw * k, th * k);
}

/// Draws the map artwork as sharp tiles for whatever part is on screen. Place
/// it inside the zoomable content, sized [contentW] x [contentW * 19 / 9]:
/// a low-resolution picture is always underneath, and tiles of the right
/// sharpness are drawn on top as the view zooms.
class MapTileLayer extends StatelessWidget {
  final TransformationController controller;
  final Size viewport;
  final double contentW;
  final double pixelRatio;

  const MapTileLayer({
    super.key,
    required this.controller,
    required this.viewport,
    required this.contentW,
    required this.pixelRatio,
  });

  Widget _tile(TileLevel level, TileRef t) {
    final r = tileRect(level, t, contentW);
    final path = '${level.dir}/${t.col}_${t.row}.jpg';
    // A hair of overlap hides seams between neighbouring tiles.
    return Positioned(
      key: ValueKey(path),
      left: r.left,
      top: r.top,
      width: r.width + 0.6,
      height: r.height + 0.6,
      child: Image.asset(
        path,
        fit: BoxFit.fill,
        filterQuality: FilterQuality.medium,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final contentH = contentW * kMapHeightOverWidth;
    return SizedBox(
      width: contentW,
      height: contentH,
      child: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final m = controller.value;
          final inv = Matrix4.tryInvert(m);
          final scale = m.getMaxScaleOnAxis();
          final children = <Widget>[
            Positioned.fill(
              child: Image.asset(kMapBase,
                  fit: BoxFit.fill, filterQuality: FilterQuality.medium),
            ),
          ];
          if (inv != null && viewport != Size.zero) {
            // Visible part of the map, with a margin so neighbours preload.
            final view = MatrixUtils.transformRect(
                inv, Offset.zero & viewport);
            final grown = view.inflate(viewport.shortestSide * 0.25);
            final fx0 = grown.left / contentW, fx1 = grown.right / contentW;
            final fy0 = grown.top / contentH, fy1 = grown.bottom / contentH;
            final needed = contentW * scale * pixelRatio;

            final global = pickLevel(kGlobalLevels, needed);
            for (final t in visibleTiles(global, fx0, fy0, fx1, fy1)) {
              children.add(_tile(global, t));
            }
            if (needed > kGlobalLevels.last.wFull) {
              final region = pickLevel(kRegionLevels, needed);
              for (final t in visibleTiles(region, fx0, fy0, fx1, fy1)) {
                children.add(_tile(region, t));
              }
            }
          }
          return Stack(clipBehavior: Clip.hardEdge, children: children);
        },
      ),
    );
  }
}
