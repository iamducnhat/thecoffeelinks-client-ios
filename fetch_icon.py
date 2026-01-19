import os
import urllib.request
import json
import ssl

# --- CONFIGURATION ---
ICON_NAME = "menu"  # Change this variable to fetch different icons
# Path to the Assets.xcassets directory
ASSETS_DIR = "/Users/nguyenducnhat/appcafe/thecoffeelinks-native-swift/thecoffeelinks-native-swift/Assets.xcassets"

def fetch_and_add_icon(icon_name):
    print(f"--- Processing Icon: {icon_name} ---")
    
    # 1. Prepare paths
    imageset_name = f"{icon_name}.imageset"
    imageset_path = os.path.join(ASSETS_DIR, imageset_name)
    svg_filename = f"{icon_name}.svg"
    svg_dest_path = os.path.join(imageset_path, svg_filename)
    
    # 2. Create directory if it doesn't exist
    if not os.path.exists(imageset_path):
        try:
            os.makedirs(imageset_path)
            print(f"✅ Created directory: {imageset_path}")
        except OSError as e:
            print(f"❌ Failed to create directory: {e}")
            return
    else:
        print(f"ℹ️ Directory already exists: {imageset_path}")
    
    # 3. Download SVG
    url = f"https://unpkg.com/lucide-static@latest/icons/{icon_name}.svg"
    print(f"⬇️ Downloading from: {url}")
    
    try:
        # Create unverified context to avoid SSL certificate errors in some environments
        context = ssl._create_unverified_context()
        with urllib.request.urlopen(url, context=context) as response, open(svg_dest_path, 'wb') as out_file:
            data = response.read()
            out_file.write(data)
        print(f"✅ Downloaded {svg_filename}")
    except Exception as e:
        print(f"❌ Failed to download icon '{icon_name}'. Error: {e}")
        # Clean up directory if download failed and it was empty
        return

    # 4. Create Contents.json
    contents_json = {
        "images": [
            {
                "filename": svg_filename,
                "idiom": "universal"
            }
        ],
        "info": {
            "author": "xcode",
            "version": 1
        },
        "properties": {
            "preserves-vector-representation": True
        }
    }
    
    contents_json_path = os.path.join(imageset_path, "Contents.json")
    try:
        with open(contents_json_path, "w") as f:
            json.dump(contents_json, f, indent=2)
        print(f"✅ Created Contents.json at {contents_json_path}")
    except IOError as e:
        print(f"❌ Failed to write Contents.json: {e}")
        
    print(f"🎉 Successfully added '{icon_name}' to Assets!")

if __name__ == "__main__":
    fetch_and_add_icon(ICON_NAME)
