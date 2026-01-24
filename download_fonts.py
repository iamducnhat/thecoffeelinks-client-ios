
import urllib.request
import os

font_urls = {
    "LibreBaskerville-Regular.ttf": "https://raw.githubusercontent.com/impallari/Libre-Baskerville/master/fonts/ttf/LibreBaskerville-Regular.ttf",
    "LibreBaskerville-Bold.ttf": "https://raw.githubusercontent.com/impallari/Libre-Baskerville/master/fonts/ttf/LibreBaskerville-Bold.ttf",
    "LibreBaskerville-Italic.ttf": "https://raw.githubusercontent.com/impallari/Libre-Baskerville/master/fonts/ttf/LibreBaskerville-Italic.ttf"
}

target_dir = "thecoffeelinks-client-ios/Fonts/"

if not os.path.exists(target_dir):
    os.makedirs(target_dir)

for font, url in font_urls.items():
    print(f"Downloading {font} from {url}...")
    try:
        with urllib.request.urlopen(url, timeout=20) as response:
            content = response.read()
            if len(content) > 1000:
                with open(os.path.join(target_dir, font), "wb") as f:
                    f.write(content)
                print(f"  SUCCESS: Downloaded {font} ({len(content)} bytes)")
            else:
                print(f"  FAILED: Content too short ({len(content)} bytes)")
    except Exception as e:
        print(f"  ERROR: {e}")
