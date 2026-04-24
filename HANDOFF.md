# 项目交接文档（HANDOFF）

最后更新：2026-04-24

## 1. 项目目标

- 项目：住院管理系统（App 名：住院通）
- 当前阶段：Flutter 主线迭代（Android 优先）
- 目标：离线稳定、录入高效、模板逻辑清晰、界面统一且适配手机/平板

## 2. 本版完成内容（重点）

- 本地持久化升级
  - 主数据与安全配置改为 JSON 文件优先存储
  - 兼容旧版 `SharedPreferences` 数据
  - 首次读取旧数据成功后自动迁移到 JSON 文件
- 密码保护升级
  - 新设置/修改的密码保存为 PBKDF2-SHA256 哈希
  - 每次设置密码生成随机 salt
  - 旧明文密码首次校验成功后自动升级为哈希
- 测试补齐
  - 新增本地仓储保存/读取/迁移测试
  - 新增密码哈希与旧密码兼容测试
  - 新增状态层密码设置/校验测试
- 文档补齐
  - 新增 `docs/data_and_security.md`
  - 新增 `docs/architecture.md`
  - 更新 README 与切换清单
- UI 视觉试改版
  - 编辑/新增弹窗改为单一表单面板 + 行分割，减少字段独立框带来的割裂感
  - 页面区块卡片增加更轻的渐变、阴影和左侧强调线
  - 入院详情顶部摘要卡增强层次，速记白板预览改为更明确的小卡片
  - 速记白板改为大画布 + 悬浮固定工具栏，并新增“重做”能力

## 3. 关键文件

- 本地仓储：`flutter_app/lib/src/data/local_storage_repository.dart`
- 密码哈希：`flutter_app/lib/src/utils/password_codec.dart`
- 数据模型：`flutter_app/lib/src/models/app_models.dart`
- 状态管理：`flutter_app/lib/src/state/hospital_app_state.dart`
- 仓储测试：`flutter_app/test/local_storage_repository_test.dart`
- 密码测试：`flutter_app/test/password_codec_test.dart`
- 状态测试：`flutter_app/test/security_state_test.dart`
- 编辑弹窗：`flutter_app/lib/src/widgets/dynamic_form_dialog.dart`
- 速记白板：`flutter_app/lib/src/widgets/sketch_board_dialog.dart`
- 区块卡片：`flutter_app/lib/src/widgets/section_card.dart`
- 数据安全文档：`docs/data_and_security.md`
- 架构文档：`docs/architecture.md`

## 4. 本轮验证

在 `flutter_app` 目录执行：

```bash
flutter analyze lib test
flutter test
```

结果：

- `flutter analyze lib test` 通过（No issues found）
- `flutter test` 通过（All tests passed）
- UI 本轮尚未连接真机人工验收，建议重点查看：新增/编辑弹窗、入院详情、日常记录速记白板

## 5. 已知注意点

- 本版仍保留旧版 `SharedPreferences` 数据，不主动删除，便于异常回退排查。
- 白板图片目前仍随主数据 JSON 序列化，已从 `SharedPreferences` 迁出；后续如果图片继续增多，建议再拆成独立图片文件存储。
- 密码哈希升级发生在旧明文密码首次验证成功后；未登录验证前，旧配置仍保持兼容读取。
- 根目录 Web 原型仍存在，Flutter 为当前主线。

## 6. 建议下一步

1. 真机回归旧版本升级场景：旧数据启动、旧密码登录、重启后数据仍在。
2. 将速记白板 PNG 与影像图片进一步拆成文件路径存储，减少主 JSON 体积。
3. 逐步拆分 `HospitalAppState`，优先拆字段配置、模板、数据迁移、安全服务。
4. 继续补字段配置联动、导入导出校验、测评分级区间、速记白板预览相关测试。

## 7. Git 交接约定

- 离开前：更新本文件 + `SWITCH_CHECKLIST.md` 并推送远端。
- 接手后：先阅读本文件，再执行回归清单。
