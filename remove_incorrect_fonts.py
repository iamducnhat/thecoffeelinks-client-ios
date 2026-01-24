
import re

# Paths
pbxproj_path = "thecoffeelinks-client-ios.xcodeproj/project.pbxproj"

# 1. IDs to remove (from the file content we saw)
# These are the ones in "Sources" phase of UI Tests
ids_to_remove = [
    "41AC0EF77B0841ACA8201237", # Regular in Sources
    "BEB83FA86A50496DB07F5D85", # Italic in Sources
    "ED8CB22A53484087A3789505"  # Bold in Sources
]

with open(pbxproj_path, 'r') as f:
    lines = f.readlines()

new_lines = []
for line in lines:
    # Check if the line contains any of the IDs to remove
    should_remove = False
    for id_remove in ids_to_remove:
        if id_remove in line:
            print(f"Removing line: {line.strip()}")
            should_remove = True
            break
    
    if not should_remove:
        new_lines.append(line)

with open(pbxproj_path, 'w') as f:
    f.writelines(new_lines)

print("Successfully updated project.pbxproj")
