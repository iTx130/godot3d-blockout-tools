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

Box, Cone, Corner Curved, Corner Ramp, Cylinder, Doorway, Railing, Ramp, Skewbox, Sphere, Stairs Curved, Stairs Linear, Stairs Linear Manual, Tube and Window.

- Dimensions use metres and Godot local axes: X width, Y height, forward depth toward −Z.
- Rounded dimensions snap to 0.01 m; disabling Round Size permits finer input.
- Window handles edit opening width, sill, lintel and opening elevation.
- Undo/redo, parameter-only scene saving, custom materials, collision layers/masks and material defaults are supported.
- Grid lines and checker shading are calculated in the shader. Grid Size sets the major-line spacing: the default 1 m coarse grid contains 0.1 m fine divisions. Minor spacing is always one tenth of Grid Size. No texture files are required. Local and world alignment are supported.

## Implementation

Meshes, normals, UVs and collision points are generated from parameters. The addon does not load a mesh library or external engine resources.

Tube is an annular wall with rectangular cross section. Its Sections parameter controls wall segmentation; a full ring uses at least four convex segments to preserve its opening. Quality 1–4 uses 8, 16, 24 and 32 radial segments for circular primitives.

## Repository layout

- `addons/blockout_tools/`: installable plugin.
- `demo/`: gallery, overview and manual acceptance scene.

Only `addons/blockout_tools/` is needed to install the plugin.

## Acknowledgements

The shape set and workflow are inspired by blockout tools for Unreal Engine 5. This is an independent, native Godot implementation. It contains no code or assets from those tools and is not affiliated with or endorsed by their authors.

## License

[MIT](LICENSE) © 2026 itx130
