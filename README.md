# APK Canary

[中文](README.md) | [English](README.en.md)

这是 APK Canary 的公开分发仓库。这里发布可独立运行的 Linux、macOS CLI、JVM 兼容包、SHA-256 清单，以及同时兼容 Codex 与 Hermes Agent 的 APK 分析 Skill。

APK Canary 读取 APK、同次构建的 `mapping.txt` 和带数字资源 ID 的 `R.txt`，生成适合 Agent 与 CI 消费的版本化紧凑 JSON。它覆盖 Manifest、ZIP 文件、DEX、资源、assets、PNG、Native Library、重复内容、基线变化和预算门禁；不生成 HTML，也不会在 CI 中替产品解释报告。

## 当前版本

- Version: `1.4.0-alpha.2`
- Source commit: `2ddeac4eba9956aefa5f0dd5f06d2566f10d4175`
- Release: [`v1.4.0-alpha.2`](https://github.com/HelloVass/apk-canary/releases/tag/v1.4.0-alpha.2)
- Checksums: [`SHA256SUMS`](https://github.com/HelloVass/apk-canary/releases/download/v1.4.0-alpha.2/SHA256SUMS)

## CLI 产物

| 系统 | CPU | Release asset |
|---|---|---|
| Linux | x86_64 | `apk-canary-1.4.0-alpha.2-linux-x86_64.tar.gz` |
| macOS | Intel | `apk-canary-1.4.0-alpha.2-darwin-x86_64.tar.gz` |
| macOS | Apple Silicon | `apk-canary-1.4.0-alpha.2-darwin-arm64.tar.gz` |
| 任意支持 Java 17 的系统 | JVM | `apk-canary-1.4.0-alpha.2-jvm.tar` |

独立 CLI 不要求本机安装 JDK、Android SDK、AAPT2 或 `apkanalyzer`。

### 安装独立 CLI

```shell
curl --fail --location --output install-apk-canary.sh \
  https://raw.githubusercontent.com/HelloVass/apk-canary/main/skills/apk-canary/scripts/install-cli.sh
chmod +x install-apk-canary.sh
./install-apk-canary.sh 1.4.0-alpha.2 "$HOME/.local/bin"
$HOME/.local/bin/apk-canary --version
```

安装脚本根据当前系统选择 CPU 架构，下载固定版本，并在安装前验证 `SHA256SUMS`。

## Agent Skill

公开仓中的 [`skills/apk-canary`](skills/apk-canary/SKILL.md) 是唯一 Skill 分发源；Release 同时提供 `apk-canary-1.4.0-alpha.2-skills.tar.gz` 供离线安装。

### Codex

在 Codex 中让 Skill Installer 安装以下公开目录：

```text
使用 $skill-installer 安装 https://github.com/HelloVass/apk-canary/tree/main/skills/apk-canary
```

项目级安装也可以把该目录复制到项目的 `.agents/skills/apk-canary/`。

### Hermes Agent

把仓库作为 Hermes tap 添加后安装：

```shell
hermes skills tap add HelloVass/apk-canary
hermes skills install HelloVass/apk-canary/apk-canary
```

也可以直接安装单个 Skill：

```shell
hermes skills install HelloVass/apk-canary/skills/apk-canary
```

## 分析 APK

```shell
apk-canary analyze app-release.apk \
  --mapping mapping.txt \
  --r-txt R.txt \
  --product product-id \
  --variant release \
  --channel google-play \
  --output build/reports/apk-canary/report.json
```

- `mapping.txt` 用于恢复 R8/ProGuard 混淆前的类身份。
- 数值 `R.txt` 用于按资源 ID 恢复原始资源名并识别 shrinker 删除项。
- AGP `resources.txt` 不是输入。
- 当前原生分析对象是 APK。Skill 提供 AAB→Universal APK 的过渡流程，但它不等于原生 AAB/APKS 或 Play 下载体积分析。

## 校验产物

```shell
shasum -a 256 -c SHA256SUMS
```

## 许可与归属

APK Canary 是受 Tencent Matrix APKChecker 启发的 Kotlin 重写。分发内容遵循 [BSD 3-Clause License](LICENSE)，上游归属与项目关系见 [NOTICE](NOTICE)。本项目由社区独立维护，不隶属于腾讯，也未获得腾讯背书。
