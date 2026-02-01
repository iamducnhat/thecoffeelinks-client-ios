
import re

# Paths
pbxproj_path = "thecoffeelinks-client-ios.xcodeproj/project.pbxproj"

# File References to fix
# 696376B4AF3B4F08ABC24923 /* LibreBaskerville-Bold.ttf */
# B4331C9B483A4F6E99149D4A /* LibreBaskerville-Regular.ttf */
# FC02A854467A483D898B0051 /* LibreBaskerville-Italic.ttf */

file_fixes = {
    "696376B4AF3B4F08ABC24923": "thecoffeelinks-client-ios/Fonts/LibreBaskerville-Bold.ttf",
    "B4331C9B483A4F6E99149D4A": "thecoffeelinks-client-ios/Fonts/LibreBaskerville-Regular.ttf",
    "FC02A854467A483D898B0051": "thecoffeelinks-client-ios/Fonts/LibreBaskerville-Italic.ttf"
}

with open(pbxproj_path, 'r') as f:
    lines = f.readlines()

new_lines = []
for line in lines:
    modified_line = line
    for file_id, new_path in file_fixes.items():
        if file_id in line and "isa = PBXFileReference" in line:
            # We want to replace path = "..." with path = "new_path"
            # Regex to find path = "...";
            # But simple string replacement should work if the format is standard
            # Expected: path = "Fonts/LibreBaskerville-Bold.ttf";
            if f'path = "Fonts/' in line:
               modified_line = line.replace(f'path = "Fonts/', f'path = "thecoffeelinks-client-ios/Fonts/')
               print(f"Updated path for {file_id}")
    new_lines.append(modified_line)

with open(pbxproj_path, 'w') as f:
    f.writelines(new_lines)

print("Successfully updated file reference paths")
