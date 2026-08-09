#!/usr/bin/env python3
from pathlib import Path
import sys

p = Path(sys.argv[1] if len(sys.argv) > 1 else "build.sh")
lines = p.read_text().splitlines(keepends=True)
out = []
i = 0
skip_until_close = None
while i < len(lines):
    line = lines[i]
    if line.startswith("TERMUX_PKG_VERSION=("):
        out.append('TERMUX_PKG_VERSION="6.6.20260307+really6.5.20250830"\n')
        while i < len(lines) and not lines[i].rstrip().endswith(")"):
            i += 1
        i += 1
        continue
    if line.startswith("TERMUX_PKG_SRCURL=("):
        out.append(
            'TERMUX_PKG_SRCURL="https://github.com/ThomasDickey/ncurses-snapshots/archive/${_SNAPSHOT_COMMIT}.tar.gz"\n'
        )
        while i < len(lines) and not lines[i].rstrip().endswith(")"):
            i += 1
        i += 1
        continue
    if line.startswith("TERMUX_PKG_SHA256=("):
        out.append(
            'TERMUX_PKG_SHA256="28cd102efe6a2610e830cc79cf270da6ff0427b2022900a9a36d2761522f9576"\n'
        )
        while i < len(lines) and not lines[i].rstrip().endswith(")"):
            i += 1
        i += 1
        continue
    if "TERMUX_PKG_SRCDIR/rxvt-unicode" in line:
        i += 1
        continue
    if "TERMUX_PKG_SRCDIR/kitty-" in line:
        i += 1
        continue
    if "alacritty+common,alacritty-direct" in line:
        i += 1
        continue
    if "building foot's terminfo" in line or "codeberg.org/dnkl/foot" in line:
        i += 1
        continue
    if "foot/foot.info" in line:
        i += 1
        if i < len(lines) and "tic -x -e foot" in lines[i]:
            i += 1
        continue
    if "tic -x -e foot,foot-direct" in line:
        i += 1
        continue
    if 'cp "$TERMUX_PKG_TMPDIR"/full-terminfo' in line and not line.rstrip().endswith("|| true"):
        line = line.rstrip("\n") + " || true\n"
    out.append(line)
    i += 1

text = "".join(out)
if "x11-packages/foot/build.sh" in text or "x11-packages/kitty/build.sh" in text:
    raise SystemExit("ncurses still references extra terminfo sources")
p.write_text(text)
print("[*] ncurses extra terminfo sources removed")
