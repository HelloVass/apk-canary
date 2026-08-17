# 本地分析工作流

## 目录

- APK 输入
- AAB 一体化输入
- 制品收集
- 执行与验收

## APK 输入

优先分析产品实际生成的 release APK。确保 APK、R8/ProGuard `mapping.txt` 和带十六进制 resource ID 的完整 `R.txt` 来自同一个 variant 和构建。

只有 APK 本地路径时也必须继续分析；mapping 和 `R.txt` 是增强输入，不是启动条件。缺少 mapping 时明确说明 DEX 名称可能混淆，缺少 `R.txt` 时明确说明资源符号恢复与静态无用资源会跳过。输入是 APK 下载链接时，使用 `curl --fail --location --show-error --output "$apk_path" "$APK_SOURCE_URL"` 保存到受忽略规则保护的本地路径并确认文件非空，再交给 CLI；不要回显带凭据的 URL，CLI 不直接接收 URL。

先运行 `apk-canary --version`，再执行 `apk-canary analyze`。默认保留完整报告；文件阈值和后缀选项只用于报告中的附加查询视图，不能替代全量规则输入。

APK 的一级体积字段是 `delivery.downloadSize`：CLI 对完整 APK 执行与官方 `apkanalyzer apk download-size` 一致的 gzip -9 估算，最小值与最大值相等。`summary.apkBytes` 只是 APK 文件自身大小，不能作为用户下载大小汇报。

## AAB 一体化输入

当输入只有 AAB 本地路径或下载链接时，必须先执行 [AAB 单输入与下载链接工作流](aab-only-analysis.md)：把 AAB 固化到受忽略规则保护的本地目录，检查并提取内嵌 `proguard.map`，存在时作为 `--mapping` 输入。mapping 解压属于 Agent 的输入准备步骤，不改变 CLI 自身无需外部 bundletool、Java、AAPT2 或 unzip 的运行时边界。

CLI 内嵌固定并校验的 `bundletool-all-1.18.3.jar`，产品 AAB 可以直接输入，不需要外部 bundletool、Java、unzip 或 AAPT2：

```shell
scripts/analyze-release.sh \
  --cli build/tools/apk-canary/apk-canary \
  --artifact app-release.aab \
  --output build/reports/apk-canary/report.json \
  -- \
  --mapping mapping.txt \
  --r-txt R.txt \
  --product product-id \
  --variant release \
  --channel google-play
```

也可以不经过脚本，直接运行 `apk-canary analyze app-release.aab`。可选 `--device-spec device-spec.json` 会把下载估算收窄到该设备。报告保留原始 AAB、设备规格、mapping 和 `R.txt` 指纹；`delivery` 记录下载范围，`bundleDelivery` 记录 bundletool 版本、默认 APKS 和 Universal APK。

这条一体化路径同时包含两种口径：

- `delivery.downloadSize` 来自默认 APKS，是 bundletool 对网络压缩下载字节的估算；未传设备规格时是兼容设备范围。
- `summary` 和 APK 内容规则来自 Universal APK，包含全部 ABI、语言和密度，不能代表单个用户的 Play 下载大小。
- 多 ABI 在 Universal APK 中是预期结果，不应直接作为失败条件。
- 动态 Feature/Asset Pack 的模块级内容归因、Play 服务端优化和安装后磁盘占用不属于当前能力。

可以把它描述为“内嵌 bundletool 的一体化 AAB 交付估算与 Universal APK 内容分析”，不能描述为 Play Console 的精确用户下载或模块级 Bundle 分析。

## 制品收集

- `mapping.txt` 用于恢复 DEX 类身份和归因。
- 数值 `R.txt` 用于按 resource ID 恢复原始资源名，并区分 shrinker 删除项。
- `resources.txt` 不是输入。
- 缺少 `R.txt` 时仍可分析 APK/AAB，但资源名称恢复和依赖该符号表的门禁必须明确跳过或失败。

AGP 中间目录随版本变化。优先在产品工程中增加归档任务，把最终 APK/AAB、mapping 和 `R.txt` 复制到稳定输出目录，避免 Skill 猜测内部路径。

## 执行与验收

1. 校验工具版本和输入文件存在且非空。
2. 生成紧凑 JSON。
3. 先检查 schema、输入指纹、规则状态和 diagnostics。
4. 再读取 gate、comparison 和各专项结果。
5. 对静态候选结合反射、WebView、Native、服务端配置和动态下发策略复核。
6. 交互式分析必须执行 [Markdown 分析报告工作流](markdown-report.md)，使用模板在 JSON 旁生成 `<artifact-stem>-apk-canary-analysis.md`，同时把两个文件交付给用户。
