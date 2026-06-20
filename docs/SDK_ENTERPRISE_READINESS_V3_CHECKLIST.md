# AI SDK Enterprise Readiness v3 Checklist (Completed Log)

## Intent

This was the worklist for moving AI SDK from a strong enterprise-hardening
baseline toward a showcase-grade SDK for Kujo. It is now a completed log; the
forward backlog lives in
[SDK_ENTERPRISE_READINESS_V4_CHECKLIST.md](SDK_ENTERPRISE_READINESS_V4_CHECKLIST.md).

## Outcome Summary (2026-06-20)

11 of 12 tasks landed in one session with no regressions. Test count grew from
90 to 100 across suites; the release-gate floor was raised accordingly.

## Lane A: Performance and Scale

- [ ] V3-PERF-01 Split `src/ai_sdk.kujo` into focused internal modules
Status: Deferred → carried to V4 (V4-PERF-01)
Notes: Deferred intentionally. The current Kujo package/import ergonomics make a
multi-file internal split risky relative to its onboarding benefit; tracked in V4
pending a clear, backward-compatible module strategy.

- [x] V3-PERF-02 Add benchmark cases for full request/parse hot paths
Status: Done (adapted)
Notes: The default VM runtime cannot drive injected-transport closures (only the
interpreter can), and the release gate runs the benchmark in VM mode. The
equivalent hot paths are now covered by `chat_parse_normalization_path` and
`stream_parse_normalization_path` benchmark cases that drive the exported parse +
normalization functions with explicit latency/throughput thresholds. The
VM-vs-interpreter transport-closure gap is tracked in V4 (V4-PERF-02).

- [x] V3-PERF-03 Add high-cardinality streaming stress coverage
Status: Done
Notes: `tests/reliability_failure_modes_tests.kujo` now streams 250 small SSE
frames through `chat_completion_stream` and validates deterministic delta/done
emission via the `emitted_events` surface.

## Lane B: Security Hardening

- [x] V3-SEC-01 Reject CR/LF in custom header names and values
Status: Done
Notes: `merge_headers_with_policy` drops any header whose name or value contains
CR/LF, even under protected-override opt-in. Covered by two new contract tests.

- [x] V3-SEC-02 Expand endpoint host parsing coverage
Status: Done
Notes: Hosts are normalized (case-insensitive, trailing-dot tolerant) before
allowlist comparison; lookalike hosts still rejected. Covered by a new resilience
test.

- [x] V3-SEC-03 Provider key source guidance and secret hygiene
Status: Done
Notes: Documented in `docs/ADOPTION_GUIDE.md`; `provider_metadata(...)` returns
the env var name, never a resolved key, and examples never print secrets.

## Lane C: Functional Completeness

- [x] V3-FUNC-01 Provider capability validation for JSON/structured output
Status: Done
Notes: Requests using `structured_output_schema` or a JSON `response_format`
against a provider lacking `json_mode` fail fast with `unsupported_feature`
before transport. Covered by two new resilience tests.

- [x] V3-FUNC-02 Normalized model/provider metadata helper
Status: Done
Notes: Exported `provider_metadata(provider)` returns identity/capabilities with
no secrets. Covered by two new contract tests.

- [x] V3-FUNC-03 Optional response-size guardrails for raw payloads
Status: Done
Notes: `max_raw_response_bytes` returns a deterministic, redacted
`response_too_large` error before parsing oversized chat/embeddings bodies.
Covered by two new resilience tests. Streaming-chunk size accounting is tracked
in V4 (V4-FUNC-01).

## Lane D: Documentation and Presentation

- [x] V3-DOC-01 Adoption guide mapping features to enterprise concerns
Status: Done — `docs/ADOPTION_GUIDE.md`, linked in the README's first half.

- [x] V3-DOC-02 One-page "build your first provider" walkthrough
Status: Done — `docs/BUILD_YOUR_FIRST_PROVIDER.md`.

- [x] V3-DOC-03 Release-candidate checklist with exact local command sequence
Status: Done — `docs/RELEASE_CANDIDATE_CHECKLIST.md`, linked from the release
process section.

## Session Log

- Date: 2026-06-20
- Task ID: V3-COMPLETE
- Summary: Implemented V3-SEC-01/02/03, V3-FUNC-01/02/03, V3-DOC-01/02/03, and
  V3-PERF-02 (adapted)/03. Deferred V3-PERF-01. Added 10 tests (90 → 100), raised
  release-gate floors, and added three adoption/extension/release docs.
- Tests/validations run: All eight suites pass; `bash scripts/release_quality_gates.sh`
  passes with aggregate test count 100; benchmark quality gate passes in VM mode.
- Follow-up: See `docs/SDK_ENTERPRISE_READINESS_V4_CHECKLIST.md`.
