# Changelog

All notable changes to this project will be documented in this file.

The format is based on Keep a Changelog and this project follows semantic versioning for package versions.

## [Unreleased]

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
