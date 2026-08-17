# APK Canary

[中文](README.md) | [English](README.en.md)

这是 APK Canary 的公开分发仓库。这里发布可独立运行的 Linux、macOS CLI、SHA-256 清单，以及同时兼容 Codex 与 Hermes Agent 的 APK 分析 Skill。

APK Canary 读取 APK 或 AAB、同次构建的 `mapping.txt` 和带数字资源 ID 的 `R.txt`，生成适合 Agent 与 CI 消费的版本化紧凑 JSON。它把用户下载大小作为一级指标：APK 使用官方 apkanalyzer 等价的 gzip -9 估算，AAB 使用内嵌 bundletool 的 APKS 交付范围；文件自身和 Universal APK 大小只作为内容诊断。工具还覆盖 Manifest、ZIP 文件、DEX、资源、assets、PNG、Native Library、重复内容、基线变化和预算门禁。

## 当前版本

- Version: `1.5.0-alpha.2`
- Source commit: `f501db954e4daa855009226a2cdd8cd494686ab8`
- Release: [`v1.5.0-alpha.2`](https://github.com/HelloVass/apk-canary/releases/tag/v1.5.0-alpha.2)
- Checksums: [`SHA256SUMS`](https://github.com/HelloVass/apk-canary/releases/download/v1.5.0-alpha.2/SHA256SUMS)

## CLI 产物

| 系统 | CPU | Release asset |
|---|---|---|
| Linux | x86_64 | `apk-canary-1.5.0-alpha.2-linux-x86_64.tar.gz` |
| macOS | Intel | `apk-canary-1.5.0-alpha.2-darwin-x86_64.tar.gz` |
| macOS | Apple Silicon | `apk-canary-1.5.0-alpha.2-darwin-arm64.tar.gz` |

独立 CLI 不要求本机安装 JDK、Android SDK、AAPT2 或 `apkanalyzer`。

### 安装独立 CLI

```shell
curl --fail --location --output install-apk-canary.sh \
  https://raw.githubusercontent.com/HelloVass/apk-canary/main/skills/apk-canary/scripts/install-cli.sh
chmod +x install-apk-canary.sh
./install-apk-canary.sh 1.5.0-alpha.2 "$HOME/.local/bin"
$HOME/.local/bin/apk-canary --version
```

安装脚本根据当前系统选择 CPU 架构，下载固定版本，并在安装前验证 `SHA256SUMS`。

安装完成后，Native CLI 可以检查或升级自身；自动模式按 SemVer 只升级、不降级，显式 `--version` 才允许
切换旧版本。每次仍会下载并验证 Release 的 `SHA256SUMS`，且只在候选二进制版本校验成功后执行原子替换：

```shell
apk-canary update --check
apk-canary update
apk-canary update --version 1.5.0-alpha.2
```

## Agent Skill

公开仓中的 [`skills/apk-canary`](skills/apk-canary/SKILL.md) 是唯一 Skill 分发源；Release 同时提供 `apk-canary-1.5.0-alpha.2-skills.tar.gz` 供离线安装。

Skill 会编排本地路径或下载链接形式的 APK/AAB：准备同次 mapping 与 `R.txt`、调用 CLI 生成紧凑 JSON、校验报告后按固定模板交付 Markdown 分析文档。JSON 仍是唯一机器协议和 CI 门禁输入；Markdown 用于向研发解释下载大小、组成、变化、候选风险与优化优先级。

### CLI 直接安装（推荐）

把与 CLI 同版本的完整 Skill 安装到当前项目，或安装到用户级共享 Agent Skills 目录：

```shell
apk-canary init .
apk-canary skills install --user
apk-canary skills list
```

项目级路径为 `.agents/skills/apk-canary`，用户级路径为 `~/.agents/skills/apk-canary`。CLI 下载同版本
`apk-canary-1.5.0-alpha.2-skills.tar.gz` 并验证 `SHA256SUMS`。受管元数据会记录内容摘要；升级或删除若发现
目录不是 CLI 创建，或安装后已被人工修改，会拒绝覆盖，只有显式 `--force` 才继续。

### Codex

不方便先安装 CLI 时，也可在 Codex 中让 Skill Installer 安装以下公开目录：

```text
使用 $skill-installer 安装 https://github.com/HelloVass/apk-canary/tree/main/skills/apk-canary
```

项目级安装也可以把该目录复制到项目的 `.agents/skills/apk-canary/`。

### Hermes Agent

不使用 CLI 受管安装时，可把仓库作为 Hermes tap 添加后安装：

```shell
hermes skills tap add HelloVass/apk-canary
hermes skills install HelloVass/apk-canary/apk-canary
```

也可以直接安装单个 Skill：

```shell
hermes skills install HelloVass/apk-canary/skills/apk-canary
```

## 分析 APK 或 AAB

```shell
apk-canary analyze app-release.apk \
  --mapping mapping.txt \
  --r-txt R.txt \
  --product product-id \
  --variant release \
  --channel google-play \
  --output build/reports/apk-canary/report.json
```

AAB 使用同一个命令，无需另装 bundletool、AAPT2 或 JDK：

```shell
apk-canary analyze app-release.aab \
  --mapping mapping.txt \
  --r-txt R.txt \
  --device-spec device-spec.json \
  --output build/reports/apk-canary/report.json
```

- `mapping.txt` 用于恢复 R8/ProGuard 混淆前的类身份。
- 数值 `R.txt` 用于按资源 ID 恢复原始资源名并识别 shrinker 删除项。
- AGP `resources.txt` 不是输入。
- APK 与 AAB 都先读取 `delivery.downloadSize`。APK 是 gzip -9 单值估算；AAB 是 bundletool 基于 Split APK 的预计压缩下载范围。`summary.apkBytes` 只是 APK 文件或 Universal APK 文件大小，不能替代用户下载大小。

## 校验产物

```shell
shasum -a 256 -c SHA256SUMS
```

## 许可与归属

APK Canary 是受 Tencent Matrix APKChecker 启发的 Kotlin 重写。项目代码遵循 [BSD 3-Clause License](LICENSE)，上游及内嵌 bundletool 归属见 [NOTICE](NOTICE)；独立 CLI 包同时附带 bundletool 的原始 LICENSE 与 NOTICE。本项目由社区独立维护，不隶属于腾讯或 Google，也未获得其背书。
