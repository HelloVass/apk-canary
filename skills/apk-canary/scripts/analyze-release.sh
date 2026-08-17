#!/usr/bin/env bash

set -euo pipefail

usage() {
    printf '%s\n' \
        "Usage: $0 --cli <path> --artifact <apk-or-aab> --output <json>" \
        "          [-- <additional apk-canary options>]"
}

cli=""
artifact=""
output=""
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

case "$artifact" in
    *.apk|*.APK|*.aab|*.AAB)
        ;;
    *)
        printf 'Unsupported artifact type: %s\n' "$artifact" >&2
        exit 65
        ;;
esac

"$cli" analyze "$artifact" \
    --output "$output" \
    "${additional_options[@]}"
