# BACKROOMS: LEVEL 0 — Godot 4 Android prototype

An offline first-person 3D horror prototype targeting Android arm64 in landscape orientation.

## Included gameplay
- Procedurally assembled yellow maze with walls, floor, ceiling and scattered lighting.
- First-person movement, mouse look, touch movement/look, sprint and flashlight.
- Stamina and flashlight battery meters.
- A pursuing monster, five collectible notes and a marked exit.
- Russian-language HUD and end-game screen.

## Run in Godot
Open the repository root in Godot 4.3 and run `main.tscn`. Desktop controls: WASD, mouse, Shift and F. On touch devices, drag the left side to move and the right side to look; use the on-screen sprint and flashlight buttons.

## Android export
The export preset is named `Android`, targets `arm64-v8a`, and exports to `build/BACKROOMS.apk`. Install the matching Godot Android export templates and configure Android SDK/JDK in Godot Editor Settings before exporting locally.

A GitHub Actions workflow at `.github/workflows/android.yml` runs on pushes to `main` and can also be started manually. It imports the project, runs a headless scene check, exports a debug APK and uploads it as an artifact when successful.

## Verification and limitations
The repository upload is complete, but this prototype has not yet been validated in the Godot editor or on a physical Android device. The GitHub Actions build is currently being checked. Visuals are procedural placeholders; this is an early prototype, not a finished commercial release. Monster navigation, touch controls, performance and collision behavior still need playtesting on Android hardware.
