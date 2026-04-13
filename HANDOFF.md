# 项目交接文档（HANDOFF）

最后更新：2026-04-14

## 1. 项目目标
- 项目：住院管理系统（App 名：住院通）
- 当前阶段：Flutter 主线持续迭代（Android 优先）
- 核心目标：离线稳定、录入高效、模板逻辑清晰、UI 风格统一

## 2. 当前状态（本轮完成）
- 首页病人卡片布局升级
  - 列表从固定比例网格改为“按可视字段动态估算宽度 + 自适应列数”的卡片流式布局
  - 卡片高度改为由内容自然撑开，显著减少底部空白
  - 右箭头保持竖向居中，字段区可用宽度进一步提升
- 首页密度一键切换（新增）
  - 新增 `标准 / 紧凑` 两档密度切换（位于搜索框下方）
  - `标准`：更疏朗、卡片更瘦高（默认）
  - `紧凑`：更紧凑、卡片更密集
  - 密度切换会联动：卡片宽度策略、卡片上下内边距、字段行距、行高、标签与姓名区尺寸
- 首页信息排版优化
  - 字段行距按密度分档，默认标准模式下可读性更高
  - 姓名行与护理等级标签比例统一优化
- 既有重要能力保持
  - 病人 `admissionNo` 可在字段配置中控制可见
  - 新增病人时 `admissionNo` 可编辑，编辑病人时保持主键锁定
  - 病人姓名 `name` 作为系统字段不可删除

## 3. 关键文件
- 首页主页面：`flutter_app/lib/src/pages/home_tab_page.dart`
- 状态与数据：`flutter_app/lib/src/state/hospital_app_state.dart`
- 字段配置：`flutter_app/lib/src/pages/field_config_page.dart`
- 动态表单：`flutter_app/lib/src/widgets/dynamic_form_dialog.dart`
- 我的页面：`flutter_app/lib/src/pages/mine_tab_page.dart`
- 主题与组件：`flutter_app/lib/src/theme/app_theme.dart`、`flutter_app/lib/src/widgets/section_card.dart`

## 4. 验证结果（本轮）
在 `flutter_app` 目录执行：

```bash
flutter analyze --no-pub lib/src/pages/home_tab_page.dart
flutter analyze --no-pub
```

当前结论：
- 两条 `analyze` 均通过，无错误
- 本轮未额外执行 `flutter test`（后续接手建议补跑）

## 5. 已知注意点
- 命令执行目录必须在 `flutter_app`，否则可能出现分析或构建路径异常。
- 当前仓库仍有历史遗留的多文件改动（并非全部来自本轮），提交前需确认范围。
- Android 构建若卡在 `assembleDebug`，优先检查代理、JDK、Android cmdline-tools、Gradle 网络访问。

## 6. 建议下一步
1. 对首页卡片在手机/平板横竖屏分别做一次视觉回归，确认两档密度都满足可读性与信息密度预期。
2. 将“密度模式”做持久化（例如保存到本地设置），避免重启后恢复默认。
3. 补充首页卡片布局的 widget 测试（字段数变化、密度切换、窄屏/宽屏断点）。
4. 补跑 `flutter test` 与关键流程手测（首页->病人明细->入院详情->日常/测评/影像）。

## 7. Git 交接约定
- 离开前：更新本文件 + `SWITCH_CHECKLIST.md`，并推送远端。
- 接手后：先阅读本文件，再执行回归清单。
