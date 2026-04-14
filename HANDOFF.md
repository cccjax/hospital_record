# 项目交接文档（HANDOFF）

最后更新：2026-04-14

## 1. 项目目标
- 项目：住院管理系统（App 名：住院通）
- 当前阶段：Flutter 主线迭代（Android 优先）
- 目标：离线稳定、录入高效、模板逻辑清晰、界面统一且适配手机/平板

## 2. 本版完成内容（重点）
- 首页与模板列表分页化
  - 首页病人卡片、模板病种卡片已支持“左右滑分页”
  - 分页行数按可用高度动态估算，尽量减少下方空白
- 分页指示器升级
  - 分页点改为页面底部悬浮显示（顶层）
  - 去掉“第X页/提示文字”，仅保留半透明圆点
- 模板卡片布局优化
  - 病种卡片、版本卡片改为“动态长宽比 + 自适应列数”
  - 修复版本卡片内容过长时 `BOTTOM OVERFLOWED` 问题
- 字段配置联动修复
  - 病种模板与版本列表字段展示改为全量跟随 `showInList`
  - 不再受“最多显示 3/4 行”硬编码限制
- 字段配置可见图标语义修正
  - 睁眼：当前可见
  - 闭眼：当前隐藏
- 病种新增体验修复
  - 新增病种时 `diseaseCode`（病种编码）可编辑，不再被锁定

## 3. 关键文件
- 首页：`flutter_app/lib/src/pages/home_tab_page.dart`
- 模板页：`flutter_app/lib/src/pages/template_tab_page.dart`
- 模板病种详情：`flutter_app/lib/src/pages/template_disease_detail_page.dart`
- 字段配置：`flutter_app/lib/src/pages/field_config_page.dart`
- 动态表单：`flutter_app/lib/src/widgets/dynamic_form_dialog.dart`
- 分页组件：`flutter_app/lib/src/widgets/paged_card_grid.dart`
- 状态管理：`flutter_app/lib/src/state/hospital_app_state.dart`

## 4. 本轮验证
在 `flutter_app` 目录执行：

```bash
flutter analyze lib/src/pages/home_tab_page.dart lib/src/pages/template_tab_page.dart lib/src/widgets/paged_card_grid.dart
flutter analyze lib/src/pages/template_disease_detail_page.dart
flutter analyze lib/src/pages/field_config_page.dart
flutter analyze lib/src/widgets/dynamic_form_dialog.dart
```

结果：
- 上述检查均通过（No issues found）
- `flutter test` 本轮未执行，建议接手后补跑

## 5. 已知注意点
- 仓库当前为持续迭代状态，改动文件较多；提交前需确认“本版范围”。
- `flutter analyze` 若在错误目录执行，可能出现路径误判；建议固定在 `flutter_app/` 执行。

## 6. 建议下一步
1. 真机回归分页体验（手机竖屏/横屏、平板竖屏/横屏）。
2. 评估分页点是否需要在底部导航栏上方再上移 4~8px（避免视觉贴边）。
3. 为分页组件补充 widget test（页数变化、数据减少后的页码回退、回调一致性）。
4. 补跑 `flutter test` 与关键流程手测（首页->病人->入院详情->模板->字段配置）。

## 7. Git 交接约定
- 离开前：更新本文件 + `SWITCH_CHECKLIST.md` 并推送远端。
- 接手后：先阅读本文件，再执行回归清单。
