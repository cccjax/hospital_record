# 项目交接文档（HANDOFF）

本文件用于双设备切换时保持上下文一致。每次结束开发前请更新本文件。

## 1) 当前目标
- 项目：住院管理系统（离线优先），当前进入 Flutter 复刻阶段。
- 阶段目标：在保留 Web 原型逻辑的前提下，完成 Flutter 多端实现（iOS/Android）。
- 当前重点：先把核心业务链路跑通，再逐轮做 UI 与交互细节打磨。

## 2) 当前状态（2026-04-09）
- 仓库：`cccjax/hospital_record`
- 分支：`main`
- 已有两套实现：
  - Web 原型：`app.js`、`index.html`、`style.css`（可继续作为交互参考基线）
  - Flutter 复刻：`flutter_app/`（新增并持续迭代）

## 3) Flutter 当前完成度
- 应用骨架：
  - 底部 Tab：`首页` / `模板` / `我的`
  - 启动密码校验页（启用密码后生效）
- 首页：
  - 病人列表、搜索、在院筛选、病人新增/编辑/删除
  - 点击整行进入病人明细
- 病人明细：
  - 基础档案展示与编辑
  - 入院记录列表、入院新增/编辑/删除
  - 已加入“在院记录存在时禁止重复新增入院”逻辑
- 入院详情：
  - 入院详情展示与编辑
  - 日常记录新增/编辑/删除/详情
  - 住院测评新增/编辑/删除/只读详情
  - 影像资料拍照/相册上传、缩略图预览、删除
  - 住院测评进度条（区间 + 当前得分标识）
- 模板页：
  - 病种搜索
  - 病种展开/收起版本列表
  - 病种、版本、测评项、分级区间增删改
- 我的页：
  - 数据迁移（导入/导出 JSON）
  - 密码保护（开启/修改/关闭）
  - 字段配置（新增/编辑/删除、显示隐藏、排序模式）

## 4) 本次更新内容
- [x] 新增 `flutter_app` 目录并完成基础工程结构。
- [x] 完成核心数据模型、状态层、默认数据与本地存储读写。
- [x] 完成主要页面链路与关键表单交互（病人/入院/日常/测评/模板/我的）。
- [x] 更新 Flutter 项目说明文档：`flutter_app/README.md`（中文）。
- [x] 修复状态层尾部结构问题并补充错误提示字段。

## 5) 下一步（接手后前 30 分钟）
1. 在 Flutter 可用环境执行：
   - `flutter pub get`
   - `flutter analyze`
   - `flutter run`
2. 优先回归核心链路：
   - 首页病人 -> 病人明细 -> 新增入院 -> 入院详情
   - 新增日常 / 新增测评 / 上传影像
   - 模板配置（病种 -> 版本 -> 测评项 -> 分级）
   - 我的页（导入导出/密码/字段配置）
3. 根据运行反馈修正样式细节与少量布局偏差（主要是行高、字号、箭头/按钮对齐）。

## 6) 待确认事项
- [ ] Flutter 端是否继续保留“首页卡片大字号”视觉风格，还是改为更紧凑医疗风格。
- [ ] 测评项是否需要补充分值权重（当前按选项分值直接累加）。
- [ ] 影像资料是否需要后续支持本地文件路径引用（当前为 Base64 存储）。

## 7) 风险与注意事项
- `git` 未加入系统 PATH，当前可用路径：
  - `D:\SoftWare\AI\mingit-2.53.0.2\cmd\git.exe`
- Flutter/Dart 在部分会话可能出现命令卡住现象，若再次出现建议先单独验证 SDK 环境再继续自动化命令。
- 字段配置影响全局展示，修改后务必联动验证首页、病人明细、入院详情相关字段显示。

## 8) 常用命令
```bash
# 在仓库根目录执行
"D:\SoftWare\AI\mingit-2.53.0.2\cmd\git.exe" status
"D:\SoftWare\AI\mingit-2.53.0.2\cmd\git.exe" add flutter_app HANDOFF.md SWITCH_CHECKLIST.md
"D:\SoftWare\AI\mingit-2.53.0.2\cmd\git.exe" commit -m "feat: 初始化 flutter_app 并补全核心页面与状态层"
"D:\SoftWare\AI\mingit-2.53.0.2\cmd\git.exe" push origin main
```

## 9) 关键文件
- Web 原型逻辑：`D:\SoftWare\AI\hospital_record\app.js`
- Flutter 入口：`D:\SoftWare\AI\hospital_record\flutter_app\lib\main.dart`
- Flutter 状态层：`D:\SoftWare\AI\hospital_record\flutter_app\lib\src\state\hospital_app_state.dart`
- Flutter 页面目录：`D:\SoftWare\AI\hospital_record\flutter_app\lib\src\pages`
- 交接文档：`D:\SoftWare\AI\hospital_record\HANDOFF.md`
- 切换清单：`D:\SoftWare\AI\hospital_record\SWITCH_CHECKLIST.md`
