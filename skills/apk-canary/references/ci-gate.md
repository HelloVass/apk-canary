# GitHub Actions 卡口

## 目录

- 执行顺序
- 退出码
- 基线与预算
- 报告归档
- 发布制品

## 执行顺序

保持以下依赖关系：

```text
构建同次制品和符号
        ↓
APK Canary 分析与预算
        ↓
归档 JSON 报告
        ↓
上传或发布制品
```

不要让上传任务隐式完成第一次构建，否则 CLI 没有机会在发布前卡住同一个产物。可以先显式执行 Gradle 构建，再调用上传任务；Gradle 应复用未变化的输出。

## 退出码

- `0`：分析成功，且已配置的预算通过。
- `2`：报告已写入，但预算失败；CI 应失败并保留报告。
- 其他非零值：参数、输入或分析失败；不得当作普通预算超标处理。

不要在 shell 中用无条件 `|| true` 吞掉分析结果。报告归档步骤使用 `if: always()`，发布步骤只在前置步骤成功时执行。

## 基线与预算

- 初次接入先生成稳定版本报告，再从真实数据建立产品预算。
- baseline 必须匹配 product、variant 和 channel。
- 一级预算使用 `maxDownloadBytes`，增长预算使用 `comparison.download`；`maxApkBytes` 仅作为原始 APK 或 Universal APK 辅助约束。
- 旧 baseline 没有 `delivery.downloadSize` 时应重新生成，不能回退到文件大小执行下载增长门禁。
- 预算配置属于产品仓库，CLI 不硬编码业务阈值。
- 绝对大小、相对增长、DEX、资源、assets 和 SO 门禁可以同时使用。
- 静态候选优先设置“不得新增”预算，不要把候选直接当作可删除文件。
- 临时豁免必须包含精确指标、原因和过期时间。

## 报告归档

只归档紧凑 JSON 及必要的构建元数据。CI 不生成 HTML，也不在 workflow 中使用大型脚本硬编码解释逻辑。Agent 或平台在任务完成后读取 JSON。

建议 artifact 至少记录：

- APK Canary 版本。
- Git commit 与 CI run ID。
- 当前报告。
- 作为比较输入的 baseline 标识。
- AAB 报告中的原始 AAB、可选设备规格和派生制品指纹。

APK Canary Release 位于公开分发仓库，产品 CI 不需要额外的 GitHub token。安装器通过匿名 HTTPS 下载固定版本并校验 `SHA256SUMS`；如果 runner 已有通过认证的 `gh`，也可以复用它，但不得因此跳过哈希校验。

## 发布制品

当前 CLI 直接支持 APK 与 AAB 输入，并统一输出 `delivery.downloadSize`。APK 使用 gzip -9 单值估算；AAB 由内嵌 bundletool 生成默认 APKS 下载范围与 Universal APK 内容报告，可以用 `--device-spec` 获取设备级估算。不能把 APK/AAB 文件或 Universal APK 的 `summary.apkBytes` 声明为用户下载体积。模块级动态 Feature/Asset Pack 归因仍需后续能力。
