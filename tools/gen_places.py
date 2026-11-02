#!/usr/bin/env python3
"""Generates lib/features/map/places_data.dart.

The artwork (assets/images/south_africa_map.jpg) is an illustration, not a real
projection, so real lat/lng cannot be used directly. Instead:

  * ANCHORS are towns/regions whose position on the artwork is known (the sign icons).
  * Every other town is placed relative to nearby anchors: its real offset (in degrees)
    from each anchor is converted to pixels and the anchors' estimates are blended
    (inverse-distance weighting). Anchors are exact.
  * OVERRIDES let you nudge any town by hand (pixel coordinates on the 1672x941 image).

Run:  python3 tools/gen_places.py            -> writes the Dart file
      python3 tools/gen_places.py --preview  -> also writes tools/preview.png to check placement
"""
import math
import sys
from pathlib import Path

W, H = 1672, 941  # artwork size in pixels; positions are stored as fractions

# name, province, lat, lng, tier (1 major .. 3 small)
PLACES = [
    # Western Cape
    ("Cape Town", "Western Cape", -33.92, 18.42, 1),
    ("Stellenbosch", "Western Cape", -33.93, 18.86, 2),
    ("Paarl", "Western Cape", -33.73, 18.97, 2),
    ("Franschhoek", "Western Cape", -33.91, 19.12, 3),
    ("Somerset West", "Western Cape", -34.08, 18.84, 3),
    ("Hermanus", "Western Cape", -34.42, 19.24, 2),
    ("Worcester", "Western Cape", -33.65, 19.45, 2),
    ("Swellendam", "Western Cape", -34.02, 20.44, 3),
    ("Mossel Bay", "Western Cape", -34.18, 22.14, 2),
    ("George", "Western Cape", -33.96, 22.46, 1),
    ("Oudtshoorn", "Western Cape", -33.59, 22.20, 3),
    ("Knysna", "Western Cape", -34.04, 23.05, 2),
    ("Plettenberg Bay", "Western Cape", -34.05, 23.37, 3),
    ("Beaufort West", "Western Cape", -32.35, 22.58, 3),
    ("West Coast", "Western Cape", -33.10, 18.03, 2),
    ("Garden Route", "Western Cape", -34.18, 21.70, 2),
    # Northern Cape
    ("Namaqua Flower Route", "Northern Cape", -29.66, 17.89, 2),
    ("Kimberley", "Northern Cape", -28.74, 24.77, 1),
    ("Upington", "Northern Cape", -28.45, 21.26, 2),
    ("Kuruman", "Northern Cape", -27.45, 23.43, 3),
    ("De Aar", "Northern Cape", -30.65, 24.01, 3),
    ("Sutherland", "Northern Cape", -32.40, 20.66, 3),
    # Eastern Cape
    ("Gqeberha", "Eastern Cape", -33.96, 25.60, 1),
    ("Jeffreys Bay", "Eastern Cape", -34.05, 24.91, 3),
    ("Makhanda", "Eastern Cape", -33.31, 26.52, 3),
    ("Port Alfred", "Eastern Cape", -33.59, 26.89, 3),
    ("East London", "Eastern Cape", -33.02, 27.91, 1),
    ("Komani", "Eastern Cape", -31.90, 26.88, 3),
    ("Mthatha", "Eastern Cape", -31.59, 28.78, 2),
    ("Graaff-Reinet", "Eastern Cape", -32.25, 24.54, 3),
    ("Cradock", "Eastern Cape", -32.16, 25.62, 3),
    # KwaZulu-Natal
    ("Durban", "KwaZulu-Natal", -29.86, 31.02, 1),
    ("Umhlanga", "KwaZulu-Natal", -29.73, 31.08, 3),
    ("Ballito", "KwaZulu-Natal", -29.54, 31.21, 3),
    ("Hillcrest", "KwaZulu-Natal", -29.78, 30.76, 3),
    ("Pietermaritzburg", "KwaZulu-Natal", -29.62, 30.39, 1),
    ("Howick", "KwaZulu-Natal", -29.48, 30.23, 3),
    ("Port Shepstone", "KwaZulu-Natal", -30.74, 30.45, 3),
    ("Richards Bay", "KwaZulu-Natal", -28.78, 32.04, 2),
    ("Ladysmith", "KwaZulu-Natal", -28.56, 29.78, 3),
    ("Newcastle", "KwaZulu-Natal", -27.76, 29.93, 3),
    ("Drakensberg Mountains", "KwaZulu-Natal", -28.95, 29.35, 2),
    # Gauteng
    ("Johannesburg", "Gauteng", -26.20, 28.05, 1),
    ("Soweto", "Gauteng", -26.27, 27.86, 2),
    ("Sandton", "Gauteng", -26.11, 28.06, 2),
    ("Pretoria", "Gauteng", -25.75, 28.19, 1),
    ("Centurion", "Gauteng", -25.86, 28.19, 2),
    ("Benoni", "Gauteng", -26.19, 28.32, 3),
    ("Krugersdorp", "Gauteng", -26.10, 27.77, 3),
    ("Vereeniging", "Gauteng", -26.67, 27.93, 3),
    # Free State
    ("Bloemfontein", "Free State", -29.12, 26.21, 1),
    ("Welkom", "Free State", -27.98, 26.73, 3),
    ("Kroonstad", "Free State", -27.65, 27.23, 3),
    ("Bethlehem", "Free State", -28.23, 28.31, 3),
    ("Parys", "Free State", -26.90, 27.46, 3),
    ("Harrismith", "Free State", -28.27, 29.13, 3),
    # North West
    ("Rustenburg", "North West", -25.67, 27.24, 2),
    ("Mahikeng", "North West", -25.86, 25.64, 2),
    ("Potchefstroom", "North West", -26.71, 27.10, 3),
    ("Klerksdorp", "North West", -26.85, 26.67, 3),
    ("Sun City", "North West", -25.34, 27.09, 3),
    # Mpumalanga
    ("Mbombela", "Mpumalanga", -25.47, 30.97, 1),
    ("eMalahleni", "Mpumalanga", -25.87, 29.23, 3),
    ("Middelburg", "Mpumalanga", -25.77, 29.46, 3),
    ("Secunda", "Mpumalanga", -26.55, 29.17, 3),
    ("Hazyview", "Mpumalanga", -25.04, 31.13, 3),
    ("Sabie", "Mpumalanga", -25.10, 30.78, 3),
    # Limpopo
    ("Polokwane", "Limpopo", -23.90, 29.45, 1),
    ("Tzaneen", "Limpopo", -23.83, 30.16, 3),
    ("Mokopane", "Limpopo", -24.19, 29.01, 3),
    ("Thohoyandou", "Limpopo", -22.95, 30.48, 3),
    ("Phalaborwa", "Limpopo", -23.94, 31.14, 3),
    ("Bela-Bela", "Limpopo", -24.88, 28.29, 3),
]

# Known positions on the artwork (icon centre of each illustrated sign), in pixels.
ANCHORS = {
    "Cape Town": (822, 198),
    "Pretoria": (1212, 181),
    "Johannesburg": (1360, 257),
    "Bloemfontein": (761, 444),
    "Drakensberg Mountains": (1110, 386),
    "Durban": (1413, 521),
    "East London": (1266, 642),
    "Gqeberha": (978, 700),
    "George": (693, 666),
    "Garden Route": (428, 640),
    "West Coast": (254, 418),
    "Namaqua Flower Route": (500, 318),
}

# Hand-tuned positions (pixels) for towns that the blending put in a poor spot.
OVERRIDES = {
    # Cape Town area
    "Stellenbosch": (872, 252), "Paarl": (930, 236), "Somerset West": (842, 274),
    "Franschhoek": (905, 276),
    # South-west / Garden Route side
    "Swellendam": (520, 520), "Oudtshoorn": (620, 590), "Knysna": (745, 625),
    "Plettenberg Bay": (815, 642), "Jeffreys Bay": (900, 668),
    "Beaufort West": (600, 505), "De Aar": (700, 505), "Sutherland": (560, 450),
    # Northern Cape (west)
    "Upington": (430, 395), "Kuruman": (600, 350),
    # North-west
    "Rustenburg": (1160, 240), "Mahikeng": (1060, 262), "Sun City": (1195, 215),
    # Gauteng crowd around the Johannesburg / Pretoria signs
    "Sandton": (1405, 236), "Soweto": (1320, 285), "Krugersdorp": (1300, 240),
    "Benoni": (1415, 287), "Vereeniging": (1350, 322), "Centurion": (1237, 216),
    # Mpumalanga / Limpopo squeezed onto the land at the top right
    "Secunda": (1400, 332), "eMalahleni": (1470, 288), "Middelburg": (1500, 312),
    "Mbombela": (1520, 265), "Hazyview": (1572, 238), "Sabie": (1500, 212),
    "Polokwane": (1318, 150), "Bela-Bela": (1262, 215), "Tzaneen": (1445, 150),
    "Phalaborwa": (1520, 172), "Thohoyandou": (1400, 122), "Mokopane": (1345, 180),
    # Durban area
    "Umhlanga": (1450, 492), "Ballito": (1495, 470), "Hillcrest": (1375, 498),
    "Pietermaritzburg": (1340, 468), "Howick": (1300, 430),
}

PX_PER_DEG_X = 100.0
PX_PER_DEG_Y = 115.0


def blend(lat, lng):
    num_x = num_y = den = 0.0
    by_name = {p[0]: p for p in PLACES}
    for name, (ax, ay) in ANCHORS.items():
        _, _, alat, alng, _ = by_name[name]
        dlat, dlng = lat - alat, lng - alng
        d2 = dlat * dlat + dlng * dlng
        if d2 < 1e-9:
            return ax, ay
        w = 1.0 / (d2 ** 1.5)
        num_x += w * (ax + dlng * PX_PER_DEG_X)
        num_y += w * (ay - dlat * PX_PER_DEG_Y)
        den += w
    return num_x / den, num_y / den


def compute():
    out = []
    for name, prov, lat, lng, tier in PLACES:
        if name in OVERRIDES:
            x, y = OVERRIDES[name]
        else:
            x, y = blend(lat, lng)
        x = min(max(x, 40), W - 40)
        y = min(max(y, 40), H - 40)
        out.append((name, prov, lat, lng, tier, x, y, name in ANCHORS))
    return out


def write_dart(places, path):
    lines = [
        "// GENERATED by tools/gen_places.py - edit that script, not this file.",
        "// Positions are fractions (0..1) of the map artwork's width/height.",
        "import 'place.dart';",
        "",
        "const List<Place> kPlaces = [",
    ]
    for name, prov, lat, lng, tier, x, y, ill in places:
        lines.append(
            f"  Place('{name}', '{prov}', {lat}, {lng}, {tier}, "
            f"{x / W:.4f}, {y / H:.4f}, {'true' if ill else 'false'}),"
        )
    lines.append("];")
    Path(path).write_text("\n".join(lines) + "\n")


def preview(places, src, dst):
    from PIL import Image, ImageDraw
    im = Image.open(src).convert("RGB")
    d = ImageDraw.Draw(im)
    for name, prov, lat, lng, tier, x, y, ill in places:
        col = (255, 0, 0) if ill else (255, 255, 0) if tier == 1 else (0, 255, 255) if tier == 2 else (255, 255, 255)
        r = 7 if ill else 5
        d.ellipse([x - r, y - r, x + r, y + r], fill=col, outline=(0, 0, 0))
        d.text((x + 8, y - 5), name, fill=(255, 255, 255), stroke_width=2, stroke_fill=(0, 0, 0))
    im.save(dst)


if __name__ == "__main__":
    root = Path(__file__).resolve().parent.parent
    places = compute()
    write_dart(places, root / "lib/features/map/places_data.dart")
    print(f"wrote {len(places)} places")
    if "--preview" in sys.argv:
        preview(places, root / "assets/images/south_africa_map.jpg", root / "tools/preview.png")
        print("wrote tools/preview.png")
