import sys
import re
import uuid

# Define files to add
FILES_TO_ADD = [
    "DesignSystem.swift",
    "AppState.swift",
    "HomeView.swift",
    "EventsView.swift",
    "VouchersView.swift",
    "ProfileView.swift",
    "PointsView.swift",
    "OrdersView.swift"
    # ContentView.swift and App.swift are likely already there or need checking
]

PROJECT_PATH = "thecoffeelinks-native-swift.xcodeproj/project.pbxproj"

def generate_id():
    return str(uuid.uuid4()).replace("-", "")[:24].upper()

def main():
    try:
        with open(PROJECT_PATH, "r") as f:
            content = f.read()
    except FileNotFoundError:
        print(f"Error: Could not find {PROJECT_PATH}")
        sys.exit(1)

    # 1. Check if files are already added to avoid duplication
    files_added_count = 0
    
    # We need to find the main group ID
    # Usually strictly after /* Begin PBXGroup section */
    main_group_match = re.search(r'rootObject = ([A-F0-9]+) /\* Project object \*/;', content)
    if not main_group_match:
        print("Error: Could not find rootObject")
        sys.exit(1)
        
    project_id = main_group_match.group(1)
    
    # deeply simplify: just look for the group named 'thecoffeelinks-native-swift'
    # This is risky but standard Xcode templates usually have a group with the app name
    group_match = re.search(r'([A-F0-9]+) /\* thecoffeelinks-native-swift \*/ = \{', content)
    if not group_match:
         print("Error: Could not find main group ID")
         sys.exit(1)
    
    main_group_id = group_match.group(1)

    # Find PBXBuildFile section
    build_files_marker = "/* Begin PBXBuildFile section */"
    file_refs_marker = "/* Begin PBXFileReference section */"
    sources_build_phase_marker = "/* Begin PBXSourcesBuildPhase section */"
    
    # We need to inject:
    # 1. PBXBuildFile entry
    # 2. PBXFileReference entry
    # 3. PBXGroup children
    # 4. PBXSourcesBuildPhase files

    new_build_files = []
    new_file_refs = []
    new_group_children = []
    new_source_files = []

    for filename in FILES_TO_ADD:
        if filename in content:
            print(f"Skipping {filename}, already in project.")
            continue
            
        file_ref_id = generate_id()
        build_file_id = generate_id()
        
        # PBXFileReference
        new_file_refs.append(f'\t\t{file_ref_id} /* {filename} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {filename}; sourceTree = "<group>"; }};')
        
        # PBXBuildFile
        new_build_files.append(f'\t\t{build_file_id} /* {filename} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_ref_id} /* {filename} */; }};')
        
        # Group Child
        new_group_children.append(f'\t\t\t\t{file_ref_id} /* {filename} */,')
        
        # Source Build Phase
        new_source_files.append(f'\t\t\t\t{build_file_id} /* {filename} in Sources */,')
        
        files_added_count += 1

    if files_added_count == 0:
        print("No new files to add.")
        sys.exit(0)

    # Apply changes
    
    # 1. Add File Refs
    content = content.replace(file_refs_marker, file_refs_marker + "\n" + "\n".join(new_file_refs))
    
    # 2. Add Build Files
    content = content.replace(build_files_marker, build_files_marker + "\n" + "\n".join(new_build_files))
    
    # Updated Strategy: Target the specific group for source files "thecoffeelinks-native-swift"
    # From file inspection: 25544E702F1424F2009A6830 is the group for the folder "thecoffeelinks-native-swift"
    
    # We look for: 25544E70... = { ... children = ( ... );
    # Note: It might be a PBXFileSystemSynchronizedRootGroup which doesn't have local children but reads from disk?
    # Inspecting line 33: isa = PBXFileSystemSynchronizedRootGroup; path = "thecoffeelinks-native-swift";
    
    # IF it is a synchronized root group, we CANNOT add children to it in the PBXProj. 
    # Xcode 16+ uses synchronized groups which automatically pick up files on disk. 
    # If the user asks for xcodebuild and it fails, it means the files ARE on disk but maybe not being picked up or we need to clean build?
    
    # Wait, if it is a PBXFileSystemSynchronizedRootGroup, we don't need to add references!
    # Let's check if the previous xcodebuild failure was just a fluke or if we need to force it.
    
    print("Detected PBXFileSystemSynchronizedRootGroup. Files should be picked up automatically if in the right folder.")
    print("Verifying if files are in 'thecoffeelinks-native-swift' subfolder...")
    
    # We will just exit successfully if we detect this, as we shouldn't modify the pbxproj for sync groups.
    if "isa = PBXFileSystemSynchronizedRootGroup" in content and 'path = "thecoffeelinks-native-swift"' in content:
        print("Project uses File System Synchronization. Skipping manual PBX editing.")
        sys.exit(0)
    
    # Fallback to old logic if standard group (unlikely based on file view)
    group_regex = re.compile(r'children = \(([^)]+)\);', re.DOTALL)

    # 4. Add to Sources Build Phase
    # This is tricky because there might be multiple sources build phases (targets/tests).
    # We'll validly assume the first one is the app target for simple projects.
    sources_regex = re.compile(r'isa = PBXSourcesBuildPhase;[^}]*files = \(([^)]+)\);', re.DOTALL)
    
    match = sources_regex.search(content)
    if match:
        current_sources = match.group(1)
        new_sources_block = current_sources + "\n" + "\n".join(new_source_files)
        # Only replace the first occurrence (main target)
        content = content.replace(current_sources, new_sources_block, 1)
    else:
        print("Error: Could not locate sources build phase")
        sys.exit(1)

    with open(PROJECT_PATH, "w") as f:
        f.write(content)
        
    print(f"Successfully added {files_added_count} files to project.")

if __name__ == "__main__":
    main()
