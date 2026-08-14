# JSON 报告阅读顺序

## 目录

- 完整性
- 门禁与变化
- 组成和候选
- 输出结论

## 完整性

不要从最大文件直接开始。先执行：

```shell
jq '{schemaVersion, tool, artifact, diagnostics, rules}' report.json
```

确认：

1. `schemaVersion` 是当前 CLI 支持的协议。
2. `tool.version` 与运行的二进制一致。
3. product、variant、channel、commit 和 buildId 符合当前任务。
4. `artifact.inputs` 中的 APK、mapping 和 `R.txt` 指纹存在且来自预期制品。
5. 关键规则没有 `ERROR`，`SKIPPED` 有可解释原因。
6. `diagnostics` 不包含会让结论失真的解析失败。

## 门禁与变化

读取 `gate`，区分实际违规和已应用豁免；随后读取 `comparison` 的总量变化、分类变化、Top growth 和 Top savings。没有 baseline 时不得编造增长原因。

## 组成和候选

按问题选择字段，不要一次展开完整大报告：

```shell
jq '.groups[:20]' report.json
jq '.dex.packages[:30]' report.json
jq '.dex.classes[:30]' report.json
jq '.duplicates.groups[:20]' report.json
jq '.unusedResources.candidates[:50]' report.json
jq '.unusedAssets.candidates[:50]' report.json
jq '.nativeLibraries' report.json
```

资源、assets、静态 STL、非透明 PNG 和未 strip SO 都是优化线索。结合业务所有权、动态访问方式、设备覆盖和 SDK 配置再给删除或替换建议。

## 输出结论

最终分析至少说明：

- 报告是否完整可信。
- 当前是否通过预算，以及最重要的违规。
- 相比基线增长来自哪些文件、分类、包或类。
- 确定性问题和需要产品复核的候选分别是什么。
- 建议动作、预估收益、风险和验证方式。
- AAB Universal 桥接报告必须明确不是 Play 实际下载口径。
