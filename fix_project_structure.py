import re
import sys

project_path = 'thecoffeelinks-native-swift.xcodeproj/project.pbxproj'
plist_name = 'Info.plist'

with open(project_path, 'r') as f:
    content = f.read()

# 1. Find the file reference ID for Info.plist
# Format: 12345678 /* Info.plist */ = {isa = PBXFileReference; ... path = Info.plist; ... };
file_ref_pattern = re.compile(r'([A-F0-9]{24}) /\* Info.plist \*/ = \{isa = PBXFileReference;')
match = file_ref_pattern.search(content)

if not match:
    print("Could not find PBXFileReference for Info.plist. It might be named differently or already gone.")
    # Try searching just by path
    file_ref_pattern_2 = re.compile(r'([A-F0-9]{24}) /\* Info.plist \*/')
    match = file_ref_pattern_2.search(content)

if not match:
    print("Aborting: Info.plist reference not found.")
    sys.exit(1)

file_ref_id = match.group(1)
print(f"Found Info.plist FileRef ID: {file_ref_id}")

# 2. Find the BuildFile ID that refers to this FileRef
# Format: ABCDEF12 /* Info.plist in Resources */ = {isa = PBXBuildFile; fileRef = 12345678 /* Info.plist */; };
# or just fileRef = 12345678
build_file_pattern = re.compile(r'([A-F0-9]{24}) /\* Info.plist in Resources \*/ = \{isa = PBXBuildFile; fileRef = ' + file_ref_id)
match_build = build_file_pattern.search(content)

if not match_build:
    print("Info.plist does not seem to be in a Build Phase (good). Checking partial matches...")
    # It might be in 'CopyFiles' or 'Resources' but without 'in Resources' comment.
    # Search for any PBXBuildFile pointing to this fileRef
    build_file_pattern_generic = re.compile(r'([A-F0-9]{24}) .*= \{isa = PBXBuildFile; fileRef = ' + file_ref_id)
    match_build = build_file_pattern_generic.search(content)

if not match_build:
    print("No PBXBuildFile found for Info.plist. It is likely not in any build phase.")
    sys.exit(0)

build_file_id = match_build.group(1)
print(f"Found Info.plist BuildFile ID: {build_file_id}")

# 3. Remove the BuildFile definition
# Remove the line defining the BuildFile
content = re.sub(r'\s*' + build_file_id + r' .*= \{isa = PBXBuildFile; fileRef = ' + file_ref_id + r'.*?};\n', '', content)

# 4. Remove the BuildFile ID from PBXResourcesBuildPhase
# Look for `files = (` inside `PBXResourcesBuildPhase` and remove the line with `build_file_id`
# This is trickier with regex as sections are large.
# We will just remove the line containing the ID if it looks like a list item.
content = re.sub(r'\s*' + build_file_id + r' /\* .* \*/,\n', '', content)

with open(project_path, 'w') as f:
    f.write(content)

print("Successfully removed Info.plist from Build Phases.")
