#!/usr/bin/env bash

set -euo pipefail

usage() {
    printf 'Usage: %s <version> [install-directory] [--dry-run]\n' "$0"
}

if [[ $# -lt 1 || $# -gt 3 ]]; then
    usage >&2
    exit 64
fi

version="${1#v}"
install_directory="${2:-$PWD/build/tools/apk-canary}"
dry_run="${3:-}"

if [[ -z "$version" ]]; then
    usage >&2
    exit 64
fi
if [[ -n "$dry_run" && "$dry_run" != "--dry-run" ]]; then
    usage >&2
    exit 64
fi

system_name="$(uname -s)"
machine_name="$(uname -m)"
case "${system_name}:${machine_name}" in
    Linux:x86_64)
        target="linux-x86_64"
        ;;
    Darwin:x86_64)
        target="darwin-x86_64"
        ;;
    Darwin:arm64)
        target="darwin-arm64"
        ;;
    *)
        printf 'Unsupported platform: %s %s\n' "$system_name" "$machine_name" >&2
        exit 69
        ;;
esac

repository="${APK_CANARY_REPOSITORY:-HelloVass/apk-canary}"
download_base_url="${APK_CANARY_DOWNLOAD_BASE_URL:-https://github.com/${repository}/releases/download/v${version}}"
archive="apk-canary-${version}-${target}.tar.gz"

if [[ "$dry_run" == "--dry-run" ]]; then
    printf 'target=%s\n' "$target"
    printf 'archive=%s/%s\n' "$download_base_url" "$archive"
    printf 'checksums=%s/SHA256SUMS\n' "$download_base_url"
    printf 'install=%s/apk-canary\n' "$install_directory"
    exit 0
fi

if ! command -v tar >/dev/null 2>&1; then
    printf 'Required command is unavailable: tar\n' >&2
    exit 69
fi

temporary_directory="$(mktemp -d "${TMPDIR:-/tmp}/apk-canary-install.XXXXXX")"
cleanup() {
    rm -rf "$temporary_directory"
}
trap cleanup EXIT

if command -v gh >/dev/null 2>&1 && gh auth status --hostname github.com >/dev/null 2>&1; then
    gh release download "v${version}" \
        --repo "$repository" \
        --pattern "$archive" \
        --pattern SHA256SUMS \
        --dir "$temporary_directory"
else
    if ! command -v curl >/dev/null 2>&1; then
        printf 'Release download requires gh or curl\n' >&2
        exit 69
    fi
    if ! curl --fail --silent --show-error --location \
        "$download_base_url/$archive" \
        --output "$temporary_directory/$archive"; then
        printf 'Release archive download failed: %s/%s\n' "$download_base_url" "$archive" >&2
        exit 69
    fi
    if ! curl --fail --silent --show-error --location \
        "$download_base_url/SHA256SUMS" \
        --output "$temporary_directory/SHA256SUMS"; then
        printf 'Release checksum download failed: %s/SHA256SUMS\n' "$download_base_url" >&2
        exit 69
    fi
fi

checksum_line="$(awk -v archive="$archive" '$2 == archive || $2 == "*" archive { print; exit }' \
    "$temporary_directory/SHA256SUMS")"
if [[ -z "$checksum_line" ]]; then
    printf 'SHA256SUMS does not contain %s\n' "$archive" >&2
    exit 65
fi

if command -v sha256sum >/dev/null 2>&1; then
    printf '%s\n' "$checksum_line" | (cd "$temporary_directory" && sha256sum --check -)
elif command -v shasum >/dev/null 2>&1; then
    printf '%s\n' "$checksum_line" | (cd "$temporary_directory" && shasum --algorithm 256 --check -)
else
    printf 'Neither sha256sum nor shasum is available\n' >&2
    exit 69
fi

tar -xzf "$temporary_directory/$archive" -C "$temporary_directory"
binary="$temporary_directory/apk-canary-${version}-${target}/apk-canary"
if [[ ! -f "$binary" ]]; then
    printf 'Release archive does not contain the expected binary: %s\n' "$binary" >&2
    exit 65
fi

mkdir -p "$install_directory"
install -m 0755 "$binary" "$install_directory/apk-canary"
expected_version="apk-canary version ${version}"
if ! installed_version="$("$install_directory/apk-canary" --version 2>/dev/null)"; then
    printf 'Installed binary does not support the required --version contract\n' >&2
    exit 65
fi
if [[ "$installed_version" != "$expected_version" ]]; then
    printf 'Installed binary version mismatch: expected "%s", got "%s"\n' \
        "$expected_version" \
        "$installed_version" >&2
    exit 65
fi
printf '%s\n' "$installed_version"
