"""Runner script: import the provided logo into project, create symbol-only images, and generate app icons.

Usage:
  pip install pillow
  python scripts/apply_brand.py --input scripts/input/brand_attached.png --full

Options:
  --input   Path to uploaded logo image (required)
  --full    Use full logo as brand asset (keeps text)
  --symbol  Produce symbol-only version and write into `coffee_brand` and `coffee_symbol` imagesets
"""
import os
import sys
import argparse
from subprocess import check_call

ROOT = os.path.dirname(os.path.dirname(__file__))
ASSETS = os.path.join(ROOT, 'TheCoffeeLinks', 'Resources', 'Assets.xcassets')


def run_extract(input_path, out_basename='coffee_brand.png', size=1024, radius=0.42, symbol=False):
    out_path = os.path.join(ASSETS, 'coffee_brand.imageset', out_basename)
    cmd = [sys.executable, os.path.join(os.path.dirname(__file__), 'extract_symbol.py'), input_path, out_path, '--size', str(size), '--radius', str(radius)]
    print('Running:', ' '.join(cmd))
    check_call(cmd)

    if symbol:
        # also write into the coffee_symbol.imageset as coffee_symbol.png
        sym_out = os.path.join(ASSETS, 'coffee_symbol.imageset', 'coffee_symbol.png')
        cmd2 = [sys.executable, os.path.join(os.path.dirname(__file__), 'extract_symbol.py'), input_path, sym_out, '--size', str(size), '--radius', str(radius)]
        check_call(cmd2)


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--input', required=True)
    parser.add_argument('--full', action='store_true')
    parser.add_argument('--symbol', action='store_true')
    args = parser.parse_args()

    if not os.path.exists(args.input):
        print('Input logo not found at', args.input)
        sys.exit(1)

    # If user asked for symbol-only processing, use smaller radius to strip text
    radius = 0.42 if args.symbol else 0.5
    run_extract(args.input, radius=radius, symbol=args.symbol)

    # Generate app icons from the symbol result if symbol requested
    if args.symbol:
        sym_img = os.path.join(os.path.dirname(__file__), 'output', 'coffee_symbol_1024.png')
        # the extract script wrote to assets directly; prefer using the brand asset 1024 (if present)
        brand_1x = os.path.join(ASSETS, 'coffee_brand.imageset', 'coffee_brand.png')
        src_for_icons = brand_1x if os.path.exists(brand_1x) else None
        if src_for_icons:
            cmd_icon = [sys.executable, os.path.join(os.path.dirname(__file__), 'generate_app_icons.py'), src_for_icons]
            print('Generating app icons:',' '.join(cmd_icon))
            check_call(cmd_icon)

    print('\nDone. After running, open Xcode and verify the assets and LaunchScreen.')