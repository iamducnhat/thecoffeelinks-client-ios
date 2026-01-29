
import os
import json

base_path = "/Users/nguyenducnhat/appcafe/thecoffeelinks-client-ios/TheCoffeeLinks/Resources/Assets.xcassets"
colors_path = os.path.join(base_path, "Colors")

if not os.path.exists(colors_path):
    os.makedirs(colors_path)
    # create Contents.json for the folder (namespace)
    with open(os.path.join(colors_path, "Contents.json"), "w") as f:
         json.dump({
            "info" : {
                "author" : "xcode",
                "version" : 1
            },
            "properties" : {
                "provides-namespace" : True
            }
        }, f, indent=2)


colors = {
    "BackgroundPaper": {"light": "#F9F7F4", "dark": "#0F0D0B"},
    "SurfaceCard": {"light": "#F0ECE6", "dark": "#1A1714"},
    "TextInk": {"light": "#1A110D", "dark": "#F5F2EE"},
    "TextMuted": {"light": "#4D3A31", "dark": "#B8ADA2"},
    "TextTertiary": {"light": "#8C7368", "dark": "#7A7068"},
    "PrimaryEspresso": {"light": "#3B5D48", "dark": "#6E8F78"},
    "Border": {"light": "#D4CCC2", "dark": "#2A2520"},
    "BorderTertiary": {"light": "#C4BAB0", "dark": "#3A352F"},
    "SemanticError": {"light": "#B91C1C", "dark": "#DC2626"},
    "SemanticSuccess": {"light": "#15803D", "dark": "#22C55E"},
    "SemanticWarning": {"light": "#D97706", "dark": "#F59E0B"}
}

for name, values in colors.items():
    folder_name = f"{name}.colorset"
    folder_path = os.path.join(colors_path, folder_name)
    if not os.path.exists(folder_path):
        os.makedirs(folder_path)
    
    contents = {
      "colors" : [
        {
          "idiom" : "universal",
          "color" : {
            "color-space" : "srgb",
            "components" : {
              "red" : f"0x{values['light'][1:3]}",
              "alpha" : "1.000",
              "blue" : f"0x{values['light'][5:7]}",
              "green" : f"0x{values['light'][3:5]}"
            }
          }
        },
        {
          "appearances" : [
            {
              "appearance" : "luminosity",
              "value" : "dark"
            }
          ],
          "idiom" : "universal",
          "color" : {
            "color-space" : "srgb",
            "components" : {
              "red" : f"0x{values['dark'][1:3]}",
              "alpha" : "1.000",
              "blue" : f"0x{values['dark'][5:7]}",
              "green" : f"0x{values['dark'][3:5]}"
            }
          }
        }
      ],
      "info" : {
        "author" : "xcode",
        "version" : 1
      }
    }
    
    with open(os.path.join(folder_path, "Contents.json"), "w") as f:
        json.dump(contents, f, indent=2)
    
    print(f"Created {name}")

print("Done")
