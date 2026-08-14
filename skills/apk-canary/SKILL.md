---
name: apk-canary
description: Analyze APK artifacts and enforce Android size gates.
license: BSD-3-Clause
metadata:
  hermes:
    tags: [android, apk, size, ci]
    category: devops
---

# APK Canary

Use APK Canary as the deterministic analyzer and use the Agent to orchestrate builds, read JSON, explain findings, and propose product-specific actions.

This Skill supports Codex and Hermes Agent on Linux and macOS from the same directory. In Codex, resolve linked files and commands relative to the Skill directory shown by the loader. Hermes exposes the same directory and also supports `${HERMES_SKILL_DIR}`. Do not copy only `SKILL.md`; the scripts, references, and workflow asset are part of the Skill.

Use this Skill for APK size, DEX, resources, assets, PNG, native libraries, mapping or `R.txt` restoration, baseline changes, budgets, and APK Canary CI integration. Also use it for an AAB release pipeline only when the explicitly limited AAB-to-Universal-APK bridge is acceptable.

## Choose the workflow

1. For an APK or Android project that produces APKs, read [references/local-analysis.md](references/local-analysis.md).
2. For GitHub Actions integration or release gating, read [references/ci-gate.md](references/ci-gate.md).
3. For a compact report that needs interpretation, read [references/report-reading.md](references/report-reading.md).
4. For an AAB-only release pipeline, read the AAB bridge section in [references/local-analysis.md](references/local-analysis.md) before running anything. Never present the bridge report as native AAB or Play download-size analysis.

## Preserve artifact integrity

- Use the APK, `mapping.txt`, and numeric `R.txt` from the same variant and build invocation.
- Never substitute AGP `resources.txt` for `R.txt`.
- Keep business APKs, mappings, symbol tables, baselines, budgets, and reports out of source control unless the repository explicitly provides a safe fixture policy.
- Generate compact JSON. Do not add HTML report generation or interpretation logic to CI.
- Archive the JSON even when a budget gate fails; distinguish exit code `2` from analyzer failures.
- Treat static unused resources/assets and optimization candidates as review leads, not deletion proof.

## Acquire the CLI

Prefer a pinned GitHub Release and verify `SHA256SUMS`. Run:

```shell
scripts/install-cli.sh 1.4.0-alpha.3 build/tools/apk-canary
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

For an AAB-only pipeline, use [scripts/analyze-release.sh](scripts/analyze-release.sh) only as a temporary Universal APK bridge. The script validates the bundle, generates `universal.apk`, and invokes the current APK analyzer.

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
- Report which checks are deterministic and which findings require product review.
- When modifying this repository, follow the root `AGENTS.md`, update `cli/docs/CAPABILITY_GAP.md`, run the repository quality gate, and keep implementation, tests, docs, and report schema aligned.
