# Godot 3D Blockout Tools

简体中文 | [English](README.en.md)

原生 Godot 编辑器插件，用于快速搭建 3D 白模（blockout）。提供 15 种参数化形状、视口内可拖拽编辑的控制柄、碰撞体以及程序化网格材质。

![15 种形状展示](docs/gallery.png)

## 安装

将 `addons/blockout_tools` 复制到你的 Godot 项目中，然后在 **项目设置 → 插件** 中启用 **Blockout Tools**。在左侧停靠面板中选择形状并点击 **Add Blockout Shape**。可以在检查器中修改尺寸，也可以直接在 3D 视口中拖拽形状控制柄。

开发和验收目标版本为 **Godot 4.7.2**，其他版本尚未验证。

## 演示项目

打开 `project.godot` 并按 **F5** 运行 15 种形状展示场景。鼠标右键拖拽旋转视角，滚轮缩放，Tab / Shift+Tab 切换选中形状，R 返回总览。`demo/my_acceptance.tscn` 为手动测试场景。

## 形状与编辑

Box、Cone、Corner Curved、Corner Ramp、Cylinder、Doorway、Railing、Ramp、Skewbox、Sphere、Stairs Curved、Stairs Linear、Tube 和 Window。Stairs Linear Manual 暂时从创建列表和检查器形状选项中隐藏，已有节点保持兼容。

- 尺寸单位为米，使用 Godot 本地坐标轴：X 为宽度，Y 为高度，深度朝向 −Z。
- 启用 Round Size 时尺寸吸附到 0.01 m；关闭后可输入更精细的数值。
- 全部 15 种形状的手柄沿用编辑器的“使用吸附”开关，默认步长为编辑器位移吸附步长的十分之一。在检查器 **Geometry → Grid Snap Ratio**（默认 0.1）中调整比例，每个形状分别保存。Ctrl 临时切换吸附，Shift 将当前步长再缩小十倍。网格以当前编辑场景的根节点为基准，普通 Node 根节点使用世界坐标。旋转后的手柄沿移动分量最大的坐标轴对齐网格平面。精确对齐需要非整厘米尺寸时，会保留其他部分的可见尺寸并关闭 Round Size，所有参数变化可一起撤销／重做。Doorway 和 Window 开口保留墙厚和开口范围，范围内没有网格点时优先满足这些约束。
- Doorway 在门洞左右内侧和顶部增加手柄，可对称调整门洞净宽和净高，保持外框尺寸不变。Window 的控制柄可编辑开口宽度、窗台、过梁和开口高度。
- 支持撤销/重做、仅保存参数的场景存储、自定义材质、碰撞层/掩码以及材质默认值。
- 网格线和棋盘格明暗均在着色器中计算。Grid Size 设置主网格线间距：默认 1 m 主网格内含 0.1 m 细分网格，细分间距始终为 Grid Size 的十分之一。无需任何贴图文件，支持本地和世界坐标对齐。

## 实现

网格、法线、UV 和碰撞点均由参数实时生成，插件不加载任何网格库或外部引擎资源。

Tube 是矩形截面的环形墙体。Sections 参数控制墙体分段数；完整圆环至少使用四个凸分段以保留中间开口。圆形基础体的 Quality 1–4 分别对应 8、16、24、32 个径向分段。

## 仓库结构

- `addons/blockout_tools/`：可安装的插件本体。
- `demo/`：展示场景、总览场景和手动验收场景。
- `docs/gameplay/`：已移出的 Gameplay 源码、场景、测试及恢复说明，仅供归档。

安装插件只需要 `addons/blockout_tools/` 目录。

## 致谢

形状集合和工作流程参考了 Unreal Engine 5 的 blockout tools。本项目是独立的 Godot 原生实现，不包含其任何代码或资源，与其作者无关联，也未获得其背书。

## 许可证

[MIT](LICENSE) © 2026 itx130
