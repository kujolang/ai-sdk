# AI SDK Enterprise Readiness v3 Checklist

## Intent

This is the next-session worklist for moving AI SDK from a strong enterprise-hardening baseline toward a showcase-grade SDK for Kujo.

## Current Assessment

Status: Strong enterprise baseline, still requiring deployment-specific validation before production use.

What is solid now:
- Source layout is organized around `src/`, with examples, scripts, tests, schemas, docs, and workflows in dedicated folders.
- Chat, streaming, and embeddings share normalized contracts, fixture mode, retries, fallbacks, observability hooks, endpoint policy, and governance budget controls.
- Release gates include contract, resilience, embeddings, security, reliability, parser, feature, live-provider, schema, benchmark, and supply-chain checks.
- README now presents a clearer production-readiness position and root/project structure map.

Recent hardening added:
- Case-insensitive protected-header handling for common `Authorization` and `Content-Type` casing variants.
- Redaction false-positive reduction for non-secret token-count governance fields.
- Chat request-context precomputation before retry loops.
- Embeddings governance budget parity for per-request, rolling token, and rolling cost controls.
- New tests and release-gate floors for those behaviors.

## Agent Operating Rules

For each v3 task:
1. Pick one unchecked task with no open dependency.
2. Mark it In Progress before implementation.
3. Keep changes backward-compatible unless the task explicitly requires a contract bump.
4. Add tests and README/docs updates in the same change.
5. Run the relevant suite plus `bash scripts/release_quality_gates.sh`.
6. Add a dated Session Log entry with commands and outcomes.

## Status Legend

- Todo
- In Progress
- Done
- Blocked

## Lane A: Performance and Scale

- [ ] V3-PERF-01 Split `src/ai_sdk.kujo` into focused internal modules if Kujo package ergonomics allow it
Status: Todo
Priority: P1
Dependencies: None
Why:
- The core module is now large enough that onboarding and review speed may suffer.
Acceptance:
- Public exports remain backward-compatible.
- README import examples still work.
- Contract and release gates pass.

- [ ] V3-PERF-02 Add benchmark cases for full injected-transport chat and embeddings request loops
Status: Todo
Priority: P1
Dependencies: None
Why:
- Current benchmark guardrails cover fixture normalization and retry-delay paths, but not full request-context and parser hot paths.
Acceptance:
- Benchmark script includes successful injected transport for chat and embeddings.
- Thresholds are strict enough to catch regressions while stable locally and in CI.

- [ ] V3-PERF-03 Add high-cardinality streaming stress coverage
Status: Todo
Priority: P2
Dependencies: None
Why:
- Streaming normalization and callback emission should be validated under many small delta chunks.
Acceptance:
- Stress or reliability suite includes a large chunk-count stream case.
- Runtime remains deterministic and avoids excessive allocations.

## Lane B: Security Hardening

- [ ] V3-SEC-01 Add header injection rejection for CR/LF in custom header names and values
Status: Todo
Priority: P0
Dependencies: None
Why:
- Custom headers should not allow newline-bearing names or values to reach transport adapters.
Acceptance:
- Header merge policy drops or rejects CR/LF-bearing headers deterministically.
- Tests cover malicious header names and values.
- README documents the policy.

- [ ] V3-SEC-02 Expand endpoint host parsing coverage for ports, trailing dots, and mixed-case schemes/hosts
Status: Todo
Priority: P1
Dependencies: None
Why:
- Endpoint allowlists should be predictable across common URL spellings.
Acceptance:
- Tests cover allowed host with explicit port and blocked lookalike hosts.
- Behavior remains strict and documented.

- [ ] V3-SEC-03 Add provider key source guidance and secret hygiene examples
Status: Todo
Priority: P2
Dependencies: None
Why:
- Enterprise adopters need clear patterns for environment variables, secret stores, and redacted logs.
Acceptance:
- README or runbook includes provider-key handling guidance.
- Examples do not print provider keys or sensitive headers.

## Lane C: Functional Completeness

- [ ] V3-FUNC-01 Add provider capability validation for requested JSON/structured output modes
Status: Todo
Priority: P1
Dependencies: None
Why:
- `structured_output_schema` should fail clearly when a provider lacks JSON-mode support.
Acceptance:
- Request path checks provider capability before transport when structured output is requested.
- Tests cover supported and unsupported providers.

- [ ] V3-FUNC-02 Add normalized model/provider metadata helper
Status: Todo
Priority: P2
Dependencies: None
Why:
- Users need a simple way to inspect provider identity, base URL, default model, and capabilities.
Acceptance:
- New exported helper is documented and tested.
- No secrets are included in returned metadata.

- [ ] V3-FUNC-03 Add optional response-size guardrails for raw payloads
Status: Todo
Priority: P2
Dependencies: None
Why:
- Large provider responses can create memory and logging pressure.
Acceptance:
- Option controls max retained raw body size before normalization.
- Error shape is deterministic and redacted.

## Lane D: Documentation and Presentation

- [ ] V3-DOC-01 Add an adoption guide that maps SDK features to enterprise concerns
Status: Todo
Priority: P0
Dependencies: None
Why:
- This project is meant to showcase Kujo; evaluators should quickly see how language features produce real operational value.
Acceptance:
- New doc explains security, reliability, observability, cost controls, fixtures, and CI gates.
- README links it in the first half of the file.

- [ ] V3-DOC-02 Add a one-page "build your first provider" walkthrough
Status: Todo
Priority: P1
Dependencies: None
Why:
- Provider extensibility is a major universal-usefulness story.
Acceptance:
- Walkthrough starts from `custom_openai_compatible_provider(...)`.
- Includes validation, fixture test, and live smoke guidance.

- [ ] V3-DOC-03 Add release-candidate checklist with exact local command sequence
Status: Todo
Priority: P1
Dependencies: None
Why:
- Release readiness should be easy for contributors to execute without reading multiple files.
Acceptance:
- Checklist includes supply-chain check, release gate, schema check, examples, and live smoke policy.
- README links the checklist from release process.

## Recommended Execution Order

1. V3-SEC-01
2. V3-DOC-01
3. V3-PERF-02
4. V3-FUNC-01
5. V3-DOC-03
6. Remaining tasks by priority

## Session Log

- Date: 2026-06-19
- Task ID: V3-BOOTSTRAP
- Summary: Created v3 readiness checklist after hardening review. Captured remaining performance, security, functionality, and presentation tasks for the next session.
- Tests/validations run: Pending in current session; see final session report.
- README/docs updated: README points to this v3 checklist and clarifies production-readiness position.
- Follow-up notes: Start next session with V3-SEC-01 unless a higher-priority user request supersedes it.
