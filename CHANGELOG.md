# Changelog

## 1.2.0 — 2026-10-13

### Added

- Process-local client state inspection and cleanup with `client_state`, `reset_client_state`, and `reset_memory_state_backend`.
- Optional strict concurrent accounting and `atomic_memory_backend()`, with exclusive ownership and quarantine after uncertain writes.
- `redirects` policy and optional `on_transport_chunk` callbacks on runtimes with readable HTTP collection. Published Kujo 1.5/1.6 retain ordinary calls and reject the callback option before I/O.

### Fixed

- Retain governance, breaker, admission, and trace counters across value-copied client calls.
- Charge completed token/cost usage before budget or structured-output rejection, and recheck budgets before retries.
- Pass original embedding input to native encoders and finalize rejected descriptors without leaking admission slots.
- Preserve streaming cache/reasoning usage metadata across frames without usage.
- Enforce native download limits, prevent redirects under endpoint allowlists, and keep HTTP error envelopes JSON-serializable.
- Revalidate fallback governance overrides before transport or accounting.

### Verification and compatibility

- Full local release gates pass on Kujo 1.5.0 and 1.6.0: 185 Kujo tests each, plus wrapper/HTTP checks, schemas, examples, docs, and benchmarks.
- Minimum Kujo version remains 1.6.0; response, driver, and catalog contracts remain 1.0.0. Existing best-effort accounting and buffered streaming remain supported.
- See [release evidence and runtime requirements](docs/RELEASE_1_2_0.md). The maintainer explicitly waived live-provider smoke for 1.2.0 only; no live-provider result is claimed.

## 1.1.1 — 2026-09-28

- Normalize thrown transport failures, preserve cleanup, and redact credential-bearing provider errors.
- Validate model-catalog identity and shape; retain response and provider-driver contract 1.0.0.
- Add bounded Watchdog metadata mapping without telemetry authority.
- Validate on published Kujo 1.6.0 artifacts; use a pinned checksum-verifying CI installer.
- Live-provider validation deferred for this release only by explicit maintainer authorization; offline and supply-chain gates remain required.


## 1.1.0 - 2026-08-26

- Added provider-driver contract 1.0.0 and additive Kennel exports.
- Added implicit built-in OpenAI-compatible driver resolution without changing legacy APIs.
- Added bounded descriptors, semantic decode boundaries, a fictional native-provider fixture, and adversarial tests.
- Preserved normalized response/model-catalog contract 1.0.0, custom transports, buffered streaming, and operational controls.

This is an additive package release. The provider-driver contract, normalized response contract, and model-catalog contract remain at 1.0.0.

All notable changes to this project will be documented in this file.

The format is based on Keep a Changelog and this project follows semantic versioning for package versions.

## Earlier hardening included in 1.1.1

The entries below were already present in the 1.1.1 source tree.

### Added

- Versioned model-catalog authoring and validation primitives for deterministic orchestrators, plus `scripts/generate_model_catalog.kujo`, a copyable config example, canonical hashing, and duplicate provider/model rejection.
- Launch-readiness Spec and Eval suite for prelaunch review, with live-provider proof kept external unless credentials are explicitly configured and approved.
- Provider-owned `resolve_model_preference(provider, preference)` routing with explicit resolution provenance, provider class mappings, overrides, and deterministic fallback behavior.
- `provider_metadata(provider)` helper returning safe-to-log provider identity and capabilities (never a resolved API key).
- `max_raw_response_bytes` option that rejects oversized provider responses with a deterministic, redacted `response_too_large` error before parsing.
- JSON/structured-output capability validation: requests using `structured_output_schema` or a JSON `response_format` against a provider without `json_mode` now fail fast with `unsupported_feature` before transport.
- High-cardinality streaming reliability coverage and parser/normalization benchmark cases.
- Adoption guide, "build your first provider" walkthrough, and release-candidate checklist docs; v4 enterprise-readiness backlog.

### Security

- Custom headers whose name or value contains CR/LF are dropped during the merge (header-injection / request-smuggling defense), even under protected-override opt-in.
- Endpoint allowlist host matching is now normalized (case-insensitive, trailing-dot tolerant) while still rejecting lookalike hosts.

### Changed

- README readiness wording now scopes AI SDK as a release-candidate-oriented validation baseline rather than a universal production certification.
- Raised release-gate test floors (aggregate floor 61 → 95); total test count grew from 90 to 100.

## [1.0.0] - 2026-06-10

### Added

- Formalized the stable 1.0.0 Kujo SDK release, with release-discipline artifacts and versioning process documentation aligned to the released package metadata.

## [0.1.0]

### Added

- Initial AI SDK release with provider abstractions, normalized contracts, reliability controls, security controls, and CI/release quality gates.
