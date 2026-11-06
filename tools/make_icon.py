"""Draws the app icon (run: python3 tools/make_icon.py). Needs Playwright."""
from playwright.sync_api import sync_playwright

def svg(bg, fg_scale):
    # Content sits in the middle; fg_scale shrinks it for the adaptive icon.
    bgrect = '<rect width="1024" height="1024" fill="url(#g)"/>' if bg else ''
    return f'''<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1024" viewBox="0 0 1024 1024">
<defs>
<linearGradient id="g" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#1D5BD6"/><stop offset="1" stop-color="#0A2466"/></linearGradient>
<linearGradient id="pin" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#FFE48A"/><stop offset="1" stop-color="#E0A22A"/></linearGradient>
</defs>
{bgrect}
<g transform="translate(512 512) scale({fg_scale}) translate(-512 -512)">
<path d="M170 800 C 330 800, 250 600, 420 600 S 560 760, 700 640" fill="none" stroke="#fff" stroke-opacity=".95" stroke-width="30" stroke-linecap="round" stroke-dasharray="2 62"/>
<circle cx="170" cy="800" r="26" fill="#fff"/>
<path d="M700 640 C 640 560 560 500 560 400 a140 140 0 1 1 280 0 C 840 500 760 560 700 640Z" fill="url(#pin)" stroke="#fff" stroke-width="14" stroke-linejoin="round"/>
<circle cx="700" cy="400" r="52" fill="#0A2466"/>
<path d="M676 404 l18 18 l34 -40" fill="none" stroke="#fff" stroke-width="16" stroke-linecap="round" stroke-linejoin="round"/>
</g></svg>'''

with sync_playwright() as p:
    b = p.chromium.launch()
    for name, bg, sc in [('icon', True, 1.0), ('icon_foreground', False, 0.72)]:
        pg = b.new_page(viewport={'width': 1024, 'height': 1024})
        pg.set_content(f'<body style="margin:0;background:transparent">{svg(bg, sc)}</body>')
        pg.screenshot(path=f'assets/icon/{name}.png', omit_background=True)
    b.close()
