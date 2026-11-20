#!/usr/bin/env python3
"""Prepare a Godot Android export template with a WebRTC-compatible ARM64 runtime."""

import argparse
from pathlib import Path
from zipfile import ZipFile

ARM64_RUNTIME = "lib/arm64-v8a/libc++_shared.so"
WEBRTC_REQUIRED_SYMBOL = b"_ZTTNSt6__ndk119basic_istringstreamIcNS_11char_traitsIcEENS_9allocatorIcEEEE"


def prepare(template: Path, runtime: Path, output: Path) -> None:
    if template.resolve() == output.resolve():
        raise ValueError("Use a separate output path for the patched template.")
    library = runtime.read_bytes()
    if library[:4] != b"\x7fELF" or len(library) < 20 or library[18:20] != b"\xb7\x00":
        raise ValueError("The runtime must be an Android ARM64 ELF library.")
    if WEBRTC_REQUIRED_SYMBOL not in library:
        raise ValueError("The runtime lacks the C++ symbol required by the bundled WebRTC extension.")

    with ZipFile(template) as original:
        if ARM64_RUNTIME not in original.namelist():
            raise ValueError("The Godot template is missing the ARM64 C++ runtime.")
        with ZipFile(output, "w") as patched:
            for entry in original.infolist():
                contents = library if entry.filename == ARM64_RUNTIME else original.read(entry)
                patched.writestr(entry, contents)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("template", type=Path, help="Godot android_debug.apk or android_release.apk")
    parser.add_argument("runtime", type=Path, help="NDK ARM64 libc++_shared.so, such as from r28c")
    parser.add_argument("output", type=Path, help="APK to select as the matching custom export template")
    args = parser.parse_args()
    prepare(args.template, args.runtime, args.output)
