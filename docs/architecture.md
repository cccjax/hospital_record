# 架构说明

最后更新：2026-04-24

## 项目主线

当前主线是 Flutter 应用：

- `flutter_app/lib/main.dart`：启动入口，初始化 `HospitalAppState`。
- `flutter_app/lib/src/app.dart`：应用壳与主题入口。
- `flutter_app/lib/src/state/hospital_app_state.dart`：当前核心状态管理。
- `flutter_app/lib/src/data/local_storage_repository.dart`：本地持久化。
- `flutter_app/lib/src/models/app_models.dart`：主要数据模型。

根目录的 `app.js`、`index.html`、`style.css` 是早期 Web 原型，后续建议移动到 `legacy_web/` 或在文档中明确为历史参考，避免与 Flutter 主线混淆。

## 当前模块

- 首页：病人列表、快捷筛选、护理等级标签、分页卡片。
- 病人详情：基础信息、入院记录卡片。
- 入院详情：入院详情、日常记录、住院测评、速记白板预览。
- 模板中心：病情评估模板、诊断模板、版本管理、测评项配置。
- 字段配置：动态字段、系统字段、下拉选项、护理等级颜色。
- 我的：数据迁移、密码保护、指纹解锁。

## 状态管理现状

`HospitalAppState` 当前承担了较多职责：

- 数据初始化与修复。
- 病人、入院、日常记录增删改。
- 模板和版本增删改。
- 字段配置联动。
- 导入导出。
- 密码保护与会话解锁。

短期继续使用该结构可以减少重构风险；中长期建议拆分为服务层，以降低单文件复杂度。

## 建议拆分方向

后续可逐步拆分，不建议一次性大改：

- `PatientService`：病人、入院、日常记录。
- `TemplateService`：病种、病情评估模板、诊断模板、版本。
- `FieldSchemaService`：字段配置、系统字段、显示逻辑。
- `MigrationService`：导入导出、版本迁移、文件校验。
- `SecurityService`：密码哈希、指纹开关、会话锁定。
- `SketchStorageService`：速记白板图片文件化与缩略图。

## UI 组件方向

已经沉淀的通用组件：

- 卡片分页：`flutter_app/lib/src/widgets/paged_card_grid.dart`
- 返回按钮：`flutter_app/lib/src/widgets/app_back_button.dart`
- 统一弹窗：`flutter_app/lib/src/widgets/dialog_utils.dart`
- 动态表单：`flutter_app/lib/src/widgets/dynamic_form_dialog.dart`
- 下拉选择：`flutter_app/lib/src/widgets/app_dropdown_form_field.dart`
- 速记白板：`flutter_app/lib/src/widgets/sketch_board_dialog.dart`

后续建议继续统一：

- 表单行布局。
- 图标按钮尺寸与颜色。
- 卡片标题区和标签样式。
- 空状态、错误状态、确认弹窗。
- 平板双栏布局。

## 质量策略

本版新增了基础测试：

- `flutter_app/test/local_storage_repository_test.dart`
- `flutter_app/test/password_codec_test.dart`
- `flutter_app/test/security_state_test.dart`

建议后续继续补：

- 字段配置联动测试。
- 导入导出校验测试。
- 测评分级区间测试。
- 护理等级颜色配置测试。
- 速记白板保存和预览测试。
