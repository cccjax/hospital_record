# 项目交接文档（HANDOFF）

最后更新：2026-04-09

## 1. 项目目标
- 项目：住院管理系统（离线优先）
- 当前阶段：在保留 Web 原型业务逻辑的前提下，持续完善 Flutter 版本（Android/iOS）
- 核心目标：业务逻辑准确、页面可用稳定、UI 持续贴近原型并提升质感

## 2. 当前状态（本轮完成）
- 首页
  - 修复概览区域布局约束异常（`BoxConstraints forces an infinite height`）
  - 统计卡视觉统一且可正常渲染
- 全局 UI
  - 统一按钮风格（`FilledButton` / `FilledButton.tonal` / `TextButton` / `OutlinedButton` / `IconButton`）
  - 统一按钮尺寸、圆角、字重和间距，减少页面风格割裂
- 数据迁移（“我的 > 数据迁移”）
  - 改为文件迁移：导出为 JSON 文件、从 JSON 文件导入
  - 导入新增“前置校验 + 最终确认”机制
    - 前置校验：UTF-8、JSON 合法性、顶层结构、关键字段类型、可解析性、空数据拦截
    - 最终确认：明确提示“覆盖当前本地数据”，并展示导入摘要（病人/入院/日常/模板/测评/影像数量）
- 字段展示
  - 多行文本字段（`FieldType.textarea`）无论内容长短，展示时均占据整行

## 3. 关键文件
- Flutter 入口：`flutter_app/lib/main.dart`
- 全局状态：`flutter_app/lib/src/state/hospital_app_state.dart`
- 首页：`flutter_app/lib/src/pages/home_tab_page.dart`
- 数据迁移页：`flutter_app/lib/src/pages/mine_migration_page.dart`
- 全局主题：`flutter_app/lib/src/theme/app_theme.dart`
- 字段网格：`flutter_app/lib/src/widgets/field_grid.dart`

## 4. 运行与验证
在 `flutter_app` 目录执行：

```bash
flutter pub get
flutter analyze
flutter test
flutter run -d emulator-5554
```

## 5. 已知注意点
- 当前仓库同时包含 Web 原型（`app.js` / `index.html` / `style.css`）与 Flutter 版本（`flutter_app/`），迭代以 Flutter 为主。
- 数据导入是“覆盖式”写入，已加双保险（校验 + 最终确认），但仍建议在大规模操作前先导出一份当前备份。

## 6. 建议下一步
1. 在真实业务样例下回归导入校验提示文案（让错误信息更用户友好）。
2. 增加“导入前自动快照备份”开关（可选）。
3. 继续做 UI 精修（间距、信息密度、文字层级）以进一步贴近原型。

## 7. Git 交接约定
- 离开前：更新本文件 + `SWITCH_CHECKLIST.md`，并推送远端。
- 接手后：优先阅读本文件，再执行回归检查。
