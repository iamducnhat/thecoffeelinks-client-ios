import sys
import os
import re
import uuid

# Configuration
PROJECT_DIR = "thecoffeelinks-client-ios"
PROJECT_FILE = "thecoffeelinks-client-ios.xcodeproj/project.pbxproj"
EXCLUDE_DIRS = ["Preview Content", "Assets.xcassets", "build"]

def generate_id():
    return str(uuid.uuid4()).replace("-", "")[:24].upper()

def get_swift_files(root_dir):
    swift_files = []
    for root, dirs, files in os.walk(root_dir):
        # Filter excludes
        dirs[:] = [d for d in dirs if d not in EXCLUDE_DIRS]
        
        for file in files:
            if file.endswith(".swift"):
                full_path = os.path.join(root, file)
                # Store relative path from project root
                rel_path = os.path.relpath(full_path, ".")
                swift_files.append(rel_path)
    return swift_files

def main():
    if not os.path.exists(PROJECT_FILE):
        print(f"Error: {PROJECT_FILE} not found.")
        sys.exit(1)

    with open(PROJECT_FILE, "r") as f:
        content = f.read()

    # Detect Sync Group
    if "isa = PBXFileSystemSynchronizedRootGroup" in content:
        print("Project uses File System Synchronization. No manual addition needed.")
        sys.exit(0)

    disk_files = get_swift_files(PROJECT_DIR)
    added_files = []

    # Markers
    file_ref_marker = "/* Begin PBXFileReference section */"
    build_file_marker = "/* Begin PBXBuildFile section */"
    sources_marker_regex = re.compile(r'isa = PBXSourcesBuildPhase;[^}]*files = \(([^)]+)\);', re.DOTALL)
    
    # Check what's missing
    missing_files = []
    for file_path in disk_files:
        filename = os.path.basename(file_path)
        # Simple check: if filename is in project content, assume it's added (loose check to avoid dupes)
        # Better: check for the specific file reference entry
        if f'path = {filename};' not in content and f'path = "{filename}";' not in content:
             missing_files.append(file_path)

    if not missing_files:
        print("All files appear to be in the project.")
        sys.exit(0)

    print(f"Found {len(missing_files)} missing files. Adding them...")

    new_file_refs = []
    new_build_files = []
    new_source_files = []
    
    # We need to find the ID of the main group to add references to (or a sub-group)
    # For now, we'll try to add them to the main group 'thecoffeelinks-client-ios'
    # Finding main group children block
    main_group_regex = re.compile(r'([A-F0-9]+) /\* thecoffeelinks-client-ios \*/ = \{[^}]*children = \(([^)]+)\);', re.DOTALL)
    match = main_group_regex.search(content)
    
    if not match:
        print("Could not find main group children block.")
        sys.exit(1)
        
    main_group_id = match.group(1)
    current_children = match.group(2)
    new_children_refs = []

    for file_path in missing_files:
        filename = os.path.basename(file_path)
        file_ref_id = generate_id()
        build_file_id = generate_id()
        
        # Use simple path (filename) assuming flat structure or handle full path relative?
        # Xcode usually expects path relative to group. If we add to main group, path should be relative to project?
        # Actually, simpler to just add them with full relative path from project root if possible, or just filename if in group.
        # Let's try adding with the relative path we found.
        
        # PBXFileReference
        new_file_refs.append(f'\t\t{file_ref_id} /* {filename} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = "{file_path}"; sourceTree = "<group>"; }};')
        
        # PBXBuildFile
        new_build_files.append(f'\t\t{build_file_id} /* {filename} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_ref_id} /* {filename} */; }};')
        
        # Add to Group Children
        new_children_refs.append(f'\t\t\t\t{file_ref_id} /* {filename} */,')

        # Add to Build Phase
        new_source_files.append(f'\t\t\t\t{build_file_id} /* {filename} in Sources */,')
        
        added_files.append(filename)

    # Apply changes
    
    # 1. File Refs
    content = content.replace(file_ref_marker, file_ref_marker + "\n" + "\n".join(new_file_refs))
    
    # 2. Build Files
    content = content.replace(build_file_marker, build_file_marker + "\n" + "\n".join(new_build_files))
    
    # 3. Group Children
    # We inject new children into the main group
    new_children_block = current_children + "\n" + "\n".join(new_children_refs)
    content = content.replace(current_children, new_children_block, 1)
    
    # 4. Sources Build Phase
    sources_match = sources_marker_regex.search(content)
    if sources_match:
        current_sources = sources_match.group(1)
        new_sources_block = current_sources + "\n" + "\n".join(new_source_files)
        content = content.replace(current_sources, new_sources_block, 1)
    
    with open(PROJECT_FILE, "w") as f:
        f.write(content)
        
    print(f"Successfully added: {', '.join(added_files)}")

if __name__ == "__main__":
    main()
