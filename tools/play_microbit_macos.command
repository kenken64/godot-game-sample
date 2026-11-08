#!/bin/sh
set -eu

if [ "$(uname -s)" != "Darwin" ]; then
    printf '%s\n' 'This compatibility launcher is for macOS.' >&2
    exit 1
fi

launcher_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
if [ "${1:-}" = "--input-check" ]; then
    shift
    microbit_executable=${GODOT_EDITOR:-/Applications/Godot.app/Contents/MacOS/Godot}
    if [ ! -x "$microbit_executable" ]; then
        printf '%s\n' 'The input checker needs the Godot editor. Install it or set GODOT_EDITOR to its executable.' >&2
        exit 1
    fi
    set -- --path "$launcher_dir" --windowed --resolution 800x500 --script "$launcher_dir/microbit_input_check.gd" "$@"
else
    if [ -n "${GODOT_MICROBIT_APP:-}" ]; then
        microbit_app=$GODOT_MICROBIT_APP
    elif [ -d "$launcher_dir/tsg-game-macos.app" ]; then
        microbit_app="$launcher_dir/tsg-game-macos.app"
    elif [ -d "$launcher_dir/../../GodotForgeSample-export/tsg-game-macos.app" ]; then
        microbit_app="$launcher_dir/../../GodotForgeSample-export/tsg-game-macos.app"
    else
        printf '%s\n' 'Place these tools beside tsg-game-macos.app, or set GODOT_MICROBIT_APP to the app bundle path.' >&2
        exit 1
    fi
    microbit_bundle_executable=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleExecutable' "$microbit_app/Contents/Info.plist")
    microbit_executable="$microbit_app/Contents/MacOS/$microbit_bundle_executable"
fi

IFS= read -r microbit_mapping < "$launcher_dir/microbit-gamepad-macos.txt"
# Select IOKit before the engine initializes SDL. This affects only this launch.
export SDL_JOYSTICK_MFI=0
if [ -n "${SDL_GAMECONTROLLERCONFIG:-}" ]; then
    SDL_GAMECONTROLLERCONFIG="${SDL_GAMECONTROLLERCONFIG}
${microbit_mapping}"
else
    SDL_GAMECONTROLLERCONFIG=$microbit_mapping
fi
export SDL_GAMECONTROLLERCONFIG

exec "$microbit_executable" "$@"
