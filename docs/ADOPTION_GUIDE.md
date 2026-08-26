# AI SDK Adoption Guide

Existing applications require no migration. A provider dictionary without `driver` continues through the built-in OpenAI-compatible adapter. Select a native driver package only when its wire protocol differs; application-facing response, error, streaming, transport, governance, and observability contracts remain unchanged.

This guide maps AI SDK features to the operational concerns an enterprise
evaluator cares about. It is written so a reviewer can quickly see how Kujo
language features turn into real, testable operational value — and so a new
adopter can wire the SDK into a service with confidence.

If you only read one document before adopting, read this one.

## How the SDK Maps to Enterprise Concerns

| Concern | What the SDK gives you | Where it lives |
| --- | --- | --- |
| Vendor neutrality | One normalized request/response contract across OpenAI, OpenRouter, DeepSeek, and custom OpenAI-compatible endpoints | `src/providers.kujo`, `chat_completion`, `embeddings` |
| Reliability | Retries with budget ceilings, exponential backoff + bounded jitter, circuit breaker, fallback providers, layered timeouts and deadlines | `chat_completion`, `embeddings` options |
| Security | HTTPS-only custom endpoints, embedded-credential rejection, outbound host allowlist, protected-header policy, CR/LF header-injection rejection, recursive secret redaction | `merge_headers_for_request`, endpoint policy, redaction |
| Cost & governance | Per-request token caps, rolling token and cost budgets, prompt/tool/response-size guardrails | governance budget options |
| Observability | Lifecycle hooks (`on_request_start`/`on_request_complete`/`on_retry`), deterministic counters, trace/request correlation IDs and timing | `observability` block, hooks |
| Testability | Deterministic offline fixtures and an injected transport hook, so CI never needs a live key | `offline_fixture`, `transport` |
| Release safety | Contract schemas, layered test floors, benchmark guardrails, supply-chain pinning checks | `scripts/`, `schemas/`, `.github/workflows/` |

## Security

The SDK is conservative by default:

- **Transport**: custom provider URLs must be `https://` (or explicitly opted-in
  localhost HTTP). URLs with embedded credentials, query strings, or fragments
  are rejected at provider-creation time.
- **Outbound host policy**: set `endpoint_allowlist_enabled: true` with an
  explicit `endpoint_allowlist_hosts` list. Host matching is case-insensitive
  and tolerant of a trailing dot, so `API.OpenAI.Com` and `api.openai.com.` both
  resolve to `api.openai.com` without weakening lookalike rejection.
- **Header policy**: `Authorization` and `Content-Type` are protected from
  override unless you set `allow_unsafe_header_override: true`. Any custom header
  whose name or value contains a CR or LF is dropped to prevent header injection
  and request smuggling.
- **Redaction**: raw success and error payloads are recursively redacted for
  secret-bearing keys and value patterns (bearer tokens, `sk-`, private keys,
  provider key prefixes) before being returned. Operational counters such as
  `used_tokens` stay visible.

### Provider Key Source Guidance and Secret Hygiene

- **Prefer environment variables or a secret manager**, never source literals.
  Each provider preset declares the env var it reads (`provider_metadata(provider)`
  returns `api_key_env`); resolve the key from that variable or inject it from a
  secret store at startup.
- **Never log a resolved key.** `provider_metadata(...)` intentionally returns
  the env var *name*, never the value, so provider identity is safe to log.
- **Rely on redaction, but do not depend on it for keys you put in prompts.**
  Redaction protects the `raw` echo of provider payloads; do not place secrets in
  user-visible message content.
- **Keep `allow_unsafe_header_override` off** unless you have a concrete reason,
  and keep the endpoint allowlist on in deployed environments.
- **Rotate on exposure.** Treat any key printed to a shared log as compromised.

## Reliability

Start from the operational profile in the README, then tune:

- Keep `retry_budget` small (1–2) to avoid retry amplification during provider
  incidents; `max_retries` is an upper bound, `retry_budget` is the hard ceiling.
- Set `overall_timeout_ms` (or an absolute `deadline_ms`) so a single call can
  never exceed your latency SLO; the SDK returns a deterministic
  `deadline_exceeded` error rather than hanging.
- Enable `circuit_breaker_enabled` with a threshold and cooldown to fail fast
  under sustained provider failure; half-open probing recovers automatically.
- Use `fallback_providers` to fail over to a secondary provider when the primary
  failure is still retryable.

## Cost and Governance

- `max_total_tokens_per_request` caps a single request's planned tokens.
- `rolling_token_budget_tokens` and `rolling_cost_budget_cents` (with
  `estimated_cost_per_1k_tokens_cents`) enforce tenant-level rolling budgets,
  backed by an optional shared `state_backend` so budgets hold across instances.
- `max_prompt_characters`, `max_tools_per_request`, and `max_raw_response_bytes`
  bound blast radius before and after transport.

## Observability

Wire `on_request_start`, `on_request_complete`, and `on_retry` to your metrics
backend. Every network-path response carries an `observability` block with
`start_count`, `complete_count`, `retry_count`, `trace_id`, `request_id`, and
timing. See [TELEMETRY_INTEROPERABILITY.md](TELEMETRY_INTEROPERABILITY.md) for an
OpenTelemetry-style mapping and a runnable bridge example.

## Fixtures and CI

Set `offline_fixture: true` for deterministic offline development, or inject a
`transport` function for full request-path tests without a live key. The repo's
own test suites use both patterns, so CI runs with no secrets configured.

## Where to Go Next

- [BUILD_YOUR_FIRST_PROVIDER.md](BUILD_YOUR_FIRST_PROVIDER.md) — add and validate
  a custom provider in one page.
- [PRODUCTION_PROFILE_AND_RUNBOOK.md](PRODUCTION_PROFILE_AND_RUNBOOK.md) —
  recommended defaults and incident playbooks.
- [RELEASE_CANDIDATE_CHECKLIST.md](RELEASE_CANDIDATE_CHECKLIST.md) — the exact
  local command sequence to validate a release.
