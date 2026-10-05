# Archived Gameplay usage

## Player perspectives

Select **Player** under **Gameplay Nodes** in the dock and click **Add Gameplay Node** to instance the standalone `addons/blockout_tools/nodes/player.tscn` under the current scene root, with undo/redo support. Spawn Point is available; End Point remains a disabled placeholder.

The Player origin is at its feet, with a default camera height of 1.6 m. Adjust **Perspective** (initial first/third person) and **View Height** (camera pivot height above the feet, in metres) in the Player Inspector. Press **Tab** at runtime to switch perspectives without changing the viewing direction. Third person shows a capsule body and places the camera 3 m behind it, with a spring arm that retracts near walls.

Move the Player onto the floor in the editor, then press **F6** to run the current scene: W/S moves forward/backward, A/D strafes, Space jumps, and the mouse turns the view. Esc releases the mouse; left click captures it again. Losing window focus also releases the mouse. Physical keys are read directly, so no Input Map setup is required. Both the scene and controller ship with the addon.

BodyMesh is visible by default in the editor for placement; at runtime it is hidden in first person and shown in third person. With the mouse captured, press **Alt** to toggle noclip flight: W/S flies along the viewing direction, A/D strafes, Space ascends, and Ctrl descends. Flight ignores gravity, walls and floors in either perspective. Turning it off restores the original collision layers/masks, camera obstruction checks and gravity. Esc or loss of window focus pauses flight movement.

## Spawn Point

Select **Spawn Point** under **Gameplay Nodes**, then click **Add Gameplay Node**. Place its foot origin on the floor and rotate around Y. The capsule is 2 m tall with a 0.5 m radius, matching Player clearance; the horizontal arrow points forward (-Z). These green outlines are editor gizmos and do not render during gameplay. Turn off **Enabled** in the Inspector to ignore this point (the gizmo turns grey). Its Area3D collision never blocks the player.

Add a **Player** through Gameplay Nodes and run the scene (F6). At startup, Player uses the first enabled Spawn Point in scene-tree order, including nested scenes, with the correct world position and horizontal heading. Spawn pitch, roll and scale are not applied to Player. If no point is enabled, Player keeps its placed transform. Spawn Point relocates existing Gameplay Players; it does not create extra Players or respawn them when toggled during play.
