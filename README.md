# hospital_record（住院通）

住院管理系统项目仓库，包含两部分：
- Web 原型（`app.js` / `index.html` / `style.css`）
- Flutter 正式实现（`flutter_app/`，当前主线）

## 本版重点
- 模板体系升级：病种下拆分「病情评估模板」与「诊断模板」
- 模板版本页与字段配置联动：`templateVersion` 字段可在版本页直接展示/维护
- 护理等级作为系统字段保留（不可删除），并支持在病人信息中编辑
- 护理等级颜色支持自由选色（调色盘 + RGB + HEX）
- 首页列表统一视觉：卡片底色统一，护理等级仅在标签上体现颜色
- 常用操作按钮（新增/编辑/删除）逐步图标化，界面更紧凑

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
