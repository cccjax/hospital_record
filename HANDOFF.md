# 项目交接文档（HANDOFF）

最后更新：2026-04-09

## 1. 项目目标
- 项目：住院管理系统（离线优先）
- 当前阶段：在保留 Web 原型业务逻辑的前提下，持续完善 Flutter 版本（Android/iOS）
- 核心目标：业务逻辑准确、页面可用稳定、UI 持续贴近原型并提升质感

## 2. 当前状态（本轮完成）
- 新增/编辑 UI（重点）
  - 新增统一编辑弹层组件（统一头部、分组面板、操作区、错误提示）
  - 动态表单弹窗、字段配置弹窗、测评项/区间弹窗全部切换为统一风格
  - 住院测评编辑页重做：信息层级更清晰、选项密度更合理
- 住院测评体验优化
  - 评分选项改为“每个选项独占一整行”，长度统一、点击区更稳定
  - 评分条重做：区间分色更明显，显示区间边界分隔线，标记点颜色随区间变化
  - 入院详情页的“住院测评记录行”新增紧凑评分条，便于快速查看结果
- 规则校验增强
  - “患病等级区间”新增“不可重叠”校验
  - 页面层即时提示 + 状态层兜底校验（双保险）
- 字段配置页
  - 修复“调整顺序”中下箭头无效问题（上/下都可正常移动）
- 全局细节
  - 返回按钮重做为简洁左箭头（去外轮廓），与页面风格统一
  - 保留此前完成项：数据迁移文件化、导入前置校验+最终确认、多行文本整行展示等

## 3. 关键文件
- Flutter 入口：`flutter_app/lib/main.dart`
- 全局状态：`flutter_app/lib/src/state/hospital_app_state.dart`
- 编辑弹层组件：`flutter_app/lib/src/widgets/editor_dialog.dart`
- 通用动态表单：`flutter_app/lib/src/widgets/dynamic_form_dialog.dart`
- 评分条组件：`flutter_app/lib/src/widgets/assessment_score_bar.dart`
- 字段配置页：`flutter_app/lib/src/pages/field_config_page.dart`
- 模板版本页：`flutter_app/lib/src/pages/template_version_page.dart`
- 入院详情页：`flutter_app/lib/src/pages/admission_detail_page.dart`
- 住院测评编辑页：`flutter_app/lib/src/pages/assessment_edit_page.dart`
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
- 评分条颜色是按区间顺序映射调色板；如后续有明确风险等级语义（低/中/高），建议固定色义映射策略。

## 6. 建议下一步
1. 基于真实病种模板验证“区间不重叠”规则边界（闭区间/开区间业务定义）是否与业务一致。
2. 继续统一剩余页面的小组件细节（页头按钮/信息标签/提示文案）以进一步贴近原型。
3. 补一组面向核心流程的 widget/integration 测试（字段配置排序、测评录入、区间校验）。

## 7. Git 交接约定
- 离开前：更新本文件 + `SWITCH_CHECKLIST.md`，并推送远端。
- 接手后：优先阅读本文件，再执行回归检查。
