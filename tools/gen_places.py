#!/usr/bin/env python3
"""Generates lib/features/map/places_data.dart.

The map artwork is drawn from real latitude/longitude (tools/mapgeo.py), so every
place lands exactly where its GPS position says.

Tiers: 1 major city, 2 regional town, 3 small town, 4 Cape Town suburb,
5 Cape Town neighbourhood (only visible at deep zoom).

Run:  python3 tools/gen_places.py            -> writes the Dart file
      python3 tools/gen_places.py --preview  -> also writes tools/preview.png
"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from mapgeo import proj

# name, province, lat, lng, tier
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
    # Cape Town metro: tier 4 = major suburbs, tier 5 = neighbourhoods (deep zoom)
    ("Sea Point", "Western Cape", -33.919, 18.385, 4),
    ("Camps Bay", "Western Cape", -33.95, 18.378, 4),
    ("Claremont", "Western Cape", -33.985, 18.466, 4),
    ("Constantia", "Western Cape", -34.025, 18.42, 4),
    ("Bellville", "Western Cape", -33.903, 18.629, 4),
    ("Durbanville", "Western Cape", -33.833, 18.649, 4),
    ("Khayelitsha", "Western Cape", -34.04, 18.678, 4),
    ("Mitchells Plain", "Western Cape", -34.05, 18.62, 4),
    ("Muizenberg", "Western Cape", -34.108, 18.47, 4),
    ("Simon's Town", "Western Cape", -34.19, 18.433, 4),
    ("Hout Bay", "Western Cape", -34.045, 18.36, 4),
    ("Table View", "Western Cape", -33.825, 18.49, 4),
    ("Century City", "Western Cape", -33.893, 18.51, 4),
    ("Milnerton", "Western Cape", -33.87, 18.495, 4),
    ("Fish Hoek", "Western Cape", -34.137, 18.43, 4),
    ("Kommetjie", "Western Cape", -34.14, 18.33, 4),
    ("Gordon's Bay", "Western Cape", -34.16, 18.87, 4),
    ("Strand", "Western Cape", -34.115, 18.825, 4),
    ("Blouberg", "Western Cape", -33.8, 18.47, 4),
    ("Kuils River", "Western Cape", -33.93, 18.68, 4),
    ("Woodstock", "Western Cape", -33.927, 18.447, 5),
    ("Observatory", "Western Cape", -33.94, 18.472, 5),
    ("Green Point", "Western Cape", -33.905, 18.405, 5),
    ("V&A Waterfront", "Western Cape", -33.903, 18.421, 5),
    ("Newlands", "Western Cape", -33.972, 18.455, 5),
    ("Bishopscourt", "Western Cape", -34.0, 18.455, 5),
    ("Tokai", "Western Cape", -34.06, 18.43, 5),
    ("Noordhoek", "Western Cape", -34.1, 18.375, 5),
    ("Kalk Bay", "Western Cape", -34.127, 18.449, 5),
    ("Cape Point", "Western Cape", -34.355, 18.497, 5),
    ("Parow", "Western Cape", -33.905, 18.598, 5),
    ("Goodwood", "Western Cape", -33.907, 18.557, 5),
    ("Brackenfell", "Western Cape", -33.88, 18.7, 5),
    ("Kraaifontein", "Western Cape", -33.843, 18.72, 5),
    ("Langa", "Western Cape", -33.945, 18.53, 5),
    ("Gugulethu", "Western Cape", -33.985, 18.565, 5),
    ("Athlone", "Western Cape", -33.965, 18.505, 5),
    ("Rondebosch", "Western Cape", -33.96, 18.475, 5),
    ("Wynberg", "Western Cape", -34.0, 18.47, 5),
    ("Plumstead", "Western Cape", -34.03, 18.465, 5),
    ("Lakeside", "Western Cape", -34.085, 18.47, 5),
    ("Bo-Kaap", "Western Cape", -33.92, 18.415, 5),
    ("Clifton", "Western Cape", -33.935, 18.378, 5),
    ("Llandudno", "Western Cape", -34.01, 18.34, 5),
    ("Scarborough", "Western Cape", -34.195, 18.375, 5),
    ("Pinelands", "Western Cape", -33.94, 18.5, 5),
    ("Tygerberg", "Western Cape", -33.88, 18.61, 5),
    ("Rosebank", "Western Cape", -33.955, 18.475, 5),
    ("Mowbray", "Western Cape", -33.945, 18.475, 5),
]


def compute():
    out = []
    for name, prov, lat, lng, tier in PLACES:
        fx, fy = proj(lat, lng)
        out.append((name, prov, lat, lng, tier, fx, fy))
    return out


def write_dart(places, path):
    lines = [
        "// GENERATED by tools/gen_places.py - edit that script, not this file.",
        "// Positions are fractions (0..1) of the map's width/height.",
        "import 'place.dart';",
        "",
        "const List<Place> kPlaces = [",
    ]
    for name, prov, lat, lng, tier, fx, fy in places:
        n = name.replace("'", "\\'")
        lines.append(
            f"  Place('{n}', '{prov}', {lat}, {lng}, {tier}, {fx:.5f}, {fy:.5f}),"
        )
    lines.append("];")
    Path(path).write_text("\n".join(lines) + "\n")


def preview(places, dst):
    from PIL import Image, ImageDraw
    im = Image.open(Path(dst).parent.parent / "assets/map/base.jpg").convert("RGB")
    W, H = im.size
    d = ImageDraw.Draw(im)
    for name, prov, lat, lng, tier, fx, fy in places:
        if tier > 3:
            continue
        x, y = fx * W, fy * H
        col = (255, 255, 0) if tier == 1 else (0, 255, 255) if tier == 2 else (255, 255, 255)
        d.ellipse([x - 4, y - 4, x + 4, y + 4], fill=col, outline=(0, 0, 0))
        d.text((x + 6, y - 5), name, fill=(255, 255, 255), stroke_width=2, stroke_fill=(0, 0, 0))
    im.save(dst)


if __name__ == "__main__":
    root = Path(__file__).resolve().parent.parent
    places = compute()
    write_dart(places, root / "lib/features/map/places_data.dart")
    print(f"wrote {len(places)} places")
    if "--preview" in sys.argv:
        preview(places, root / "tools/preview.png")
        print("wrote tools/preview.png")
