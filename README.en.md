# APK Canary

[中文](README.md) | [English](README.en.md)

This is the public distribution repository for APK Canary. It publishes standalone Linux and macOS CLIs, SHA-256 checksums, and one APK analysis Skill compatible with both Codex and Hermes Agent.

APK Canary reads an APK or AAB together with the matching `mapping.txt` and numeric-ID `R.txt`, then emits versioned compact JSON for agents and CI. User download size is the primary metric: APK uses a gzip -9 estimate equivalent to official apkanalyzer semantics, while AAB uses embedded bundletool's APKS delivery range. Artifact and Universal APK sizes remain secondary content diagnostics. The tool also covers the manifest, ZIP entries, DEX, resources, assets, PNG files, native libraries, duplicate content, baseline changes, and budget gates.

## Current release

- Version: `1.5.0-alpha.1`
- Source commit: `bd9b6f1c33d973fc46f0b85ed7083197ab36e965`
- Release: [`v1.5.0-alpha.1`](https://github.com/HelloVass/apk-canary/releases/tag/v1.5.0-alpha.1)
- Checksums: [`SHA256SUMS`](https://github.com/HelloVass/apk-canary/releases/download/v1.5.0-alpha.1/SHA256SUMS)

## CLI artifacts

| OS | CPU | Release asset |
|---|---|---|
| Linux | x86_64 | `apk-canary-1.5.0-alpha.1-linux-x86_64.tar.gz` |
| macOS | Intel | `apk-canary-1.5.0-alpha.1-darwin-x86_64.tar.gz` |
| macOS | Apple Silicon | `apk-canary-1.5.0-alpha.1-darwin-arm64.tar.gz` |

The standalone CLI does not require a local JDK, Android SDK, AAPT2, or `apkanalyzer`.

### Install the standalone CLI

```shell
curl --fail --location --output install-apk-canary.sh \
  https://raw.githubusercontent.com/HelloVass/apk-canary/main/skills/apk-canary/scripts/install-cli.sh
chmod +x install-apk-canary.sh
./install-apk-canary.sh 1.5.0-alpha.1 "$HOME/.local/bin"
$HOME/.local/bin/apk-canary --version
```

The installer selects the current OS and CPU architecture, downloads the pinned version, and verifies `SHA256SUMS` before installation.

## Agent Skill

[`skills/apk-canary`](skills/apk-canary/SKILL.md) is the single Skill distribution source. Each Release also contains `apk-canary-1.5.0-alpha.1-skills.tar.gz` for offline installation.

The Skill orchestrates an APK/AAB supplied as a local path or download URL: prepare matching mapping and `R.txt` inputs, run the CLI to preserve compact JSON, validate it, and deliver a structured Markdown analysis from the bundled template. JSON remains the only machine protocol and CI gate input; Markdown explains download size, composition, changes, candidate risks, and optimization priorities to developers.

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

## Analyze an APK or AAB

```shell
apk-canary analyze app-release.apk \
  --mapping mapping.txt \
  --r-txt R.txt \
  --product product-id \
  --variant release \
  --channel google-play \
  --output build/reports/apk-canary/report.json
```

AAB uses the same command and does not require a separate bundletool, AAPT2, or JDK installation:

```shell
apk-canary analyze app-release.aab \
  --mapping mapping.txt \
  --r-txt R.txt \
  --device-spec device-spec.json \
  --output build/reports/apk-canary/report.json
```

- `mapping.txt` restores class identities before R8/ProGuard obfuscation.
- A numeric-ID `R.txt` restores original resource names by ID and identifies entries removed by the shrinker.
- AGP `resources.txt` is not an input.
- Read `delivery.downloadSize` first for both APK and AAB. APK uses a single gzip -9 estimate; AAB uses bundletool's estimated compressed Split APK delivery range. `summary.apkBytes` is only the APK file or Universal APK file size and must not replace the user download metric.

## Verify artifacts

```shell
shasum -a 256 -c SHA256SUMS
```

## License and attribution

APK Canary is a Kotlin reimplementation inspired by Tencent Matrix APKChecker. Project code is available under the [BSD 3-Clause License](LICENSE); see [NOTICE](NOTICE) for upstream and embedded bundletool attribution. Standalone CLI archives also include bundletool's original LICENSE and NOTICE. This project is independently maintained and is not affiliated with or endorsed by Tencent or Google.
