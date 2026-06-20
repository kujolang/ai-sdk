# AI SDK Enterprise Readiness v4 Checklist

## Intent

The next-session worklist. v3 took AI SDK to a showcase-grade enterprise baseline
(100 tests, hardened security/governance, adoption docs). v4 focuses on
maintainability at scale, deeper runtime coverage, and a few high-value
functional gaps surfaced while completing v3.

## Current Assessment

Status: Showcase-grade enterprise baseline. Chat, streaming, and embeddings share
normalized contracts with retries, fallbacks, circuit breaking, governance
budgets, endpoint/host and header policy, secret redaction, response-size
guardrails, observability hooks, fixtures, and an injected transport. Release
gates span contract, resilience, embeddings, security, reliability, parser,
feature, live-provider, schema, benchmark, and supply-chain checks.

Known constraints to design around:
- The default VM runtime cannot drive injected-transport closures; only the
  interpreter (`test-run`, `run --interpreter`) can. Benchmarks that need a full
  request loop must run in interpreter mode or use exported pure functions.
- Mutating a captured dict from inside a streaming callback does not propagate
  back to the caller's scope; validate streaming via the returned
  `emitted_events` surface instead.

## Agent Operating Rules

For each v4 task:
1. Pick one unchecked task with no open dependency.
2. Mark it In Progress before implementation.
3. Keep changes backward-compatible unless the task explicitly requires a
   contract bump.
4. Add tests and README/docs updates in the same change.
5. Run the relevant suite plus `bash scripts/release_quality_gates.sh`.
6. Add a dated Session Log entry with commands and outcomes.

## Status Legend

- Todo
- In Progress
- Done
- Blocked

## Lane A: Maintainability and Scale

- [ ] V4-PERF-01 Split `src/ai_sdk.kujo` into focused internal modules
Status: Todo
Priority: P1
Dependencies: A confirmed, backward-compatible Kujo multi-file import strategy.
Why:
- The core module is ~3.2k lines; onboarding and review speed suffer.
Acceptance:
- Public exports remain backward-compatible and README imports still work.
- Contract and release gates pass unchanged.

- [ ] V4-PERF-02 Close the VM-vs-interpreter injected-transport gap for benchmarks
Status: Todo
Priority: P2
Dependencies: Runtime investigation (may belong in the Kujo runtime repo).
Why:
- Full injected-transport request-loop benchmarks currently only run under the
  interpreter; the release gate runs the benchmark in VM mode.
Acceptance:
- Either the VM supports transport closures, or the gate runs request-loop
  benchmarks in interpreter mode with documented rationale and thresholds.

## Lane B: Functional Completeness

- [ ] V4-FUNC-01 Apply response-size guardrail to streamed chunk accumulation
Status: Todo
Priority: P1
Dependencies: None
Why:
- `max_raw_response_bytes` currently guards non-stream bodies; a hostile or
  runaway stream can still accumulate unbounded chunk text.
Acceptance:
- Streaming path enforces a cumulative byte ceiling and returns a deterministic,
  redacted `response_too_large` error.
- Tests cover an oversized streamed response.

- [ ] V4-FUNC-02 Structured-output validation for nested/typed schema fields
Status: Todo
Priority: P2
Dependencies: None
Why:
- Validation currently checks presence of top-level required fields only.
Acceptance:
- Optional type checks for declared fields (string/number/bool/object/array).
- Backward-compatible; absent type declarations behave as today.

- [ ] V4-FUNC-03 First-class retry-after honoring from provider headers/body
Status: Todo
Priority: P2
Dependencies: None
Why:
- 429/503 responses often carry a `Retry-After` hint the SDK ignores.
Acceptance:
- When present and parseable, the next retry delay respects `Retry-After`,
  bounded by `max_retry_delay_ms`.
- Tests cover seconds and HTTP-date forms.

## Lane C: Security Hardening

- [ ] V4-SEC-01 Reject control characters beyond CR/LF in headers
Status: Todo
Priority: P2
Dependencies: Runtime escape-sequence support (NUL/`\x00` is not lexable today).
Why:
- NUL and other control bytes can also corrupt headers at the transport layer.
Acceptance:
- Header merge drops names/values containing any control character.
- Tests cover the additional cases once the runtime can express them.

- [ ] V4-SEC-02 Optional request-body redaction policy for outbound logs
Status: Todo
Priority: P2
Dependencies: None
Why:
- Observability hooks expose request metadata; outbound bodies may carry PII.
Acceptance:
- Opt-in policy redacts configured fields in start/retry hook payloads.
- Documented in the adoption guide and telemetry doc.

## Lane D: Documentation and Presentation

- [ ] V4-DOC-01 Add a runnable "kitchen-sink" hardened example
Status: Todo
Priority: P1
Dependencies: None
Why:
- A single copyable example showing every operational control wired together
  accelerates evaluation.
Acceptance:
- New `examples/` file runs in fixture mode and is covered by the feature smoke
  floor.

- [ ] V4-DOC-02 Publish a capability/version compatibility note per provider
Status: Todo
Priority: P2
Dependencies: None
Why:
- Default models drift; evaluators need a dated capability snapshot.
Acceptance:
- Compatibility matrix gains a dated "verified against" column with caveats.

## Recommended Execution Order

1. V4-FUNC-01
2. V4-DOC-01
3. V4-FUNC-03
4. V4-PERF-01
5. Remaining tasks by priority

## Session Log

- Date: 2026-06-20
- Task ID: V4-BOOTSTRAP
- Summary: Created v4 backlog after completing 11/12 v3 tasks. Captured the two
  runtime constraints discovered during v3 (VM transport closures, streaming
  callback capture) so future sessions design around them.
- Follow-up: Start with V4-FUNC-01 unless a higher-priority user request
  supersedes it.
