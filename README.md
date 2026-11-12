# BACKROOMS: LEVEL 0

A first-person 3D horror prototype built with Godot 4.3 for Android (arm64, landscape) and desktop testing.

## Gameplay in this project

- Procedurally generated yellow Backrooms-style maze with collision, ceiling and fluorescent fixtures.
- First-person movement, mouse look, mobile multitouch movement/look, sprint and flashlight.
- Stamina and flashlight battery management.
- A pursuing creature with grid-based breadth-first-search pathfinding around maze walls.
- Five collectible notes and a marked extraction point.
- Procedurally synthesized fluorescent hum and proximity heartbeat; no external audio downloads are needed.

## Run locally

1. Install Godot 4.3.
2. Open this repository folder in Godot.
3. Run `main.tscn`.

Desktop controls: WASD, mouse, Shift to sprint, F to toggle flashlight. On touch devices, drag the left portion of the screen to move and the right portion to look; use the on-screen sprint and flashlight controls.

## Android APK

The export preset is named `Android`, targets `arm64-v8a`, and writes `build/BACKROOMS.apk`. The GitHub Actions workflow installs Godot 4.3 export templates, configures the Android SDK/JDK and a temporary debug signing key, validates the project, exports the debug APK and uploads it as a workflow artifact.

Open the **Actions** tab and select the latest **Build BACKROOMS Android APK** run. The APK appears under Artifacts only after every export step succeeds. This is a debug APK for testing, not a Play Store release.

## Current status and limitations

This is an early playable prototype, not a finished commercial game. Godot headless import and scene startup are checked by CI; Android export and real-device playtesting must still pass before calling the APK verified. Procedural visuals/audio are placeholders, and touch layout, performance, collisions, monster behavior and balance need testing on physical Android devices. Menus, saves, multiple levels and endings are not implemented.
