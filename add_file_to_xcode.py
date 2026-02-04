#!/usr/bin/env python3
"""
Add AppFlowController.swift to Xcode project.pbxproj
"""
import re
import uuid
import sys

def generate_uuid():
    """Generate a 24-character hex string like Xcode uses"""
    return uuid.uuid4().hex[:24].upper()

def add_file_to_pbxproj(pbxproj_path, file_path, group_name="Services"):
    with open(pbxproj_path, 'r') as f:
        content = f.read()
    
    # Generate UUIDs for this file
    file_ref_uuid = generate_uuid()
    build_file_uuid = generate_uuid()
    
    # 1. Add PBXFileReference
    file_ref_section = re.search(r'/\* Begin PBXFileReference section \*/(.*?)/\* End PBXFileReference section \*/', content, re.DOTALL)
    if file_ref_section:
        new_file_ref = f'\t\t{file_ref_uuid} /* AppFlowController.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = AppFlowController.swift; sourceTree = "<group>"; }};\n'
        insert_pos = file_ref_section.end(1)
        content = content[:insert_pos] + new_file_ref + content[insert_pos:]
    
    # 2. Add PBXBuildFile
    build_file_section = re.search(r'/\* Begin PBXBuildFile section \*/(.*?)/\* End PBXBuildFile section \*/', content, re.DOTALL)
    if build_file_section:
        new_build_file = f'\t\t{build_file_uuid} /* AppFlowController.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {file_ref_uuid} /* AppFlowController.swift */; }};\n'
        insert_pos = build_file_section.end(1)
        content = content[:insert_pos] + new_build_file + content[insert_pos:]
    
    # 3. Add to Services PBXGroup
    services_group = re.search(rf'([A-F0-9]{{24}}) /\* {group_name} \*/ = {{\s*isa = PBXGroup;\s*children = \((.*?)\);', content, re.DOTALL)
    if services_group:
        children_content = services_group.group(2)
        new_child = f'\n\t\t\t\t{file_ref_uuid} /* AppFlowController.swift */,'
        children_content_with_new = children_content + new_child
        content = content.replace(services_group.group(0), services_group.group(0).replace(children_content, children_content_with_new))
    
    # 4. Add to PBXSourcesBuildPhase
    sources_phase = re.search(r'([A-F0-9]{24}) /\* Sources \*/ = {\s*isa = PBXSourcesBuildPhase;\s*buildActionMask = \d+;\s*files = \((.*?)\);', content, re.DOTALL)
    if sources_phase:
        files_content = sources_phase.group(2)
        new_file_entry = f'\n\t\t\t\t{build_file_uuid} /* AppFlowController.swift in Sources */,'
        files_content_with_new = files_content + new_file_entry
        content = content.replace(sources_phase.group(0), sources_phase.group(0).replace(files_content, files_content_with_new))
    
    # Write back
    with open(pbxproj_path, 'w') as f:
        f.write(content)
    
    print(f"✅ Added AppFlowController.swift to {pbxproj_path}")
    print(f"   File Reference UUID: {file_ref_uuid}")
    print(f"   Build File UUID: {build_file_uuid}")

if __name__ == "__main__":
    pbxproj = "/Users/nguyenducnhat/appcafe/thecoffeelinks-client-ios/TheCoffeeLinks.xcodeproj/project.pbxproj"
    file_to_add = "TheCoffeeLinks/Core/Services/AppFlowController.swift"
    
    try:
        add_file_to_pbxproj(pbxproj, file_to_add)
        print("\n⚠️  Now rebuild the project in Xcode")
    except Exception as e:
        print(f"❌ Error: {e}")
        sys.exit(1)
