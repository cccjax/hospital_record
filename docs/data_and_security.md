# 数据与安全说明

最后更新：2026-04-24

## 目标

本项目以离线使用为主，数据需要稳定保存在本机，并支持文件导入导出。随着速记白板、影像资料等内容增加，继续把完整 JSON 长期放在 `SharedPreferences` 中会增加体积、性能与兼容风险，因此本版将主数据迁移为文件优先存储。

## 本地数据文件

代码入口：

- `flutter_app/lib/src/data/local_storage_repository.dart`

当前文件：

- `hospital_record_data_v1.json`：应用主数据，包括字段配置、病人、入院记录、日常记录、模板、测评、影像等。
- `hospital_record_security_v1.json`：密码保护与指纹开关等安全配置。

文件目录由 Flutter 的 `path_provider` 获取系统应用支持目录后创建 `hospital_record` 子目录。测试环境可通过 `LocalStorageRepository(storageDirectory: ...)` 注入临时目录。

## 旧数据兼容

旧版数据仍从 `SharedPreferences` 兼容读取：

- `hospital_record_prototype_data_v1`
- `hospital_record_prototype_security_v1`

加载顺序：

1. 优先读取 JSON 文件。
2. 若文件不存在或不可读，尝试读取旧版 `SharedPreferences`。
3. 若旧版数据读取成功，自动写入新的 JSON 文件。

本版不会主动删除旧版 `SharedPreferences` 数据，便于异常时保留回退线索。

## 密码保护

新设置或修改的密码不再保存明文，而是保存为：

- 算法：PBKDF2-SHA256
- 随机盐：每次设置密码都会生成新的 salt
- 格式：`pbkdf2_sha256:iterations:salt:hash`

旧版明文密码兼容逻辑：

1. 用户输入密码。
2. 如果存量值不是哈希格式，则按旧明文方式校验。
3. 校验成功后立即升级为 PBKDF2-SHA256 哈希并保存。

## 指纹解锁

指纹解锁仍然依赖已开启的密码保护：

- 未开启密码保护时，不能启用指纹解锁。
- 指纹解锁只负责打开当前会话，不替代本地密码配置。

## 回归建议

升级本版后建议至少验证：

- 首次启动能读取旧数据。
- 修改病人、入院、日常记录后重启仍保留。
- 开启密码后，配置文件中不出现明文密码。
- 旧明文密码配置首次登录成功后会自动升级。
- 数据导出与导入仍可用。

## 后续优化

后续若白板或图片数量继续增加，建议进一步拆分：

- 结构化数据继续保存在 JSON 或数据库。
- 白板 PNG、影像图片单独保存为文件。
- 主数据只保存图片文件路径、缩略图路径和元信息。
