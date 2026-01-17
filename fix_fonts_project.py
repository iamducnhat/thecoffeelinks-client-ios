
import re
import uuid

# Paths
pbxproj_path = "thecoffeelinks-native-swift.xcodeproj/project.pbxproj"

# File References (from the file content we saw)
font_refs = {
    "LibreBaskerville-Regular.ttf": "B4331C9B483A4F6E99149D4A",
    "LibreBaskerville-Bold.ttf": "696376B4AF3B4F08ABC24923",
    "LibreBaskerville-Italic.ttf": "FC02A854467A483D898B0051"
}

# Main Target Information
# Target: thecoffeelinks-native-swift (25544E6D2F1424F2009A6830)
# Resources Phase: 25544E6C2F1424F2009A6830
resources_phase_id = "25544E6C2F1424F2009A6830"

def generate_id():
    return uuid.uuid4().hex[:24].upper()

with open(pbxproj_path, 'r') as f:
    content = f.read()

# 1. Create new PBXBuildFile entries
new_build_files = []
new_build_file_ids = []

print("Generating new PBXBuildFile entries...")
for font_name, file_ref in font_refs.items():
    new_id = generate_id()
    new_build_file_ids.append((new_id, font_name))
    # Entry format: ID /* Name in Resources */ = {isa = PBXBuildFile; fileRef = REF /* Name */; };
    entry = f'\t\t{new_id} /* {font_name} in Resources */ = {{isa = PBXBuildFile; fileRef = {file_ref} /* {font_name} */; }};'
    new_build_files.append(entry)

# Insert new PBXBuildFile entries
# Find the end of PBXBuildFile section
build_file_section_end = content.find("/* End PBXBuildFile section */")
if build_file_section_end == -1:
    print("Error: Could not find PBXBuildFile section")
    exit(1)

content = content[:build_file_section_end] + "\n".join(new_build_files) + "\n" + content[build_file_section_end:]

# 2. Add to PBXResourcesBuildPhase
print(f"Adding to Resources Build Phase {resources_phase_id}...")
# Find the section for the resources phase
# Look for: 25544E6C2F1424F2009A6830 /* Resources */ = { ... files = ( ... );
regex = re.compile(rf'{resources_phase_id} /\* Resources \*/ = {{.*?files = \((.*?)\);', re.DOTALL)
match = regex.search(content)

if not match:
    print("Error: Could not find PBXResourcesBuildPhase")
    exit(1)

current_files_block = match.group(1)
new_files_block = current_files_block
if not new_files_block.endswith("\n"):
    new_files_block += "\n"

for new_id, font_name in new_build_file_ids:
    new_files_block += f'\t\t\t\t{new_id} /* {font_name} in Resources */,\n'

# Replace the files block
start_idx = match.start(1)
end_idx = match.end(1)
content = content[:start_idx] + new_files_block + content[end_idx:]

# Write back
with open(pbxproj_path, 'w') as f:
    f.write(content)

print("Successfully updated project.pbxproj")
