#!/usr/bin/env python3
"""Draws the portrait South Africa map and cuts it into zoom levels.

Nothing here is a photo or an upscaled picture: every level is drawn from the same
description of the land (coast, border, biomes, mountains, trees), so deeper levels
have real extra detail and stay sharp when the app zooms in.

Output (all under assets/map/):
  base.jpg              whole map, 900 x 1900 (always shown underneath)
  tiles/2, tiles/3      whole map at 1800 and 3600 px wide, cut into 600 px tiles
  cape/4, cape/5, cape/6  Cape Town metro only, at 7200 / 14400 / 28800 px equivalent
and lib/features/map/map_tiles.dart describing them for the app.

Usage:
  python3 tools/gen_map_art.py --preview OUT.png        draw the base map only
  python3 tools/gen_map_art.py --crop LEVEL TX TY OUT.png   draw one tile
  python3 tools/gen_map_art.py --all                    draw everything (a few minutes)
"""
import math
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

sys.path.insert(0, str(Path(__file__).resolve().parent))
import mapgeo as G  # noqa: E402

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "assets" / "map"
DART = ROOT / "lib" / "features" / "map" / "map_tiles.dart"
TILE = 600
BASE_W = 900
PAD = 110  # extra pixels drawn around a tile so effects line up across tile edges

# name, directory, full-frame width equivalent, region ("all" or "cape")
LEVELS = [
    (2, "tiles/2", 1800, "all"),
    (3, "tiles/3", 3600, "all"),
    (4, "cape/4", 7200, "cape"),
    (5, "cape/5", 14400, "cape"),
    (6, "cape/6", 28800, "cape"),
]


# ----------------------------------------------------------------------------
# Deterministic noise
# ----------------------------------------------------------------------------
def hash2(i, j, seed):
    with np.errstate(over="ignore"):
        i = np.asarray(i).astype(np.int64).astype(np.uint64)
        j = np.asarray(j).astype(np.int64).astype(np.uint64)
        h = i * np.uint64(0x9E3779B97F4A7C15) ^ (j + np.uint64(seed)) * np.uint64(0xC2B2AE3D27D4EB4F)
        h ^= h >> np.uint64(33)
        h *= np.uint64(0xFF51AFD7ED558CCD)
        h ^= h >> np.uint64(33)
        h *= np.uint64(0xC4CEB9FE1A85EC53)
        h ^= h >> np.uint64(33)
    return (h >> np.uint64(11)).astype(np.float64) / float(1 << 53)


def value_noise(u, v, seed):
    iu, iv = np.floor(u), np.floor(v)
    fu, fv = u - iu, v - iv
    fu = fu * fu * (3 - 2 * fu)
    fv = fv * fv * (3 - 2 * fv)
    a = hash2(iu, iv, seed)
    b = hash2(iu + 1, iv, seed)
    c = hash2(iu, iv + 1, seed)
    d = hash2(iu + 1, iv + 1, seed)
    return a * (1 - fu) * (1 - fv) + b * fu * (1 - fv) + c * (1 - fu) * fv + d * fu * fv


def fbm(mx, my, freq, octaves, seed):
    total, amp, norm = 0.0, 1.0, 0.0
    for o in range(octaves):
        total = total + amp * value_noise(mx * freq, my * freq, seed + o * 7)
        norm += amp
        amp *= 0.5
        freq *= 2.0
    return total / norm


def smoothstep(a, b, x):
    t = np.clip((x - a) / (b - a), 0.0, 1.0)
    return t * t * (3 - 2 * t)


def bilinear(arr, fx, fy):
    h, w = arr.shape[:2]
    x = np.clip(fx * w - 0.5, 0, w - 1.001)
    y = np.clip(fy * h - 0.5, 0, h - 1.001)
    x0, y0 = np.floor(x).astype(int), np.floor(y).astype(int)
    tx, ty = x - x0, y - y0
    if arr.ndim == 3:
        tx, ty = tx[..., None], ty[..., None]
    return (arr[y0, x0] * (1 - tx) * (1 - ty) + arr[y0, x0 + 1] * tx * (1 - ty)
            + arr[y0 + 1, x0] * (1 - tx) * ty + arr[y0 + 1, x0 + 1] * tx * ty)


# ----------------------------------------------------------------------------
# Geography, built once per process
# ----------------------------------------------------------------------------
def metric(points):
    return np.array([G.to_metric(*G.proj(la, ln)) for la, ln in points], float)


def fractal(pts, levels, rough, seed):
    """Midpoint displacement: makes a coast look natural while keeping its shape."""
    pts = np.asarray(pts, float)
    rng = np.random.default_rng(seed)
    for _ in range(levels):
        a, b = pts[:-1], pts[1:]
        d = b - a
        length = np.hypot(d[:, 0], d[:, 1])
        n = np.stack([-d[:, 1], d[:, 0]], 1) / np.maximum(length, 1e-12)[:, None]
        off = np.clip(rng.normal(0, 1, len(a)), -2.2, 2.2) * length * rough
        mid = (a + b) / 2 + n * off[:, None]
        out = np.empty((len(pts) * 2 - 1, 2))
        out[0::2], out[1::2] = pts, mid
        pts = out
        rough *= 0.84
    return pts


def closed(pts, levels, rough, seed):
    pts = np.vstack([pts, pts[:1]])
    return fractal(pts, levels, rough, seed)[:-1]


_GEO = None


def geo():
    global _GEO
    if _GEO is not None:
        return _GEO
    coast = fractal(metric(G.COAST), 7, 0.15, 1)
    border = fractal(metric(G.BORDER), 6, 0.06, 2)
    g = {
        "coast": coast,
        "border": border,
        "sa": np.vstack([coast, border]),
        "main": np.vstack([metric(G.MAINLAND_BEFORE), coast, metric(G.MAINLAND_AFTER)]),
        "lesotho": closed(metric(G.LESOTHO), 5, 0.06, 3),
        "eswatini": closed(metric(G.ESWATINI), 5, 0.06, 4),
        "rivers": [fractal(metric(r), 5, 0.12, 10 + i) for i, r in enumerate(G.RIVERS)],
    }
    g["fields"] = build_fields()
    g["peaks"] = build_peaks()
    _GEO = g
    return g


def build_fields():
    gw, gh = 380, 800
    lng = G.LNG0 + (np.arange(gw) + 0.5) / gw * (G.LNG1 - G.LNG0)
    lat = G.LAT_N - (np.arange(gh) + 0.5) / gh * (G.LAT_N - G.LAT_S)
    lg, lt = np.meshgrid(lng, lat)
    num = np.zeros((gh, gw, 8))
    den = np.zeros((gh, gw))
    for alat, alng, ground, tree, forest, flower in G.BIOMES:
        d2 = (lt - alat) ** 2 + ((lg - alng) * 0.88) ** 2 + 0.04
        w = d2 ** -1.3
        vec = np.array([*ground, *tree, forest * 255, flower * 255]) / 255.0
        num += w[..., None] * vec
        den += w
    return num / den[..., None]


def build_peaks():
    """Mountain peaks as (x, y, size, snow, flat) in metric units, north first."""
    rng = np.random.default_rng(99)
    peaks = []
    unit = 0.14
    for _name, line, size, snow in G.MOUNTAINS:
        pts = metric(line)
        step = size * unit * 0.55
        for a, b in zip(pts[:-1], pts[1:]):
            length = float(np.hypot(*(b - a)))
            n = max(1, int(length / step))
            for k in range(n + 1):
                t = k / n
                p = a + (b - a) * t
                p = p + rng.normal(0, step * 0.35, 2)
                peaks.append((p[0], p[1], size * (0.8 + 0.5 * rng.random()), snow, False))
                if rng.random() < 0.9:  # foothills either side of the ridge
                    q = p + rng.normal(0, step * 1.1, 2)
                    peaks.append((q[0], q[1], size * 0.55 * (0.8 + 0.5 * rng.random()), False, False))
    for lat, lng, size in G.MESAS:
        x, y = G.to_metric(*G.proj(lat, lng))
        peaks.append((x, y, size, False, True))
    peaks.sort(key=lambda p: p[1])
    return peaks


# ----------------------------------------------------------------------------
# Tile drawing
# ----------------------------------------------------------------------------
class Ctx:
    def __init__(self, wfull, ox, oy, tw, th):
        self.wfull, self.ox, self.oy, self.tw, self.th = wfull, ox, oy, tw, th
        self.ppu = wfull / 9.0  # pixels per metric unit
        self.hfull = wfull * 19 / 9.0
        xs = (ox + np.arange(tw) + 0.5) / self.ppu
        ys = (oy + np.arange(th) + 0.5) / self.ppu
        self.mx, self.my = np.meshgrid(xs, ys)
        self.fx, self.fy = self.mx / 9.0, self.my / 19.0

    def px(self, poly, shift=0.0):
        return poly * self.ppu - np.array([self.ox, self.oy]) + shift


def crisp_mask(polys, ctx, pad, ss=2):
    w, h = ctx.tw + 2 * pad, ctx.th + 2 * pad
    img = Image.new("L", (w * ss, h * ss), 0)
    d = ImageDraw.Draw(img)
    for p in polys:
        d.polygon((ctx.px(p, pad) * ss).ravel().tolist(), fill=255)
    img = img.resize((w, h), Image.BOX)
    return np.asarray(img, np.float32) / 255.0


def blurred(polys, ctx, sigma):
    """Soft version of a land mask (distance-to-coast feel) drawn at low resolution."""
    ds = max(1.0, sigma / 8.0)
    pad = int(3 * sigma) + 2
    w = int(math.ceil((ctx.tw + 2 * pad) / ds))
    h = int(math.ceil((ctx.th + 2 * pad) / ds))
    img = Image.new("L", (w, h), 0)
    d = ImageDraw.Draw(img)
    for p in polys:
        d.polygon((ctx.px(p, pad) / ds).ravel().tolist(), fill=255)
    img = img.filter(ImageFilter.GaussianBlur(sigma / ds))
    box = (pad / ds, pad / ds, (pad + ctx.tw) / ds, (pad + ctx.th) / ds)
    img = img.resize((ctx.tw, ctx.th), Image.BICUBIC, box=box)
    return np.asarray(img, np.float32) / 255.0


def lerp(a, b, t):
    return a + (b - a) * t


DEEP = np.array([0.035, 0.25, 0.38])
MID = np.array([0.06, 0.47, 0.62])
SHALLOW = np.array([0.28, 0.78, 0.78])
SAND = np.array([0.91, 0.83, 0.59])
FLOWERS = np.array([[0.93, 0.42, 0.60], [0.95, 0.62, 0.20], [0.62, 0.36, 0.78],
                    [0.98, 0.88, 0.30], [0.96, 0.96, 0.96]])


def draw_trees(ctx, ov, ss, fields, main_p, sa_p):
    """Tree canopies and flowers, placed from a world-fixed grid so every level and
    every tile agrees on where each one is."""
    d = ImageDraw.Draw(ov)
    blobs = []  # (cy_px, cx_px, r_px, colour, kind)
    for octave in range(-1, 12):
        cell = 0.035 * 2.0 ** (-octave)
        rad = 0.62 * cell * ctx.ppu
        if rad < 1.6 or rad > 13:
            continue
        x0 = ctx.ox / ctx.ppu - cell * 1.5
        x1 = (ctx.ox + ctx.tw) / ctx.ppu + cell * 1.5
        y0 = ctx.oy / ctx.ppu - cell * 1.5
        y1 = (ctx.oy + ctx.th) / ctx.ppu + cell * 1.5
        ii, jj = np.meshgrid(np.arange(int(x0 / cell), int(x1 / cell) + 2),
                             np.arange(int(y0 / cell), int(y1 / cell) + 2))
        s = 100 + octave * 4
        cx = (ii + 0.15 + 0.7 * hash2(ii, jj, s)) * cell
        cy = (jj + 0.15 + 0.7 * hash2(ii, jj, s + 1)) * cell
        px = cx * ctx.ppu - ctx.ox
        py = cy * ctx.ppu - ctx.oy
        ix = np.clip(np.round(px).astype(int) + PAD, 0, main_p.shape[1] - 1)
        iy = np.clip(np.round(py).astype(int) + PAD, 0, main_p.shape[0] - 1)
        on_land = main_p[iy, ix] > 0.95
        sa = sa_p[iy, ix]
        f = bilinear(fields, cx / 9.0, cy / 19.0)
        prob = f[..., 6] * (0.35 + 0.65 * sa)
        keep = on_land & (hash2(ii, jj, s + 2) < prob * 0.72)
        tree = np.clip(f[..., 3:6] * (0.70 + 0.55 * hash2(ii, jj, s + 3))[..., None], 0, 1)
        for x, y, c in zip(px[keep], py[keep], tree[keep]):
            blobs.append((y, x, rad * (0.8 + 0.4 * ((x * 7.13 + y * 3.7) % 1.0)), c, 0))
        if rad < 14:  # flowers
            fl = f[..., 7]
            fkeep = on_land & (hash2(ii, jj, s + 4) < fl * 0.9) & (sa > 0.5)
            pick = (hash2(ii, jj, s + 5) * len(FLOWERS)).astype(int)
            for x, y, k in zip(px[fkeep], py[fkeep], pick[fkeep]):
                blobs.append((y - 1e4, x, max(1.2, rad * 0.45), FLOWERS[k], 1))
    blobs.sort(key=lambda b: b[0])
    if len(blobs) > 60000:
        blobs = blobs[:: len(blobs) // 60000 + 1]
    for y, x, r, c, kind in blobs:
        if x < -r * 2 or y < -r * 2 or x > ctx.tw + r * 2 or y > ctx.th + r * 2:
            continue
        if kind == 1:
            col = tuple(int(v * 255) for v in c) + (255,)
            d.ellipse([(x - r) * ss, (y - r) * ss, (x + r) * ss, (y + r) * ss], fill=col)
            continue
        dark = tuple(int(v * 255 * 0.52) for v in c) + (255,)
        body = tuple(int(v * 255) for v in c) + (255,)
        lite = tuple(int(min(1, v * 1.35 + 0.05) * 255) for v in c) + (255,)
        d.ellipse([(x - r * 0.85) * ss, (y - r * 0.55) * ss, (x + r * 1.15) * ss, (y + r * 1.0) * ss], fill=dark)
        d.ellipse([(x - r) * ss, (y - r * 0.9) * ss, (x + r) * ss, (y + r * 0.8) * ss], fill=body)
        if r >= 4:
            d.ellipse([(x - r * 0.65) * ss, (y - r * 0.8) * ss, (x + r * 0.1) * ss, (y - r * 0.15) * ss], fill=lite)


def draw_mountains(ctx, ov, ss, peaks):
    d = ImageDraw.Draw(ov)
    unit = 0.14 * ctx.ppu
    for x, y, size, snow, flat in peaks:
        bw = size * unit
        if bw < 3:
            continue
        cx = x * ctx.ppu - ctx.ox
        cy = y * ctx.ppu - ctx.oy
        bh = bw * 0.85
        if cx < -bw or cx > ctx.tw + bw or cy < -bh - 4 or cy > ctx.th + bh * 0.4 + 4:
            continue
        lh, rh = (0.66, 0.54, 0.40), (0.44, 0.35, 0.27)
        lc = tuple(int(v * 255) for v in lh) + (255,)
        rc = tuple(int(v * 255) for v in rh) + (255,)
        if flat:
            top = bw * 0.34
            d.polygon([((cx - bw / 2) * ss, cy * ss), ((cx - top) * ss, (cy - bh) * ss),
                       (cx * ss, (cy - bh) * ss), (cx * ss, cy * ss)], fill=lc)
            d.polygon([(cx * ss, cy * ss), (cx * ss, (cy - bh) * ss),
                       ((cx + top) * ss, (cy - bh) * ss), ((cx + bw / 2) * ss, cy * ss)], fill=rc)
            continue
        d.polygon([((cx - bw / 2) * ss, cy * ss), (cx * ss, (cy - bh) * ss), (cx * ss, cy * ss)], fill=lc)
        d.polygon([(cx * ss, (cy - bh) * ss), ((cx + bw / 2) * ss, cy * ss), (cx * ss, cy * ss)], fill=rc)
        if snow:
            k = 0.28
            sl, sr = (0.97, 0.98, 1.0), (0.80, 0.84, 0.92)
            d.polygon([((cx - bw / 2 * k) * ss, (cy - bh * (1 - k)) * ss), (cx * ss, (cy - bh) * ss),
                       (cx * ss, (cy - bh * (1 - k)) * ss)],
                      fill=tuple(int(v * 255) for v in sl) + (255,))
            d.polygon([(cx * ss, (cy - bh) * ss), ((cx + bw / 2 * k) * ss, (cy - bh * (1 - k)) * ss),
                       (cx * ss, (cy - bh * (1 - k)) * ss)],
                      fill=tuple(int(v * 255) for v in sr) + (255,))


def draw_dashed(ctx, ov, ss, pts_m, dash, gap, width, color):
    d = ImageDraw.Draw(ov)
    p = pts_m * ctx.ppu
    seg = np.diff(p, axis=0)
    length = np.hypot(seg[:, 0], seg[:, 1])
    cum = np.concatenate([[0.0], np.cumsum(length)])
    period = dash + gap
    w = max(1, int(round(width * ss)))
    for i in range(len(length)):
        a, b = p[i], p[i + 1]
        if (max(a[0], b[0]) < ctx.ox - 20 or min(a[0], b[0]) > ctx.ox + ctx.tw + 20
                or max(a[1], b[1]) < ctx.oy - 20 or min(a[1], b[1]) > ctx.oy + ctx.th + 20):
            continue
        s0, s1 = cum[i], cum[i + 1]
        k = int(s0 // period)
        while k * period < s1:
            d0, d1 = max(k * period, s0), min(k * period + dash, s1)
            if d1 > d0 and length[i] > 0:
                t0, t1 = (d0 - s0) / length[i], (d1 - s0) / length[i]
                q0 = a + (b - a) * t0 - np.array([ctx.ox, ctx.oy])
                q1 = a + (b - a) * t1 - np.array([ctx.ox, ctx.oy])
                d.line([q0[0] * ss, q0[1] * ss, q1[0] * ss, q1[1] * ss], fill=color, width=w)
            k += 1


def render(wfull, ox, oy, tw, th):
    g = geo()
    ctx = Ctx(wfull, ox, oy, tw, th)
    ss = 2
    sl = (slice(PAD, PAD + th), slice(PAD, PAD + tw))

    main_p = crisp_mask([g["main"]], ctx, PAD, ss)
    sa_p = crisp_mask([g["sa"]], ctx, PAD, ss)
    main, sa = main_p[sl], sa_p[sl]
    leso = crisp_mask([g["lesotho"]], ctx, 0, ss)
    esw = crisp_mask([g["eswatini"]], ctx, 0, ss)

    # --- sea ---
    bm_deep = blurred([g["main"]], ctx, 0.025 * wfull)
    bm_shal = blurred([g["main"]], ctx, 0.006 * wfull)
    bm_foam = blurred([g["main"]], ctx, max(0.9, 0.0011 * wfull))
    bm_beach = blurred([g["main"]], ctx, max(1.0, 0.0018 * wfull))
    water = lerp(DEEP, MID, smoothstep(0.02, 0.25, bm_deep)[..., None])
    water = lerp(water, SHALLOW, smoothstep(0.12, 0.50, bm_shal)[..., None])
    wave = fbm(ctx.mx * 9, ctx.my * 9 * 2.5, 1.0, 4, 31)
    water = water * (0.93 + 0.14 * wave)[..., None]

    # --- land ---
    f = bilinear(g["fields"], ctx.fx, ctx.fy)
    ground = f[..., 0:3]
    t1 = fbm(ctx.mx, ctx.my, 3.0, 4, 11)
    t2 = fbm(ctx.mx, ctx.my, 26.0, 3, 12)
    ground = ground * (0.84 + 0.32 * t1)[..., None] * (0.95 + 0.10 * t2)[..., None]
    muted = ground * 0.55 + np.array([0.78, 0.70, 0.55]) * 0.45
    neighbours = np.clip(main - sa, 0, 1)[..., None]
    land = lerp(ground, muted * 0.96, neighbours)
    land = lerp(land, np.array([0.66, 0.74, 0.60]), (0.45 * leso)[..., None])
    land = lerp(land, np.array([0.50, 0.70, 0.40]), (0.25 * esw)[..., None])

    # soft hill shading, lit from the north-west
    h0 = fbm(ctx.mx, ctx.my, 4.0, 5, 21)
    h1 = fbm(ctx.mx + 0.02, ctx.my + 0.02, 4.0, 5, 21)
    land = land * np.clip(1 + 5.0 * (h0 - h1), 0.80, 1.20)[..., None]

    # beaches along the coast
    patch = fbm(ctx.mx, ctx.my, 14.0, 3, 41)
    beach = np.clip((0.82 - bm_beach) / 0.30, 0, 1) * main * np.clip(patch * 1.6 - 0.1, 0, 1)
    land = lerp(land, SAND, (0.85 * beach)[..., None])

    img = lerp(water, land, main[..., None])
    foam = np.exp(-(((bm_foam - 0.30) / 0.11) ** 2)) * (1 - main)
    foam = foam * (0.65 + 0.7 * fbm(ctx.mx, ctx.my, 60.0, 2, 51))
    img = lerp(img, np.array([0.96, 0.99, 0.99]), (0.8 * np.clip(foam, 0, 1))[..., None])

    # --- drawn details ---
    ov = Image.new("RGBA", (tw * ss, th * ss), (0, 0, 0, 0))
    river_w = max(1.6, 0.0019 * wfull)
    dr = ImageDraw.Draw(ov)
    for r in g["rivers"]:
        pts = (ctx.px(r) * ss).ravel().tolist()
        dr.line(pts, fill=(92, 168, 216, 255), width=max(1, int(river_w * ss)), joint="curve")
    draw_trees(ctx, ov, ss, g["fields"], main_p, sa_p)
    draw_mountains(ctx, ov, ss, g["peaks"])
    cream = (255, 247, 220, 235)
    draw_dashed(ctx, ov, ss, g["border"], 0.011 * wfull, 0.007 * wfull, max(1.2, 0.0014 * wfull), cream)
    draw_dashed(ctx, ov, ss, np.vstack([g["lesotho"], g["lesotho"][:1]]), 0.006 * wfull,
                0.006 * wfull, max(1.0, 0.0010 * wfull), (255, 247, 220, 190))
    draw_dashed(ctx, ov, ss, np.vstack([g["eswatini"], g["eswatini"][:1]]), 0.006 * wfull,
                0.006 * wfull, max(1.0, 0.0010 * wfull), (255, 247, 220, 190))
    ov = ov.resize((tw, th), Image.BOX)
    ova = np.asarray(ov, np.float32) / 255.0
    a = ova[..., 3:4]
    rgb = np.where(a > 0, ova[..., :3] / np.maximum(a, 1e-6), 0)
    img = img * (1 - a) + rgb * a

    # --- finish: vignette and grain ---
    edge = np.minimum(np.minimum(ctx.fx, 1 - ctx.fx), np.minimum(ctx.fy, 1 - ctx.fy))
    vig = 1 - 0.30 * np.clip(1 - edge / 0.07, 0, 1) ** 1.5
    img = img * vig[..., None]
    grain = hash2(ctx.mx * ctx.ppu, ctx.my * ctx.ppu, 7) - 0.5
    img = img + (grain * 0.025)[..., None]
    return Image.fromarray((np.clip(img, 0, 1) * 255 + 0.5).astype(np.uint8))


# ----------------------------------------------------------------------------
# Levels and files
# ----------------------------------------------------------------------------
def level_region(wfull, region):
    """Pixel window (x0, y0, x1, y1) a level covers, in that level's own pixels."""
    k = wfull / G.W3
    if region == "all":
        return 0, 0, int(round(G.W3 * k)), int(round(G.H3 * k))
    return (int(G.CAPE_X0 * k), int(G.CAPE_Y0 * k), int(G.CAPE_X1 * k), int(G.CAPE_Y1 * k))


def jobs():
    out = []
    for lv, d, wfull, region in LEVELS:
        x0, y0, x1, y1 = level_region(wfull, region)
        cols = math.ceil((x1 - x0) / TILE)
        rows = math.ceil((y1 - y0) / TILE)
        for ty in range(rows):
            for tx in range(cols):
                out.append((lv, d, wfull, x0, y0, x1, y1, tx, ty))
    return out


def do_job(job):
    lv, d, wfull, x0, y0, x1, y1, tx, ty = job
    ox, oy = x0 + tx * TILE, y0 + ty * TILE
    tw, th = min(TILE, x1 - ox), min(TILE, y1 - oy)
    img = render(wfull, ox, oy, tw, th)
    path = OUT / d / f"{tx}_{ty}.jpg"
    path.parent.mkdir(parents=True, exist_ok=True)
    img.save(path, quality=84, optimize=True)
    return str(path)


def write_dart():
    lines = [
        "// GENERATED by tools/gen_map_art.py - do not edit.",
        "",
        "/// One zoom level of the map artwork, cut into square tiles.",
        "class TileLevel {",
        "  /// Asset folder holding tiles named `<column>_<row>.jpg`.",
        "  final String dir;",
        "",
        "  /// Width in pixels this level would have if it covered the whole map. The app",
        "  /// picks the level whose value is just above the screen pixels it needs.",
        "  final int wFull;",
        "",
        "  /// Part of the map this level covers, as fractions of the whole map.",
        "  final double fx0, fy0, fx1, fy1;",
        "",
        "  /// Pixel size of the covered part.",
        "  final int pxW, pxH;",
        "",
        "  const TileLevel(this.dir, this.wFull, this.fx0, this.fy0, this.fx1, this.fy1,",
        "      this.pxW, this.pxH);",
        "",
        "  int get cols => (pxW / kMapTile).ceil();",
        "  int get rows => (pxH / kMapTile).ceil();",
        "}",
        "",
        "const int kMapTile = %d;" % TILE,
        "const String kMapBase = 'assets/map/base.jpg';",
        "",
    ]
    for name, region in (("kGlobalLevels", "all"), ("kRegionLevels", "cape")):
        lines.append("const List<TileLevel> %s = [" % name)
        for lv, d, wfull, rg in LEVELS:
            if rg != region:
                continue
            x0, y0, x1, y1 = level_region(wfull, rg)
            k = wfull / G.W3
            fx0, fx1 = x0 / (G.W3 * k), x1 / (G.W3 * k)
            fy0, fy1 = y0 / (G.H3 * k), y1 / (G.H3 * k)
            lines.append("  TileLevel('assets/map/%s', %d, %.6f, %.6f, %.6f, %.6f, %d, %d)," % (
                d, wfull, fx0, fy0, fx1, fy1, x1 - x0, y1 - y0))
        lines.append("];")
        lines.append("")
    DART.write_text("\n".join(lines))


def main(argv):
    if "--preview" in argv:
        out = argv[argv.index("--preview") + 1]
        render(BASE_W, 0, 0, BASE_W, BASE_W * 19 // 9).save(out)
        print("wrote", out)
        return
    if "--crop" in argv:
        i = argv.index("--crop")
        lv, tx, ty, out = int(argv[i + 1]), int(argv[i + 2]), int(argv[i + 3]), argv[i + 4]
        job = [j for j in jobs() if j[0] == lv and j[7] == tx and j[8] == ty][0]
        _, d, wfull, x0, y0, x1, y1, _, _ = job
        ox, oy = x0 + tx * TILE, y0 + ty * TILE
        render(wfull, ox, oy, min(TILE, x1 - ox), min(TILE, y1 - oy)).save(out)
        print("wrote", out)
        return
    if "--all" in argv:
        from multiprocessing import Pool
        OUT.mkdir(parents=True, exist_ok=True)
        render(BASE_W, 0, 0, BASE_W, BASE_W * 19 // 9).save(OUT / "base.jpg", quality=86, optimize=True)
        todo = jobs()
        with Pool(2) as pool:
            for n, path in enumerate(pool.imap_unordered(do_job, todo), 1):
                print("%d/%d %s" % (n, len(todo), path), flush=True)
        write_dart()
        print("wrote", DART)
        return
    print(__doc__)


if __name__ == "__main__":
    main(sys.argv)
