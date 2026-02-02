#!/usr/bin/env bash
set -euo pipefail

# Collect xcodebuild logs and extract warnings. Run from the project root.
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

LOG_OUT="xcodebuild.log"
JSON_OUT="xcodebuild.json"
WARN_OUT="xcodebuild-warnings.txt"

echo "Starting xcodebuild (debug, iphonesimulator). Output -> $LOG_OUT"

if [ -d "TheCoffeeLinks.xcworkspace" ]; then
  xcodebuild -workspace TheCoffeeLinks.xcworkspace -scheme TheCoffeeLinks -configuration Debug -sdk iphonesimulator clean build | tee "$LOG_OUT" | xcpretty -r json -o "$JSON_OUT" || true
else
  xcodebuild -project TheCoffeeLinks.xcodeproj -scheme TheCoffeeLinks -configuration Debug -sdk iphonesimulator clean build | tee "$LOG_OUT" | xcpretty -r json -o "$JSON_OUT" || true
fi

# Extract warnings from the raw log
grep -n "warning:" "$LOG_OUT" || true > "$WARN_OUT"

echo "Warnings extracted to $WARN_OUT. Raw log at $LOG_OUT. JSON report at $JSON_OUT (if xcpretty available)."

# Exit code 0 to avoid CI hang; scripts should allow further parsing
exit 0
