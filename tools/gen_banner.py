#!/usr/bin/env python3
"""
Generates docs/banner.svg in the grimh3xx card style (same layout as
SecureArchSetup / usbscope): dark gradient, dot grid, glow, "● GRIMH3XX",
gradient title, subtitle and pills. Fonts are embedded as woff2 subsets.

    pip install fonttools brotli
    python3 tools/gen_banner.py JetBrainsMono-Regular.ttf JetBrainsMono-ExtraBold.ttf Inter.woff2 docs/banner.svg
"""
import base64, io, sys
from fontTools import subset
from fontTools.ttLib import TTFont

TITLE = "i3wm-dotfile"
SUBTITLE = "Underground i3wm setup for Arch Linux, installed with one script"
PILLS = [("Shell", "#89E051"), ("Arch Linux", None), ("i3wm", None), ("suckless st", None), ("dotfiles", None)]

MONO = "'JBM','JetBrains Mono',ui-monospace,Consolas,Menlo,monospace"
SANS = "'INT','Inter',system-ui,'Segoe UI',Arial,sans-serif"


def woff2(path, text):
    f = TTFont(path)
    o = subset.Options()
    o.flavor = "woff2"
    o.layout_features = ["kern"]
    o.name_IDs = []
    s = subset.Subsetter(o)
    s.populate(text=text)
    s.subset(f)
    b = io.BytesIO()
    f.flavor = "woff2"
    f.save(b)
    return base64.b64encode(b.getvalue()).decode()


def main(reg, bold, inter, out):
    mono_txt = "● GRIMH3XX" + "".join(p for p, _ in PILLS)
    pills, x = [], 48
    for label, dot in PILLS:
        w = round(24 + len(label) * 7.2 + (13 if dot else 0))
        pills.append(f'<rect x="{x}" y="176" width="{w}" height="24" rx="12" fill="#3B82F6" fill-opacity="0.08" stroke="#1E2A3D"/>')
        tx = x + 12
        if dot:
            pills.append(f'<circle cx="{x + 16}" cy="188" r="3.6" fill="{dot}"/>')
            tx = x + 25
        pills.append(f'<text x="{tx}" y="192" font-family="{MONO}" font-size="12" fill="#C5CFDD">{label}</text>')
        x += w + 8

    style = (
        f"@font-face{{font-family:'JBM';font-weight:400;src:url(data:font/woff2;base64,{woff2(reg, mono_txt)}) format('woff2')}}"
        f"@font-face{{font-family:'JBM';font-weight:800;src:url(data:font/woff2;base64,{woff2(bold, TITLE)}) format('woff2')}}"
        f"@font-face{{font-family:'INT';font-weight:400;src:url(data:font/woff2;base64,{woff2(inter, SUBTITLE)}) format('woff2')}}"
    )
    title = f'<text x="46" y="122" font-family="{MONO}" font-size="54" font-weight="800" letter-spacing="-1">{TITLE}</text>'
    svg = f'''<svg xmlns="http://www.w3.org/2000/svg" width="1000" height="220" viewBox="0 0 1000 220"><style>{style}</style>
<defs>
<linearGradient id="bg" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#0B0F17"/><stop offset="1" stop-color="#0E1420"/></linearGradient>
<linearGradient id="brand" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#3B82F6"/><stop offset="1" stop-color="#22D3EE"/></linearGradient>
<pattern id="dots" width="24" height="24" patternUnits="userSpaceOnUse"><circle cx="1" cy="1" r="1" fill="#3B82F6" fill-opacity="0.16"/></pattern>
<radialGradient id="glow" cx="0.2" cy="0.1" r="0.8"><stop offset="0" stop-color="#3B82F6" stop-opacity="0.2"/><stop offset="1" stop-color="#3B82F6" stop-opacity="0"/></radialGradient>
<filter id="soft" x="-10%" y="-50%" width="120%" height="200%"><feGaussianBlur stdDeviation="12"/></filter>
<clipPath id="r"><rect width="1000" height="220" rx="16"/></clipPath>
</defs>
<g clip-path="url(#r)">
<rect width="1000" height="220" fill="url(#bg)"/><rect width="1000" height="220" fill="url(#dots)"/><rect width="1000" height="220" fill="url(#glow)"/>
<text x="48" y="58" font-family="{MONO}" font-size="12" letter-spacing="3" fill="#8B98AD"><tspan fill="#22D3EE">●</tspan>  GRIMH3XX</text><g fill="#3B82F6" opacity="0.35" filter="url(#soft)">{title}</g><g fill="url(#brand)">{title}</g><text x="48" y="158" font-family="{SANS}" font-size="18" fill="#C5CFDD">{SUBTITLE}</text>{"".join(pills)}
</g>
<rect x="0.5" y="0.5" width="999" height="219" rx="16" fill="none" stroke="#1E2A3D"/>
</svg>
'''
    with open(out, "w", encoding="utf-8") as f:
        f.write(svg)
    print(f"{out}: {len(svg)//1024} KB")


if __name__ == "__main__":
    if len(sys.argv) != 5:
        print(__doc__)
        sys.exit(1)
    main(*sys.argv[1:])
