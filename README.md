# Godot 3D Blockout Tools

简体中文 | [English](README.en.md)

原生 Godot 编辑器插件，用于快速搭建 3D 白模（blockout）。提供 15 种参数化形状、视口内可拖拽编辑的控制柄、碰撞体以及程序化网格材质。

![15 种形状展示](docs/gallery.png)

## 安装

将 `addons/blockout_tools` 复制到你的 Godot 项目中，然后在 **项目设置 → 插件** 中启用 **Blockout Tools**。在左侧停靠面板中选择形状并点击 **Add Blockout Shape**。可以在检查器中修改尺寸，也可以直接在 3D 视口中拖拽形状控制柄。

开发和验收目标版本为 **Godot 4.7.2**，其他版本尚未验证。

## 演示项目

打开 `project.godot` 并按 **F5** 运行 15 种形状展示场景。鼠标右键拖拽旋转视角，滚轮缩放，Tab / Shift+Tab 切换选中形状，R 返回总览。`demo/my_acceptance.tscn` 为手动测试场景。

## Player 视角

停靠面板的 **Gameplay Nodes** 下拉框中选择 **Player**，点击 **Add Gameplay Node**，即可将独立的 `addons/blockout_tools/nodes/player.tscn` 场景实例添加到当前场景根节点，支持撤销/重做。Spawn Point 已可用，End Point 仍为禁用的占位选项。

Player 原点位于脚底，相机高度默认为 1.6 m。在 Player 检查器中可调整 **Perspective**（初始第一/第三人称）和 **View Height**（相机支点距脚底的高度，单位米）。运行时按 **Tab** 切换人称，保持当前朝向；第三人称显示胶囊角色，镜头位于身后 3 m，并通过弹簧臂避开墙体。

添加后在编辑器中将 Player 移到地面上，再按 **F6** 运行当前场景：W/S 前进后退，A/D 左右平移，空格跳跃，鼠标控制视角。Esc 释放鼠标，鼠标左键重新捕获；窗口失去焦点时也会释放鼠标。按键直接读取物理键位，不需要配置 Input Map。场景和控制脚本都随插件安装。

BodyMesh 在编辑器中默认可见，便于摆放；运行时第一人称隐藏它，第三人称显示。鼠标已捕获时按 **Alt** 开启/关闭无碰撞飞行：W/S 沿视角方向飞行，A/D 横移，空格上升，Ctrl 下降。飞行时无重力，可以穿过墙体和地面，两种人称均可使用；退出后恢复原有碰撞层/掩码、镜头避墙和重力。Esc 或窗口失去焦点会暂停飞行移动。

## 出生点

在 **Gameplay Nodes** 中选择 **Spawn Point**，点击 **Add Gameplay Node** 添加出生点。将原点（脚底）放在地面上，绕 Y 轴旋转设置出生朝向。胶囊高 2 m、半径 0.5 m，与 Player 的碰撞尺寸一致；水平箭头指向前方（-Z）。绿色胶囊轮廓和箭头只在编辑器显示，运行时不渲染。检视器中的 **Enabled** 开关决定是否使用该点，关闭后标记变灰。出生点的 Area3D 胶囊不会阻挡玩家。

通过 Gameplay Nodes 添加 **Player**，按 **F6** 运行当前场景。Player 启动时使用场景树中第一个启用的出生点（包括嵌套场景），脚底位置和水平朝向与标记一致；出生点的俯仰、侧倾和缩放不会传给 Player。没有启用的出生点时，Player 保留编辑器中的位置和朝向。出生点定位已有的 Gameplay Player，不会额外创建 Player，也不会在运行中切换开关时触发重生。

## 形状与编辑

Box、Cone、Corner Curved、Corner Ramp、Cylinder、Doorway、Railing、Ramp、Skewbox、Sphere、Stairs Curved、Stairs Linear、Stairs Linear Manual、Tube 和 Window。

- 尺寸单位为米，使用 Godot 本地坐标轴：X 为宽度，Y 为高度，深度朝向 −Z。
- 启用 Round Size 时尺寸吸附到 0.01 m；关闭后可输入更精细的数值。
- Window 的控制柄可编辑开口宽度、窗台、过梁和开口高度。
- 支持撤销/重做、仅保存参数的场景存储、自定义材质、碰撞层/掩码以及材质默认值。
- 网格线和棋盘格明暗均在着色器中计算。Grid Size 设置主网格线间距：默认 1 m 主网格内含 0.1 m 细分网格，细分间距始终为 Grid Size 的十分之一。无需任何贴图文件，支持本地和世界坐标对齐。

## 实现

网格、法线、UV 和碰撞点均由参数实时生成，插件不加载任何网格库或外部引擎资源。

Tube 是矩形截面的环形墙体。Sections 参数控制墙体分段数；完整圆环至少使用四个凸分段以保留中间开口。圆形基础体的 Quality 1–4 分别对应 8、16、24、32 个径向分段。

## 仓库结构

- `addons/blockout_tools/`：可安装的插件本体。
- `demo/`：展示场景、总览场景和手动验收场景。

安装插件只需要 `addons/blockout_tools/` 目录。

## 致谢

形状集合和工作流程参考了 Unreal Engine 5 的 blockout tools。本项目是独立的 Godot 原生实现，不包含其任何代码或资源，与其作者无关联，也未获得其背书。

## 许可证

[MIT](LICENSE) © 2026 itx130
