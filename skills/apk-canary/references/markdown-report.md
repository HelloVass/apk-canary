# Markdown 分析报告工作流

对本地路径或下载链接触发的交互式 APK/AAB 分析，同时交付 CLI 生成的紧凑 JSON 和 Agent 编写的 Markdown 分析报告。JSON 是唯一机器协议；Markdown 只解释 JSON，不得改变、补造或替代 schema、baseline 与预算结果。纯 CI 卡口默认只归档 JSON，除非用户明确要求生成 Markdown。

## 输入与输出

- JSON：保留 CLI 的 `--output` 文件，不要美化或改写。
- Markdown：与 JSON 放在同一受忽略规则保护的目录，命名为 `<artifact-stem>-apk-canary-analysis.md`。
- 模板：从 [分析报告模板](../assets/analysis-report-template.md)复制后填充；保留全部一级分析章节，不适用的章节明确写“未提供”或“不适用”。
- 业务 APK/AAB、mapping、`R.txt`、JSON 和 Markdown 都不得提交到源码仓，除非仓库提供了明确的脱敏 fixture 策略。

## 1. 验证 JSON

先执行 [JSON 报告阅读顺序](report-reading.md)中的完整性检查。没有通过以下条件时不要输出肯定性优化结论：

1. `schemaVersion`、`tool.version`、制品格式和输入指纹可确认。
2. `delivery.downloadSize` 存在；AAB 还存在 `bundleDelivery`。
3. 所有 `ERROR` 和 `SKIPPED` 都已解释，`diagnostics` 不含会使结果失真的失败。
4. mapping、`R.txt`、device spec、baseline 和 budget 是否提供已经记录。

输入不完整时仍可生成 Markdown，但标题下方必须标记“部分可信”，并把缺失能力写入“能力边界”。

## 2. 提取决策证据

按需读取 JSON，不要把完整数组复制进 Markdown：

```shell
jq '{schemaVersion, tool, artifact, delivery, bundleDelivery, mapping, diagnostics, rules}' report.json
jq '{summary, groups, gate, comparison}' report.json
jq '{dex: (.dex | del(.packages, .classes)), packages: .dex.packages[:20]}' report.json
jq '{resourceSymbols, resourceTable, unusedResources, unusedAssets, png, duplicates}' report.json
jq '{rClasses, nativeLibraries}' report.json
```

只展示能改变决策的 Top 项，通常每类 5–10 项。按实际数据展开模板中的 `GROUP_ROWS` 和 `ACTION_ROWS`，不要保留示例或空行。保留文件路径、压缩字节、归因名称和规则状态，使读者能回到 JSON 复核。

## 3. 应用口径

- APK 与 AAB 的一级体积都来自 `delivery.downloadSize`。APK 报告单值；AAB 没有 device spec 时报告兼容设备范围。
- APK 的 `summary.apkBytes` 是 APK 文件大小；AAB 的该字段是 Universal APK 大小。两者都只能解释内容组成。
- AAB 的 Universal APK 包含全部 ABI、语言和密度。不要把其分类总量或删除收益直接包装成单台设备下载收益。
- 使用二进制单位时明确写 `KiB`、`MiB`；同时保留关键原始字节，避免把十进制 MB 与 MiB 混用。
- 没有 baseline 时明确写“无法判断版本增长”；没有 budget 时明确写“无法判断预算是否通过”。
- DEX 包/类计数不等于字节贡献。除非 JSON 提供字节归因，否则只描述方法引用、类定义和优化方向。
- `unusedResources`、`unusedAssets`、非透明 PNG、静态 STL 和 ABI 不一致都是候选，不是删除证明。
- 预估收益优先使用 `compressedBytes` 或 `wastedCompressedBytes`，并标注为理论上限；不要重复累加重叠候选。

## 4. 编写 Markdown

按 [分析报告模板](../assets/analysis-report-template.md)的顺序填写：

1. 用 3–6 条结论摘要回答实际下载大小、最大组成、首要优化方向和可信度。
2. 分开陈述确定性事实与需要产品复核的候选。
3. 对每项建议写出证据、潜在收益、风险和验证方式；没有可靠收益时写“待重新分析验证”。
4. 将 baseline、预算和规则错误放在候选优化之前；门禁失败不能被一般建议掩盖。
5. 在“产物”章节链接原始 JSON，并记录输入 artifact、mapping、`R.txt` 与 device spec 的提供状态。

## 5. 验收交付

交付前确认：

- Markdown 文件存在且非空，文件名符合约定。
- 模板中的 `{{...}}` 占位符已全部替换。
- 一级下载结论来自 `delivery.downloadSize`。
- AAB 报告明确说明 Universal APK 边界。
- `ERROR`、`SKIPPED`、缺失 baseline/budget 和静态候选误差边界没有被省略。
- JSON 与 Markdown 路径都已提供给用户；最终回复先给结论，再给两个文件链接。

可用以下命令检查未替换占位符：

```shell
if rg -n '\{\{[^}]+\}\}' artifact-apk-canary-analysis.md; then
  exit 1
fi
```
