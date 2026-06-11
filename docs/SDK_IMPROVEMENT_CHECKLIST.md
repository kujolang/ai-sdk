# AI SDK Improvement Checklist and Agent Playbook

## Purpose

This document is the execution checklist for improving the AI SDK in a safe, incremental way.

Use it to:
- Track prioritized work across security, correctness, DX, structure, and features.
- Let an AI agent pick one item at a time, complete it, and mark it done.
- Keep README and tests aligned with every shipped change.

## Review Scope Completed

Reviewed files:
- README.md
- ai_sdk.kujo
- providers.kujo
- main.kujo
- stress_harness.kujo
- tests/sdk_contract_tests.kujo
- kujo.toml
- kennel.toml
- .github/workflows/ci.yml

Validation note:
- Historical note: early sessions encountered PATH ambiguity with the Python linter; use README `KUJO_BIN` runtime setup for consistent validation commands.

## Agent Execution Protocol

For each work session, follow this exact process:

1. Read this file and README.md fully before editing.
2. Choose exactly one unchecked task with no open dependency.
3. Set task status to In Progress.
4. Implement the smallest safe change that satisfies the task.
5. Add or update tests for the change.
6. Run available validation commands.
7. Update README.md when behavior, API, structure, or commands changed.
8. Mark the task Done and add a short completion note under Session Log.
9. Stop, then pick the next task only when explicitly instructed.

## Global Definition of Done

A task is done only if all are true:
- Code change implemented and formatted consistently.
- New behavior covered by tests, or an explicit reason is documented.
- Existing tests still pass in supported runtime.
- README.md updated when user-facing behavior changed.
- This checklist updated with status and brief completion note.

## Current Findings Snapshot

This snapshot is historical context from the initial hardening review.

Current state:
- Tasks in this checklist are complete (see lane statuses and Session Log).
- Active enterprise follow-up items are tracked in `docs/SDK_ENTERPRISE_READINESS_V2_CHECKLIST.md`.

## Prioritized Work Board

Status legend: Todo, In Progress, Done, Blocked

## Lane A: Security and Reliability

- [x] A-01 Retry only retryable HTTP failures
Status: Done
Priority: P0
Complexity: S
Dependencies: None
Scope:
- Update retryability classification so non-retryable 4xx responses are not retried by default.
- Keep retries for network errors, 429, and 5xx.
Acceptance:
- Retry behavior is deterministic and documented.
- Tests cover 400, 401, 404, 409, 429, 500.
Completion note (2026-05-21): Added explicit HTTP retry classification helper, prevented fallback retrying of non-retryable 4xx responses, added contract tests for 400/401/404/409/429/500 plus network errors, and documented policy in README.

- [x] A-02 Header safety policy
Status: Done
Priority: P0
Complexity: M
Dependencies: None
Scope:
- Introduce a controlled header policy.
- Default deny override of Authorization and Content-Type unless explicit opt-in.
Acceptance:
- Header override behavior is explicit and tested.
- README includes header override policy.
Completion note (2026-05-21): Added protected-header merge policy that blocks Authorization/Content-Type overrides by default, with explicit allow_unsafe_header_override opt-in; added contract tests and README policy docs.

- [x] A-03 Harden custom provider endpoint validation
Status: Done
Priority: P1
Complexity: S
Dependencies: None
Scope:
- Validate `base_url` format at provider creation.
- Default require https, with explicit local-dev opt-in for http localhost.
Acceptance:
- Invalid base URLs fail fast with clear errors.
- Tests for accepted and rejected URLs.
Completion note (2026-05-21): Added custom provider base_url validation for https-by-default, localhost HTTP opt-in, and fail-fast config_error handling in client request flow; added acceptance tests and README docs.

- [x] A-04 Pin CI runtime source
Status: Done
Priority: P1
Complexity: S
Dependencies: None
Scope:
- Pin Kujo runtime build to a known commit/tag in CI.
- Add checksum or provenance note if possible.
Acceptance:
- CI becomes reproducible across runs.
- README or docs mention how runtime pinning is managed.
Completion note (2026-05-21): Pinned CI runtime source to fixed KUJO_RUNTIME_REF commit and switched CI clone step to fetch/checkout the pinned ref; documented pinning ownership in README.

## Lane B: Core Contract Correctness

- [x] B-01 Improve non-stream success normalization
Status: Done
Priority: P0
Complexity: M
Dependencies: None
Scope:
- Support broader `choices` content variants safely.
- Preserve current contract shape while improving extraction logic.
Acceptance:
- Contract remains backward-compatible.
- Tests cover string and structured content variants.
Completion note (2026-05-21): Expanded non-stream normalization to support string content, structured content arrays, and choice-level text/content fallbacks while preserving contract keys and response shape.

- [x] B-02 Improve usage token normalization
Status: Done
Priority: P1
Complexity: S
Dependencies: None
Scope:
- Normalize from common provider fields (`prompt_tokens`, `completion_tokens`, `input_tokens`, `output_tokens`, `total_tokens`).
Acceptance:
- `usage` is accurate across known payload variants.
- Tests cover fallback combinations.
Completion note (2026-05-21): Added unified usage normalization that maps prompt/completion and input/output variants with computed total fallback; applied to both non-stream and stream paths with new coverage.

- [x] B-03 Preserve provider error metadata
Status: Done
Priority: P1
Complexity: S
Dependencies: None
Scope:
- Capture and expose structured error details (`type`, `param`, provider code) in normalized error payload.
Acceptance:
- Error contract includes more actionable details without breaking existing keys.
- README documents expanded error fields.
Completion note (2026-05-21): Added provider error normalization helper that preserves optional metadata (`type`, `param`, provider code) in normalized error payloads while keeping existing error keys unchanged.

- [x] B-04 Protect streaming from callback exceptions
Status: Done
Priority: P1
Complexity: M
Dependencies: None
Scope:
- Wrap callback execution defensively.
- Return normalized error if callback handling fails.
Acceptance:
- Stream path fails predictably when callback throws.
- Tests verify callback error handling behavior.
Completion note (2026-05-21): Added defensive callback invocation in streaming path and now return normalized stream_callback_error responses when callback execution fails on delta/done/error events.

## Lane C: DRY and Maintainability

- [x] C-01 Centralize option resolution defaults
Status: Done
Priority: P1
Complexity: S
Dependencies: None
Scope:
- Add helper(s) for resolving options with defaults.
- Remove repeated `has_key` and type checks where safe.
Acceptance:
- Reduced duplication in payload build and retry option parsing.
Completion note (2026-05-21): Added shared option-resolution helpers and reused them across payload assembly, retry parsing, fixture handling, timeout handling, and header override policy parsing.

- [x] C-02 Consolidate message extraction helpers
Status: Done
Priority: P2
Complexity: M
Dependencies: B-01
Scope:
- Create focused helper functions for parsing choice/delta/message fields.
- Use same extraction rules for stream and non-stream paths where possible.
Acceptance:
- Less duplicated parsing logic.
- Existing tests still pass; new parser tests added.
Completion note (2026-05-21): Introduced shared choice/delta extraction helpers and reused them across non-stream normalization, stream normalization, and emitted delta chunk collection; added stream parser regression coverage.

- [x] C-03 Constants for defaults and limits
Status: Done
Priority: P2
Complexity: S
Dependencies: None
Scope:
- Replace magic numbers with constants for timeouts, retries, and token defaults.
Acceptance:
- Defaults are easy to find and document.
Completion note (2026-05-21): Centralized timeout, retry, and token defaults in a single helper and wired option resolution to reuse those values; documented defaults in README.

## Lane D: Repository Structure and Developer Experience

- [x] D-01 Reorganize top-level file layout
Status: Done
Priority: P1
Complexity: M
Dependencies: None
Scope:
- Proposed layout:
- src/ai_sdk.kujo
- src/providers.kujo
- examples/main.kujo
- scripts/stress_harness.kujo
- tests/sdk_contract_tests.kujo
- docs/*
- Update imports, scripts, and config paths accordingly.
Acceptance:
- Root is cleaner and easier for new contributors.
- README reflects new run/test commands.
Completion note (2026-05-21): Moved core modules to src, runnable example to examples, and stress harness to scripts; updated imports, CI/example commands, package metadata paths, and README structure/commands.

- [x] D-02 Clarify package metadata source of truth
Status: Done
Priority: P2
Complexity: S
Dependencies: D-01
Scope:
- Define purpose of kujo.toml versus kennel.toml.
- Remove or align duplicate/conflicting fields.
Acceptance:
- Metadata ownership is explicit and documented.
Completion note (2026-05-21): Aligned package identity fields between kujo.toml and kennel.toml and documented kennel.toml as metadata source of truth with kujo.toml as lightweight compatibility manifest.

- [x] D-03 Add extension guide for providers and capabilities
Status: Done
Priority: P2
Complexity: S
Dependencies: None
Scope:
- Add docs explaining how to register a provider preset, set capabilities, and validate contract behavior.
Acceptance:
- New provider additions can follow a repeatable checklist.
Completion note (2026-05-21): Added dedicated provider extension guide with required preset fields, capability semantics, contract validation workflow, and repeatable add-provider checklist.

## Lane E: Test and Quality Expansion

- [x] E-01 Add retry policy contract tests
Status: Done
Priority: P0
Complexity: M
Dependencies: A-01
Scope:
- Add deterministic tests around retryability classification logic.
Acceptance:
- Failing classifications are caught quickly.
Completion note (2026-05-21): Expanded retry policy contract tests with HTTP boundary coverage and non-HTTP retryable fallback coverage to catch classification regressions quickly.

- [x] E-02 Add parser and malformed payload tests
Status: Done
Priority: P1
Complexity: M
Dependencies: B-01, B-02
Scope:
- Add tests for empty body, malformed JSON, provider error shapes, and usage variants.
Acceptance:
- Parser behavior is explicitly validated.
Completion note (2026-05-21): Added parser/malformed payload contract tests for empty body and malformed JSON, plus provider error bad-shape fallback and total-only usage payload variant.

- [x] E-03 Add streaming edge-case tests
Status: Done
Priority: P1
Complexity: M
Dependencies: B-04
Scope:
- Add tests for multiline SSE data frames, done markers, no delta, and callback exceptions.
Acceptance:
- Stream contract is reliable for real provider outputs.
Completion note (2026-05-21): Added streaming edge-case coverage for multiline SSE frames, done marker handling, no-delta normalization, and done-event callback exceptions; updated SSE parser to accumulate multiline frame payloads.

- [x] E-04 Add CI quality gates
Status: Done
Priority: P2
Complexity: S
Dependencies: A-04
Scope:
- Add checks for docs freshness and command smoke tests aligned with runtime constraints.
Acceptance:
- CI fails fast on missing docs or stale examples.
Completion note (2026-05-21): Added CI gate step that verifies required docs exist and README command/module path references stay aligned with the reorganized repository layout.

## Lane F: Feature Growth (After Core Hardening)

- [x] F-01 Add transport abstraction hook
Status: Done
Priority: P1
Complexity: M
Dependencies: A-01
Scope:
- Allow injectable transport for testing and alternative HTTP stacks.
Acceptance:
- Network-path tests can run without real provider calls.
Completion note (2026-05-21): Added injectable transport hook with option/client-level resolution and default http_request fallback; added success and error path tests using mocked transport implementations.

- [x] F-02 Add observability hooks
Status: Done
Priority: P2
Complexity: M
Dependencies: F-01
Scope:
- Add request lifecycle hooks for timing, retries, and status metrics.
Acceptance:
- Consumers can instrument SDK calls without patching core logic.
Completion note (2026-05-21): Added lifecycle observability hooks (`on_request_start`, `on_request_complete`, `on_retry`) with safe invocation and deterministic per-call observability counters on responses.

- [x] F-03 Add embeddings endpoint support
Status: Done
Priority: P3
Complexity: M
Dependencies: F-01
Scope:
- Introduce normalized embeddings request/response contract.
Acceptance:
- Provider-agnostic embeddings flow documented and tested.
Completion note (2026-05-21): Added provider-agnostic embeddings endpoint support with normalized embeddings contract, capability gating, offline fixture response, and transport-hook-compatible request path.

## Lane G: Production Hardening

- [x] G-01 Remove scratch artifacts and enforce hygiene
Status: Done
Priority: P0
Complexity: S
Dependencies: None
Scope:
- Remove non-project scratch `.kujo` files from repository root.
- Add guardrails to prevent accidental check-in of ad hoc scratch files.
Acceptance:
- Root no longer contains untracked scratch artifacts.
- Ignore policy and/or CI hygiene checks prevent recurrence.
Completion note (2026-05-21): Removed root scratch Kujo files, added root scratch ignore pattern, and added CI guard that fails if disallowed root `test_*.kujo` files are present.

- [x] G-02 Add live provider validation in CI release flows
Status: Done
Priority: P0
Complexity: M
Dependencies: None
Scope:
- Add a release workflow job that runs live provider smoke checks with secrets when available.
- Keep CI deterministic by skipping live runs safely when secrets are absent.
Acceptance:
- Release CI can validate at least one live provider path.
- Failures are visible and actionable in workflow logs.
Completion note (2026-05-21): Added release-validation workflow with deterministic contract gates and live-provider smoke stage using configured provider secrets; added live smoke test that validates one available provider and skips safely when no keys are configured.

- [x] G-03 Add failure-mode reliability validation suite
Status: Done
Priority: P0
Complexity: M
Dependencies: None
Scope:
- Add deterministic tests for timeout, 429 retry pressure, malformed SSE, partial-body JSON, and retry exhaustion.
Acceptance:
- Reliability regressions are caught by contract/reliability tests.
Completion note (2026-05-21): Added dedicated reliability failure-mode test suite covering timeout normalization, 429 burst recovery, retry exhaustion, malformed SSE handling, partial JSON handling, and mixed-frame SSE parser robustness; wired suite into CI and release deterministic gates.

- [x] G-04 Add release quality gates
Status: Done
Priority: P1
Complexity: M
Dependencies: G-02, G-03
Scope:
- Add release gate checks for coverage floor, parser fuzz/smoke checks, and feature smoke commands.
Acceptance:
- Release flow fails fast when quality thresholds are not met.
Completion note (2026-05-21): Added parser fuzz and feature smoke suites plus a release quality-gate script that enforces per-suite and aggregate test-count floors and runs a feature smoke command; wired release workflow to run the gate script.

- [x] G-05 Add supply-chain and security verification
Status: Done
Priority: P1
Complexity: M
Dependencies: None
Scope:
- Generate SBOM, verify dependency policy, and add artifact-integrity/signing readiness checks.
Acceptance:
- CI captures supply-chain metadata and enforces security policy checks.
Completion note (2026-05-21): Added supply-chain policy script, release workflow SBOM generation, integrity-manifest generation and artifact upload, plus SBOM provenance attestation; added CI policy-check gate and local artifacts ignore rule.

- [x] G-06 Add versioned contract and deprecation policy docs
Status: Done
Priority: P1
Complexity: S
Dependencies: None
Scope:
- Publish explicit contract versioning and deprecation/compatibility policy.
Acceptance:
- API stability expectations are documented and reviewable.
Completion note (2026-05-21): Added docs/API_CONTRACT_POLICY.md with semantic contract versioning and deprecation lifecycle rules; added `contract_version` to normalized responses and exported `sdk_contract_version()` for explicit compatibility assertions.

- [x] G-07 Add operational safety limits and controls
Status: Done
Priority: P1
Complexity: M
Dependencies: None
Scope:
- Add configurable concurrency/request budget safety knobs and retry budget ceilings.
Acceptance:
- SDK offers explicit safeguards for production load behavior.
Completion note (2026-05-21): Added request budget controls (`max_prompt_characters`, `max_tools_per_request`), retry ceiling (`retry_budget`), and client in-flight guard (`max_in_flight_requests`) with deterministic `request_budget_exceeded` and `concurrency_limit_exceeded` error responses.

- [x] G-08 Add telemetry interoperability guidance and examples
Status: Done
Priority: P2
Complexity: S
Dependencies: F-02
Scope:
- Add OpenTelemetry-style mapping docs/examples for lifecycle hooks and metrics fields.
Acceptance:
- Integrators can wire SDK telemetry to common observability backends.
Completion note (2026-05-21): Added telemetry interoperability guide with hook-to-OpenTelemetry mapping and metrics conventions, plus runnable telemetry bridge example demonstrating start/retry/complete signal translation.

- [x] G-09 Add production profile and incident runbook
Status: Done
Priority: P1
Complexity: S
Dependencies: G-07
Scope:
- Add production configuration profile and incident/debugging runbook.
Acceptance:
- Operators have clear defaults and troubleshooting procedures.
Completion note (2026-05-21): Added production profile/runbook documentation with SLO metrics, failure classification, and incident playbooks; added runnable production-profile example and wired it into release quality-gate smoke commands.

## Lane H: Performance and Resiliency Enhancements

- [x] H-01 Reduce repeated option-resolution overhead in hot paths
Status: Done
Priority: P1
Complexity: M
Dependencies: C-01
Scope:
- Remove repeated option-resolution calls from retry-path request execution and embeddings path.
- Reuse pre-resolved options for payload/transport selection where possible.
Acceptance:
- Request execution no longer re-resolves options per retry attempt.
- Embeddings flow no longer re-resolves options during payload and transport setup.
Completion note (2026-05-21): Added resolved-option helper paths for payload/transport and updated chat/embeddings call paths to use one-pass resolved options in hot execution paths.

- [x] H-02 Add jittered retry policy and optional circuit-breaker control
Status: Done
Priority: P1
Complexity: M
Dependencies: H-01
Scope:
- Add bounded retry jitter control.
- Add optional circuit-breaker behavior for repeated retryable failures within a request retry loop.
Acceptance:
- Retry delay computation supports configurable jitter windows.
- Circuit breaker can fail fast before exhausting full retry budgets when enabled.
Completion note (2026-05-21): Added `retry_jitter_ms` option and deterministic bounded jitter computation; added optional request-scope circuit-breaker controls (`circuit_breaker_enabled`, threshold, cooldown) with normalized `circuit_breaker_open` failures and coverage in contract tests.

- [x] H-03 Add half-open probe mode for circuit breaker recovery
Status: Done
Priority: P1
Complexity: M
Dependencies: H-02
Scope:
- Add cooldown-expiry half-open probe behavior so the breaker can test recovery before returning to closed mode.
- Add probe-specific retry controls and contract coverage.
Acceptance:
- Open breaker returns `circuit_breaker_open` while cooldown is active.
- After cooldown, probe behavior is configurable and failures can re-open breaker quickly.
Completion note (2026-05-21): Added `circuit_breaker_half_open_enabled` and `circuit_breaker_half_open_max_retries` options with cooldown-expiry probe behavior; expanded contract and production docs/examples accordingly.

## Lane I: Universality, Scale, and Runtime Hardening

- [x] I-01 Add distributed breaker and governance backend hooks
Status: Completed
Priority: P0
Complexity: M
Dependencies: H-03
Scope:
- Add optional external state backend interface for shared breaker and budget state across instances.
Acceptance:
- SDK can use pluggable shared state for breaker/budget operations.
Completion note (2026-05-21): Added pluggable state backend hooks via `state_backend`/`state_namespace` with dict/function/registry-backed access paths and breaker state persistence integration.

- [x] I-02 Add true incremental streaming parse path
Status: Completed
Priority: P0
Complexity: M
Dependencies: None
Scope:
- Add chunk-based stream parser and streaming HTTP response processing path.
Acceptance:
- Stream path can parse events incrementally from chunk sequences.
Completion note (2026-05-21): Added chunk-wise SSE parser (`parse_sse_chunks`) and wired stream request handling to prefer transport chunk streams (`_stream_chunks`/`stream_chunks`) before body fallback parsing.

- [x] I-03 Add timeout tiers and deadline propagation
Status: Completed
Priority: P0
Complexity: M
Dependencies: None
Scope:
- Add connect/read/overall timeouts and retry-loop deadline propagation.
Acceptance:
- Requests stop when overall deadline is exceeded.
Completion note (2026-05-21): Added connect/read/overall timeout options and hard deadline enforcement (`deadline_exceeded`) across retry loops with remaining-time propagation into request timeout.

- [x] I-04 Add structured output guarantee mode
Status: Completed
Priority: P1
Complexity: M
Dependencies: None
Scope:
- Add schema-constrained output mode with validation/retry behavior.
Acceptance:
- Invalid structured responses fail with deterministic contract errors.
Completion note (2026-05-21): Added schema-based structured output validation with required-field checks and deterministic `structured_output_invalid` errors integrated into retry paths.

- [x] I-05 Add provider fallback orchestration
Status: Completed
Priority: P0
Complexity: M
Dependencies: None
Scope:
- Add policy-driven provider fallback attempts.
Acceptance:
- Retryable failures can fail over to alternate provider configs.
Completion note (2026-05-21): Added policy-driven fallback orchestration with per-entry provider/options overrides and retryability-based failover decisions.

- [x] I-06 Add benchmark quality gates
Status: Completed
Priority: P1
Complexity: S
Dependencies: H-01
Scope:
- Add benchmark script and CI gate with regression thresholds.
Acceptance:
- CI fails if benchmark thresholds regress past budget.
Completion note (2026-05-21): Added `scripts/benchmark_quality_gate.kujo` and wired benchmark enforcement into CI and release quality-gate scripts.

- [x] I-07 Add queue-based admission control
Status: Completed
Priority: P1
Complexity: M
Dependencies: G-07
Scope:
- Add optional queue wait strategy when in-flight limits are saturated.
Acceptance:
- Saturated requests can wait up to configured queue timeout.
Completion note (2026-05-21): Added queue-based admission controls (`queue_wait_timeout_ms`, `queue_poll_interval_ms`) with deterministic `concurrency_queue_timeout` behavior.

- [x] I-08 Add token and cost governance budgets
Status: Completed
Priority: P1
Complexity: M
Dependencies: None
Scope:
- Add per-request and rolling budget checks for tokens/cost.
Acceptance:
- Budget exceedance returns deterministic governance errors.
Completion note (2026-05-21): Added per-request token planning budgets plus rolling token/cost governance accounting with backend-aware persistence and deterministic `governance_budget_exceeded` responses.

- [x] I-09 Add enhanced observability identifiers and latencies
Status: Completed
Priority: P1
Complexity: S
Dependencies: F-02
Scope:
- Add stable request ids, trace ids, and duration metrics fields.
Acceptance:
- Observability payloads include consistent correlation metadata.
Completion note (2026-05-21): Added trace/request correlation IDs and duration metadata to request-level observability and completion hook payloads.

- [x] I-10 Add automatic sensitive payload redaction
Status: Completed
Priority: P0
Complexity: M
Dependencies: None
Scope:
- Redact sensitive fields from raw payloads and error raw bodies.
Acceptance:
- Raw contract payloads avoid leaking common secret keys/tokens.
Completion note (2026-05-21): Added recursive raw-payload redaction across normalized success/error payloads for common secret-bearing keys and bearer/token patterns.

- [x] I-11 Expand reliability suite with chaos/soak scenarios
Status: Completed
Priority: P1
Complexity: M
Dependencies: G-03
Scope:
- Add chaos-style deterministic tests for retry storms and malformed stream bursts.
Acceptance:
- Reliability suites catch additional large-sequence failure patterns.
Completion note (2026-05-21): Expanded reliability coverage with deterministic retry-storm and malformed-stream-burst scenarios.

- [x] I-12 Add compatibility matrix workflow
Status: Completed
Priority: P1
Complexity: M
Dependencies: A-04
Scope:
- Add CI workflow running contract/smoke suites against multiple pinned runtime refs.
Acceptance:
- Matrix workflow reports compatibility status per runtime ref.
Completion note (2026-05-21): Added GitHub Actions compatibility matrix workflow running contract/reliability/feature suites across multiple pinned Kujo runtime commit refs.

## Implementation Order Recommendation

Recommended order:
1. A-01
2. E-01
3. A-02
4. B-01
5. B-02
6. E-02
7. B-04
8. E-03
9. D-01
10. D-02
11. A-04
12. Remaining tasks by priority

## Session Log

Add one entry per completed task:

Template:
- Date:
- Task ID:
- Summary of change:
- Tests added/updated:
- Commands run:
- README updated: Yes or No
- Follow-up notes:

- Date: 2026-05-21
- Task ID: A-01
- Summary of change: Retry logic now retries only network errors, HTTP 429, and HTTP 5xx. Non-retryable 4xx responses now return immediately.
- Tests added/updated: Added retry policy classification test coverage in tests/sdk_contract_tests.kujo for 400, 401, 404, 409, 429, 500, and network_error.
- Commands run: kujo test-run tests/sdk_contract_tests.kujo (failed: unrecognized subcommand under the Python linter); /path/to/kujo/target/debug/kujo test-run tests/sdk_contract_tests.kujo (pass); /path/to/kujo/target/debug/kujo run main.kujo --interpreter (pass); /path/to/kujo/target/debug/kujo run stress_harness.kujo --interpreter (pass).
- README updated: Yes
- Follow-up notes: Local PATH points to the Python linter by default; use runtime binary path for SDK validation in this environment.

- Date: 2026-05-21
- Task ID: A-02
- Summary of change: Added controlled header merge behavior that protects Authorization and Content-Type by default and permits protected overrides only with explicit opt-in.
- Tests added/updated: Added merge policy tests for default deny and opt-in allow behavior.
- Commands run: /path/to/kujo/target/debug/kujo test-run tests/sdk_contract_tests.kujo (pass); /path/to/kujo/target/debug/kujo run main.kujo --interpreter (pass).
- README updated: Yes
- Follow-up notes: Protected header policy now explicit in request options behavior.

- Date: 2026-05-21
- Task ID: A-03
- Summary of change: Added provider endpoint validation with https default, insecure localhost opt-in, and immediate config_error responses for invalid endpoints.
- Tests added/updated: Added accepted/rejected URL tests plus fail-fast request-path test for invalid custom provider configuration.
- Commands run: /path/to/kujo/target/debug/kujo test-run tests/sdk_contract_tests.kujo (pass); /path/to/kujo/target/debug/kujo run main.kujo --interpreter (pass).
- README updated: Yes
- Follow-up notes: Added environment flag and explicit function opt-in path for localhost HTTP development endpoints.

- Date: 2026-05-21
- Task ID: A-04
- Summary of change: CI runtime build now uses a pinned Kujo commit hash via workflow env (KUJO_RUNTIME_REF) with explicit fetch/checkout to improve reproducibility.
- Tests added/updated: No direct code tests; validated existing contract and smoke commands after workflow/doc changes.
- Commands run: /path/to/kujo/target/debug/kujo test-run tests/sdk_contract_tests.kujo (pass); /path/to/kujo/target/debug/kujo run main.kujo --interpreter (pass).
- README updated: Yes
- Follow-up notes: Update KUJO_RUNTIME_REF intentionally when upgrading runtime behavior in CI.

- Date: 2026-05-21
- Task ID: B-01
- Summary of change: Added broader non-stream output extraction helpers and fallback paths for common provider content variants.
- Tests added/updated: Added normalization contract tests for string content, structured content arrays, and choice-level text fallback variants.
- Commands run: /path/to/kujo/target/debug/kujo test-run tests/sdk_contract_tests.kujo (pass); /path/to/kujo/target/debug/kujo run main.kujo --interpreter (pass).
- README updated: Yes
- Follow-up notes: Added test-export for normalization helper to keep parsing behavior deterministic and regression-testable.

- Date: 2026-05-21
- Task ID: B-02
- Summary of change: Usage token normalization now supports prompt/completion and input/output payload variants and computes total when absent.
- Tests added/updated: Added usage normalization tests for legacy fields, modern fields, and mixed fallback combinations.
- Commands run: /path/to/kujo/target/debug/kujo test-run tests/sdk_contract_tests.kujo (pass); /path/to/kujo/target/debug/kujo run main.kujo --interpreter (pass).
- README updated: Yes
- Follow-up notes: Usage mapping now consistently shared by stream and non-stream normalization paths.

- Date: 2026-05-21
- Task ID: B-03
- Summary of change: Provider error normalization now retains optional structured metadata and exposes it in normalized error payloads.
- Tests added/updated: Added tests for metadata-preserving provider errors and metadata-missing provider errors.
- Commands run: /path/to/kujo/target/debug/kujo test-run tests/sdk_contract_tests.kujo (pass after nested dict assignment fix); /path/to/kujo/target/debug/kujo run main.kujo --interpreter (pass).
- README updated: Yes
- Follow-up notes: Used runtime-compatible dict mutation strategy (mutate nested error dict, then reassign) to avoid complex index assignment limitations.

- Date: 2026-05-21
- Task ID: B-04
- Summary of change: Streaming callback execution is now wrapped defensively and callback exceptions produce deterministic normalized error responses.
- Tests added/updated: Added callback exception tests for both successful stream delta events and error-event stream paths.
- Commands run: /path/to/kujo/target/debug/kujo test-run tests/sdk_contract_tests.kujo (pass); /path/to/kujo/target/debug/kujo run main.kujo --interpreter (pass).
- README updated: Yes
- Follow-up notes: Stream callback failures now preserve emitted_events context to aid debugging and downstream handling.

- Date: 2026-05-21
- Task ID: C-01
- Summary of change: Introduced centralized option-resolution defaults and removed repeated option parsing in key request/build/retry flows.
- Tests added/updated: Added resolve_options regression tests for default values and explicit overrides.
- Commands run: /path/to/kujo/target/debug/kujo test-run tests/sdk_contract_tests.kujo (pass).
- README updated: No
- Follow-up notes: Refactor is backward-compatible and intended to simplify future option-related changes.

- Date: 2026-05-21
- Task ID: C-02
- Summary of change: Consolidated parsing logic for choice message fields and stream delta fields into focused helper functions reused by stream and non-stream paths.
- Tests added/updated: Added stream parser regression test for structured delta content variants and preserved full contract suite coverage.
- Commands run: /path/to/kujo/target/debug/kujo test-run tests/sdk_contract_tests.kujo (pass).
- README updated: No
- Follow-up notes: Shared extraction helpers reduce drift risk between stream and non-stream parsing behavior.

- Date: 2026-05-21
- Task ID: C-03
- Summary of change: Replaced magic default values with centralized limits helper used by option resolution.
- Tests added/updated: Added regression test to ensure centralized defaults remain stable and aligned with resolved options.
- Commands run: /path/to/kujo/target/debug/kujo test-run tests/sdk_contract_tests.kujo (pass).
- README updated: Yes
- Follow-up notes: Default values now have a single source of truth through sdk_default_limits().

- Date: 2026-05-21
- Task ID: D-01
- Summary of change: Reorganized repository layout to src/examples/scripts and updated import/module paths and command references.
- Tests added/updated: No new tests; updated test and runtime imports to new src-prefixed module paths.
- Commands run: /path/to/kujo/target/debug/kujo test-run tests/sdk_contract_tests.kujo (pass); /path/to/kujo/target/debug/kujo run examples/main.kujo --interpreter (pass); /path/to/kujo/target/debug/kujo run scripts/stress_harness.kujo --interpreter (pass); README stale-path grep check (no stale matches).
- README updated: Yes
- Follow-up notes: Runtime import resolution now relies on explicit src module prefixes in examples/tests/scripts.

- Date: 2026-05-21
- Task ID: D-02
- Summary of change: Clarified metadata ownership and removed package-name mismatch between manifests.
- Tests added/updated: No new tests required for metadata-only changes.
- Commands run: /path/to/kujo/target/debug/kujo test-run tests/sdk_contract_tests.kujo (pass); /path/to/kujo/target/debug/kujo run examples/main.kujo --interpreter (pass); README path grep for stale commands (no stale matches).
- README updated: Yes
- Follow-up notes: Keep canonical metadata updates in kennel.toml and mirror package identity in kujo.toml when needed.

- Date: 2026-05-21
- Task ID: D-03
- Summary of change: Added docs/PROVIDER_EXTENSION_GUIDE.md and linked it from README for contributor discoverability.
- Tests added/updated: No test file changes; documentation-only task.
- Commands run: /path/to/kujo/target/debug/kujo test-run tests/sdk_contract_tests.kujo (pass); /path/to/kujo/target/debug/kujo run examples/main.kujo --interpreter (pass); README command path grep (pass).
- README updated: Yes
- Follow-up notes: Guide includes a step-by-step provider onboarding checklist for consistent capability and contract validation.

- Date: 2026-05-21
- Task ID: E-01
- Summary of change: Added deterministic retry classification tests for HTTP status boundaries and non-HTTP fallback retryability behavior.
- Tests added/updated: Added new contract tests for 429/499/500/599 boundaries and transport/provider fallback retryability handling.
- Commands run: /path/to/kujo/target/debug/kujo test-run tests/sdk_contract_tests.kujo (pass).
- README updated: No
- Follow-up notes: Retry classification regressions now fail with targeted boundary assertions.

- Date: 2026-05-21
- Task ID: E-02
- Summary of change: Expanded parser and malformed payload coverage to explicitly validate edge-case normalization behavior.
- Tests added/updated: Added tests for empty body, malformed JSON, non-dict provider error shape, and total-only usage payload handling.
- Commands run: /path/to/kujo/target/debug/kujo test-run tests/sdk_contract_tests.kujo (pass).
- README updated: No
- Follow-up notes: parse_json_safe is exported as parse_json_contract for deterministic contract testing.

- Date: 2026-05-21
- Task ID: E-03
- Summary of change: Expanded streaming edge-case contract tests and hardened SSE parsing for multiline data-frame assembly.
- Tests added/updated: Added tests for multiline SSE parsing and done markers, no-delta stream events, and done-callback exception normalization.
- Commands run: /path/to/kujo/target/debug/kujo test-run tests/sdk_contract_tests.kujo (pass).
- README updated: No
- Follow-up notes: parse_sse_lines is exported as parse_sse_contract for targeted stream parser tests.

- Date: 2026-05-21
- Task ID: E-04
- Summary of change: Added CI freshness checks for key docs and README command/module path references.
- Tests added/updated: No test file changes; CI workflow quality-gate step added.
- Commands run: /path/to/kujo/target/debug/kujo test-run tests/sdk_contract_tests.kujo (pass).
- README updated: No
- Follow-up notes: CI now fails early if docs or command paths drift from repository structure.

- Date: 2026-05-21
- Task ID: F-01
- Summary of change: Added transport abstraction hook to allow injected request execution without real network calls.
- Tests added/updated: Added injected transport success/error contract tests with deterministic mocked responses.
- Commands run: /path/to/kujo/target/debug/kujo test-run tests/sdk_contract_tests.kujo (pass); /path/to/kujo/target/debug/kujo run examples/main.kujo --interpreter (pass).
- README updated: Yes
- Follow-up notes: Transport injection supports alternative HTTP stacks and test-only network isolation.

- Date: 2026-05-21
- Task ID: F-02
- Summary of change: Added request lifecycle hook support and response-level observability counters for timing/retry/status instrumentation.
- Tests added/updated: Added observability hook tests for start/complete and retry paths with injected transport.
- Commands run: /path/to/kujo/target/debug/kujo test-run tests/sdk_contract_tests.kujo (pass); /path/to/kujo/target/debug/kujo run examples/main.kujo --interpreter (pass).
- README updated: Yes
- Follow-up notes: Hook callback failures are safely ignored to avoid instrumentation-related request failures.

- Date: 2026-05-21
- Task ID: F-03
- Summary of change: Added embeddings endpoint API and normalized response flow with success/error handling and capability checks.
- Tests added/updated: Added embeddings fixture, transport success, and unsupported-capability tests.
- Commands run: /path/to/kujo/target/debug/kujo test-run tests/sdk_contract_tests.kujo (pass); /path/to/kujo/target/debug/kujo run examples/main.kujo --interpreter (pass).
- README updated: Yes
- Follow-up notes: Provider presets now declare embeddings capability and custom providers default embeddings support to true.

- Date: 2026-05-21
- Task ID: G-01
- Summary of change: Removed root scratch Kujo artifacts and added hygiene guardrails in ignore policy and CI checks to prevent accidental reintroduction.
- Tests added/updated: No new contract tests; CI workflow now includes scratch-file hygiene validation.
- Commands run: rm -f test_assign.kujo test_closure.kujo test_closure_simple.kujo test_final.kujo test_read.kujo test_simple_f.kujo test_top_level.kujo; git ls-files --others --exclude-standard (pass/no output); /path/to/kujo/target/debug/kujo test-run tests/sdk_contract_tests.kujo (pass).
- README updated: No
- Follow-up notes: Root-level ad hoc scratch experiments should use ignored naming/path conventions to avoid repo noise.

- Date: 2026-05-21
- Task ID: G-02
- Summary of change: Added release validation workflow and live-provider smoke contract test for OpenAI, DeepSeek, or OpenRouter when corresponding secrets are configured.
- Tests added/updated: Added tests/live_provider_smoke_tests.kujo with deterministic skip behavior when no live-provider keys are present.
- Commands run: /path/to/kujo/target/debug/kujo test-run tests/sdk_contract_tests.kujo (pass); /path/to/kujo/target/debug/kujo test-run tests/live_provider_smoke_tests.kujo (pass).
- README updated: Yes
- Follow-up notes: Release workflow surfaces provider-selection context and preserves deterministic behavior in secretless environments.

- Date: 2026-05-21
- Task ID: G-03
- Summary of change: Added deterministic reliability failure-mode suite and integrated it into both CI and release validation workflows.
- Tests added/updated: Added tests/reliability_failure_modes_tests.kujo covering timeout, 429 retry pressure, retry exhaustion, malformed SSE, partial JSON, and mixed-frame SSE parsing.
- Commands run: /path/to/kujo/target/debug/kujo test-run tests/reliability_failure_modes_tests.kujo (pass); /path/to/kujo/target/debug/kujo test-run tests/sdk_contract_tests.kujo (pass); /path/to/kujo/target/debug/kujo test-run tests/live_provider_smoke_tests.kujo (pass).
- README updated: Yes
- Follow-up notes: Reliability suite now acts as a first-class regression gate for critical failure handling behavior.

- Date: 2026-05-21
- Task ID: G-04
- Summary of change: Added release-quality gate automation with parser fuzz/feature smoke suites and test-floor enforcement for release validation.
- Tests added/updated: Added tests/parser_fuzz_smoke_tests.kujo and tests/feature_smoke_tests.kujo; added scripts/release_quality_gates.sh.
- Commands run: /path/to/kujo/target/debug/kujo test-run tests/parser_fuzz_smoke_tests.kujo (pass); /path/to/kujo/target/debug/kujo test-run tests/feature_smoke_tests.kujo (pass); KUJO_BIN=/path/to/kujo/target/debug/kujo bash scripts/release_quality_gates.sh (pass, aggregate tests: 49).
- README updated: Yes
- Follow-up notes: Release contract job now executes centralized quality-gate logic to catch regressions and threshold drift early.

- Date: 2026-05-21
- Task ID: G-05
- Summary of change: Added supply-chain policy enforcement, SBOM generation, integrity manifest creation, artifact upload, and SBOM provenance attestation in release validation.
- Tests added/updated: No runtime contract tests; added scripts/supply_chain_policy_check.sh and scripts/generate_integrity_manifest.sh with CI/release workflow enforcement.
- Commands run: bash scripts/supply_chain_policy_check.sh (pass); bash scripts/generate_integrity_manifest.sh artifacts/security (pass); KUJO_BIN=/path/to/kujo/target/debug/kujo bash scripts/release_quality_gates.sh (pass).
- README updated: Yes
- Follow-up notes: Security artifacts are produced under artifacts/security in CI and excluded from local source control.

- Date: 2026-05-21
- Task ID: G-06
- Summary of change: Added explicit contract versioning policy docs and embedded `contract_version` in normalized chat/stream/error/embeddings responses.
- Tests added/updated: Added contract test asserting `contract_version` presence across success/error/embeddings responses.
- Commands run: /path/to/kujo/target/debug/kujo test-run tests/sdk_contract_tests.kujo (pass); KUJO_BIN=/path/to/kujo/target/debug/kujo bash scripts/release_quality_gates.sh (pass).
- README updated: Yes
- Follow-up notes: Contract changes now require semantic versioning decisions and policy updates before merge.

- Date: 2026-05-21
- Task ID: G-07
- Summary of change: Added production safety limits for retries, prompt/tool request budgets, and in-flight concurrency limits with normalized fast-fail errors.
- Tests added/updated: Added contract tests for retry_budget cap, prompt budget exceed, tool budget exceed, and max_in_flight_requests guard.
- Commands run: /path/to/kujo/target/debug/kujo test-run tests/sdk_contract_tests.kujo (pass); KUJO_BIN=/path/to/kujo/target/debug/kujo bash scripts/release_quality_gates.sh (pass, aggregate tests: 54).
- README updated: Yes
- Follow-up notes: Safety controls are configurable per request and are intended to prevent runaway request characteristics under production load.

- Date: 2026-05-21
- Task ID: G-08
- Summary of change: Added OpenTelemetry-style hook mapping guide and telemetry bridge example for integrating SDK lifecycle events with observability pipelines.
- Tests added/updated: No new contract tests; validated runnable telemetry bridge example and full release quality gates.
- Commands run: /path/to/kujo/target/debug/kujo run examples/telemetry_bridge.kujo --interpreter (pass); KUJO_BIN=/path/to/kujo/target/debug/kujo bash scripts/release_quality_gates.sh (pass).
- README updated: Yes
- Follow-up notes: Example demonstrates retry lifecycle and final normalized response telemetry emission in JSON form.

- Date: 2026-05-21
- Task ID: G-09
- Summary of change: Added production defaults and incident runbook documentation plus runnable production-profile example and quality-gate smoke integration.
- Tests added/updated: No new test suites; extended release quality smoke commands to run examples/production_profile.kujo.
- Commands run: /path/to/kujo/target/debug/kujo run examples/production_profile.kujo --interpreter (pass); KUJO_BIN=/path/to/kujo/target/debug/kujo bash scripts/release_quality_gates.sh (pass).
- README updated: Yes
- Follow-up notes: Runbook includes triage workflow, escalation criteria, and targeted mitigation playbooks for common failure classes.

- Date: 2026-05-21
- Task ID: H-01
- Summary of change: Refactored chat/embeddings hot paths to use one-pass resolved options for transport and payload construction.
- Tests added/updated: Updated contract suite coverage remained green after one-pass refactor.
- Commands run: /path/to/kujo/target/debug/kujo test-run tests/sdk_contract_tests.kujo (pass); KUJO_BIN=/path/to/kujo/target/debug/kujo bash scripts/release_quality_gates.sh (pass).
- README updated: No
- Follow-up notes: Resolved-option helper functions now centralize option reuse in request-path internals.

- Date: 2026-05-21
- Task ID: H-02
- Summary of change: Added retry jitter and optional request-scope circuit-breaker controls with deterministic contract-test coverage.
- Tests added/updated: Added retry-delay contract test and circuit-breaker open-path test in sdk contract suite; expanded defaults/override assertions for new options.
- Commands run: /path/to/kujo/target/debug/kujo test-run tests/sdk_contract_tests.kujo (pass); KUJO_BIN=/path/to/kujo/target/debug/kujo bash scripts/release_quality_gates.sh (pass).
- README updated: Yes
- Follow-up notes: Circuit breaker currently scopes to a single request retry loop, providing fast-fail protection during repeated retryable failures.

- Date: 2026-05-21
- Task ID: H-03
- Summary of change: Added half-open probe recovery mode to circuit breaker with explicit probe retry controls.
- Tests added/updated: Added half-open probe contract test and expanded defaults/override assertions for half-open options.
- Commands run: /path/to/kujo/target/debug/kujo test-run tests/sdk_contract_tests.kujo --verbose (pass); KUJO_BIN=/path/to/kujo/target/debug/kujo bash scripts/release_quality_gates.sh (pass, aggregate tests: 57).
- README updated: Yes
- Follow-up notes: Breaker now blocks during active cooldown, then runs configurable low-risk probes before normal retry behavior resumes.

- Date: 2026-05-21
- Task ID: I-01
- Summary of change: Added shared-state backend hooks for breaker/governance state with namespace support and deterministic fallback behavior.
- Tests added/updated: Added state backend option coverage and shared-breaker contract test updates.
- Commands run: /path/to/kujo/target/debug/kujo test-run tests/sdk_contract_tests.kujo -v (pass).
- README updated: No
- Follow-up notes: Backend supports dict state, functional get/set, and registry-id patterns for integration flexibility.

- Date: 2026-05-21
- Task ID: I-02
- Summary of change: Implemented incremental SSE chunk parsing and stream-chunk transport ingestion path.
- Tests added/updated: Added chunked SSE stream contract test and parser export updates.
- Commands run: /path/to/kujo/target/debug/kujo test-run tests/sdk_contract_tests.kujo -v (pass).
- README updated: No
- Follow-up notes: Stream requests now prioritize `_stream_chunks`/`stream_chunks` before body-level SSE parsing.

- Date: 2026-05-21
- Task ID: I-03
- Summary of change: Added connect/read/overall timeout tiers plus absolute deadline propagation and fail-fast deadline exceeded handling.
- Tests added/updated: Expanded defaults/override coverage and added deadline short-circuit contract test.
- Commands run: /path/to/kujo/target/debug/kujo test-run tests/sdk_contract_tests.kujo -v (pass).
- README updated: No
- Follow-up notes: Retry loop now respects overall deadline bounds across attempts.

- Date: 2026-05-21
- Task ID: I-04
- Summary of change: Added structured output guarantee mode with JSON and required-field validation.
- Tests added/updated: Added deterministic structured output invalid/success contract tests.
- Commands run: /path/to/kujo/target/debug/kujo test-run tests/sdk_contract_tests.kujo -v (pass).
- README updated: No
- Follow-up notes: Validation errors return `structured_output_invalid` with schema-aware diagnostics.

- Date: 2026-05-21
- Task ID: I-05
- Summary of change: Added provider fallback orchestration with retryability-gated failover and per-fallback option overrides.
- Tests added/updated: Added fallback-success and non-retryable-no-fallback contract tests.
- Commands run: /path/to/kujo/target/debug/kujo test-run tests/sdk_contract_tests.kujo -v (pass).
- README updated: No
- Follow-up notes: Fallback metadata is attached to fallback-attempt results for traceability.

- Date: 2026-05-21
- Task ID: I-06
- Summary of change: Added benchmark quality-gate script and integrated it into CI and release-quality scripts.
- Tests added/updated: Added scripts/benchmark_quality_gate.kujo and workflow/script gate steps.
- Commands run: /path/to/kujo/target/debug/kujo run scripts/benchmark_quality_gate.kujo --interpreter (pass).
- README updated: No
- Follow-up notes: Gate validates average latency and throughput against conservative thresholds.

- Date: 2026-05-21
- Task ID: I-07
- Summary of change: Added queue-based admission control with configurable wait timeout and poll interval.
- Tests added/updated: Added queue timeout contract coverage under saturated in-flight slots.
- Commands run: /path/to/kujo/target/debug/kujo test-run tests/sdk_contract_tests.kujo -v (pass).
- README updated: No
- Follow-up notes: Saturation can now wait briefly before deterministic `concurrency_queue_timeout` failure.

- Date: 2026-05-21
- Task ID: I-08
- Summary of change: Added per-request token and rolling token/cost governance budgets with backend-aware persistence.
- Tests added/updated: Added governance contract tests for per-request, rolling-token, and rolling-cost exceedance scenarios.
- Commands run: /path/to/kujo/target/debug/kujo test-run tests/sdk_contract_tests.kujo -v (pass).
- README updated: No
- Follow-up notes: Governance failures are normalized as `governance_budget_exceeded` with budget-type details.

- Date: 2026-05-21
- Task ID: I-09
- Summary of change: Added trace/request identifiers and duration metrics to request observability payloads.
- Tests added/updated: Expanded observability contract assertions for correlation IDs and request durations.
- Commands run: /path/to/kujo/target/debug/kujo test-run tests/sdk_contract_tests.kujo -v (pass).
- README updated: No
- Follow-up notes: Aggregated observability now preserves per-attempt correlation metadata.

- Date: 2026-05-21
- Task ID: I-10
- Summary of change: Added recursive sensitive-field redaction for raw success/error payload surfaces.
- Tests added/updated: Added contract test verifying redaction of common secret-bearing key/value patterns.
- Commands run: /path/to/kujo/target/debug/kujo test-run tests/sdk_contract_tests.kujo (pass).
- README updated: No
- Follow-up notes: Redaction is applied before normalized payloads are returned to callers.

- Date: 2026-05-21
- Task ID: I-11
- Summary of change: Expanded reliability suite with deterministic retry-storm and malformed-stream burst scenarios.
- Tests added/updated: Added two new reliability failure-mode tests and stabilized malformed-burst assertions.
- Commands run: /path/to/kujo/target/debug/kujo test-run tests/reliability_failure_modes_tests.kujo (pass).
- README updated: No
- Follow-up notes: Reliability suite now better captures long-sequence degradation patterns.

- Date: 2026-05-21
- Task ID: I-12
- Summary of change: Added compatibility matrix workflow for pinned Kujo runtime refs.
- Tests added/updated: Added .github/workflows/compatibility-matrix.yml for contract/reliability/feature matrix validation.
- Commands run: Workflow definition validated by repository lint/error checks; local suite smoke remained green.
- README updated: No
- Follow-up notes: Matrix pin list should be advanced deliberately as runtime upgrades are evaluated.

## Handoff Prompt Template for Future Agents

Use this prompt pattern:

"Read docs/SDK_ENTERPRISE_READINESS_V2_CHECKLIST.md and README.md. Identify the highest-priority open enterprise-governance item, implement it with tests/docs updates, run `bash scripts/supply_chain_policy_check.sh` and `bash scripts/release_quality_gates.sh`, then append a dated Session Log entry summarizing what changed and what remains."
