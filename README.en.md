<div align="center">

# Godot 3D Blockout Tools

**Build 3D blockouts quickly inside the Godot editor**

15 parametric shapes · Viewport handles · Grid snapping · Automatic collision · Procedural grid material

[![Godot 4.7.2](https://img.shields.io/badge/Godot-4.7.2-478cbf?logo=godotengine&logoColor=white)](https://godotengine.org/)
[![Release](https://img.shields.io/github/v/release/iTx130/godot3d-blockout-tools?color=ff8c1a)](https://github.com/iTx130/godot3d-blockout-tools/releases)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

[简体中文](README.md) | English

![A level blockout built with Blockout Tools](docs/images/hero.png)

</div>

## ✨ Features

- 🧱 **15 parametric shapes**: primitives, ramps, stairs, doorways, windows and railings for common level blockouts.
- 🖱️ **Edit in the viewport**: drag handles to resize shapes, or enter exact values in the Inspector.
- 📐 **Grid snapping**: every shape handle follows the editor's snap settings, with a Ctrl toggle and Shift fine step.
- 🎨 **Procedural grid material**: grid lines and checker shading are computed in the shader. No textures; local and world alignment.
- 🧩 **Automatic collision**: convex collision generated from parameters, with configurable layers and masks.
- ↩️ **Full undo/redo**: scenes store only parameters; meshes, normals, UVs and collision points are generated on the fly.

## 🚀 Quick start

1. Download `blockout_tools-vX.Y.Z.zip` from [Releases](https://github.com/iTx130/godot3d-blockout-tools/releases) and extract it into your project root, or copy `addons/blockout_tools` from this repository into your project.
2. Enable **Blockout Tools** under **Project Settings → Plugins**.
3. Select a shape in the left dock and click **Add Blockout Shape**.
4. Drag the handles in the 3D viewport or edit parameters in the Inspector.

<p align="center"><img src="docs/images/dock.png" alt="Blockout Tools dock" width="380"></p>

> [!NOTE]
> The development and acceptance target is **Godot 4.7.2**. Other versions have not been validated.

## 🧱 Shapes

![Every shape available for creation](docs/images/shapes.png)

| Category | Shapes |
|---|---|
| Primitives | Box · Skewbox · Cylinder · Cone · Sphere · Tube |
| Ramps and stairs | Ramp · Corner Ramp · Corner Curved · Stairs Linear · Stairs Curved |
| Architecture | Doorway · Window · Railing |

Stairs Linear Manual is temporarily hidden from creation and the Inspector shape selector; existing nodes remain compatible.

Most shapes also have styles and toggles, such as outer or inner Corner Curved, Box, Sloped or Closed stairs, Open or Closed railings with slope, hemispheres, and partial-angle Tubes and curved stairs:

![Shape options](docs/images/variants.png)

## 🖱️ Editing and snapping

![Viewport handle positions: red X, green Y, blue Z, orange Box X/Z corner](docs/images/handles.png)

<p align="center"><sub>Handle positions in the editor: red edits X, green edits Y, blue edits Z, and orange is the Box X/Z corner handle.</sub></p>

- Dimensions use metres and Godot local axes: **X width, Y height, forward depth toward −Z**.
- Rounded dimensions snap to 0.01 m; disabling **Round Size** permits finer input.

| Control | Effect |
|---|---|
| Editor Use Snap toggle | Enables handle snapping; the default step matches the editor translation snap step |
| **Geometry → Grid Snap Ratio** | Scales the snap step (default 1.0); each shape saves its own value |
| Hold <kbd>Ctrl</kbd> | Temporarily toggles snapping |
| Hold <kbd>Shift</kbd> | Divides the current step by ten |

<details>
<summary><b>Snapping details</b></summary>

The grid follows the edited scene root; a plain Node root uses world coordinates. Rotated handles snap to grid planes along their largest movement component. Exact alignment between centimetres preserves other visible dimensions before disabling Round Size; all parameter changes undo/redo together. Doorway and Window openings retain their wall-thickness and opening limits, which take priority when no grid plane fits inside the allowed range.

</details>

<details>
<summary><b>Box: corner handle</b></summary>

Box keeps its X/Y/Z axis handles and adds an X/Z handle at the corner opposite the origin `(X, Y, -Z)`. Drag freely in the local XZ plane to edit width and depth together without locking their ratio or changing height or origin; grid snapping, centimetre rounding and one-step cancel/undo/redo are supported. Rotated corners align two independent scene-grid coordinates together, with height and minimum-size constraints taking priority.

</details>

<details>
<summary><b>Railing: length, height and elevation</b></summary>

- **Default layout**: a total length of 2 m with two one-metre spans and posts at 0, 1 and 2 m.
- **Length handle**: at the far −Z end. Drags keep full one-metre spans and grow or remove only the final span: a 2.4 m railing has posts at 0, 1, 2 and 2.4 m.
- **Height handle**: at the first post's top, editing Railing Height. The default one-metre height has two rails, with half-metre layer spacing and only the top layer moving through a partial interval. The minimum height is 0.5 m with one rail. Closed panels follow the post height.
- **Elevation handle**: on top of the interior post nearest the length midpoint; ties favor the start, and a single span uses the end post's top. The handle follows its post's top and can snap back to level while still editing the whole railing's slope. Elevation snapping aligns the far bottom edge, not the middle handle; a midpoint handle moves by half the end elevation, and other positions use their actual distance ratio.
- Editing Railing Sections or Railing Section Length restores uniform spacing; existing scenes keep their layout until dragged.

</details>

<details>
<summary><b>Doorway and Window: opening handles</b></summary>

Doorway adds handles at both inner edges and the opening top. They adjust the symmetric clear width and clear height without changing the outer frame. Window handles edit opening width, sill, lintel and opening elevation.

</details>

## 🎨 Material and collision

![Material options](docs/images/materials.png)

- **Grid Size** sets the major-line spacing: the default 0.5 m coarse grid contains 0.1 m fine divisions.
- **Grid Subdivisions** (default 5) controls minor spacing, equal to Grid Size / Grid Subdivisions.
- Custom materials, material defaults, collision layers/masks, and local or world alignment are supported.

## 🎮 Demo project

Open `project.godot` and press <kbd>F5</kbd> for the 15-shape gallery. `demo/my_acceptance.tscn` provides the manual test scene.

| Input | Action |
|---|---|
| Right mouse drag | Orbit |
| Mouse wheel | Zoom |
| <kbd>Tab</kbd> / <kbd>Shift</kbd>+<kbd>Tab</kbd> | Select shape |
| <kbd>R</kbd> | Return to overview |

## ⚙️ Implementation

Meshes, normals, UVs and collision points are generated from parameters. The addon does not load a mesh library or external engine resources.

- **Tube** is an annular wall with rectangular cross section. Its Sections parameter controls wall segmentation; a full ring uses at least four convex segments to preserve its opening.
- **Quality 1–4** uses 8, 16, 24 and 32 radial segments for circular primitives.

## 📁 Repository layout

| Path | Contents |
|---|---|
| `addons/blockout_tools/` | Installable plugin (the only directory needed to install) |
| `demo/` | Gallery, overview and manual acceptance scenes |

## 📄 License

[MIT](LICENSE) © 2026 itx130
