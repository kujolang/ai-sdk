# Operational Profile and Incident Runbook

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
kujo test-run tests/sdk_contract_tests.ruff
kujo test-run tests/reliability_failure_modes_tests.ruff
kujo test-run tests/parser_fuzz_smoke_tests.ruff
kujo test-run tests/feature_smoke_tests.ruff
kujo run examples/production_profile.ruff --interpreter
```

## Escalation Criteria

Escalate to incident response when any condition persists for 10+ minutes:
- success rate below 99%
- sustained 429 or 5xx above normal baseline
- repeated `concurrency_limit_exceeded` despite queue controls
- repeated `invalid_json` after provider rollback/retry policy adjustments
