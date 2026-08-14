#!/usr/bin/env bash

set -euo pipefail

usage() {
    printf '%s\n' \
        "Usage: $0 --cli <path> --artifact <apk-or-aab> --output <json>" \
        "          [--bundletool <jar>] [-- <additional apk-canary options>]"
}

cli=""
artifact=""
output=""
bundletool=""
additional_options=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        --cli)
            cli="${2:-}"
            shift 2
            ;;
        --artifact)
            artifact="${2:-}"
            shift 2
            ;;
        --output)
            output="${2:-}"
            shift 2
            ;;
        --bundletool)
            bundletool="${2:-}"
            shift 2
            ;;
        --)
            shift
            additional_options=("$@")
            break
            ;;
        *)
            usage >&2
            exit 64
            ;;
    esac
done

if [[ ! -x "$cli" || ! -f "$artifact" || -z "$output" ]]; then
    usage >&2
    exit 64
fi

mkdir -p "$(dirname "$output")"
analysis_artifact="$artifact"
temporary_directory=""

case "$artifact" in
    *.apk|*.APK)
        ;;
    *.aab|*.AAB)
        if [[ ! -f "$bundletool" ]]; then
            printf 'AAB bridge requires --bundletool <bundletool.jar>\n' >&2
            exit 64
        fi
        for command_name in java unzip; do
            if ! command -v "$command_name" >/dev/null 2>&1; then
                printf 'AAB bridge requires command: %s\n' "$command_name" >&2
                exit 69
            fi
        done

        temporary_directory="$(mktemp -d "${TMPDIR:-/tmp}/apk-canary-aab.XXXXXX")"
        cleanup() {
            rm -rf "$temporary_directory"
        }
        trap cleanup EXIT

        printf '%s\n' \
            'Warning: analyzing a Universal APK derived from the AAB; this is not Play download-size analysis.' >&2
        java -jar "$bundletool" validate "--bundle=$artifact"
        java -jar "$bundletool" build-apks \
            "--bundle=$artifact" \
            "--output=$temporary_directory/artifact.apks" \
            --mode=universal \
            --overwrite
        unzip -j -o "$temporary_directory/artifact.apks" universal.apk -d "$temporary_directory"
        analysis_artifact="$temporary_directory/universal.apk"
        ;;
    *)
        printf 'Unsupported artifact type: %s\n' "$artifact" >&2
        exit 65
        ;;
esac

"$cli" analyze "$analysis_artifact" \
    --output "$output" \
    "${additional_options[@]}"
