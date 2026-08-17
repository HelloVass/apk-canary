# AAB 单输入与下载链接工作流

当研发只提供 AAB 本地路径或下载链接时，先把 AAB 固化为本地文件，再检查 Bundle 内嵌的 R8/ProGuard mapping。存在 mapping 时必须提取并作为 `--mapping` 输入，避免 DEX 包级与类级归因停留在混淆名。整个流程不需要额外 APK。

## 能力口径

- 以 `delivery.downloadSize` 作为用户下载大小：未传 `--device-spec` 时它是兼容设备的预计下载范围，不是某一台设备的精确值。
- `summary`、文件、DEX、资源、assets、PNG、重复文件和 SO 规则分析 bundletool 生成的 Universal APK；它包含全部 ABI、语言和密度，只用于内容诊断。
- AAB 文件大小和 Universal APK 大小都不是 Google Play 用户下载大小。
- CLI 不直接接收 URL。Agent 负责下载、校验和保存 AAB，再把本地路径传给 CLI。

## 1. 准备隔离目录

在 APK Canary 仓库内操作时，把业务 AAB、mapping 和报告放在 `cli/samples/local/<product>/<version>/`；该目录受忽略规则保护。不要把业务制品、反混淆信息、带凭据的下载链接或报告提交到 Git。

为每次分析创建新的运行目录，避免旧 mapping 污染新 AAB：

```shell
run_dir="cli/samples/local/product/version/run"
mkdir -p "$run_dir"
aab_path="$run_dir/app-release.aab"
report_path="$run_dir/report.json"
```

在其他产品仓库中，使用同等受忽略规则保护的构建目录或临时目录。

## 2. 下载或接收 AAB

如果输入是下载链接，下载时跟随重定向并在失败时立即停止：

```shell
curl --fail --location --show-error \
  --output "$aab_path" \
  "$AAB_SOURCE_URL"
test -s "$aab_path"
```

不要在日志、报告或提交信息中回显可能包含签名参数或访问令牌的 URL。记录本地 AAB 的文件大小和 SHA-256，便于复核输入身份。

## 3. 自动提取内嵌 mapping

先检查标准 Bundle Metadata 路径：

```shell
mapping_entry="BUNDLE-METADATA/com.android.tools.build.obfuscation/proguard.map"
mapping_args=()

if unzip -Z1 "$aab_path" | rg -Fx "$mapping_entry" >/dev/null; then
  unzip -j "$aab_path" "$mapping_entry" -d "$run_dir"
  mapping_path="$run_dir/proguard.map"
  test -s "$mapping_path"
  mapping_args=(--mapping "$mapping_path")
fi
```

把解压视为 Agent 的输入准备步骤，不是 APK Canary CLI 的运行时依赖。CLI 自身仍内嵌 bundletool 和 AAPT2，不要求用户另装这些工具。

遵守以下边界：

- 不要假设每个 AAB 都包含 mapping。没有该条目时继续分析，但明确说明 mapping 规则为 `SKIPPED`，DEX 名称可能仍被混淆。
- 如果研发另外提供 mapping，只在确认它与 AAB 来自同一次构建后使用。AAB 内嵌 mapping 通常是 AAB 单输入场景中更可靠的匹配来源。
- 不要把 `dependencies.pb`、`resources.pb` 或其他 Bundle Metadata 当作 mapping。

## 4. 处理 R.txt 边界

AAB 通常不包含 APK Canary 所需的、带数字 resource ID 的完整 AGP `R.txt`。不要把 `resources.pb` 或 `resources.txt` 伪装成 `R.txt`。

- 研发提供同次构建的数值 `R.txt` 时，追加 `--r-txt <path>`。
- 只有 AAB 时，`resource-table` 仍可解析最终资源表；`resource-symbols` 和 `unused-resources` 应明确为 `SKIPPED`。
- 缺少 `R.txt` 不影响下载估算、Manifest、DEX、文件类型与压缩率、大文件、重复文件、assets、PNG 和 ABI/SO 分析。

## 5. 运行 CLI

```shell
apk-canary analyze "$aab_path" \
  "${mapping_args[@]}" \
  --product product-id \
  --variant release \
  --channel google-play \
  --output "$report_path"
```

有目标设备规格时追加 `--device-spec device-spec.json`，把预计下载范围收窄到该设备。不要为了运行内容规则而要求研发再提供 APK；CLI 会从 AAB 生成默认 APKS 和 Universal APK。

## 6. 验收报告

先检查协议、输入身份、下载口径、mapping 是否生效、规则状态和诊断：

```shell
jq '{
  schemaVersion,
  artifact: {format: .artifact.format, inputs: .artifact.inputs},
  mapping,
  delivery,
  bundleDelivery,
  rules: [.rules[] | {id, status}],
  diagnostics
}' "$report_path"
```

验收要点：

1. `schemaVersion` 为当前 CLI 协议，`artifact.format` 为 `AAB`，AAB 指纹与下载文件一致。
2. 存在内嵌 mapping 时，输入列表包含 `MAPPING`，`mapping.supplied=true`，`mapping` 规则为 `SUCCESS`；再读取 `classMappings` 和 `appliedMethodReferences` 判断恢复覆盖率。
3. `delivery.estimationMethod=BUNDLETOOL_GET_SIZE`，首先汇报 `downloadSize.minBytes` 与 `maxBytes`。
4. `bundleDelivery` 记录 bundletool、APKS 与 Universal APK 指纹；Universal APK 大小只能作为内容诊断。
5. 检查所有规则状态和 `diagnostics`。没有 `R.txt` 时，只把预期的资源符号规则跳过视为正常，不能忽略其他 `ERROR`。

## 7. 生成 Markdown 分析报告

执行 [Markdown 分析报告工作流](markdown-report.md)，使用 [分析报告模板](../assets/analysis-report-template.md)生成 `<artifact-stem>-apk-canary-analysis.md`。先汇报 `delivery.downloadSize`，再解释 Universal APK 内容；把 mapping 和 `R.txt` 的提供状态、所有规则跳过原因、静态候选风险以及 JSON 路径写入文档。最终同时交付原始 JSON 和 Markdown。

## AAB 单输入可得结果

| 分析面 | 只有 AAB | 说明 |
|---|---|---|
| Google Play 下载估算 | 支持 | 默认是兼容设备范围；可用 device spec 收窄 |
| Manifest、文件类型、压缩率和大文件 | 支持 | 内容规则基于 Universal APK |
| DEX 数量、方法/类和包级归因 | 支持 | 内嵌 mapping 存在时先提取并恢复原名 |
| 资源表和资源文件 | 支持 | 不依赖外部 AAPT2 |
| 精确资源名恢复和静态无用资源 | 受限 | 需要同次构建的数值 `R.txt` |
| assets、PNG 和重复文件 | 支持 | 静态候选仍需结合动态访问复核 |
| ABI/SO、strip 状态和 STL 候选 | 支持 | Universal APK 会包含全部 ABI |
| 动态 Feature、Asset Pack、模块和依赖归因 | 暂不支持 | 不要从 Universal APK 总量伪造模块结论 |
