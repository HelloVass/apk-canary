---
name: apk-canary
description: Analyze APK/AAB artifacts and enforce Android size gates.
license: BSD-3-Clause
metadata:
  hermes:
    tags: [android, apk, aab, size, ci]
    category: devops
---

# APK Canary

Use APK Canary as the deterministic analyzer and use the Agent to orchestrate builds, preserve compact JSON, write a structured Markdown analysis, explain findings, and propose product-specific actions.

This Skill supports Codex and Hermes Agent on Linux and macOS from the same directory. In Codex, resolve linked files and commands relative to the Skill directory shown by the loader. Hermes exposes the same directory and also supports `${HERMES_SKILL_DIR}`. Do not copy only `SKILL.md`; the scripts, references, and workflow asset are part of the Skill.

Use this Skill for APK or AAB size, DEX, resources, assets, PNG, native libraries, mapping or `R.txt` restoration, baseline changes, budgets, and APK Canary CI integration. Always treat `delivery.downloadSize` as the primary size metric: APK uses apkanalyzer-equivalent gzip -9 estimation, while AAB uses embedded bundletool APKS delivery estimation. Artifact and Universal APK sizes are secondary diagnostics.

## Choose the workflow

1. For an APK local path, APK download URL, or Android project that produces APK/AAB artifacts, read [references/local-analysis.md](references/local-analysis.md).
2. For an AAB local path or download URL, especially when it is the only artifact, read [references/aab-only-analysis.md](references/aab-only-analysis.md). Inspect and use its embedded mapping before analysis.
3. For GitHub Actions integration or release gating, read [references/ci-gate.md](references/ci-gate.md).
4. For a compact report that needs interpretation, read [references/report-reading.md](references/report-reading.md).
5. For every interactive APK/AAB analysis, read [references/markdown-report.md](references/markdown-report.md) and fill [assets/analysis-report-template.md](assets/analysis-report-template.md). Deliver both JSON and Markdown.

Never present Universal APK content totals as a single-device Play download.

## Preserve artifact integrity

- Use the APK/AAB, `mapping.txt`, and numeric `R.txt` from the same variant and build invocation.
- Never substitute AGP `resources.txt` for `R.txt`.
- Keep business APKs, mappings, symbol tables, baselines, budgets, and reports out of source control unless the repository explicitly provides a safe fixture policy.
- Generate compact JSON. Do not add HTML report generation or interpretation logic to CI.
- Treat JSON as the machine protocol. For interactive analysis, write the Markdown interpretation beside it without modifying the JSON.
- Archive the JSON even when a budget gate fails; distinguish exit code `2` from analyzer failures.
- Treat static unused resources/assets and optimization candidates as review leads, not deletion proof.

## Acquire the CLI

Prefer a pinned GitHub Release and verify `SHA256SUMS`. Run:

```shell
scripts/install-cli.sh 1.5.0-alpha.1 build/tools/apk-canary
build/tools/apk-canary/apk-canary --version
```

The installer downloads the pinned public GitHub Release and verifies `SHA256SUMS`. It prefers an authenticated `gh` client when available and otherwise uses anonymous HTTPS.

When working inside the APK Canary source repository, build the local distribution instead:

```shell
./cli/gradlew -p cli clean check installDist
```

Do not silently switch between a source build and a released binary; record the selected version in the report or handoff.

## Run an analysis

For a direct APK, invoke the CLI without a wrapper:

```shell
apk-canary analyze app-release.apk \
  --mapping mapping.txt \
  --r-txt R.txt \
  --product product-id \
  --variant release \
  --channel google-play \
  --output build/reports/apk-canary/report.json
```

For AAB, invoke the same CLI directly or use [scripts/analyze-release.sh](scripts/analyze-release.sh) as a thin artifact wrapper:

```shell
apk-canary analyze app-release.aab \
  --mapping mapping.txt \
  --r-txt R.txt \
  --device-spec device-spec.json \
  --output build/reports/apk-canary/report.json
```

When the AAB is the only artifact or arrives as a URL, follow [references/aab-only-analysis.md](references/aab-only-analysis.md): localize the AAB, extract its embedded `proguard.map` when present, and pass it through `--mapping`.

Read `delivery.downloadSize` first for both inputs. For AAB, read `bundleDelivery` for bundletool and derived artifact provenance, then treat `summary` and content rules as Universal APK results containing all ABIs, languages, and densities.

After any interactive APK/AAB run, follow [references/markdown-report.md](references/markdown-report.md), copy [assets/analysis-report-template.md](assets/analysis-report-template.md), and save `<artifact-stem>-apk-canary-analysis.md` beside the JSON. CI-only gates continue to archive compact JSON unless the user explicitly asks for Markdown.

## Add a CI gate

Start from [assets/github-actions/apk-canary.yml](assets/github-actions/apk-canary.yml), then adapt the variant, artifact paths, product identity, baseline source, and product-owned `config/apk-canary/budget.json`. Copy [scripts/install-cli.sh](scripts/install-cli.sh) into the product repository if the workflow references it. Do not commit the template with placeholder paths or product identifiers.

Keep the sequence strict:

1. Build the product artifact and its symbols.
2. Run APK Canary against those exact outputs.
3. Archive the JSON with `if: always()`.
4. Upload or publish the release artifact only after the analyzer exits successfully.

## Complete the task

- Confirm `apk-canary --version` and report `tool.version` match the pinned version.
- Confirm `schemaVersion`, artifact identity, input fingerprints, rule statuses, and diagnostics before discussing size findings.
- For interactive APK/AAB analysis, deliver the original JSON and a fully populated Markdown analysis with no template placeholders.
- Report which checks are deterministic and which findings require product review.
- When modifying this repository, follow the root `AGENTS.md`, update `cli/docs/CAPABILITY_GAP.md`, run the repository quality gate, and keep implementation, tests, docs, and report schema aligned.
