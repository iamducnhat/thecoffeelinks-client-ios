"""Generate AppIcon sizes from a single square source image.

Usage:
  pip install pillow
  python scripts/generate_app_icons.py scripts/input/coffee_symbol_1024.png

This script will generate the sizes listed in the app's AppIcon.appiconset and write them into the asset folder.
"""
from PIL import Image
import os
import sys

ICON_SPECS = [
    (20, '20.png'), (40, '40.png'), (60, '60.png'),
    (29, '29.png'), (58, '58.png'), (87, '87.png'),
    (40, '40.png'), (80, '80.png'), (120, '120.png'),
    (180, '180.png'), (57, '57.png'), (114, '114.png'),
    (72, '72.png'), (144, '144.png'), (76, '76.png'), (152, '152.png'),
    (167, '167.png'), (1024, '1024.png'), (512, '512.png')
]

APPICON_DIR = os.path.join(os.path.dirname(__file__), '..', 'TheCoffeeLinks', 'Resources', 'Assets.xcassets', 'AppIcon.appiconset')


def generate(src_path):
    img = Image.open(src_path).convert('RGBA')
    w,h = img.size
    if w != h:
        print('Source image should be square. Cropping to center square...')
        side = min(w,h)
        left = (w-side)//2
        top = (h-side)//2
        img = img.crop((left, top, left+side, top+side))

    for size, name in ICON_SPECS:
        # generate @1x, @2x, @3x where appropriate
        # heuristics: if size>100 we just write size as-is
        out = img.resize((size, size), Image.LANCZOS)
        out_path = os.path.join(APPICON_DIR, name)
        out.save(out_path)
        print(f'Wrote {out_path}')

if __name__ == '__main__':
    if len(sys.argv) < 2:
        print('Usage: generate_app_icons.py source_image')
        sys.exit(1)
    generate(sys.argv[1])
