# BACKROOMS: LEVEL 0 — Godot 4 Android prototype

An offline first-person 3D horror prototype. The project targets Android arm64 and landscape orientation; Android 8+ is the intended minimum deployment target.

## Implemented
- Runtime-built grid maze with yellow walls, ceiling, fluorescent fixtures and collision.
- First-person movement, desktop mouse look, multitouch movement/look, sprint and flashlight.
- Stamina and flashlight battery drain.
- Monster pursuit using grid breadth-first search, routing around solid maze walls.
- Five collectible notes and a visible green extraction frame matching the win-condition location.
- Procedurally synthesized looping fluorescent hum and proximity heartbeat. No downloaded audio or network access is needed at runtime.

## Run in Godot
Open this folder in Godot 4.3 and run `main.tscn`. Desktop controls: WASD, mouse, Shift, F. On touch devices, drag on the left side to move relative to the initial touch point and drag on the right side to look; use the on-screen sprint and flashlight buttons.

## Android export
The export preset is named `Android`, targets `arm64-v8a`, and the project is configured for landscape orientation. Install the matching Godot Android export templates and configure Android SDK/JDK in Godot Editor Settings before exporting locally.

A GitHub Actions workflow is included at `.github/workflows/android.yml`. It uses the `barichello/godot-ci:4.3` container, imports and launches the project headlessly, exports a debug APK, verifies that the APK is non-empty, and uploads it as a workflow artifact. The workflow has not yet been executed from this environment.

## Known limitations / verification status

This is an early prototype, not a finished release. It has not been run in the Godot engine or on a physical Android device in this environment. The scene and scripts therefore still need engine-level validation. The monster uses grid BFS rather than full 3D navigation; touch layout, performance, collision edge cases and audio balance need device playtesting. Health, hiding places, save/settings menus, multiple endings and production-quality assets are not implemented. The Android workflow is prepared but its container/toolchain availability and actual export still need to be confirmed by a GitHub Actions run.
