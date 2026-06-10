#!/usr/bin/env bash
set -euo pipefail

WORKFLOW_FILES=(
	".github/workflows/ci.yml"
	".github/workflows/release-validation.yml"
)

echo "Running supply-chain policy checks..."

for workflow_file in "${WORKFLOW_FILES[@]}"; do
	if [[ ! -f "$workflow_file" ]]; then
		echo "Missing required workflow file: $workflow_file"
		exit 1
	fi

	if ! grep -Eq 'KUJO_RUNTIME_REF:[[:space:]]*"[0-9a-f]{40}"' "$workflow_file"; then
		echo "Missing or invalid KUJO_RUNTIME_REF pin in $workflow_file"
		exit 1
	fi
done

if grep -REn 'uses:[[:space:]]+[^[:space:]]+@(main|master|HEAD)$' .github/workflows/*.yml; then
	echo "Workflow action references must not use floating branch refs (main/master/HEAD)."
	exit 1
fi

invalid_action_refs="$(grep -REn 'uses:[[:space:]]+[^[:space:]]+@[^[:space:]]+' .github/workflows/*.yml | grep -Ev '@[0-9a-f]{40}([[:space:]]*#.*)?$' || true)"
if [[ -n "$invalid_action_refs" ]]; then
	echo "Workflow action references must be pinned to immutable 40-character commit SHAs."
	echo "$invalid_action_refs"
	exit 1
fi

if grep -REn 'http://' .github/workflows/*.yml; then
	echo "Insecure http:// references are not allowed in workflow definitions."
	exit 1
fi

echo "Supply-chain policy checks passed."