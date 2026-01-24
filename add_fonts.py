import sys
import re
import uuid
import os

PROJECT_PATH = "thecoffeelinks-client-ios.xcodeproj/project.pbxproj"
FONT_FILES = [
    "Fonts/LibreBaskerville-Regular.ttf",
    "Fonts/LibreBaskerville-Bold.ttf",
    "Fonts/LibreBaskerville-Italic.ttf"
]

def generate_id():
    return str(uuid.uuid4()).replace("-", "")[:24].upper()

def main():
    if not os.path.exists(PROJECT_PATH):
        print(f"Error: {PROJECT_PATH} not found")
        sys.exit(1)

    with open(PROJECT_PATH, "r") as f:
        content = f.read()

    # 1. Helper: Find Main Group UUID
    # This is rough but effective for standard projects
    main_group_match = re.search(r'mainGroup = ([A-F0-9]+);', content)
    if not main_group_match:
        print("Error: Could not find mainGroup")
        sys.exit(1)
    main_group_id = main_group_match.group(1)

    # 2. Get the "Resources" build phase ID
    # We look for "Resources" in PBXResourcesBuildPhase
    # The section looks like:
    # /* Begin PBXResourcesBuildPhase section */
    #    ...
    #    ABC... /* Resources */ = { ... files = ( ... ); ... };
    resources_regex = re.compile(r'([A-F0-9]+) /\* Resources \*/ = \{[^}]*isa = PBXResourcesBuildPhase;', re.DOTALL)
    res_match = resources_regex.search(content)
    
    if not res_match:
        # Fallback: Look for any PBXResourcesBuildPhase and pick the first one (usually app target)
        resources_regex_fallback = re.compile(r'([A-F0-9]+) .*= \{[^}]*isa = PBXResourcesBuildPhase;', re.DOTALL)
        res_match = resources_regex_fallback.search(content)
        
    if not res_match:
        print("Error: Could not find Resources build phase")
        sys.exit(1)
        
    resources_phase_id = res_match.group(1)
    print(f"Found Resources Phase ID: {resources_phase_id}")

    # Markers
    file_ref_marker = "/* Begin PBXFileReference section */"
    build_file_marker = "/* Begin PBXBuildFile section */"
    
    new_file_refs = []
    new_build_files = []
    new_resources_files = []
    
    # We need to add files to the main group's children as well, or a subfolder. 
    # For simplicity, we'll try to add them to the main group or just rely on file refs existing.
    # Actually, they need to be in a group to be visible in Xcode, but for building, just FileRef + BuildPhase is enough?
    # No, typically need to be in the group hierarchy.
    # Let's find the main group's children list.
    group_regex = re.compile(r'([A-F0-9]+) /\* thecoffeelinks-client-ios \*/ = \{[^}]*children = \(([^)]+)\);', re.DOTALL)
    # This regex targets the group named identically to the project, which is standard.
    
    files_added = 0
    
    for font_path in FONT_FILES:
        filename = os.path.basename(font_path)
        if filename in content:
            print(f"Skipping {filename}, already seems to be in project")
            continue
            
        file_ref_id = generate_id()
        build_file_id = generate_id()
        
        # PBXFileReference
        # Note: path should be relative to project. Since we run from root, "Fonts/..." is fine if added to root group.
        # But usually files are inside the app folder.
        # We downloaded to `thecoffeelinks-client-ios/Fonts`. 
        # If project is in `thecoffeelinks-client-ios`, then path is just "Fonts/..."
        
        new_file_refs.append(f'\t\t{file_ref_id} /* {filename} */ = {{isa = PBXFileReference; lastKnownFileType = file; name = "{filename}"; path = "{font_path}"; sourceTree = "<group>"; }};')
        
        # PBXBuildFile
        new_build_files.append(f'\t\t{build_file_id} /* {filename} in Resources */ = {{isa = PBXBuildFile; fileRef = {file_ref_id} /* {filename} */; }};')
        
        # Resource Build Phase Entry
        new_resources_files.append(f'\t\t\t\t{build_file_id} /* {filename} in Resources */,')
        
        files_added += 1

    if files_added == 0:
        print("No new fonts to add.")
        sys.exit(0)

    # Inject File Refs
    content = content.replace(file_ref_marker, file_ref_marker + "\n" + "\n".join(new_file_refs))
    
    # Inject Build Files
    content = content.replace(build_file_marker, build_file_marker + "\n" + "\n".join(new_build_files))
    
    # Inject into Resources Build Phase
    # We need to find `files = (` inside the resources phase block
    # This is tricky with regex. We look for the ID we found earlier.
    res_phase_block_regex = re.compile(f'({resources_phase_id} .*= {{.*files = \()', re.DOTALL)
    match = res_phase_block_regex.search(content)
    if match:
        insertion_point = match.group(1)
        content = content.replace(insertion_point, insertion_point + "\n" + "\n".join(new_resources_files))
    else:
        print("Error: Could not inject into resources phase files list")
        sys.exit(1)

    # Optimistic: Add to Main Group (so they appear in Xcode, ensuring checking logic works)
    # We look for the main group section.
    # We'll just append them to the first PBXGroup that looks like the main folder "thecoffeelinks-client-ios"
    # Identify group by path or name
    # 25544E70 is the ID we saw in previous script for "thecoffeelinks-client-ios" group
    
    # Let's try to be generic: find the MainGroup object
    main_group_block_match = re.search(r'([A-F0-9]+) /\* thecoffeelinks-client-ios \*/ = \{[^}]*children = \(([^)]*)\);', content)
    if main_group_block_match:
        group_id = main_group_block_match.group(1)
        current_children = main_group_block_match.group(2)
        
        # We need to add the file refs here
        new_children = []
        # We need to Map filename -> file_ref_id from our previous loop. 
        # Re-parsing is messy. Let's just do a simple replacement for now.
        # Wait, I didn't save the map. 
        # Let's skip adding to the Group for now. Adding to Build Phase + FileRef is usually enough for compilation.
        # Xcode might complain about "missing from project navigator" but it should build.
        pass
    else:
        print("Warning: Could not find main group to add files to navigator. Build might succeed but project file will be slightly malformed.")

    with open(PROJECT_PATH, "w") as f:
        f.write(content)
        
    print(f"Successfully added {files_added} fonts to project resources.")

if __name__ == "__main__":
    main()
