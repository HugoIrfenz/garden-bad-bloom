# Android export verification

The Android preset packages the game as a landscape, ARM64 APK with embedded Godot resources. The verified build uses the native Godot exporter and a local debug signing key.

## Local dependencies

| Dependency | Verified version |
| --- | --- |
| Godot editor and Android debug template | 4.4.1 stable |
| Eclipse Temurin OpenJDK | 17.0.21.1+2 |
| Android SDK Build-Tools | 34.0.0 |
| Android SDK Platform-Tools package | 37.0.1 |
| Android application target | API 34 |

The local installation lives under `~/.local/share/garden-android-tools`. Its isolated Godot settings point to the Java and SDK directories. The version-matched Android template is under `editor-data/godot/export_templates/4.4.1.stable/android_debug.apk`. Godot generated the debug keystore in the same isolated profile. The project's preset contains no keys, signing credentials, or workstation-specific paths.

Use the official [Godot 4.4.1 archive](https://godotengine.org/download/archive/4.4.1-stable/), [Godot Android export documentation](https://docs.godotengine.org/en/4.4/tutorials/export/exporting_for_android.html), [Eclipse Temurin release downloads](https://adoptium.net/temurin/releases/?version=17), and [Android SDK package documentation](https://developer.android.com/tools/releases/build-tools) to reproduce the local toolchain on another machine.

## Build and inspect on the laptop

Keep the `Android` preset's `runnable=false` setting. This export uses a staged project copy and makes no device connections. The process trace checks for any unexpected ADB invocation. [Godot 4.4.1 Android exporter source](https://github.com/godotengine/godot/blob/4.4.1-stable/platform/android/export/export_plugin.cpp)

Run this from the project root with the local toolchain installed.

```bash
set -euo pipefail
project_dir="$PWD"
android_tools_dir="$HOME/.local/share/garden-android-tools"
godot_bin="$HOME/.local/share/garden-godot/Godot_v4.4.1-stable_linux.x86_64"
android_build_dir="$(mktemp -d /tmp/garden-android-export.XXXXXX)"
android_apk="$android_build_dir/GardenBadBloom-debug.apk"
android_build_tools="$android_tools_dir/sdk/build-tools/34.0.0"

export JAVA_HOME="$android_tools_dir/java"
export PATH="$JAVA_HOME/bin:$PATH"
export XDG_CONFIG_HOME="$android_tools_dir/editor-config"
export XDG_DATA_HOME="$android_tools_dir/editor-data"

mkdir -p "$android_build_dir/project"
rsync -a --exclude .godot --exclude .git --exclude '*.apk' "$project_dir/" "$android_build_dir/project/"
strace -f -qq -e trace=execve -o "$android_build_dir/import-processes.log" \
  "$godot_bin" --headless --editor --path "$android_build_dir/project" --import --quit
strace -f -qq -e trace=execve -o "$android_build_dir/export-processes.log" \
  "$godot_bin" --headless --path "$android_build_dir/project" --export-debug Android "$android_apk"

if rg -q 'execve\("[^"]*/adb"' "$android_build_dir/"*-processes.log; then
  printf '%s\n' 'Unexpected ADB invocation during packaging.' >&2
  exit 1
fi

"$android_build_tools/apksigner" verify --verbose "$android_apk"
"$android_build_tools/aapt" dump badging "$android_apk" |
  rg '^(package|sdkVersion|targetSdkVersion|application-label:|application-debuggable$|native-code)'
"$android_build_tools/aapt" dump permissions "$android_apk"
"$android_build_tools/aapt" dump xmltree "$android_apk" AndroidManifest.xml |
  rg 'screenOrientation|uses-permission'
unzip -tq "$android_apk"
printf '%s\n' "$android_apk"
```

## Observed manifest and signing

| Check | Debug verification result |
| --- | --- |
| Package and version | `org.gardenbadbloom.game`, `0.1.12` (code 13) |
| Supported ABI | `arm64-v8a` |
| Android versions | Minimum API 21, target API 34 |
| Activity orientation | Landscape (`screenOrientation=0x0`) |
| Declared permissions | Zero |
| APK signatures | Verified v1, v2, and v3 with a single debug signer |
| Archive and assets | ZIP integrity passed. The media atlas, jukebox, relic ledger, and all 37 soundtrack assets are embedded. Docs and tests are omitted. |
| Device access | No ADB process appeared in either trace |

This verification covers the [0.1.12 Android debug release](https://github.com/hugosyrf/garden-bad-bloom/releases/tag/v0.1.12). Phone playtesting remains with the owner.
