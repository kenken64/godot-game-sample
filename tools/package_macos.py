"""Add the native micro:bit-aware startup executable to a Godot macOS export."""
import argparse
from pathlib import Path
import plistlib
import shutil
import subprocess
import tempfile


def package_macos(app: Path) -> None:
    tools = Path(__file__).resolve().parent
    info = plistlib.loads((app / "Contents/Info.plist").read_bytes())
    executable = app / "Contents/MacOS" / info["CFBundleExecutable"]
    engine = executable.with_name(executable.name + ".engine")
    original = engine if engine.exists() else executable
    with tempfile.TemporaryDirectory(prefix="tsg-native-launcher-") as temporary:
        build = Path(temporary)
        entitlement_result = subprocess.run(
            ["codesign", "-d", "--entitlements", ":-", str(original)],
            text=True, capture_output=True, check=True,
        )
        entitlement_args = []
        if entitlement_result.stdout.strip():
            entitlements = build / "entitlements.plist"
            plistlib.loads(entitlement_result.stdout.encode())
            entitlements.write_text(entitlement_result.stdout)
            entitlement_args = ["--entitlements", str(entitlements)]
        binaries = []
        for architecture, target in [("arm64", "arm64-apple-macos11"), ("x86_64", "x86_64-apple-macos10.15")]:
            binary = build / architecture
            subprocess.run([
                "xcrun", "clang", "-target", target, "-O2", "-Wall", "-Wextra",
                str(tools / "macos_game_launcher.c"), "-framework", "CoreFoundation",
                "-framework", "IOKit", "-o", str(binary),
            ], check=True)
            binaries.append(binary)
        launcher = build / "launcher"
        subprocess.run(["xcrun", "lipo", "-create", *map(str, binaries), "-output", str(launcher)], check=True)
        if not engine.exists():
            executable.rename(engine)
        shutil.copy2(launcher, executable)
        executable.chmod(0o755)
        shutil.copy2(tools / "microbit-gamepad-macos.txt", app / "Contents/Resources/microbit-gamepad-macos.txt")
        for target in [engine, app]:
            subprocess.run(["codesign", "--force", "--sign", "-", "--timestamp=none", *entitlement_args, str(target)], check=True)
        subprocess.run(["codesign", "--verify", "--deep", "--strict", str(app)], check=True)
    print(f"Native macOS micro:bit startup included: {app}", flush=True)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("app", type=Path)
    package_macos(parser.parse_args().app.resolve())
