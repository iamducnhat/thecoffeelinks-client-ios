"""Extract the center symbol from a supplied logo image and produce square PNGs.

Behavior:
- Center-crops a square from the input image, resizes to target.
- Samples the corner pixels to estimate the logo background color and fills the final canvas with that color.
- Applies a circular mask (configurable radius fraction) to isolate the central symbol and removes surrounding text.
- Writes output PNG and optional @2x/@3x variants for asset catalog use.

Usage:
  pip install pillow
  python scripts/extract_symbol.py scripts/input/brand_full.png TheCoffeeLinks/Resources/Assets.xcassets/coffee_brand.imageset/coffee_brand.png --size 1024 --radius 0.42

"""
from PIL import Image, ImageOps
import sys
import os
import argparse


def _avg_corner_color(img, sample=8):
    w,h = img.size
    corners = [
        (0,0,sample,sample),
        (w-sample,0,w, sample),
        (0,h-sample,sample,h),
        (w-sample,h-sample,w,h)
    ]
    rs,gs,bs,as_ = 0,0,0,0
    count = 0
    for box in corners:
        crop = img.crop(box)
        for px in crop.getdata():
            r,g,b,a = px
            rs += r; gs += g; bs += b; as_ += a
            count += 1
    if count == 0:
        return (255,255,255)
    return (int(rs/count), int(gs/count), int(bs/count))


def extract_symbol(input_path, output_path_base, size=1024, radius_frac=0.42, write_variants=True):
    img = Image.open(input_path).convert('RGBA')
    w,h = img.size
    side = min(w,h)
    left = (w - side)//2
    top = (h - side)//2
    crop = img.crop((left, top, left+side, top+side))

    # Resize to target size
    crop = crop.resize((size, size), Image.LANCZOS)

    # Estimate background color from corners
    bg = _avg_corner_color(crop, sample=max(6, size//100))

    # Make circular mask (white inside symbol area)
    mask = Image.new('L', (size,size), 0)
    cx = cy = size / 2.0
    r = size * radius_frac
    for y in range(size):
        for x in range(size):
            dx = x - cx
            dy = y - cy
            d = (dx*dx + dy*dy)**0.5
            if d <= r:
                mask.putpixel((x,y), 255)

    # Compose final image: fill with background color, paste masked central content
    bg_canvas = Image.new('RGBA', (size,size), (*bg, 255))
    # paste the crop using mask so only central circular area shows the crop; the rest remains bg color
    bg_canvas.paste(crop, (0,0), mask)

    # Ensure output dir exists
    out_dir = os.path.dirname(output_path_base)
    os.makedirs(out_dir, exist_ok=True)

    # Write 1x, 2x, 3x
    base_name = os.path.basename(output_path_base)
    name_no_ext, ext = os.path.splitext(base_name)

    # 1x
    out_path_1x = os.path.join(out_dir, f"{name_no_ext}{ext}")
    bg_canvas.save(out_path_1x)
    print(f"Saved {out_path_1x}")

    if write_variants:
        # 2x
        bg_2x = bg_canvas.resize((size*2, size*2), Image.LANCZOS)
        out_path_2x = os.path.join(out_dir, f"{name_no_ext}@2x{ext}")
        bg_2x.save(out_path_2x)
        print(f"Saved {out_path_2x}")
        # 3x
        bg_3x = bg_canvas.resize((size*3, size*3), Image.LANCZOS)
        out_path_3x = os.path.join(out_dir, f"{name_no_ext}@3x{ext}")
        bg_3x.save(out_path_3x)
        print(f"Saved {out_path_3x}")

    return out_path_1x


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Extract symbol from logo and write asset images')
    parser.add_argument('input', help='Input logo image path')
    parser.add_argument('output', help='Output base path (e.g., Assets.xcassets/.../coffee_brand.png)')
    parser.add_argument('--size', type=int, default=1024, help='Base output size (1x)')
    parser.add_argument('--radius', type=float, default=0.42, help='Mask radius fraction relative to image size')
    args = parser.parse_args()

    if not os.path.exists(args.input):
        print(f'Input not found: {args.input}')
        print('Please place your logo image at that path.')
        sys.exit(1)

    extract_symbol(args.input, args.output, size=args.size, radius_frac=args.radius)

