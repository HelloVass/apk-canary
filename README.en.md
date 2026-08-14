# APK Canary

[中文](README.md) | [English](README.en.md)

This is the public distribution repository for APK Canary. It publishes standalone Linux and macOS CLIs, a JVM fallback, SHA-256 checksums, and one APK analysis Skill compatible with both Codex and Hermes Agent.

APK Canary reads an APK together with the matching `mapping.txt` and numeric-ID `R.txt`, then emits versioned compact JSON for agents and CI. It covers the manifest, ZIP entries, DEX, resources, assets, PNG files, native libraries, duplicate content, baseline changes, and budget gates. It does not generate HTML or embed product-specific report interpretation in CI.

## Current release

- Version: `1.4.0-alpha.2`
- Source commit: `2ddeac4eba9956aefa5f0dd5f06d2566f10d4175`
- Release: [`v1.4.0-alpha.2`](https://github.com/HelloVass/apk-canary/releases/tag/v1.4.0-alpha.2)
- Checksums: [`SHA256SUMS`](https://github.com/HelloVass/apk-canary/releases/download/v1.4.0-alpha.2/SHA256SUMS)

## CLI artifacts

| OS | CPU | Release asset |
|---|---|---|
| Linux | x86_64 | `apk-canary-1.4.0-alpha.2-linux-x86_64.tar.gz` |
| macOS | Intel | `apk-canary-1.4.0-alpha.2-darwin-x86_64.tar.gz` |
| macOS | Apple Silicon | `apk-canary-1.4.0-alpha.2-darwin-arm64.tar.gz` |
| Any Java 17-capable system | JVM | `apk-canary-1.4.0-alpha.2-jvm.tar` |

The standalone CLI does not require a local JDK, Android SDK, AAPT2, or `apkanalyzer`.

### Install the standalone CLI

```shell
curl --fail --location --output install-apk-canary.sh \
  https://raw.githubusercontent.com/HelloVass/apk-canary/main/skills/apk-canary/scripts/install-cli.sh
chmod +x install-apk-canary.sh
./install-apk-canary.sh 1.4.0-alpha.2 "$HOME/.local/bin"
$HOME/.local/bin/apk-canary --version
```

The installer selects the current OS and CPU architecture, downloads the pinned version, and verifies `SHA256SUMS` before installation.

## Agent Skill

[`skills/apk-canary`](skills/apk-canary/SKILL.md) is the single Skill distribution source. Each Release also contains `apk-canary-1.4.0-alpha.2-skills.tar.gz` for offline installation.

### Codex

Ask Skill Installer in Codex to install the public directory:

```text
Use $skill-installer to install https://github.com/HelloVass/apk-canary/tree/main/skills/apk-canary
```

For a project-local installation, copy the directory to `.agents/skills/apk-canary/`.

### Hermes Agent

Add this repository as a Hermes tap, then install the Skill:

```shell
hermes skills tap add HelloVass/apk-canary
hermes skills install HelloVass/apk-canary/apk-canary
```

Alternatively, install the single Skill directly:

```shell
hermes skills install HelloVass/apk-canary/skills/apk-canary
```

## Analyze an APK

```shell
apk-canary analyze app-release.apk \
  --mapping mapping.txt \
  --r-txt R.txt \
  --product product-id \
  --variant release \
  --channel google-play \
  --output build/reports/apk-canary/report.json
```

- `mapping.txt` restores class identities before R8/ProGuard obfuscation.
- A numeric-ID `R.txt` restores original resource names by ID and identifies entries removed by the shrinker.
- AGP `resources.txt` is not an input.
- Native analysis currently targets APKs. The Skill includes a transitional AAB-to-Universal-APK workflow, but that is not native AAB/APKS or Play download-size analysis.

## Verify artifacts

```shell
shasum -a 256 -c SHA256SUMS
```

## License and attribution

APK Canary is a Kotlin reimplementation inspired by Tencent Matrix APKChecker. The distribution is available under the [BSD 3-Clause License](LICENSE); see [NOTICE](NOTICE) for upstream attribution and project status. This project is independently maintained and is not affiliated with or endorsed by Tencent.
