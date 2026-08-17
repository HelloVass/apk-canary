# APK Canary 分析报告：{{ARTIFACT_NAME}}

> 可信度：{{TRUST_LEVEL}}；依据：APK Canary {{TOOL_VERSION}} / schemaVersion {{SCHEMA_VERSION}}

## 结论摘要

- 用户下载大小：{{PRIMARY_DOWNLOAD_SIZE}}
- 内容诊断大小：{{CONTENT_SIZE}}
- 最大体积来源：{{LARGEST_COMPONENTS}}
- 首要优化方向：{{PRIMARY_ACTIONS}}
- 门禁与版本变化：{{GATE_AND_COMPARISON_SUMMARY}}

## 制品与报告可信度

| 项目 | 结果 |
|---|---|
| 制品 | {{ARTIFACT_IDENTITY}} |
| 格式 | {{ARTIFACT_FORMAT}} |
| applicationId | {{APPLICATION_ID}} |
| variant / channel | {{VARIANT_AND_CHANNEL}} |
| 输入指纹 | {{INPUT_FINGERPRINTS}} |
| mapping | {{MAPPING_STATUS}} |
| R.txt | {{R_TXT_STATUS}} |
| device spec | {{DEVICE_SPEC_STATUS}} |
| 规则与 diagnostics | {{RULE_HEALTH}} |

## 用户下载大小

{{DOWNLOAD_SIZE_ANALYSIS}}

<!-- AAB：说明 device spec 和 Universal APK 边界；APK：说明 gzip -9 网络压缩估算。 -->

## 包体组成

| 类型 | 压缩体积 | 占比 | 判断 |
|---|---:|---:|---|
{{GROUP_ROWS}}

{{LARGEST_FILES_ANALYSIS}}

## DEX 与依赖归因

{{DEX_SUMMARY}}

{{DEX_ATTRIBUTION}}

方法引用和类定义用于确定依赖压力与所有权，除非 JSON 提供字节归因，否则不把它们等同于 DEX 字节占比。

## 资源、assets 与媒体

{{RESOURCE_ANALYSIS}}

{{ASSET_AND_MEDIA_ANALYSIS}}

{{PNG_AND_DUPLICATE_ANALYSIS}}

## ABI 与 Native Library

{{NATIVE_ANALYSIS}}

<!-- AAB：明确 Universal APK 多 ABI 总量不是单台设备下载量。 -->

## Baseline 与预算

{{BASELINE_ANALYSIS}}

{{BUDGET_ANALYSIS}}

## 优化建议

| 优先级 | 建议 | 证据 | 潜在收益 | 风险 | 验证方式 |
|---|---|---|---:|---|---|
{{ACTION_ROWS}}

## 确定性结论

{{DETERMINISTIC_FINDINGS}}

## 需要产品复核的候选

{{REVIEW_REQUIRED_FINDINGS}}

## 能力边界

{{LIMITATIONS}}

## 产物

- 原始制品：{{ARTIFACT_PATH}}
- 机器报告：[JSON 报告]({{JSON_REPORT_PATH}})
- 分析文档：{{MARKDOWN_REPORT_PATH}}
