# Gameplay 归档

2026-10-05 从插件移出。这里保存此前的 Player、Spawn Point 和 Gameplay 面板相关实现，供查阅或以后迁移到独立项目。当前 Blockout Tools 只提供 Shape 功能。

## 内容

- `addons/blockout_tools/`：原 Player / Spawn Point 脚本、场景、UID 和出生点 Gizmo，按原仓库路径保存。
- `tests/`：原 Gameplay 几何、Player 运行/编辑器/视角、Spawn Point 运行/编辑器测试及 Gameplay 测试入口。
- `integration/`：修改前的插件、Dock、共用验收脚本和测试说明快照。这些文件同时含有 Shape 代码，作为接入参考保留。
- [原中文使用说明](usage.zh.md) / [Original English usage](usage.en.md)：来自移出前的双语 README；描述的是历史功能。
- `manifest.json`：每份原文件的原路径、归档路径、SHA-256 及移动/快照类型。

归档文件保持原始内容和 UID；`res://addons/blockout_tools/...`、`res://tests/...` 引用也保持原路径。文件不会直接从此目录运行。此目录及上级 `docs/` 的 `.gdignore` 阻止 Godot 导入归档脚本，避免全局类与 UID 冲突。发布工作流仅打包正式 `addons/blockout_tools/`，不包含此归档。

## 恢复或迁移

1. 先在独立分支或项目中操作。把 `addons/blockout_tools/` 和 `tests/` 下需要的文件按 `manifest.json` 的 `original_path` 放回项目；保留对应 `.uid` 文件。迁移到其他路径时，更新场景和脚本中的资源引用。
2. 对照 `integration/addons/blockout_tools/plugin.gd` 与 `blockout_dock.gd` 恢复所需 preload、出生点 Gizmo 注册/卸载、节点创建方法和面板连接。快照同时包含旧 Shape 实现，应比较后合入 Gameplay 部分，避免覆盖之后的 Shape 改动。
3. 如果恢复原验收流程，对照 `integration/tests/` 中的 runner、Dock 和冷安装快照重新接入测试；原 Shape 测试仍位于项目 `tests/`。运行 `tests/run_gameplay_tests.ps1 -Render` 前需恢复该流程。当前 source audit 禁止正式 addon 出现玩法文件，恢复功能时也要更新这项边界检查。
4. 原 Gameplay 测试的鼠标捕获检查需要真实 Godot 窗口。重新导入并验证后再使用；归档不代表对迁移后的代码完成验证。

已有外部项目若仍引用原 Player 或 Spawn Point 场景，需要自行保留这些资源或按上述路径恢复，才能继续加载。End Point 原来只有禁用的面板占位项，没有独立场景。
