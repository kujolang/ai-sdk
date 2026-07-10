# API Contract Versioning and Deprecation Policy

## Purpose

This document defines how the AI SDK response contract evolves over time and how deprecations are announced and removed.

## Contract Version Field

All normalized SDK responses include a `contract_version` field.

Current contract version: `1.0.0`

Response types that include `contract_version`:
- chat completion success
- chat completion error
- chat stream final normalized response
- embeddings success
- embeddings error

Machine-readable schemas for the active contract version are maintained under:
- `schemas/contracts/1.0.0/chat_success.schema.json`
- `schemas/contracts/1.0.0/error.schema.json`
- `schemas/contracts/1.0.0/embeddings_success.schema.json`

## Compatibility Policy

The SDK follows semantic contract versioning:
- PATCH (`1.0.x`): bug fixes and clarifications only, no shape-breaking changes
- MINOR (`1.x.0`): additive changes only (new optional fields, new capabilities, new docs)
- MAJOR (`x.0.0`): breaking changes to existing fields, types, or required semantics

## Deprecation Lifecycle

1. Announcement:
- Mark the field/behavior as deprecated in README and this policy file.
- Add migration guidance and replacement behavior.

2. Grace period:
- Keep deprecated behavior available for at least one MINOR release.
- Keep contract tests covering deprecated behavior during grace period.

3. Removal:
- Remove only in the next MAJOR contract version.
- Update README, changelog/readme task log, and tests in the same change.

## Breaking Change Requirements

Any breaking change must include all of the following in one PR:
- MAJOR `contract_version` bump
- updated migration notes in README
- updated compatibility/deprecation notes in this file
- updated machine-readable schema files under `schemas/contracts/<new-version>/`
- updated contract tests reflecting old and new behavior boundaries
- release-validation workflow passing with updated quality gates

## Non-Breaking Additions

The following are allowed in MINOR/PATCH releases:
- new optional metadata keys
- new provider capabilities
- new endpoints that do not alter existing endpoint contracts
- stricter validation that only affects clearly invalid inputs
- additive provider metadata and standalone resolver contracts such as model-preference resolution, provided existing response fields and semantics remain unchanged

## Governance Checklist

Before merging contract-affecting changes:
- confirm whether change is additive or breaking
- update `contract_version` if required
- update README and this policy document
- run `bash scripts/verify_contract_schemas.sh`
- run contract, reliability, parser fuzz, and feature smoke suites
- verify release-validation workflow still passes
