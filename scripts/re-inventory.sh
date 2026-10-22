#!/bin/bash
# re-inventory.sh — list installed apps with what you need to pick a target:
# bundle id, version, architectures, how it's built, and where it came from.
#
#   scripts/re-inventory.sh [folder ...]     (default: /Applications ~/Applications)
#
# Read-only: reads Info.plists and Mach-O headers, runs nothing it finds.
set -u
[ $# -eq 0 ] && set -- /Applications "$HOME/Applications"
# lipo and vtool come with the Xcode Command Line Tools; without them the Archs
# column and Mac Catalyst detection would be silently wrong, so stop.
for t in lipo vtool; do
  xcrun --find "$t" >/dev/null 2>&1 || {
    echo "re-inventory.sh needs the Xcode Command Line Tools ($t not found). Install them with: xcode-select --install" >&2
    exit 3
  }
done

# Where a bundle came from, read from its code signature.
source_of() {
  local sig
  sig="$(codesign -dvv "$1" 2>&1)"   # Authority lines need -vv
  if [ -d "$1/Contents/_MASReceipt" ] || echo "$sig" | grep -qE 'Authority=Apple (Mac OS|iPhone OS) Application Signing'; then echo "App Store"
  elif echo "$sig" | grep -q 'Authority=Developer ID Application'; then echo "Developer ID"
  elif echo "$sig" | grep -q 'Authority=Apple Development'; then echo "development build"
  elif echo "$sig" | grep -q 'Signature=adhoc'; then echo "ad-hoc signed"
  elif echo "$sig" | grep -q 'not signed'; then echo "unsigned"
  else echo "other"; fi
}

printf '| App | Bundle id | Version | Archs | Built with | Source |\n|---|---|---|---|---|---|\n'
for root in "$@"; do
  [ -d "$root" ] || continue
  find "$root" -maxdepth 2 -name "*.app" -prune 2>/dev/null | sort | while read -r app; do
    info="$app/Contents/Info.plist"
    [ -f "$info" ] || { [ -f "$app/WrappedBundle/Info.plist" ] || continue; }
    pb() { /usr/libexec/PlistBuddy -c "Print :$1" "$info" 2>/dev/null; }
    name="$(basename "$app" .app)"
    if [ -d "$app/Wrapper" ] || [ -L "$app/WrappedBundle" ]; then
      # An iOS app wrapped for the Mac: read the inner iOS bundle (flat layout).
      # Anything that can't be read is shown as ?.
      inner="$(cd "$app/WrappedBundle" 2>/dev/null && pwd -P)"
      if [ -n "$inner" ] && [ -f "$inner/Info.plist" ]; then
        info="$inner/Info.plist"
        exe="$inner/$(pb CFBundleExecutable)"
        printf '| %s | `%s` | %s | %s | iOS app (wrapped) | %s |\n' "$name" "$(pb CFBundleIdentifier || echo '?')" \
          "$(pb CFBundleShortVersionString || echo '?')" "$(lipo -archs "$exe" 2>/dev/null || echo '?')" "$(source_of "$inner")"
      else
        printf '| %s | ? | ? | ? | iOS app (wrapped) | ? |\n' "$name"
      fi
      continue
    fi
    exe="$app/Contents/MacOS/$(pb CFBundleExecutable)"
    archs="$(lipo -archs "$exe" 2>/dev/null || echo '?')"
    fw="$app/Contents/Frameworks"
    kind="native"
    if   [ -d "$fw/Electron Framework.framework" ]; then kind="Electron"
    elif ls "$fw" 2>/dev/null | grep -qi '^QtCore'; then kind="Qt"
    elif [ -d "$fw/FlutterMacOS.framework" ]; then kind="Flutter"
    elif [ -d "$app/Contents/PlugIns/JavaAppletPlugin.plugin" ] || ls "$app/Contents" 2>/dev/null | grep -qiE '^(runtime|jre|java)$'; then kind="Java"
    elif vtool -show-build "$exe" 2>/dev/null | grep -q 'MACCATALYST'; then kind="Mac Catalyst"
    elif [ -d "$fw/CefSharp.framework" ] || [ -d "$fw/Chromium Embedded Framework.framework" ]; then kind="CEF"
    fi
    src="$(source_of "$app")"
    printf '| %s | `%s` | %s | %s | %s | %s |\n' "$name" "$(pb CFBundleIdentifier)" "$(pb CFBundleShortVersionString)" "$archs" "$kind" "$src"
  done
done
