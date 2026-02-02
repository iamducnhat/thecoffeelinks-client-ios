What I added

- `TheCoffeeLinks/Resources/LaunchScreen/LaunchScreen.storyboard` — a system launch storyboard that centers the `coffee` image.
- `Info.plist` updated to use `UILaunchStoryboardName = LaunchScreen`.
- `TheCoffeeLinks/Resources/Assets.xcassets/coffee_symbol.imageset/` — placeholder asset entry for a symbol-only logo.
- `scripts/extract_symbol.py` — crop + circular mask helper to produce a symbol-only PNG from an input logo.
- `scripts/generate_app_icons.py` — generate several AppIcon sizes from a square source image and write into `AppIcon.appiconset`.

How to provide images and run the automation

1) Drop your original logo (the one you attached) into `scripts/input/logo.png` (replace filename as needed).

2) To extract a centered symbol-only image (cropped + circular mask):
   - pip install pillow
   - python scripts/extract_symbol.py scripts/input/logo.png scripts/output/coffee_symbol_1024.png 1024

   This writes `scripts/output/coffee_symbol_1024.png`. From that output you can create @1x/@2x/@3x manually, or:

3) To generate app icons:
   - python scripts/generate_app_icons.py scripts/output/coffee_symbol_1024.png

   This will write PNGs into `TheCoffeeLinks/Resources/Assets.xcassets/AppIcon.appiconset` to replace the existing ones.

4) Place symbol image files into `TheCoffeeLinks/Resources/Assets.xcassets/coffee_symbol.imageset/` using these filenames:
   - coffee_symbol.png (1x)
   - coffee_symbol@2x.png
   - coffee_symbol@3x.png

Notes & caveats

- Automatic text removal via center-cropping + circular mask works well for round badges where the desired symbol is central. If you'd like me to manually remove the text and export cleaned assets, upload the source logo at high resolution and tell me to proceed and I'll do it for you.
- After adding images, open Xcode and verify the asset catalog entries and LaunchScreen in Interface Builder.
- If you want me to also replace `coffee` asset (used in the in-app Splash) with the new symbol-only image, I can add that automatically.

Tell me if you want me to: 
- run the scripts here (I can if you allow adding the source image into `scripts/input/`), or
- I should proceed to replace existing `coffee` asset with the generated symbol files automatically now.