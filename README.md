# hospital_record（住院通）

住院管理系统项目仓库，包含两部分：
- Web 原型（`app.js` / `index.html` / `style.css`）
- Flutter 正式实现（`flutter_app/`，当前主线）

## 本版重点
- 本地持久化升级：应用主数据与安全配置改为文件优先存储，兼容旧版 `SharedPreferences` 数据自动迁移
- 密码保护升级：新设置/修改的密码保存为 PBKDF2-SHA256 哈希，旧明文密码在首次验证成功后自动升级
- UI 视觉升级：编辑/新增弹窗改为更轻的表单面板，页面区块卡片和入院详情摘要增强层次感
- 速记白板升级：画布最大化、工具栏悬浮固定、支持撤销/重做、白板预览卡片更清晰
- 模板体系升级：病种下拆分「病情评估模板」与「诊断模板」
- 模板版本页与字段配置联动：`templateVersion` 字段可在版本页直接展示/维护
- 护理等级作为系统字段保留（不可删除），并支持在病人信息中编辑
- 护理等级颜色支持自由选色（调色盘 + RGB + HEX）
- 首页列表统一视觉：卡片底色统一，护理等级仅在标签上体现颜色
- 常用操作按钮（新增/编辑/删除）逐步图标化，界面更紧凑
- 首页病人列表、模板病种列表支持左右滑分页，减少长列表上下滚动
- 分页指示器改为半透明悬浮底部圆点（固定在页面底部顶层）
- 病种与版本卡片改为动态比例 + 自适应布局，修复内容溢出与空白过大
- 字段配置“是否可见”图标语义修正（睁眼=当前可见，闭眼=当前隐藏）
- 新增病种时 `病种编码` 可编辑，不再被锁定

## 目录结构
- `flutter_app/`：Flutter 应用源码
- `HANDOFF.md`：交接说明（状态、风险、下一步）
- `SWITCH_CHECKLIST.md`：切换设备/交接时的回归清单

## 快速开始（Flutter）
```bash
cd flutter_app
flutter pub get
flutter run -d emulator-5554
```

## 质量检查（建议）
```bash
cd flutter_app
flutter analyze lib test
flutter test
```

说明：
- 建议优先使用 `flutter analyze lib test`，避免分析 `build/` 目录导致耗时增加。
- 如果你在根目录执行 `flutter analyze`，可能会出现 `Analyzing Administrator...` 这类误判路径现象。

## 数据与安全
- 主数据文件：`hospital_record_data_v1.json`
- 安全配置文件：`hospital_record_security_v1.json`
- 文件目录：由系统应用支持目录提供，代码入口见 `flutter_app/lib/src/data/local_storage_repository.dart`
- 旧版数据：仍会从 `SharedPreferences` 读取；首次读取成功后会写入新的 JSON 文件
- 密码：新密码不再保存明文，旧明文密码会在用户验证成功后自动升级为哈希

## 打包 APK
```bash
cd flutter_app
flutter build apk --release
```

产物路径：
- `flutter_app/build/app/outputs/flutter-apk/app-release.apk`

## 正式签名（简版）
1. 准备 keystore（建议长期保存）。
2. 在 `flutter_app/android/key.properties` 配置签名参数。
3. 在 `flutter_app/android/app/build.gradle` 引用签名配置。
4. 执行：
```bash
cd flutter_app
flutter build apk --release
```

## 交接文档
- `HANDOFF.md`
- `SWITCH_CHECKLIST.md`
- `docs/data_and_security.md`
- `docs/architecture.md`

## 版本说明（2026-04-24）
- 文档与代码已同步到“文件持久化 + 密码哈希 + 基础回归测试”版本。
- 本版保留旧数据兼容迁移，但建议升级后先做一次导出备份，再继续日常使用。
- 若需要提交生产包，建议先在真机回归：首页分页、模板分页、字段配置联动、病种新增编辑流程、数据导入导出、密码保护。
