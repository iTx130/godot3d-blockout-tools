# Godot 3D Blockout Tools 测试

目标版本为 Godot 4.7.2。根据改动所属功能选择测试流程：只修改 Shape 就只运行 Shape 测试；只修改 Gameplay 就只运行 Gameplay 测试。跨两类功能、共享插件/Dock 基础设施、测试入口修改或明确要求完整验收时，运行完整测试。

## 测试入口

在仓库根目录运行：

```powershell
# Shape：形状、参数、网格、碰撞、材质、形状 Gizmo 和形状 Dock 控件
.\tests\run_shape_tests.ps1

# Gameplay：Player、Spawn Point、控制器、玩法 Gizmo 和 Gameplay Dock 控件
.\tests\run_gameplay_tests.ps1

# 完整测试：以上两类；原来的命令继续可用
.\tests\run_acceptance.ps1
```

三个入口均支持 `-Godot 'C:\path\to\Godot_console.exe'` 和 `-Render`。也可设置 `GODOT_BIN` 或把 godot / godot4 加入 PATH。

统一入口支持等价参数 `-Suite Shape`、`-Suite Gameplay`、`-Suite All`，默认 `All`。几何、Shader、Gizmo 或可见视角改动加 `-Render`，并检查生成截图。

## 覆盖范围

| 检查 | Shape | Gameplay | 完整 |
| --- | --- | --- | --- |
| Godot 导入、源码审计 | 是 | 是 | 一次 |
| 原生 Shape 几何与物理 | 是 | — | 是 |
| Functional 279、Window Gizmo 70、Axis Gizmo 1216 | 是 | — | 是 |
| Custom Material Inspector | 是 | — | 是 |
| Dock | Shape 控件 | Gameplay 控件 | 两类控件 |
| Gameplay 几何（出生点胶囊、箭头、朝向） | — | 是 | 是 |
| Player、Spawn Point 运行和编辑器 | — | 是 | 是 |
| 无导入缓存的冷安装 | 15 种 Shape、画廊 | Player、Spawn Point | 两类 |
| `-Render` | 形状画廊、网格 GPU 检查 | 出生点编辑器、Player 双视角 | 全部 |

导入和源码审计是两类测试各自需要的共享前置检查，会加载插件的共享资源。选择某类测试不会执行另一类功能断言或渲染检查。完整流程执行所有断言，共享步骤只执行一次。

Gameplay 运行测试需要真实窗口：无窗口显示驱动无法捕获鼠标，因此不能用 headless 替代 Player 输入测试。

## 报告

- Shape：`tests/evidence/shape-acceptance-run.json`
- Gameplay：`tests/evidence/gameplay-acceptance-run.json`
- 完整：`tests/evidence/acceptance-run.json`

总报告记录 `suite`、请求的渲染检查、各步骤结果和失败原因。单类入口的 Godot 日志和冷安装报告带 `shape-` / `gameplay-` 前缀，完整测试保留原文件名。任何非零退出码、脚本/Shader 错误或未完成步骤都会使流程失败。

`tests/evidence/`、`.godot/` 和临时冷安装项目不进入 Git。当前仓库还将测试脚本、`AGENTS.md`、本文件作为本地开发资料忽略。

## 手动检查

### Shape

F5 打开 15 种形状画廊：右键旋转、滚轮缩放、Tab / Shift+Tab 切换、R 回到总览。检查形状、碰撞和材质。

在 Node3D 场景中通过 Dock 添加 Box，将尺寸改为 (2, 3, 4)，检查 X 宽 2 m、Y 高 3 m、沿 -Z 深 4 m。拖拽尺寸和 Window 开口手柄，检查撤销/重做、保存重开、参数恢复及无重复生成节点。检查 Tube 中心可穿过、环壁阻挡，以及楼梯与栏杆碰撞。

检查局部/世界网格、Grid Size 1 / 0.5 / 2 m、粗细线比例、颜色和 Custom Material；材质更新应避免重建几何。

### Gameplay

通过 Gameplay Nodes 添加 Player 和 Spawn Point，确认外部场景引用、owner、选中、唯一命名、撤销/重做和保存重开。End Point 保持禁用占位。

F6 检查 WASD、斜向速度、Space 跳跃、重力与墙体碰撞、鼠标视角、Esc/点击捕获及失焦处理。Tab 切换第一/第三人称，确认身体显隐、弹簧臂避墙、Perspective / View Height 保存。Alt 切换飞行，检查穿墙、Space/Ctrl 升降、暂停和恢复碰撞。

出生点胶囊高 2 m、半径 0.5 m、原点在脚底，箭头指向 -Z。检查 Enabled、场景树顺序、嵌套变换及无启用出生点时保留放置位置；标记仅在编辑器显示且不会阻挡 Player。人工确认运动手感和视角舒适度。