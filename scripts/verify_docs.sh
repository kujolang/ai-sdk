#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
for path in docs/PROVIDER_EXTENSION_GUIDE.md docs/API_CONTRACT_POLICY.md src/ai_sdk.kujo src/providers.kujo; do
 test -f "$path"
done
for command in 'kujo run examples/main.kujo' 'kujo run scripts/stress_harness.kujo' 'kujo --version'; do
 grep -Fq "$command" README.md
done
if grep -Eq '/Users/[^[:space:]]+/2026/' README.md docs/PROVIDER_EXTENSION_GUIDE.md; then
 echo 'Found machine-specific runtime paths in public docs.' >&2
 exit 1
fi
echo 'Documentation command checks passed.'
