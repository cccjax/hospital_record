# hospital_record

住院管理系统项目仓库，包含：
- Web 原型实现（`app.js` / `index.html` / `style.css`）
- Flutter 业务实现（`flutter_app/`）

## 快速开始（Flutter）
```bash
cd flutter_app
flutter pub get
flutter run -d emulator-5554
```

## 打包 APK（Release）
```bash
cd flutter_app
flutter build apk --release
```

产物路径：
- `flutter_app/build/app/outputs/flutter-apk/app-release.apk`

## 交接文档
- `HANDOFF.md`
- `SWITCH_CHECKLIST.md`
