#!/usr/bin/env bash
set -euo pipefail

SCHEMA_DIR="schemas/contracts/1.0.0"

python3 - <<'PY'
import json
from pathlib import Path

schema_dir = Path("schemas/contracts/1.0.0")
required_files = {
    "chat_success.schema.json": {
        "required_top": {"ok", "provider", "contract_version", "request_id", "model", "output_text", "usage", "status_code", "normalized_at", "raw"},
        "ok_const": True,
    },
    "error.schema.json": {
        "required_top": {"ok", "provider", "contract_version", "error", "status_code", "normalized_at", "raw"},
        "ok_const": False,
    },
    "embeddings_success.schema.json": {
        "required_top": {"ok", "provider", "contract_version", "model", "embeddings", "usage", "status_code", "normalized_at", "raw"},
        "ok_const": True,
    },
}

if not schema_dir.exists():
    raise SystemExit(f"Missing schema directory: {schema_dir}")

for file_name, expectations in required_files.items():
    path = schema_dir / file_name
    if not path.exists():
        raise SystemExit(f"Missing schema file: {path}")

    with path.open("r", encoding="utf-8") as f:
        schema = json.load(f)

    if schema.get("$schema") != "https://json-schema.org/draft/2020-12/schema":
        raise SystemExit(f"Schema {path} missing or invalid $schema declaration")

    if schema.get("type") != "object":
        raise SystemExit(f"Schema {path} must declare type=object")

    properties = schema.get("properties")
    if not isinstance(properties, dict):
        raise SystemExit(f"Schema {path} must define object properties")

    required_top = set(schema.get("required", []))
    missing_required = expectations["required_top"] - required_top
    if missing_required:
        raise SystemExit(f"Schema {path} missing required keys: {sorted(missing_required)}")

    ok_property = properties.get("ok", {})
    if ok_property.get("const") is not expectations["ok_const"]:
        raise SystemExit(f"Schema {path} must enforce ok={expectations['ok_const']}")

    contract_version = properties.get("contract_version", {})
    if contract_version.get("const") != "1.0.0":
        raise SystemExit(f"Schema {path} must pin contract_version const to 1.0.0")

print("Contract schemas verified:", ", ".join(sorted(required_files.keys())))
PY

echo "Contract schema verification passed for ${SCHEMA_DIR}."