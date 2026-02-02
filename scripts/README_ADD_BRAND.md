How I wire the brand logo into the project

1) Add your full logo image files into `scripts/input/` (recommended names):
   - `brand_full.png` (1024x1024 suggested)
   - or `brand_full.pdf` (vector, recommended)

2) After adding the image, run (locally):
   - python scripts/extract_symbol.py scripts/input/brand_full.png scripts/output/coffee_symbol_1024.png 1024
   - python scripts/generate_app_icons.py scripts/output/coffee_symbol_1024.png

3) Then copy or rename the logo files into the asset catalog:
   - `TheCoffeeLinks/Resources/Assets.xcassets/coffee_brand.imageset/coffee_brand.png` (1x)
   - `coffee_brand@2x.png`
   - `coffee_brand@3x.png`

4) Open the project in Xcode and verify `LaunchScreen.storyboard` and the in-app `SplashScreen` show the `coffee_brand` image.

If you'd like, I can add your attached image into `scripts/input/` and run the scripts here — say "yes, add it and run" and I'll import it and generate the assets for you.