# Kujo AI SDK

Provider-gated SDK primitives for building OpenAI-compatible chat and embeddings integrations in Kujo.

This project gives you a single, normalized response contract across configured OpenAI-compatible providers (OpenAI, OpenRouter, DeepSeek, and custom endpoints), plus retries, streaming events, and deterministic offline fixtures.

## Why This Exists

- Keep application code provider-agnostic.
- Normalize success and error shapes for easier downstream handling.
- Reduce API-specific glue code in every service.
- Support local and CI development without secrets via fixture mode.

This repository is library-first: import `src/ai_sdk.kujo` and `src/providers.kujo` into Kujo workflows, or use the bundled example app for a runnable entrypoint. It does not expose a separate user-facing CLI.

## Highlights

- Provider presets with capability metadata.
- Unified request payload builder.
- Normalized response contract (success + error).
- Retry/backoff for retryable transport and HTTP failures.
- Streaming callback API (`delta`, `done`, `error`).
- Deterministic fixture mode for offline development.
- Contract tests and stress harness included.

## Requirements

- Kujo CLI/runtime available on your machine.
- API key only if you want live provider calls.

## Runtime Command Setup

Use a single runtime selector for all commands in this README:

```bash
export KUJO_BIN="${KUJO_BIN:-/path/to/kujo/target/debug/kujo}"
./kujo test-run --help >/dev/null
```

If the `test-run` help command fails, set `KUJO_BIN` to your Kujo runtime binary path and rerun through `./kujo`.

## Quick Start

```bash
cd ai-sdk
./kujo run examples/main.kujo
```

If `OPENAI_API_KEY` is missing, the example automatically falls back to fixture mode.

## Opt-In Live Provider Calls

OpenAI:

```bash
export OPENAI_API_KEY="your_api_key"
./kujo run examples/main.kujo
```

DeepSeek:

```bash
export DEEPSEEK_API_KEY="your_api_key"
./kujo run examples/main.kujo
```

The provider preset defines which environment variable is read for credentials.

## Operational Quickstart Profile

Use this as a provider-gated operational baseline for both chat and embeddings:

```kujo
from src.providers import openai_provider
from src.ai_sdk import create_client, create_message, chat_completion, embeddings

provider := openai_provider()
client := create_client(provider, env("OPENAI_API_KEY"))

chat_options := {
	"model": "gpt-4.1-mini",
	"max_retries": 2,
	"retry_budget": 2,
	"retry_delay_ms": 200,
	"max_retry_delay_ms": 1500,
	"retry_jitter_ms": 25,
	"timeout": 20.0,
	"connect_timeout": 5.0,
	"read_timeout": 20.0,
	"overall_timeout_ms": 25000,
	"deadline_ms": 0,
	"max_prompt_characters": 12000,
	"max_tools_per_request": 16,
	"max_total_tokens_per_request": 4000,
	"max_in_flight_requests": 8,
	"queue_wait_timeout_ms": 2000,
	"queue_poll_interval_ms": 25,
	"endpoint_allowlist_enabled": true,
	"endpoint_allowlist_hosts": ["api.openai.com"],
	"trace_id": ""
}

embedding_options := {
	"model": "text-embedding-3-small",
	"max_retries": 2,
	"retry_budget": 2,
	"retry_delay_ms": 150,
	"max_retry_delay_ms": 1200,
	"retry_jitter_ms": 25,
	"timeout": 15.0,
	"connect_timeout": 5.0,
	"read_timeout": 15.0,
	"overall_timeout_ms": 15000,
	"deadline_ms": 0,
	"max_prompt_characters": 12000,
	"endpoint_allowlist_enabled": true,
	"endpoint_allowlist_hosts": ["api.openai.com"],
	"trace_id": ""
}

messages := [create_message("user", "Summarize retry budgets in one sentence.")]
chat_result := chat_completion(client, messages, chat_options)
embedding_result := embeddings(client, "Observability and retry budgets", embedding_options)
```

Profile notes:

- Keep `endpoint_allowlist_enabled` on in deployed environments and pin explicit hosts.
- Use `overall_timeout_ms` for bounded request latency.
- Keep `retry_budget` small to avoid retry amplification under provider incidents.
- Apply prompt/tool/token budgets to control cost and blast radius.

## API Surface

From [src/ai_sdk.kujo](src/ai_sdk.kujo):

- `create_client(provider, api_key_override)`
- `create_message(role, content)`
- `build_chat_payload(client, messages, options)`
- `provider_supports(provider, capability_key)`
- `sdk_default_limits()`
- `sdk_contract_version()`
- `chat_completion(client, messages, options)`
- `chat_completion_stream(client, messages, options, on_event)`
- `embeddings(client, input, options)`

From [src/providers.kujo](src/providers.kujo):

- `openai_provider()`
- `openrouter_provider()`
- `deepseek_provider()`
- `custom_openai_compatible_provider(base_url, api_key_env, default_model)`
- `custom_openai_compatible_provider_with_options(base_url, api_key_env, default_model, allow_insecure_localhost)`

## Minimal Usage

```kujo
from src.providers import openai_provider
from src.ai_sdk import create_client, create_message, chat_completion

provider := openai_provider()
client := create_client(provider, env("OPENAI_API_KEY"))
messages := [
	create_message("system", "You are concise and helpful."),
	create_message("user", "Explain why normalized AI response contracts are useful.")
]

result := chat_completion(client, messages, {
	"temperature": 0.2,
	"max_tokens": 160,
	"max_retries": 2
})

if result["ok"] {
	print(result["output_text"])
} else {
	print(result["error"]["code"], result["error"]["message"])
}
```

## Streaming Usage

```kujo
from src.providers import openai_provider
from src.ai_sdk import create_client, create_message, chat_completion_stream

provider := openai_provider()
client := create_client(provider, env("OPENAI_API_KEY"))
messages := [create_message("user", "Stream a short response.")]

handler := func(event) {
	if event["type"] == "delta" {
		print(event["delta"])
	}
	if event["type"] == "done" {
		print("[stream complete]")
	}
	if event["type"] == "error" {
		print("[stream error]", event["error"])
	}
}

result := chat_completion_stream(client, messages, null, handler)
```

`chat_completion_stream(...)` emits callback events and also returns the final normalized response with `emitted_events` attached for validation.

If the callback throws, the stream call fails predictably with a normalized `stream_callback_error` response.

## Normalized Contract

Success response includes:

- `ok`, `provider`, `contract_version`, `request_id`, `model`
- `output_text`, `finish_reason`, `tool_calls`
- `usage.input_tokens`, `usage.output_tokens`, `usage.total_tokens`
- `status_code`, `normalized_at`, `raw`

`output_text` normalization supports common non-stream variants, including string message content, structured content arrays, and choice-level text fallback fields.

`usage` normalization accepts either `prompt_tokens`/`completion_tokens` or `input_tokens`/`output_tokens`, with `total_tokens` computed when absent.

Error response includes:

- `ok`, `provider`, `contract_version`, `status_code`, `normalized_at`, `raw`
- `error.code`, `error.message`, `error.retryable`

For provider-originated errors, optional metadata fields may also be present:

- `error.type`
- `error.param`
- `error.provider_code`

Embeddings response includes:

- `ok`, `provider`, `contract_version`, `model`
- `embeddings[]` entries with `index` and `vector`
- `usage.input_tokens`, `usage.total_tokens`
- `status_code`, `normalized_at`, `raw`

## Retry Policy

`chat_completion(...)` retries only retryable failures:

- `network_error`
- `http_error` with status `429`
- `http_error` with status `>= 500`

Other HTTP failures (for example `400`, `401`, `404`, `409`) return immediately without retry.

`embeddings(...)` now follows the same retry policy and honors `max_retries`, `retry_budget`, `retry_delay_ms`, `max_retry_delay_ms`, and `retry_jitter_ms`.

`embeddings(...)` also honors `overall_timeout_ms` and `deadline_ms`, returning deterministic `deadline_exceeded` errors when request-level deadlines are breached.

Default limits are centralized in `sdk_default_limits()`:

- `temperature`: `0.2`
- `max_tokens`: `400`
- `max_retries`: `2`
- `retry_budget`: `2`
- `retry_jitter_ms`: `0` (set >0 to enable bounded deterministic jitter)
- `retry_delay_ms`: `300`
- `max_retry_delay_ms`: `4000`
- `timeout`: `45.0`
- `connect_timeout`: `10.0`
- `read_timeout`: `45.0`
- `overall_timeout_ms`: `0` (disabled unless set)
- `deadline_ms`: `0` (disabled unless set)
- `circuit_breaker_enabled`: `false`
- `circuit_breaker_error_threshold`: `5`
- `circuit_breaker_cooldown_ms`: `15000`
- `circuit_breaker_half_open_enabled`: `true`
- `circuit_breaker_half_open_max_retries`: `0`
- `structured_output_schema`: `null`
- `structured_output_retryable`: `true`
- `fallback_providers`: `[]`
- `state_backend`: `null`
- `state_namespace`: `""`
- `max_prompt_characters`: `20000`
- `max_tools_per_request`: `32`
- `max_in_flight_requests`: `4`
- `queue_wait_timeout_ms`: `0`
- `queue_poll_interval_ms`: `25`
- `max_total_tokens_per_request`: `0`
- `rolling_token_budget_tokens`: `0`
- `rolling_cost_budget_cents`: `0.0`
- `estimated_cost_per_1k_tokens_cents`: `0.0`
- `trace_id`: `""`
- `endpoint_allowlist_enabled`: `false`
- `endpoint_allowlist_hosts`: `[]`

## Operational Safety Controls

The SDK includes operational safety knobs in request options:

- `retry_budget`: hard ceiling on retry attempts, even when `max_retries` is larger.
- `retry_jitter_ms`: adds bounded jitter to retry delay to reduce synchronized retry spikes.
- `connect_timeout` / `read_timeout` / `overall_timeout_ms` / `deadline_ms`: layered timeout and deadline controls with deterministic `deadline_exceeded` behavior.
- `circuit_breaker_enabled`: enables fail-fast mode after consecutive retryable failures in a request retry loop.
- `circuit_breaker_error_threshold`: number of consecutive retryable failures before opening the breaker.
- `circuit_breaker_cooldown_ms`: cooldown window before retry attempts are allowed again.
- `circuit_breaker_half_open_enabled`: after cooldown, allow a probe request before returning to closed state.
- `circuit_breaker_half_open_max_retries`: retry ceiling used only during half-open probe requests.
- `state_backend` + `state_namespace`: optional shared state backend hooks for breaker and governance budgets across instances.
- `endpoint_allowlist_enabled` + `endpoint_allowlist_hosts`: optional outbound host policy mode that blocks requests when provider host is not explicitly allowlisted.
- `structured_output_schema`: enforce JSON object outputs with required fields (`structured_output_invalid` on violations).
- `fallback_providers`: fail over to alternate provider configs for both chat and embeddings when primary failures remain retryable.
- `max_prompt_characters`: fails fast with `request_budget_exceeded` when chat prompt or embeddings input content is too large.
- `max_tools_per_request`: fails fast when tools exceed configured request budget.
- `max_in_flight_requests`: returns `concurrency_limit_exceeded` when client in-flight slot budget is saturated.
- `queue_wait_timeout_ms` + `queue_poll_interval_ms`: optional queue-wait admission control before returning `concurrency_queue_timeout`.
- `max_total_tokens_per_request`: per-request token governance cap.
- `rolling_token_budget_tokens` / `rolling_cost_budget_cents` / `estimated_cost_per_1k_tokens_cents`: rolling governance budgets returning `governance_budget_exceeded` on exceedance.

## Header Override Policy

Request options can include `headers`, but the SDK protects `Authorization` and `Content-Type` by default.

- Default behavior: protected headers cannot be overridden.
- Explicit opt-in: set `allow_unsafe_header_override: true` to allow overriding protected headers.

Custom non-protected headers (for example `X-Trace`) are always merged.

## Transport Hook

`chat_completion(...)` and streaming calls can use an injected transport for testing or alternative HTTP stacks.

- Pass `transport` in options as a function with signature `(url, request_options) -> Ok(response) | Err(error)`.
- If no transport is provided, SDK falls back to `http_request`.

## Observability Hooks

You can instrument request lifecycle events through options:

- `on_request_start(event)` for request-start metadata
- `on_request_complete(event)` for request completion status/error metadata
- `on_retry(event)` for retry timing and retry reason metadata

Hook errors are safely ignored so instrumentation does not break SDK request flow.

Network-path responses for both chat and embeddings include an `observability` object with `start_count`, `complete_count`, and `retry_count` counters for deterministic metrics in tests and telemetry adapters.

Observability payloads also include correlation and timing metadata (`trace_id`, `request_id`, `started_at`, `finished_at`, `duration_ms`).

Raw success/error payloads are recursively redacted for common and alias secret-bearing keys (for example `api-key`, `clientSecret`, `private_key`, credential/token variants) plus bearer/private-key/token-like value patterns before returning normalized contracts.

OpenTelemetry-style mapping guidance and a runnable bridge example are available in [docs/TELEMETRY_INTEROPERABILITY.md](docs/TELEMETRY_INTEROPERABILITY.md).

Production defaults and incident procedures are documented in [docs/PRODUCTION_PROFILE_AND_RUNBOOK.md](docs/PRODUCTION_PROFILE_AND_RUNBOOK.md).

## Custom Provider Endpoint Validation

`custom_openai_compatible_provider(...)` validates `base_url` at creation time:

- `https://...` endpoints are accepted by default.
- `http://localhost...` and `http://127.0.0.1...` require explicit local-dev opt-in.
- Other `http://...` endpoints are rejected.
- URLs with embedded credentials (for example `https://user:pass@example.com/...`) are rejected.
- Query-string and fragment URL forms are rejected; use `https://host[/optional-path]` (or opted-in localhost HTTP) without `?query` or `#fragment` suffixes.

Local-dev opt-in options:

- Set environment variable `KUJO_AI_SDK_ALLOW_INSECURE_LOCALHOST=1` and call `custom_openai_compatible_provider(...)`.
- Or call `custom_openai_compatible_provider_with_options(..., true)` explicitly.

## Project Structure

- [src/ai_sdk.kujo](src/ai_sdk.kujo): Core SDK behavior (normalization, retries, streaming, fixture mode)
- [src/providers.kujo](src/providers.kujo): Provider presets/capabilities
- [examples/main.kujo](examples/main.kujo): Runnable example
- [examples/telemetry_bridge.kujo](examples/telemetry_bridge.kujo): Telemetry hook bridge example
- [examples/production_profile.kujo](examples/production_profile.kujo): Operational defaults example
- [scripts/stress_harness.kujo](scripts/stress_harness.kujo): High-iteration fixture stability runner
- [tests/sdk_contract_tests.kujo](tests/sdk_contract_tests.kujo): Contract tests
- [schemas/contracts/1.0.0](schemas/contracts/1.0.0): Machine-readable response contract schemas for `contract_version` `1.0.0`
- [docs/PROVIDER_EXTENSION_GUIDE.md](docs/PROVIDER_EXTENSION_GUIDE.md): How to add provider presets and validate capabilities
- [docs/API_CONTRACT_POLICY.md](docs/API_CONTRACT_POLICY.md): Contract versioning and deprecation policy
- [docs/TELEMETRY_INTEROPERABILITY.md](docs/TELEMETRY_INTEROPERABILITY.md): Hook/event mapping to observability backends
- [docs/PRODUCTION_PROFILE_AND_RUNBOOK.md](docs/PRODUCTION_PROFILE_AND_RUNBOOK.md): Recommended operational defaults and incident playbooks
- [docs/ARCHITECTURE_DATA_FLOW.md](docs/ARCHITECTURE_DATA_FLOW.md): Request lifecycle diagram and reliability/safety data-flow narrative
- [docs/PROVIDER_COMPATIBILITY_MATRIX.md](docs/PROVIDER_COMPATIBILITY_MATRIX.md): Provider capability matrix with caveats for chat/streaming/tool-calls/embeddings
- [CHANGELOG.md](CHANGELOG.md): Versioned release history and notable changes
- [LICENSE](LICENSE): Project license text (MIT)
- [kujo.toml](kujo.toml): Package metadata
- [docs/SDK_ENTERPRISE_READINESS_V2_CHECKLIST.md](docs/SDK_ENTERPRISE_READINESS_V2_CHECKLIST.md): Next-session enterprise hardening backlog

## Metadata Ownership

- [kennel.toml](kennel.toml) is the source of truth for package metadata, entry points, scripts, exports, and build settings.
- [kujo.toml](kujo.toml) is a lightweight compatibility manifest and should keep only aligned package identity fields.

## Testing

Core contract suite:

```bash
"$KUJO_BIN" test-run tests/sdk_contract_tests.kujo
```

Contract resilience suite:

```bash
"$KUJO_BIN" test-run tests/sdk_contract_resilience_tests.kujo
```

Contract embeddings suite:

```bash
"$KUJO_BIN" test-run tests/sdk_contract_embeddings_tests.kujo
```

Security redaction suite:

```bash
"$KUJO_BIN" test-run tests/security_redaction_tests.kujo
```

Reliability failure-mode suite:

```bash
"$KUJO_BIN" test-run tests/reliability_failure_modes_tests.kujo
```

Parser fuzz/smoke suite:

```bash
"$KUJO_BIN" test-run tests/parser_fuzz_smoke_tests.kujo
```

Feature smoke suite:

```bash
"$KUJO_BIN" test-run tests/feature_smoke_tests.kujo
```

Telemetry bridge example:

```bash
./kujo run examples/telemetry_bridge.kujo --interpreter
```

Production profile example:

```bash
./kujo run examples/production_profile.kujo
```

Live-provider smoke test (used by release validation workflow):

```bash
./kujo test-run tests/live_provider_smoke_tests.kujo
```

If no provider key is configured (`OPENAI_API_KEY`, `DEEPSEEK_API_KEY`, `OPENROUTER_API_KEY`), the live smoke test exits as a documented skip path.

Release workflow policy:
- Release/prerelease validation requires at least one configured provider secret for live-provider smoke evidence.
- Manual `workflow_dispatch` runs may set `allow_live_provider_skip=true` when explicitly testing non-release paths without provider keys.

Release quality-gate script:

```bash
bash scripts/release_quality_gates.sh
```

The script enforces minimum test-floor thresholds across contract/security/reliability/parser/feature/live suites and runs a final feature smoke command.
The script also runs the benchmark quality gate (`scripts/benchmark_quality_gate.kujo`).
Benchmark guardrails cover chat and embeddings normalization paths plus retry-delay micro-bench cases with explicit latency and throughput thresholds.
The gate fails if runtime smoke or benchmark commands emit type-checking warnings.

Supply-chain policy check:

```bash
bash scripts/supply_chain_policy_check.sh
```

Contract schema verification:

```bash
bash scripts/verify_contract_schemas.sh
```

Integrity manifest generation (expects SBOM path when used in CI/release):

```bash
bash scripts/generate_integrity_manifest.sh artifacts/security
```

Release validation publishes SBOM and integrity manifest artifacts and attaches build-provenance attestation for SBOM output.

## Release and Versioning Process

For each release candidate:

1. Update package version fields in `kennel.toml` and `kujo.toml`.
2. Add release notes under the matching version heading in `CHANGELOG.md`.
3. If response contracts changed, apply `docs/API_CONTRACT_POLICY.md` rules and update contract tests accordingly.
4. Run `bash scripts/supply_chain_policy_check.sh` and `bash scripts/release_quality_gates.sh`.
5. Publish a GitHub release after CI/release workflows pass.

## Stress Harness

```bash
./kujo run scripts/stress_harness.kujo
```

## GitHub Readiness Checklist

- Ensure Kujo CLI/runtime is available in your environment.
- Run contract tests before pushing.
- Keep response-contract changes backward-compatible whenever possible.
- Document any breaking contract changes in this README.
- CI runtime builds are pinned to a fixed Kujo commit in .github/workflows/ci.yml (`KUJO_RUNTIME_REF`) for reproducibility.
- Runtime compatibility checks also run through .github/workflows/compatibility-matrix.yml across pinned runtime refs.
- Release validation runs via .github/workflows/release-validation.yml with deterministic contract checks plus optional live-provider smoke validation when provider secrets are configured.
- Release/prerelease events require live-provider smoke evidence (provider secret required), with manual-only override on `workflow_dispatch`.
- Release quality thresholds are enforced via scripts/release_quality_gates.sh.

## Contributing

Contributions are welcome through issues and pull requests.
