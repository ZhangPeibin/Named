#!/usr/bin/env python3
"""Generate the round 8 Named logo kit and its PNG exports.

Source artwork: docs/brand/logo/纯图标.svg
Wordmark: outlined Manrope 800 from the round 7 kit.
Rasteriser: headless Google Chrome (override with CHROME=/path/to/chrome).
"""

from __future__ import annotations

import os
import re
import struct
import subprocess
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[4]
HERE = Path(__file__).resolve().parent
EXPORTS = HERE / "exports"
CHROME = os.environ.get(
    "CHROME", "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
)

RED = "#D94F58"
INK = "#232A31"
PAPER = "#FBF8F2"
DARK = "#171A1D"

MARK_SOURCE = ROOT / "docs/brand/logo/纯图标.svg"
WORDMARK_SOURCE = ROOT / "docs/brand/logo/round7/c-weave/c-wordmark.svg"

MARK_PATH = re.search(r'<path d="([^"]+)"', MARK_SOURCE.read_text()).group(1)
WORDMARK_MATCH = re.search(
    r'<path fill="#232A31" d="([^"]+)" transform="([^"]+)"',
    WORDMARK_SOURCE.read_text(),
)
WORDMARK_PATH = WORDMARK_MATCH.group(1)
WORDMARK_TRANSFORM = WORDMARK_MATCH.group(2)


def mark(color: str, canvas: float, ratio: float) -> str:
    scale = ratio * canvas / 853
    return (
        f'<g transform="translate({canvas / 2:.3f} {canvas / 2:.3f}) '
        f'scale({scale:.6f}) translate(-1026.5 -828.5)">'
        f'<path fill="{color}" d="{MARK_PATH}"/>'
        f'<circle cx="1161" cy="739" r="86" fill="{color}"/></g>'
    )


def symbol_svg(color: str, size: int = 256, ratio: float = 0.86) -> str:
    return (
        f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {size} {size}" '
        f'width="{size}" height="{size}" role="img" aria-labelledby="t">'
        f'<title id="t">Named symbol</title>{mark(color, size, ratio)}</svg>'
    )


def wordmark_svg(color: str) -> str:
    return (
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 530 150" '
        'width="530" height="150" role="img" aria-labelledby="t">'
        f'<title id="t">Named wordmark</title><g id="wordmark">'
        f'<path fill="{color}" d="{WORDMARK_PATH}" '
        f'transform="{WORDMARK_TRANSFORM}"/></g></svg>'
    )


def lockup_svg(mark_color: str, text_color: str) -> str:
    return (
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 700 256" '
        'width="700" height="256" role="img" aria-labelledby="t">'
        '<title id="t">Named horizontal lockup</title><g id="lockup">'
        f'<g transform="translate(30.6 44)">{mark(mark_color, 168, 0.901)}</g>'
        '<g transform="translate(195.2 56.45) scale(0.916)">'
        f'<path fill="{text_color}" d="{WORDMARK_PATH}" '
        f'transform="{WORDMARK_TRANSFORM}"/></g></g></svg>'
    )


def stacked_svg(mark_color: str, text_color: str) -> str:
    return (
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 520 390" '
        'width="520" height="390" role="img" aria-labelledby="t">'
        '<title id="t">Named stacked lockup</title><g id="lockup">'
        f'<g transform="translate(165 50)">{mark(mark_color, 190, 0.895)}</g>'
        '<g transform="translate(51.1 252.1) scale(0.78)">'
        f'<path fill="{text_color}" d="{WORDMARK_PATH}" '
        f'transform="{WORDMARK_TRANSFORM}"/></g></g></svg>'
    )


def icon_svg(background: str, radius: int, mark_color: str = RED) -> str:
    return (
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 256 256" '
        'width="256" height="256" role="img" aria-labelledby="t">'
        '<title id="t">Named app icon</title>'
        f'<rect width="256" height="256" rx="{radius}" fill="{background}"/>'
        f'{mark(mark_color, 256, 0.74)}</svg>'
    )


def splash_svg(color: str) -> str:
    return (
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024" '
        'width="1024" height="1024" role="img" aria-labelledby="t">'
        f'<title id="t">Named splash mark</title>{mark(color, 1024, 0.58)}</svg>'
    )


def write(name: str, content: str) -> Path:
    path = HERE / name
    path.write_text(content)
    return path


def render(svg: str, width: int, height: int, destination: Path) -> None:
    with tempfile.TemporaryDirectory(prefix="named-logo-") as tmp:
        html = Path(tmp) / "render.html"
        html.write_text(
            "<!doctype html><meta charset=utf-8>"
            "<style>html,body{margin:0;padding:0;background:transparent}"
            f"svg{{display:block;width:{width}px;height:{height}px}}</style>"
            + svg
        )
        subprocess.run(
            [
                CHROME,
                "--headless=new",
                "--disable-gpu",
                "--hide-scrollbars",
                "--force-device-scale-factor=1",
                "--default-background-color=00000000",
                f"--screenshot={destination}",
                f"--window-size={width},{height}",
                f"file://{html}",
            ],
            check=True,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )


def render_icon(svg: str, size: int, destination: Path) -> None:
    render(svg, size, size, destination)


def write_ico(destination: Path, sizes: list[int]) -> None:
    images = []
    with tempfile.TemporaryDirectory(prefix="named-ico-") as tmp:
        for size in sizes:
            png = Path(tmp) / f"{size}.png"
            render_icon(symbol_svg(RED, size, 0.86), size, png)
            images.append((size, png.read_bytes()))
        header = struct.pack("<HHH", 0, 1, len(images))
        entries = b""
        offset = 6 + 16 * len(images)
        for size, data in images:
            entries += struct.pack(
                "<BBBBHHII",
                0 if size >= 256 else size,
                0 if size >= 256 else size,
                0,
                0,
                1,
                32,
                len(data),
                offset,
            )
            offset += len(data)
        destination.write_bytes(header + entries + b"".join(d for _, d in images))


def main() -> None:
    EXPORTS.mkdir(parents=True, exist_ok=True)

    write("named-symbol.svg", symbol_svg(RED))
    write("named-symbol-on-dark.svg", symbol_svg(PAPER))
    write("named-wordmark.svg", wordmark_svg(INK))
    write("named-wordmark-on-dark.svg", wordmark_svg(PAPER))
    write("named-lockup-horizontal.svg", lockup_svg(RED, INK))
    write("named-lockup-horizontal-on-dark.svg", lockup_svg(PAPER, PAPER))
    write("named-lockup-stacked.svg", stacked_svg(RED, INK))
    write("named-lockup-stacked-on-dark.svg", stacked_svg(PAPER, PAPER))
    write("named-app-icon.svg", icon_svg(PAPER, 54))
    write("named-app-icon-square.svg", icon_svg(PAPER, 0))
    write("named-splash-mark.svg", splash_svg(RED))
    write("named-splash-mark-dark.svg", splash_svg(PAPER))

    write(EXPORTS / "favicon.svg", symbol_svg(RED, 256, 0.86))

    render(symbol_svg(RED, 1024, 0.86), 1024, 1024, EXPORTS / "symbol-1024.png")
    render_icon(icon_svg(PAPER, 0), 1024, EXPORTS / "app-icon-1024.png")
    render_icon(icon_svg(PAPER, 0), 512, EXPORTS / "app-icon-512.png")
    render_icon(splash_svg(RED), 1024, EXPORTS / "splash-mark.png")
    render_icon(splash_svg(PAPER), 1024, EXPORTS / "splash-mark-dark.png")
    render_icon(symbol_svg(RED, 512, 0.60), 512, EXPORTS / "splash-symbol.png")
    render_icon(
        symbol_svg(PAPER, 512, 0.60), 512, EXPORTS / "splash-symbol-dark.png"
    )

    for size in (16, 32, 48):
        render_icon(
            symbol_svg(RED, size, 0.86), size, EXPORTS / f"favicon-{size}.png"
        )
    write_ico(EXPORTS / "favicon.ico", [16, 32, 48])

    render_icon(icon_svg(PAPER, 0), 192, EXPORTS / "icon-192.png")
    render_icon(icon_svg(PAPER, 0), 512, EXPORTS / "icon-512.png")
    render_icon(icon_svg(PAPER, 0), 512, EXPORTS / "maskable-512.png")
    render_icon(icon_svg(PAPER, 0), 180, EXPORTS / "apple-touch-icon.png")

    render(lockup_svg(RED, INK), 1400, 512, EXPORTS / "lockup-horizontal.png")
    render(
        lockup_svg(PAPER, PAPER),
        1400,
        512,
        EXPORTS / "lockup-horizontal-on-dark.png",
    )


if __name__ == "__main__":
    main()
