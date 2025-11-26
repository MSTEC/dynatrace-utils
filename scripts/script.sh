#!/usr/bin/env bash
set -euo pipefail

# Resolve script directory and repository root so paths work regardless of CWD
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
repo_root="$(cd "$script_dir/.." >/dev/null 2>&1 && pwd)"

template="$repo_root/templates/credentials/credential.yml"
cert="$repo_root/certs/prod-cac_base64.cer"
out="$repo_root/file.p7m"

echo "Using template: $template"
echo "Using cert:     $cert"
echo "Output path:    $out"

if [ ! -f "$template" ]; then
	echo "Template file not found: $template" >&2
	exit 1
fi

if [ ! -f "$cert" ]; then
	echo "Certificate file not found: $cert" >&2
	exit 1
fi

echo "Encrypting template..."
openssl smime -encrypt -in "$template" -aes256 -out "$out" -outform pem "$cert"

echo "Created $out"

