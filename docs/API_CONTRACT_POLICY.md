# API Contract Versioning and Deprecation Policy

## Provider-driver contract

The provider-driver extension contract is independently versioned as `1.0.0`. Its version does not change the normalized response contract (`1.0.0`) or model-catalog contract (`1.0.0`). Provider-native wire changes are additive only when existing factories, exports, transport calls, normalized fields, errors, and stream events remain stable.

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
- additive versioned model-catalog contracts. Catalog entries must preserve unknown operational values as `null`, include provenance supplied by the catalog owner, and remain independent from normalized chat/embedding response versions

## Model Catalog Contract

The standalone `ai-sdk-model-catalog` schema is versioned independently through `model_catalog_contract_version()`. Catalog hashes use deterministic JSON serialization over normalized catalog identity, models, and metadata. Consumers must treat the tuple of catalog ID, catalog version, and catalog hash as routing evidence. Provider presets may publish identity and capability facts, but volatile cost, latency, reliability, and context values must not be invented when unknown.

## Governance Checklist

Before merging contract-affecting changes:
- confirm whether change is additive or breaking
- update `contract_version` if required
- update README and this policy document
- run `bash scripts/verify_contract_schemas.sh`
- run contract, reliability, parser fuzz, and feature smoke suites
- verify release-validation workflow still passes

## September 2026 hardening clarifications

Normalized contract versions, exports, request options, and environment variables are unchanged. Throwing custom transports now produce non-retryable `transport_error` results instead of escaping the SDK; `Ok`/`Err` transport behavior is unchanged. Error diagnostics redact the configured credential. Catalog authoring rejects malformed config shapes before constructor normalization. Distinct provider/model pairs containing `::` resolve independently; their formerly ambiguous ordering is deterministic. Existing unambiguous catalog hashes are preserved.

## October 2026 hardening clarifications

Public signatures, response versions, schemas, configuration and environment variables remain unchanged. Native embedding drivers now receive the supplied input instead of null. Usage-bearing stream frames retain their normalized metadata through subsequent frames without usage. Descriptor rejection includes zero-attempt observability and runs normal chat finalization. Rolling accounting now persists completed usage before rejecting a budget overrun or invalid structured output; a retry rechecks the remaining budget. Existing persistent backends may therefore record higher, more accurate usage for calls previously rejected after provider completion. This does not introduce atomic distributed reservations.

### Process-local state persistence follow-up

`create_client` adds an opaque `_state_id`; its copies share process-local counters. New exports `client_state`, `reset_client_state`, and `reset_memory_state_backend` provide inspection and explicit cleanup. Existing signatures, response shapes, backend key formats, hook precedence, and seed fields are preserved. Dictionary backends retain state per client/namespace; explicit registry IDs share across clients. Caller dictionaries remain seed snapshots. Runtime shared storage works on verified Kujo 1.5.0 and 1.6.0; the declared minimum remains 1.6.0. This additive fix makes sequential budgets, breakers, admission, and traces effective across calls. It does not make compound operations atomic or change persistent-hook failure policy.

### Atomic concurrent accounting follow-up

The additive `governance_mode` option defaults to `best_effort`, preserving existing backends and signatures. Opt-in `strict` requires `acquire(scope, owner)`, `release(scope, owner, healthy)`, `get(key, fallback)` and acknowledged `set(key, value)` hooks. The whole request runs under ownership; failures produce non-retryable `state_backend_error` in the unchanged 1.0.0 error shape. `atomic_memory_backend()` supplies a process-local implementation with atomic admission, owner checking and quarantine after uncertain accounting. Strict mode rejects legacy memory-backend fields and provider fallback; it uses authoritative backend values rather than local seeds. See the README for lifecycle and external fencing requirements. Concurrent lost updates and check/use races are prevented for participants in this contract; legacy best-effort semantics, provider overrun behavior and unknown transport completion remain unchanged.

### Runtime transport follow-up

Native downloads now enforce configured positive raw response limits during reading, with the existing 8 MiB runtime ceiling. Size-limit failures are terminal `response_too_large`. Endpoint allowlist mode disables redirects; the additive `redirects` option otherwise defaults to the previous follow behavior. Raw HTTP error envelopes omit native byte buffers to retain JSON compatibility. Additive `on_transport_chunk` exposes UTF-8-safe observed text on patched runtimes; published 1.5/1.6 reject opt-in collection before I/O while ordinary APIs retain compatibility. Existing normalized streaming callback order is unchanged. See README for callback cancellation, partial delivery and custom transport boundaries.

### Fallback governance validation follow-up

Fallback entry overrides now pass the same mode/backend validation as public calls. Strict mode remains incompatible with a provider fallback chain, including when introduced by an entry override. Unknown modes and atomic-only backends in best-effort mode return terminal `state_backend_error` before fallback transport or accounting. The primary call may already have failed before an invalid fallback is reached. Valid best-effort fallback and the 1.0.0 response shape remain unchanged.
