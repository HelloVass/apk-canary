# 本地分析工作流

## 目录

- APK 输入
- AAB 过渡路径
- 制品收集
- 执行与验收

## APK 输入

优先分析产品实际生成的 release APK。确保 APK、R8/ProGuard `mapping.txt` 和带十六进制 resource ID 的完整 `R.txt` 来自同一个 variant 和构建。

先运行 `apk-canary --version`，再执行 `apk-canary analyze`。默认保留完整报告；文件阈值和后缀选项只用于报告中的附加查询视图，不能替代全量规则输入。

## AAB 过渡路径

当前 CLI 不原生解析 AAB。产品只产生 AAB 时，可以临时使用 `scripts/analyze-release.sh`：

```shell
scripts/analyze-release.sh \
  --cli build/tools/apk-canary/apk-canary \
  --artifact app-release.aab \
  --bundletool build/bundletool.jar \
  --output build/reports/apk-canary/report.json \
  -- \
  --mapping mapping.txt \
  --r-txt R.txt \
  --product product-id \
  --variant release \
  --channel google-play
```

该路径从待发布 AAB 生成 Universal APK，因此比单独执行 `assembleRelease` 更能保证制品同源，但存在以下边界：

- Universal APK 包含全部 ABI、语言和密度，不能代表单个用户的 Play 下载大小。
- 多 ABI 在 Universal APK 中是预期结果，不应直接作为失败条件。
- 报告输入指纹属于衍生 APK；必须在 CI artifact 元数据中同时保存原始 AAB 的 SHA-256。
- 动态 Feature、Asset Pack 和设备 Split 聚合不属于当前能力。

不得把这条路径描述为原生 AAB 分析。正式能力需要 CLI 解析 Bundle 模块和 `resources.pb`，并聚合设备级 `.apks`。

## 制品收集

- `mapping.txt` 用于恢复 DEX 类身份和归因。
- 数值 `R.txt` 用于按 resource ID 恢复原始资源名，并区分 shrinker 删除项。
- `resources.txt` 不是输入。
- 缺少 `R.txt` 时仍可分析 APK，但资源名称恢复和依赖该符号表的门禁必须明确跳过或失败。

AGP 中间目录随版本变化。优先在产品工程中增加归档任务，把最终 APK/AAB、mapping 和 `R.txt` 复制到稳定输出目录，避免 Skill 猜测内部路径。

## 执行与验收

1. 校验工具版本和输入文件存在且非空。
2. 生成紧凑 JSON。
3. 先检查 schema、输入指纹、规则状态和 diagnostics。
4. 再读取 gate、comparison 和各专项结果。
5. 对静态候选结合反射、WebView、Native、服务端配置和动态下发策略复核。
