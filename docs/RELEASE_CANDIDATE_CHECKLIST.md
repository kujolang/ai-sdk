# Release Candidate Checklist

A single, copy-pasteable sequence for validating a release candidate locally
before tagging. Run every command from the repository root.

## 0. Select the Runtime

```bash
export KUJO_BIN="${KUJO_BIN:-kujo}"
./kujo test-run --help >/dev/null
```

If the help command fails, fix `KUJO_BIN` before continuing.

## 1. Update Version and Notes

- [ ] Bump `version` in `kennel.toml` and `kujo.toml` (keep them aligned).
- [ ] Add release notes under the matching version heading in `CHANGELOG.md`.
- [ ] If response contracts changed, apply `docs/API_CONTRACT_POLICY.md` and update
      contract tests and `schemas/contracts/<version>/` accordingly.

## 2. Supply-Chain Policy

```bash
bash scripts/supply_chain_policy_check.sh
```

## 3. Contract Schema Verification

```bash
bash scripts/verify_contract_schemas.sh
```

## 4. Full Release Quality Gate

This runs every test suite with its minimum floor, the benchmark quality gate,
schema verification, and the canonical examples, and fails on any type-checking
warning.

```bash
bash scripts/release_quality_gates.sh
```

Expected tail: `Release quality gates passed with aggregate test count: <N>.`

## 5. Canonical Examples

```bash
./kujo run examples/main.kujo
./kujo run examples/production_profile.kujo
./kujo run examples/telemetry_bridge.kujo --interpreter
```

## 6. Live-Provider Smoke Evidence

Release/prerelease validation requires at least one configured provider secret so
the live smoke test produces real evidence:

```bash
export OPENAI_API_KEY="..."   # or DEEPSEEK_API_KEY / OPENROUTER_API_KEY
./kujo test-run tests/live_provider_smoke_tests.kujo
```

With no key configured, the smoke test exits as a documented skip. Manual
`workflow_dispatch` runs may set `allow_live_provider_skip=true` for non-release
paths only.

## 7. Tag and Publish

- [ ] Commit version + changelog changes.
- [ ] Push and confirm CI (`ci.yml`), compatibility matrix, and release-validation
      workflows pass.
- [ ] Publish the GitHub release; release validation publishes the SBOM and
      integrity manifest and attaches build-provenance attestation.

## Quick Sequence (No Checkboxes)

```bash
export KUJO_BIN="${KUJO_BIN:-kujo}"
bash scripts/supply_chain_policy_check.sh
bash scripts/verify_contract_schemas.sh
bash scripts/release_quality_gates.sh
./kujo run examples/main.kujo
./kujo run examples/production_profile.kujo
```
