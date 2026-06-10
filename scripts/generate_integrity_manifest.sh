#!/usr/bin/env bash
set -euo pipefail

OUTPUT_DIR="${1:-artifacts/security}"
MANIFEST_FILE="$OUTPUT_DIR/integrity-manifest.sha256"

mkdir -p "$OUTPUT_DIR"
: > "$MANIFEST_FILE"

TARGET_FILES=(
	"LICENSE"
	"CHANGELOG.md"
	"README.md"
	"docs/API_CONTRACT_POLICY.md"
	"docs/SDK_IMPROVEMENT_CHECKLIST.md"
	"scripts/release_quality_gates.sh"
	"scripts/verify_contract_schemas.sh"
	"scripts/supply_chain_policy_check.sh"
	"schemas/contracts/1.0.0/chat_success.schema.json"
	"schemas/contracts/1.0.0/error.schema.json"
	"schemas/contracts/1.0.0/embeddings_success.schema.json"
	".github/workflows/ci.yml"
	".github/workflows/release-validation.yml"
	"$OUTPUT_DIR/sbom.spdx.json"
)

for target_file in "${TARGET_FILES[@]}"; do
	if [[ -f "$target_file" ]]; then
		shasum -a 256 "$target_file" >> "$MANIFEST_FILE"
	fi
done

echo "Wrote integrity manifest: $MANIFEST_FILE"