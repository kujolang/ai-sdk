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
python3 - <<'PYDOC'
from pathlib import Path
import re

# Repository guides use inline Markdown links. Check local file targets while
# allowing web links and same-page anchors; no network is required.
missing = []
for document in [Path("README.md"), *Path("docs").glob("*.md")]:
    for target in re.findall(r"\]\(([^\s)]+)\)", document.read_text()):
        if "://" in target or target.startswith("#"):
            continue
        if not (document.parent / target.split("#", 1)[0]).exists():
            missing.append(f"{document}: {target}")
if missing:
    raise SystemExit("Missing documentation link targets:\n" + "\n".join(missing))
PYDOC
echo 'Documentation command and local-link checks passed.'
