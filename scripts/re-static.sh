#!/bin/bash
# re-static.sh — read-only static survey of a macOS .app bundle.
#
#   scripts/re-static.sh /Applications/Some.app [out-dir]
#   (in a Pith run: "$PITH/scripts/re-static.sh" /Applications/Some.app "$W/dirty/evidence/static")
#
# Writes plain-text evidence files plus SUMMARY.md into out-dir (default:
# ./re-out/<AppName>-static). It never executes anything inside the bundle:
# only file, otool, nm, strings, codesign -d, lipo, vtool, plutil and
# swift-demangle read it. Secrets it notices (API-key-shaped strings) are
# masked as …REDACTED… in every file built from the executable's strings and
# in info-plist.txt — evidence of a key's existence is enough; never copy the key.
# Needs the Xcode Command Line Tools (xcode-select --install).
set -u

APP="${1:-}"
if [ -z "$APP" ] || [ ! -d "$APP/Contents" ]; then
  echo "usage: $0 /path/to/App.app [out-dir]" >&2
  exit 2
fi
# Without the Command Line Tools every reading below fails quietly and the
# summary would look valid while being wrong (even "Encrypted: no"), so stop.
for t in otool nm strings lipo vtool; do
  xcrun --find "$t" >/dev/null 2>&1 || {
    echo "re-static.sh needs the Xcode Command Line Tools ($t not found). Install them with: xcode-select --install" >&2
    exit 3
  }
done
APP="$(cd "$APP" && pwd)"
NAME="$(basename "$APP" .app)"
OUT="${2:-./re-out/${NAME}-static}"
mkdir -p "$OUT"
INFO="$APP/Contents/Info.plist"

plistval() { /usr/libexec/PlistBuddy -c "Print :$1" "$INFO" 2>/dev/null; }
# Mask API-key-shaped tokens, keeping only a short prefix and suffix. Applied to
# every file written from the strings dump, and to info-plist.txt.
mask() { LC_ALL=C sed -E 's/(appl_|goog_|amzn_|sk_live_|pk_live_|AIza|AKIA|ghp_|xox[bap]-)([A-Za-z0-9_-]{2})[A-Za-z0-9_-]{4,}([A-Za-z0-9_-]{2})/\1\2…REDACTED…\3/g'; }

EXE_NAME="$(plistval CFBundleExecutable)"
EXE="$APP/Contents/MacOS/$EXE_NAME"
BUNDLE_ID="$(plistval CFBundleIdentifier)"
VERSION="$(plistval CFBundleShortVersionString) ($(plistval CFBundleVersion))"

echo ">> $NAME  $BUNDLE_ID  $VERSION"
echo ">> evidence → $OUT"

# 1. Identity, signing, entitlements
plutil -p "$INFO" 2>&1 | mask > "$OUT/info-plist.txt"
codesign -dvvv "$APP" > "$OUT/signature.txt" 2>&1
codesign -d --entitlements - --xml "$APP" 2>/dev/null | plutil -p - > "$OUT/entitlements.txt" 2>&1 \
  || echo "(no entitlements or unreadable)" > "$OUT/entitlements.txt"
[ -d "$APP/Contents/_MASReceipt" ] && STORE="Mac App Store (has _MASReceipt)" || STORE="not from the Mac App Store (no _MASReceipt)"

# 2. Main executable: architectures, platform, encryption, linked libraries
# If otool can't read the load commands, encryption is "unknown", never "no".
if LOADCMDS="$(otool -l "$EXE" 2>/dev/null)" && printf '%s\n' "$LOADCMDS" | grep -q '^Load command'; then
  ENC_INFO="$(printf '%s\n' "$LOADCMDS" | grep -A4 LC_ENCRYPTION_INFO)"
  printf '%s\n' "$ENC_INFO" | grep -Eq '^ *cryptid [1-9]' && ENCRYPTED=yes || ENCRYPTED=no
  [ -n "$ENC_INFO" ] || ENC_INFO="no LC_ENCRYPTION_INFO"
else
  ENCRYPTED=unknown
  ENC_INFO="UNKNOWN: otool could not read the load commands; do not treat as unencrypted"
fi
{
  echo "## file";            file "$EXE"
  echo; echo "## archs";     lipo -archs "$EXE" 2>&1
  echo; echo "## build version (platform / minos / sdk)"; vtool -show-build "$EXE" 2>&1 | sed -n '1,40p'
  echo; echo "## encryption info (a non-zero cryptid means FairPlay-encrypted)"
  printf '%s\n' "$ENC_INFO"
} > "$OUT/executable.txt" 2>&1
otool -L "$EXE" > "$OUT/linked-libraries.txt" 2>&1
otool -l "$EXE" > "$OUT/load-commands.txt" 2>&1

# 3. Bundle anatomy: size, frameworks, embedded executables, helpers, XPC, plugins
du -sh "$APP" > "$OUT/size.txt" 2>&1
du -sh "$APP"/Contents/* 2>/dev/null | sort -hr >> "$OUT/size.txt"
find "$APP" -name "*.framework" -maxdepth 4 2>/dev/null | sed "s|$APP/||" | sort > "$OUT/frameworks.txt"
find "$APP" \( -name "*.xpc" -o -name "*.appex" -o -name "*.plugin" -o -name "*.bundle" -o -name "*.app" \) \
  -not -path "$APP" 2>/dev/null | sed "s|$APP/||" | sort > "$OUT/nested-bundles.txt"
# Executable Mach-O files anywhere in the bundle (bundled tools, helpers, runtimes)
find "$APP" -type f -perm +111 2>/dev/null | while read -r f; do
  kind="$(file -b "$f" | head -1)"   # a universal binary adds one line per architecture
  case "$kind" in *Mach-O*) echo "$(echo "$f" | sed "s|$APP/||")	$kind";; esac
done | sort > "$OUT/embedded-executables.txt"
# Licence / notice files (what third-party code ships, and on which terms)
find "$APP" \( -iname "*licen[cs]e*" -o -iname "*notice*" -o -iname "copying*" -o -iname "*acknowledg*" \) 2>/dev/null \
  | sed "s|$APP/||" | sort > "$OUT/licence-files.txt"
# Privacy manifests
find "$APP" -name "PrivacyInfo.xcprivacy" 2>/dev/null | while read -r f; do
  echo "## ${f#$APP/}"; plutil -p "$f"; echo
done > "$OUT/privacy-manifests.txt" 2>&1

# 4. Strings: endpoints, hosts, interesting identifiers (secrets redacted)
strings -a -n 6 "$EXE" > "$OUT/.strings-all.txt" 2>/dev/null
grep -Eo 'https?://[A-Za-z0-9._~:/?#@!$&()*+,;=%-]+' "$OUT/.strings-all.txt" | mask | sort -u > "$OUT/strings-urls.txt"
# Hosts with a dot (or localhost); drops fragments such as "x" from placeholder URLs.
sed -E 's|https?://([^/:?#]+).*|\1|' "$OUT/strings-urls.txt" | grep -E '\.|^localhost$' | sort | uniq -c | sort -rn > "$OUT/strings-hosts.txt"
# Key-shaped tokens: report the shape and a masked value only.
grep -Eo '\b(appl_|goog_|amzn_|sk_live_|pk_live_|AIza|AKIA|ghp_|xox[bap]-)[A-Za-z0-9_-]{8,}' "$OUT/.strings-all.txt" \
  | sort -u | sed -E 's/^(.{6}).*(.{2})$/\1…REDACTED…\2/' > "$OUT/strings-possible-secrets-REDACTED.txt"
grep -Ei 'revenuecat|firebase|sentry|mixpanel|amplitude|segment|appsflyer|adjust|crashlytics|bugsnag|posthog|telemetry|analytics' \
  "$OUT/.strings-all.txt" | mask | sort -u | head -200 > "$OUT/strings-sdks.txt"
grep -E '^[a-z][a-z0-9+.-]*://$|CFBundleURLSchemes|NSUserActivity|NSServices|INIntent|AppIntent|OSAScripting|scriptSuite' \
  "$OUT/.strings-all.txt" | mask | sort -u | head -100 > "$OUT/strings-automation.txt"

# 5. Code structure: Objective-C classes, Swift types and symbols
DEMANGLE="$(xcrun --find swift-demangle 2>/dev/null)"
demangle() { if [ -n "$DEMANGLE" ]; then "$DEMANGLE" --simplified 2>/dev/null; else cat; fi; }
# Objective-C class and protocol names, read from the __objc_classname section.
# Swift classes the Objective-C runtime sees are stored mangled (_TtC…); they are
# demangled to the bare type name (e.g. AppDelegate) when swift-demangle is found.
otool -v -s __TEXT __objc_classname "$EXE" 2>/dev/null \
  | awk 'NF == 2 && $1 ~ /^[0-9a-f]+$/ {print $2}' | demangle | sort -u > "$OUT/objc-classes.txt"
# nm prints a "(for architecture …):" header per slice of a universal binary; skip those.
nm -gU "$EXE" 2>/dev/null | awk 'NF && $NF !~ /\):$/ {print $NF}' | sort -u > "$OUT/.symbols.txt"
if [ -n "$DEMANGLE" ]; then
  "$DEMANGLE" --simplified < "$OUT/.symbols.txt" > "$OUT/symbols-demangled.txt" 2>/dev/null
  # Swift protocols the binary refers to by mangled name ($s…P), demangled: mostly
  # framework ones such as View, plus some of the app's own. This is not a list of
  # the app's structs, classes or enums: in a stripped binary those need
  # `ipsw swift-dump` (dirty side); Swift classes also appear in objc-classes.txt.
  grep -Eo '\$s[A-Za-z0-9_]+' "$OUT/.strings-all.txt" | sort -u | head -5000 \
    | "$DEMANGLE" --simplified 2>/dev/null | sort -u > "$OUT/swift-names.txt"
else
  cp "$OUT/.symbols.txt" "$OUT/symbols-demangled.txt"
fi
# Swift field names live in __swift5_reflstr even in a stripped binary.
# otool prints the section as little-endian 32-bit words; swap each back to bytes.
section_strings() {
  otool -X -s "$1" "$2" "$EXE" 2>/dev/null \
    | awk '{ for (i = 2; i <= NF; i++) { w = $i; o = ""; for (j = length(w) - 1; j >= 1; j -= 2) o = o substr(w, j, 2); printf "%s", o } }' \
    | xxd -r -p | strings -n 3
}
section_strings __TEXT __swift5_reflstr | sort -u > "$OUT/swift-field-names.txt"
[ -s "$OUT/swift-field-names.txt" ] && HAS_SWIFT="yes" || HAS_SWIFT="no"

# 6. Extended attributes (quarantine, App Data protection markers)
xattr -lr "$APP" 2>/dev/null | grep -E 'com.apple.(macl|quarantine|provenance)' | head -20 > "$OUT/xattrs.txt"

# 7. Summary
count() { [ -s "$1" ] && wc -l < "$1" | tr -d ' ' || echo 0; }
{
  echo "# Static survey — $NAME"
  echo
  echo "| | |"
  echo "|---|---|"
  echo "| Bundle id | \`$BUNDLE_ID\` |"
  echo "| Version | $VERSION |"
  echo "| Executable | \`Contents/MacOS/$EXE_NAME\` — $(lipo -archs "$EXE" 2>/dev/null) |"
  echo "| Distribution | $STORE |"
  echo "| Size | $(head -1 "$OUT/size.txt" | awk '{print $1}') |"
  case "$ENCRYPTED" in
    yes)     ENC_TEXT='YES — code and strings are unreadable statically; use runtime and behavioural methods' ;;
    unknown) ENC_TEXT='UNKNOWN (otool failed; do not treat as unencrypted)' ;;
    *)       ENC_TEXT='no' ;;
  esac
  echo "| Encrypted (FairPlay) | $ENC_TEXT |"
  echo "| Sandboxed | $(grep -q 'com.apple.security.app-sandbox' "$OUT/entitlements.txt" && echo yes || echo no) |"
  echo "| Swift reflection metadata | $HAS_SWIFT |"
  echo "| URL schemes declared | $(plistval CFBundleURLTypes >/dev/null && echo yes || echo none) |"
  echo "| LSUIElement (menu-bar agent) | $(plistval LSUIElement || echo no) |"
  echo
  echo "Counts: $(count "$OUT/frameworks.txt") frameworks · $(count "$OUT/nested-bundles.txt") nested bundles · $(count "$OUT/embedded-executables.txt") Mach-O executables · $(count "$OUT/licence-files.txt") licence files · $(count "$OUT/strings-urls.txt") URLs · $(count "$OUT/objc-classes.txt") ObjC class and protocol names · $(count "$OUT/swift-names.txt") Swift names (mostly protocols) · $(count "$OUT/swift-field-names.txt") Swift field names · $(count "$OUT/strings-possible-secrets-REDACTED.txt") key-shaped strings (redacted)"
  echo
  echo "## Hosts referenced (top 25)"
  echo '```'; head -25 "$OUT/strings-hosts.txt"; echo '```'
  echo
  echo "## Embedded executables"
  echo '```'; head -40 "$OUT/embedded-executables.txt"; echo '```'
  echo
  echo "Next: read the evidence files, then fill your workspace copy of report.md (dirty/report.md):"
  echo "sections 2-6 and Appendix C, i.e. §Static."
  echo "Do not run embedded tools directly — sandboxed helpers trap (exit 133) and running"
  echo "a vendor's binaries is outside a read-only survey anyway."
} > "$OUT/SUMMARY.md"
rm -f "$OUT/.strings-all.txt" "$OUT/.symbols.txt"
echo ">> done: $OUT/SUMMARY.md"
