# Changelog

按 tag 从新到旧维护中英文摘要。每次提交或合并时，先将本次改动摘要补充到 `Unreleased`；重复内容合并，测试结果仅记录实际执行过的检查。

发布时，将 `Unreleased` 改为对应的 `vX.Y.Z` 并填写发布日期，在顶部新增空的 `Unreleased`。GitHub Release 使用对应 tag 下的中英文摘要。

## [Unreleased]

### English

- Maintain bilingual release summaries in this changelog, grouped by tag, and update Unreleased with each commit or merge.
- Publish release notes from the matching changelog section; stop publishing if the summary is missing or the plugin version does not match the tag.
- Verified summary extraction and the workflow notes step with 20/20 local checks, including version boundaries, bilingual output and invalid-input rejection.

### 中文

- 按 tag 维护中英文变更摘要，每次提交或合并时更新 Unreleased。
- Release 使用 changelog 中对应版本的摘要；摘要缺失或插件版本与 tag 不一致时停止发布。
- 摘要提取和工作流说明步骤已通过 20/20 项本地检查，覆盖版本边界、中英文输出和无效输入拒绝。

## [v1.0.5] - 2026-10-01

### English

- Added a standalone Gameplay Player with WASD/Space controls, configurable view height, first/third-person switching, camera obstruction handling and Alt noclip flight.
- Added enabled Spawn Points with capsule/heading editor gizmos. Existing Players start at the first enabled point, including points in nested scenes; disabled points are ignored.
- Box size handles follow editor snapping with a per-Box Grid Snap Ratio (default 0.1), Ctrl toggle and Shift fine step. Snapping follows the edited scene root, handles rotated/scaled Boxes and preserves undo/redo, including Round Size changes for exact alignment.
- Clarified Refresh Selected and simplified the dock while retaining project-wide Default Box Size controls.
- Added tag-triggered addon ZIP packaging and automatic bilingual GitHub Releases.
- Passed Godot 4.7.2 full acceptance with rendering: 18/18 steps, native geometry 1540/1540, functional 279/279, Window Gizmo 70/70, axis Gizmo 1292/1292, Gameplay geometry 17/17, Player runtime 63/63 and editor 22/22, Spawn runtime 25/25 and editor 19/19, cold install 54/54, and GPU grid 138/138. Gallery, Spawn Point and both Player-view screenshots were inspected.

**Install:** extract `blockout_tools-v1.0.5.zip` into the project root, then enable Blockout Tools in Project Settings > Plugins.

### 中文

- 新增独立 Gameplay Player，支持 WASD/空格控制、可配置视点高度、第一/第三人称切换、镜头避墙和 Alt 无碰撞飞行。
- 新增可启用/禁用的 Spawn Point，编辑器显示胶囊和朝向箭头。已有 Player 从场景树中第一个启用的出生点开始，支持嵌套场景，忽略禁用点。
- Box 尺寸手柄沿用编辑器吸附，每个 Box 可保存 Grid Snap Ratio（默认 0.1），支持 Ctrl 切换和 Shift 精细步长。以编辑场景根节点为网格基准，支持旋转/缩放，并可撤销和重做精确对齐引起的尺寸及 Round Size 修改。
- 明确 Refresh Selected 的行为并精简面板，保留项目级 Default Box Size 控件。
- 新增 tag 触发的插件 ZIP 打包和自动中英文 GitHub Release。
- 已通过 Godot 4.7.2 完整渲染验收：18/18 步骤，原生几何 1540/1540、功能 279/279、Window Gizmo 70/70、轴手柄 1292/1292、Gameplay 几何 17/17、Player 运行时 63/63 和编辑器 22/22、Spawn 运行时 25/25 和编辑器 19/19、冷安装 54/54、GPU 网格 138/138。已检查形状展览、出生点和两种 Player 视角截图。

**安装：** 将 `blockout_tools-v1.0.5.zip` 解压到项目根目录，再在“项目设置 > 插件”中启用 Blockout Tools。

## [v1.0.4] - 2026-09-29

### English

- Added project-wide Default Box Size controls to the dock. New Boxes use the saved X/Y/Z dimensions; existing scene instances keep their sizes.
- Added compact, color-coded XYZ inputs that follow Godot editor font scaling, including 4K displays.
- Passed Godot 4.7.2 acceptance: native geometry 1369/1369, functional 279/279, Window Gizmo 70/70, axis Gizmo 1216/1216, cold install 47/47, and GPU grid 138/138.

**Install:** extract `blockout_tools-v1.0.4.zip` into the project root, then enable Blockout Tools in Project Settings > Plugins.

### 中文

- 新增项目级 Default Box Size 控件。新建 Box 使用保存的 X/Y/Z 尺寸，已有场景实例保持原尺寸。
- 新增紧凑的彩色 XYZ 输入框，跟随 Godot 编辑器字体缩放，适配 4K 屏幕。
- 已通过 Godot 4.7.2 验收：原生几何 1369/1369、功能 279/279、Window Gizmo 70/70、轴手柄 1216/1216、冷安装 47/47、GPU 网格 138/138。

**安装：** 将 `blockout_tools-v1.0.4.zip` 解压到项目根目录，再在“项目设置 > 插件”中启用 Blockout Tools。

## [v1.0.1] - 2026-09-29

### English

- Switched addon preloads to relative paths so the addon loads from other locations, such as `res://assets/addons/`.
- Fixed parsing in projects that treat Variant type-inference warnings as errors.

### 中文

- 插件预加载改用相对路径，支持放在 `res://assets/addons/` 等其他目录。
- 修复将 Variant 类型推断警告视为错误的项目中的解析问题。

## [v1.0.0] - 2026-09-27

### English

- First public release: 15 parametric blockout shapes with draggable viewport handles.
- Added automatic convex collision with configurable layers/masks and a procedural grid material with local/world alignment, without texture files.
- Included undo/redo, metre units and optional 0.01 m dimension rounding. Tested on Godot 4.7.2; MIT licensed.

### 中文

- 首个公开版本：15 种参数化白模形状，支持视口拖拽手柄编辑。
- 提供可配置碰撞层/掩码的自动凸碰撞，以及无需贴图的程序化网格材质，支持本地/世界对齐。
- 支持撤销/重做、米制单位和可选的 0.01 m 尺寸取整。已在 Godot 4.7.2 测试，采用 MIT 许可证。
