#!/usr/bin/env python3
"""
Records a real run of the interactive installer and writes docs/demo.svg
(animated terminal in the grimh3xx style: frame strip + CSS steps animation,
JetBrains Mono embedded as a subset).

    pip install pyte fonttools brotli
    python3 tools/record_demo.py docs/demo.svg

It runs `./underground-i3 --dry-run` (nothing is changed) inside a pseudo-terminal,
presses keys like a person would, and samples the screen with pyte.
"""
import base64, io, os, pty, re, select, struct, sys, termios, fcntl, time
import pyte
from fontTools import subset
from fontTools.ttLib import TTFont

COLS, ROWS = 104, 40
CW, RH, FS = 8.4, 18, 14          # char width, row height, font size
PAD_X, PAD_TOP = 18, 58
FRAME_H = ROWS * RH
HOME_FAKE = "/home/you"
PROMPT = [("anon@underground", "#22D3EE"), (":", "#D5DDE8"), ("~/UndergroundI3", "#60A5FA"), ("$ ", "#D5DDE8")]
COMMAND = "./underground-i3 --dry-run"

# ANSI → grimh3xx palette (same tones as SecureArchSetup/usbscope demos)
PAL = {
    "default": "#D5DDE8", "black": "#5B6678", "red": "#F87171", "green": "#34D399",
    "brown": "#FBBF24", "yellow": "#FBBF24", "blue": "#60A5FA", "magenta": "#C084FC",
    "cyan": "#22D3EE", "white": "#D5DDE8", "brightblack": "#5B6678", "brightred": "#F87171",
    "brightgreen": "#34D399", "brightyellow": "#FBBF24", "brightblue": "#60A5FA",
    "brightmagenta": "#C084FC", "brightcyan": "#22D3EE", "brightwhite": "#F1F5FB",
}
DIM = "#8B98AD"

FONT_DIR = os.path.expanduser("~/.local/share/fonts/JetBrainsMono")
FONT_REG = os.path.join(FONT_DIR, "JetBrainsMonoNerdFontMono-Regular.ttf")
FONT_BLD = os.path.join(FONT_DIR, "JetBrainsMonoNerdFontMono-Bold.ttf")


def color(c, default):
    if c == "default":
        return default
    if re.fullmatch(r"[0-9a-fA-F]{6}", c):
        return "#" + c.upper()
    return PAL.get(c, default)


class Recorder:
    def __init__(self):
        self.screen = pyte.Screen(COLS, ROWS)
        self.stream = pyte.ByteStream(self.screen)
        self.frames = []          # (t, snapshot)
        self.t = 0.0

    def snap(self, hold):
        rows = []
        for y in range(ROWS):
            line = self.screen.buffer[y]
            runs, cur = [], None
            for x in range(COLS):
                ch = line[x]
                fg = color(ch.fg, PAL["default"])
                bg = color(ch.bg, None) if ch.bg != "default" else None
                if ch.reverse:
                    fg, bg = (bg or "#111826"), fg
                key = (fg, bg, ch.bold)
                if cur and cur[0] == key:
                    cur[1] += ch.data
                else:
                    cur = [key, ch.data, x]
                    runs.append(cur)
            rows.append(tuple((k, d, x) for k, d, x in runs if d.strip() or k[1]))
        snap = tuple(rows)
        if self.frames and self.frames[-1][1] == snap:
            self.t += hold
            return
        self.frames.append((self.t, snap))
        self.t += hold

    def feed(self, data, hold=0.0):
        self.stream.feed(data)
        self.snap(hold)


def main(out):
    rec = Recorder()
    # fake prompt + typing
    prompt = "".join(f"\x1b[38;2;{int(c[1:3],16)};{int(c[3:5],16)};{int(c[5:],16)}m{t}" for t, c in PROMPT) + "\x1b[0m"
    rec.feed(prompt.encode(), 0.8)
    for ch in COMMAND:
        rec.feed(ch.encode(), 0.06)
    rec.feed(b"\r\n", 0.3)

    env = dict(os.environ, TERM="xterm-256color", COLUMNS=str(COLS), LINES=str(ROWS),
               HOME=HOME_FAKE, XDG_STATE_HOME=HOME_FAKE + "/.local/state",
               XDG_DATA_HOME=HOME_FAKE + "/.local/share", SHELL="/bin/bash")
    env.pop("DISPLAY", None)
    root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    pid, fd = pty.fork()
    if pid == 0:
        os.chdir(root)
        os.execvpe("./underground-i3", ["./underground-i3", "--dry-run"], env)
    fcntl.ioctl(fd, termios.TIOCSWINSZ, struct.pack("HHHH", ROWS, COLS, 0, 0))

    def pump(timeout, per_line=0.0):
        end = time.time() + timeout
        while time.time() < end:
            r, _, _ = select.select([fd], [], [], 0.05)
            if not r:
                continue
            try:
                data = os.read(fd, 65536)
            except OSError:
                return False
            if not data:
                return False
            data = data.replace(os.path.expanduser("~").encode(), HOME_FAKE.encode())
            if per_line:
                parts = data.split(b"\n")
                for i, p in enumerate(parts):
                    rec.feed(p + (b"\n" if i < len(parts) - 1 else b""), per_line)
            else:
                rec.feed(data, 0.02)
        return True

    def key(k, before=0.55):
        rec.snap(before)
        os.write(fd, k)
        pump(0.35)

    pump(1.5)                       # logo + checklist
    rec.snap(1.6)
    for k in [b"j", b"j", b"j"]:    # walk down to 'apps'
        key(k, 0.45)
    key(b" ", 0.6)                  # untick apps
    key(b" ", 0.7)                  # tick it again
    for k in [b"j", b"j", b"j", b"j"]:
        key(k, 0.4)
    key(b"\r", 1.0)                 # confirm components
    key(b"j", 1.0)                  # radio: copy
    key(b"k", 0.6)                  # back to symlink
    key(b"\r", 0.8)
    rec.snap(1.8)                   # read the plan card
    key(b"\r", 0.4)                 # install now
    pump(25, per_line=0.035)        # the run itself
    rec.snap(4.0)                   # hold the end
    try:
        os.waitpid(pid, 0)
    except ChildProcessError:
        pass
    write_svg(rec, out)


def font_b64(path, text):
    f = TTFont(path)
    opts = subset.Options()
    opts.flavor = "woff2"
    opts.layout_features = []
    opts.name_IDs = []
    opts.notdef_outline = True
    s = subset.Subsetter(opts)
    s.populate(text=text)
    s.subset(f)
    buf = io.BytesIO()
    f.flavor = "woff2"
    f.save(buf)
    return base64.b64encode(buf.getvalue()).decode()


def esc(s):
    return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")


def write_svg(rec, out):
    frames = rec.frames
    total = rec.t
    rowdefs, rowid = [], {}
    chars = set()
    for _, snap in frames:
        for row in snap:
            if row and row not in rowid:
                rowid[row] = f"r{len(rowid)}"
                parts = []
                for (fg, bg, bold), data, x in row:
                    tx = x * CW
                    if bg:
                        parts.append(f'<rect x="{tx:.1f}" y="0" width="{len(data)*CW:.1f}" height="{RH}" fill="{bg}"/>')
                    txt = data.rstrip() if not bg else data
                    if txt.strip():
                        chars.update(txt)
                        w = ' font-weight="700"' if bold else ""
                        parts.append(f'<text x="{tx:.1f}" y="14.0" fill="{fg}"{w} textLength="{len(txt)*CW:.1f}" lengthAdjust="spacingAndGlyphs">{esc(txt)}</text>')
                rowdefs.append(f'<g id="{rowid[row]}">{"".join(parts)}</g>')

    kf, strip = [], []
    for i, (t, snap) in enumerate(frames):
        kf.append(f"{t/total*100:.3f}%{{transform:translateY(-{i*FRAME_H}px)}}")
        uses = "".join(f'<use href="#{rowid[row]}" y="{y*RH}"/>' for y, row in enumerate(snap) if row)
        strip.append(f'<g transform="translate(0,{i*FRAME_H})">{uses}</g>')

    text = "".join(sorted(chars)) + "UndergroundI3 --dry-run"
    reg, bld = font_b64(FONT_REG, text), font_b64(FONT_BLD, text)
    W = int(PAD_X * 2 + COLS * CW)
    H = PAD_TOP + FRAME_H + 18
    title = "underground-i3 --dry-run"
    svg = f'''<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}" role="img" aria-label="{title}">
<style>@font-face{{font-family:'JBM';font-weight:400;src:url(data:font/woff2;base64,{reg}) format('woff2')}}@font-face{{font-family:'JBM';font-weight:700;src:url(data:font/woff2;base64,{bld}) format('woff2')}}@keyframes play{{{"".join(kf)}}}.strip{{animation:play {total:.2f}s steps(1,end) infinite}}</style>
<defs>{"".join(rowdefs)}</defs>
<rect x="0.5" y="0.5" width="{W-1}" height="{H-1}" rx="12" fill="#111826" stroke="#1E2A3D"/>
<path d="M0 40H{W}" stroke="#1E2A3D"/>
<circle cx="24" cy="20" r="6" fill="#FF5F57"/><circle cx="44" cy="20" r="6" fill="#FEBC2E"/><circle cx="64" cy="20" r="6" fill="#28C840"/>
<text x="{W/2:.0f}" y="25" text-anchor="middle" fill="{DIM}" font-family="'JBM','JetBrains Mono',ui-monospace,Consolas,Menlo,monospace" font-size="13">{title}</text>
<svg x="{PAD_X}" y="{PAD_TOP}" width="{COLS*CW:.0f}" height="{FRAME_H}" viewBox="0 0 {COLS*CW:.0f} {FRAME_H}" overflow="hidden">
<g class="strip" font-family="'JBM','JetBrains Mono',ui-monospace,Consolas,Menlo,monospace" font-size="{FS}" xml:space="preserve">{"".join(strip)}</g>
</svg>
</svg>
'''
    with open(out, "w", encoding="utf-8") as f:
        f.write(svg)
    print(f"{out}: {len(frames)} frames, {total:.1f}s, {len(svg)//1024} KB")


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else "docs/demo.svg")
