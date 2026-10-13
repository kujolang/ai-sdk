# Operational Profile and Incident Runbook

## Driver trust boundary

Treat external driver packages as executable dependencies. Review and pin them and run conformance/security tests. Core validates host/scheme, protected headers, control characters, credential placement, descriptor shape, response size, semantic results, and retry policy. Drivers cannot select transport or perform I/O. Query authentication and signing remain future work; current descriptors reject query strings.

## State enforcement limits

Client-local counters and `state`/`registry_id` backends now persist within the process on Kujo 1.5.0 and 1.6.0. Use `create_client`, inspect with `client_state`, and clean up idle clients/registries explicitly as described in the [README](../README.md). Use persistent `state_backend.get`/`set` hooks for storage across process restarts. Legacy compound updates remain non-atomic, and hooks fail open on exceptions. For concurrent accounting, opt into `governance_mode: "strict"` with a shared `atomic_memory_backend()` handle or a persistent backend implementing the documented atomic acquire/release contract. Strict errors require backend reconciliation before retrying; never automatically reset a quarantined budget. Distributed adapters must fence stale owners and preserve quarantine durably.

## Operational Profile

Use these defaults as a starting point for latency-sensitive, high-reliability deployments.

Recommended request options:
- `temperature`: `0.1`
- `max_tokens`: `400`
- `max_retries`: `3`
- `retry_budget`: `2`
- `retry_jitter_ms`: `40`
- `retry_delay_ms`: `250`
- `max_retry_delay_ms`: `2000`
- `timeout`: `30.0`
- `circuit_breaker_enabled`: `true`
- `circuit_breaker_error_threshold`: `6`
- `circuit_breaker_cooldown_ms`: `15000`
- `circuit_breaker_half_open_enabled`: `true`
- `circuit_breaker_half_open_max_retries`: `0`
- `max_prompt_characters`: `16000`
- `max_tools_per_request`: `16`
- `max_in_flight_requests`: `4`
- `allow_unsafe_header_override`: `false`

Recommended provider setup:
- Use explicit API key injection in your process manager or secret store.
- Avoid unsafe localhost HTTP providers outside development environments.
- Keep provider model defaults aligned with expected latency/cost envelope.

## Operational SLO Metrics

Track these metrics per provider/model:
- request success rate
- p50/p95 request duration
- retry rate (`retry_count > 0`)
- budget-fail rate (`request_budget_exceeded`)
- concurrency-fail rate (`concurrency_limit_exceeded`)
- error code distribution

## Incident Triage Workflow

1. Identify blast radius:
- affected provider(s)
- request types (chat, stream, embeddings)
- first-seen timestamp and deployment correlation

2. Classify primary failure mode:
- `network_error`
- `http_error` (`429` or `5xx`)
- `provider_error`
- `invalid_json`
- `request_budget_exceeded`
- `concurrency_limit_exceeded`

3. Apply immediate mitigation:
- reduce request volume or increase client-side queueing
- lower `max_in_flight_requests` if provider is unstable
- tighten `max_prompt_characters` or `max_tools_per_request` for runaway requests
- adjust `retry_budget`/`max_retries` and `retry_jitter_ms` for controlled pressure
- tune circuit-breaker threshold/cooldown to fail fast during sustained upstream instability
- tune half-open probe retries to keep recovery checks low-risk
- fail over to alternate provider preset if available

4. Verify stabilization:
- retry rate trending down
- request latency normalized
- error distribution returning to baseline

## Incident Playbooks

### Playbook A: Sustained 429 Rate Limiting

Actions:
- lower concurrent request fan-out (`max_in_flight_requests`)
- reduce `retry_budget` to avoid retry storms
- increase backoff (`retry_delay_ms`, `max_retry_delay_ms`) and add jitter (`retry_jitter_ms`)
- enable or lower circuit-breaker threshold for faster pressure relief
- temporarily reduce `max_tokens` where possible

Validation:
- 429 count falls within 5-10 minutes
- success rate returns to target

### Playbook B: Upstream Timeout/Network Flakiness

Actions:
- shorten timeout if thread starvation is observed
- keep moderate retries (`max_retries: 2-3`) with capped `retry_budget`
- use jitter and circuit-breaker cooldown to avoid synchronized retry waves
- route a controlled percentage to backup provider

Validation:
- timeout/network error ratio decreases
- p95 latency stabilizes

### Playbook C: Parser/Response Format Drift

Actions:
- inspect raw payload attached to normalized error
- compare against contract tests (`sdk_contract_tests`, `reliability_failure_modes_tests`, `parser_fuzz_smoke_tests`)
- open provider-specific compatibility patch with regression test

Validation:
- no `invalid_json` spikes after patch
- release quality gates pass

## Standard Validation Commands

```bash
./kujo test-run tests/sdk_contract_tests.kujo
./kujo test-run tests/reliability_failure_modes_tests.kujo
./kujo test-run tests/parser_fuzz_smoke_tests.kujo
./kujo test-run tests/feature_smoke_tests.kujo
./kujo run examples/production_profile.kujo --interpreter
```

## Escalation Criteria

Escalate to incident response when any condition persists for 10+ minutes:
- success rate below 99%
- sustained 429 or 5xx above normal baseline
- repeated `concurrency_limit_exceeded` despite queue controls
- repeated `invalid_json` after provider rollback/retry policy adjustments

## Native transport controls

Set `max_raw_response_bytes` to a positive integer to enforce a native download cap before parsing (the runtime ceiling remains 8 MiB). Endpoint allowlist mode disables redirect following. Without an allowlist, `redirects` defaults to `follow`; use `none` to reject redirects explicitly. These controls work on published Kujo 1.5 and 1.6. Injected transports must enforce the forwarded limits themselves.

Use `on_transport_chunk(event)` only with the native transport and a runtime containing `http_stream_collect` / `response_stream: "collect"`. The source backports add that API to 1.5 and 1.6; published immutable binaries have not changed. Unpatched binaries reject this option before I/O. The callback receives UTF-8-safe transport text fragments, which may split SSE records. Returning false or throwing cancels the request; transport and final structured-output failures are terminal to avoid replaying already-observed text. Existing normalized stream callbacks still run after the complete response. Account for partial delivery and unknown provider billing after cancellation; collection retains the bounded final body.

Run `KUJO_BIN=/path/to/runtime python3 tests/runtime_transport_tests.py` for loopback redirect, byte-limit and compatibility checks. Set `KUJO_REQUIRE_STREAM_COLLECT=1` for a patched runtime so a missing consumer fails verification instead of skipping consumer-only tests. The Python harness owns an independent loopback fixture server; SDK behavior remains implemented and exercised in Kujo, including both VM and interpreter execution.
