# Fix Build Error: Add AppFlowController.swift to Xcode Project

## Problem
The file `TheCoffeeLinks/Core/Services/AppFlowController.swift` exists but hasn't been added to the Xcode build target.

## Solution

### Option 1: Add via Xcode (Recommended)
1. Open `TheCoffeeLinks.xcodeproj` in Xcode
2. In the Project Navigator (left sidebar), right-click on `Core/Services` folder
3. Select **"Add Files to TheCoffeeLinks..."**
4. Navigate to `TheCoffeeLinks/Core/Services/AppFlowController.swift`
5. Make sure **"Copy items if needed"** is UNCHECKED (file already exists)
6. Make sure **"Add to targets: TheCoffeeLinks"** is CHECKED
7. Click **"Add"**
8. Build again (⌘B)

### Option 2: Quick Fix via Terminal
Run this command from the project root:

```bash
cd /Users/nguyenducnhat/appcafe/thecoffeelinks-client-ios
open TheCoffeeLinks.xcodeproj
```

Then manually drag `TheCoffeeLinks/Core/Services/AppFlowController.swift` from Finder into the Xcode Project Navigator under `Core/Services`.

### Option 3: Command Line (Advanced)
If you have `xed` or Xcode command-line tools:

```bash
cd /Users/nguyenducnhat/appcafe/thecoffeelinks-client-ios
xed -a TheCoffeeLinks.xcodeproj TheCoffeeLinks/Core/Services/AppFlowController.swift
```

## Verify Fix
After adding the file, rebuild:
```bash
xcodebuild -scheme TheCoffeeLinks -configuration Debug clean build
```

If successful, you should see:
```
** BUILD SUCCEEDED **
```

## Alternative: Recreate File in Xcode
If the above doesn't work:
1. Delete the file from filesystem: `rm TheCoffeeLinks/Core/Services/AppFlowController.swift`
2. In Xcode: Right-click `Core/Services` → **New File** → **Swift File**
3. Name it `AppFlowController`
4. Copy the contents from `APP_FLOW_FIX_REPORT.md` or the backup below

---

## File Contents (Backup)
If you need to recreate the file, use the content from:
`/Users/nguyenducnhat/appcafe/thecoffeelinks-client-ios/TheCoffeeLinks/Core/Services/AppFlowController.swift`
