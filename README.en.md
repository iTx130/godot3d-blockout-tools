# Godot 3D Blockout Tools

[简体中文](README.md) | English

A native Godot editor plugin for building 3D blockouts with 15 parametric shapes, editable viewport handles, collision and a procedural grid material.

![15-shape gallery](docs/gallery.png)

## Install

Copy `addons/blockout_tools` into your Godot project, then enable **Blockout Tools** under **Project Settings → Plugins**. Select a shape in the left dock and click **Add Blockout Shape**. Edit dimensions in the Inspector or drag the shape handles in the 3D viewport.

The development and acceptance target is **Godot 4.7.2**. Other versions have not been validated.

## Demo project

Open `project.godot` and press **F5** for the 15-shape gallery. Right mouse drag orbits, the wheel zooms, Tab / Shift+Tab selects a shape, and R returns to the overview. `demo/my_acceptance.tscn` provides the existing manual test scene.

## Shapes and editing

Box, Cone, Corner Curved, Corner Ramp, Cylinder, Doorway, Railing, Ramp, Skewbox, Sphere, Stairs Curved, Stairs Linear, Tube and Window. Stairs Linear Manual is temporarily hidden from creation and the Inspector shape selector; existing nodes remain compatible.

- Dimensions use metres and Godot local axes: X width, Y height, forward depth toward −Z.
- Rounded dimensions snap to 0.01 m; disabling Round Size permits finer input.
- Handles on all 15 shapes use the editor’s Use Snap toggle, with a default step matching the editor translation snap step. Change **Geometry → Grid Snap Ratio** (default 1.0) in the Inspector; each shape saves its own value. Ctrl temporarily toggles snapping and Shift further divides the current step by ten. The grid follows the edited scene root; a plain Node root uses world coordinates. Rotated handles snap to grid planes along their largest movement component. Exact alignment between centimetres preserves other visible dimensions before disabling Round Size; all parameter changes undo/redo together. Doorway and Window openings retain their wall-thickness and opening limits, which take priority when no grid plane fits inside the allowed range.
- Box keeps its X/Y/Z axis handles and adds an X/Z handle at the corner opposite the origin `(X, Y, -Z)`. Drag freely in the local XZ plane to edit width and depth together without locking their ratio or changing height or origin; grid snapping, centimetre rounding and one-step cancel/undo/redo are supported. Rotated corners align two independent scene-grid coordinates together, with height and minimum-size constraints taking priority.
- Railing defaults to a total length of 2 m with two one-metre spans and posts at 0, 1 and 2 m. It places its length handle at the far −Z end and its elevation handle on top of the interior post nearest the length midpoint; ties favor the start, and a single span uses the end post’s top. Length drags keep full one-metre spans and grow or remove only the final span: a 2.4 m railing has posts at 0, 1, 2 and 2.4 m. A Y-axis handle at the first post’s top edits Railing Height: the default one-metre height has two rails, with half-metre layer spacing and only the top layer moving through a partial interval. The minimum height is 0.5 m with one rail. Closed panels follow the post height; the elevation handle follows its post’s top and can snap back to level while still editing the whole railing’s slope. Elevation snapping aligns the far bottom edge, not the middle handle; a midpoint handle moves by half the end elevation, and other positions use their actual distance ratio. Editing Railing Sections or Railing Section Length restores uniform spacing; existing scenes keep their layout until dragged.
- Doorway adds handles at both inner edges and the opening top. They adjust the symmetric clear width and clear height without changing the outer frame. Window handles edit opening width, sill, lintel and opening elevation.
- Undo/redo, parameter-only scene saving, custom materials, collision layers/masks and material defaults are supported.
- Grid lines and checker shading are calculated in the shader. Grid Size sets the major-line spacing: the default 0.5 m coarse grid contains 0.1 m fine divisions. Grid Subdivisions (default 5) controls minor spacing, equal to Grid Size / Grid Subdivisions. No texture files are required. Local and world alignment are supported.

## Implementation

Meshes, normals, UVs and collision points are generated from parameters. The addon does not load a mesh library or external engine resources.

Tube is an annular wall with rectangular cross section. Its Sections parameter controls wall segmentation; a full ring uses at least four convex segments to preserve its opening. Quality 1–4 uses 8, 16, 24 and 32 radial segments for circular primitives.

## Repository layout

- `addons/blockout_tools/`: installable plugin.
- `demo/`: gallery, overview and manual acceptance scene.
- `docs/gameplay/`: archived Gameplay sources, scenes, tests and restoration notes.

Only `addons/blockout_tools/` is needed to install the plugin.

## Acknowledgements

The shape set and workflow are inspired by blockout tools for Unreal Engine 5. This is an independent, native Godot implementation. It contains no code or assets from those tools and is not affiliated with or endorsed by their authors.

## License

[MIT](LICENSE) © 2026 itx130
