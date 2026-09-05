# AI SDK

The SDK supports both legacy OpenAI-compatible provider dictionaries and native provider drivers. Existing provider factories and custom OpenAI-compatible usage are unchanged: a provider without `driver` automatically uses the built-in OpenAI-compatible driver. Native packages attach a validated `ai-sdk-provider-driver` 1.0.0 function bundle; core continues to own transport, security, retries, governance, and normalized response contract 1.0.0.

Public extension modules are exported as `driver` and `openai_compatible_driver`. Drivers encode bounded request descriptors and decode provider-native responses; they never perform network I/O.

[![Version](https://img.shields.io/badge/version-1.1.0-black)](https://github.com/kujolang/ai-sdk)
[![License](https://img.shields.io/badge/license-MIT-lightgrey)](LICENSE)
[![built with Kujo](https://img.shields.io/badge/built%20with-Kujo-white.svg)](https://github.com/kujolang/kujo)

Provider-gated SDK primitives for building OpenAI-compatible chat and embeddings integrations in Kujo.

This project gives you a single, normalized response contract across configured OpenAI-compatible providers (OpenAI, OpenRouter, DeepSeek, and custom endpoints), plus retries, streaming events, and deterministic offline fixtures.

Prioritize copyable examples over tests: examples should model the most token-efficient idioms we want agents to imitate.

## Why This Exists

- Keep application code provider-agnostic.
- Normalize success and error shapes for easier downstream handling.
- Reduce API-specific glue code in every service.
- Support local and CI development without secrets via fixture mode.

This repository is library-first: import `src/ai_sdk.kujo` and `src/providers.kujo` into Kujo workflows, or use the bundled example app for a runnable entrypoint. It does not expose a separate user-facing CLI.

New here? Start with the [Adoption Guide](docs/ADOPTION_GUIDE.md), which maps every SDK feature to the security, reliability, observability, cost, and CI concern it addresses, then add your own endpoint with the [Build Your First Provider](docs/BUILD_YOUR_FIRST_PROVIDER.md) walkthrough.

## Launch Readiness Position

AI SDK is a release-candidate-oriented enterprise-hardening baseline, not a blanket production certification for every environment.

It is designed to support production-adjacent validation work: deterministic fixtures, normalized contracts, retries, fallback providers, timeouts, breaker controls, host allowlists, redaction, governance budgets, CI release gates, and schema checks are already present. Before adopting it in a regulated or large-scale deployment, teams must still pin provider/runtime versions, configure live-provider smoke evidence, review outbound host policy, wire observability hooks, set tenant-appropriate token/cost budgets, and run the release gates in their own CI.

## Highlights

- Provider presets with capability metadata.
- Unified request payload builder.
- Normalized response contract (success + error).
- Retry/backoff for retryable transport and HTTP failures.
- Streaming callback API (`delta`, `done`, `error`).
- Timeout, circuit-breaker, fallback-provider, and governance budget controls.
- Endpoint allowlist and protected-header policy controls.
- Deterministic fixture mode for offline development.
- Contract schemas, release gates, benchmark guardrails, and stress harness included.

## Requirements

- Kujo CLI/runtime available on your machine.
- API key only if you want live provider calls.

## Runtime Command Setup

Use the installed Kujo command for the examples in this README:

```bash
kujo --version
kujo test-run --help >/dev/null
```

If `kujo` does not resolve, install Kujo or fix your `PATH` before continuing.

## Quick Start

```bash
cd ai-sdk
kujo run examples/main.kujo
```

If `OPENAI_API_KEY` is missing, the example automatically falls back to fixture mode.

Expected fixture-mode output begins with:

```text
AI SDK Example App
-----------------------
No OPENAI_API_KEY found. Running fixture mode so this project works offline.

Mode: fixture
OK: true
Provider: openai
Status: 200
```

## Opt-In Live Provider Calls

OpenAI:

```bash
export OPENAI_API_KEY="your_api_key"
kujo run examples/main.kujo
```

DeepSeek:

```bash
export DEEPSEEK_API_KEY="your_api_key"
kujo run examples/main.kujo
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
- `provider_metadata(provider)`
- `resolve_model_preference(provider, preference)`
- `sdk_default_limits()`
- `sdk_contract_version()`
- `chat_completion(client, messages, options)`
- `chat_completion_stream(client, messages, options, on_event)`
- `embeddings(client, input, options)`

From [src/model_catalog.kujo](src/model_catalog.kujo):

- `create_model_metadata(provider_id, model_id, options)`
- `create_model_catalog(catalog_id, version, models, metadata)`
- `provider_model_catalog(catalog_id, version, providers)`
- `validate_model_catalog(catalog)`
- `model_catalog_hash(catalog)`
- `resolve_model_catalog_entry(catalog, provider_id, model_id)`
- `model_catalog_contract_version()`

From [src/providers.kujo](src/providers.kujo):

- `openai_provider()`
- `openrouter_provider()`
- `deepseek_provider()`
- `custom_openai_compatible_provider(base_url, api_key_env, default_model)`
- `custom_openai_compatible_provider_with_options(base_url, api_key_env, default_model, allow_insecure_localhost)`

## Model Preference Resolution

Applications can pass provider-neutral intent to `resolve_model_preference(...)` instead of choosing a provider model themselves:

```kujo
from src.providers import openai_provider
from src.ai_sdk import resolve_model_preference

resolution := resolve_model_preference(openai_provider(), {
	"class": "frontier_reasoning",
	"preferred": ["team-frontier-model"],
	"fallback": "local-reasoning"
})
```

Resolution precedence is explicit `resolved_model_id`, a `provider_overrides` entry, the provider's class mapping, a compatible preferred/fallback model, then the provider default. The result records `provider`, `model`, `preference_class`, and `source` so callers can persist routing evidence without secrets. Provider presets own the class-to-model mapping; downstream orchestrators should not duplicate it. See [examples/model_preferences.kujo](examples/model_preferences.kujo).

## Versioned Model Catalogs

`src/model_catalog.kujo` is the provider-owned metadata boundary for deterministic orchestrators such as Dispatch. A catalog records a stable `id`, `version`, canonical `catalog_hash`, and sorted model entries. Entries may describe quality tiers, context capacity, tools, structured output, cost, latency, and reliability. Operational values remain `null` when they are not known; the SDK never fabricates prices, token limits, or measurements.

Provider presets expose safe model entries and capabilities, while deployments can build a versioned catalog containing approved models and measured metadata:

```kujo
from src.model_catalog import create_model_metadata, create_model_catalog

catalog := create_model_catalog("production", "2026-08-24", [
	create_model_metadata("openai", "approved-model", {
		"quality_tier": "frontier",
		"supports_tools": true,
		"supports_structured_output": true,
		"source": "platform-policy"
	})
], {"owner": "ai-platform"})
```

The hash covers normalized catalog content, not timestamps generated by consumers. Persist the catalog ID, version, and hash with every route decision so resume can reject silent metadata drift.

For JSON-first authoring, generate and validate a Dispatch-ready catalog from a config file:

```bash
kujo run scripts/generate_model_catalog.kujo --interpreter -- \
  examples/dispatch-model-catalog.config.json --output dispatch-model-catalog.json
```

The script uses `create_model_catalog_from_config`, calculates the canonical hash, and exits nonzero when the config is invalid. Authoring configs require nonempty `id` and `version`; `models` must be an array and `metadata` an object when supplied. The lower-level constructor retains its existing defaults.

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

Callbacks are emitted after the transport returns its buffered response; this API does not provide incremental network delivery. Set `max_raw_response_bytes` to bound retained parsing input (the transport must enforce its own download limit).

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

Thrown transport callbacks return a terminal `transport_error`; exception text is withheld because it may contain credentials. Custom transports should return `Ok(response)` or `Err(message)`. Error messages, provider error metadata, and raw error payloads redact the configured credential as well as recognized secret patterns.

## Retry Policy

`chat_completion(...)` retries only retryable failures:

- `network_error`
- `http_error` with status `429`
- `http_error` with status `>= 500`

Other HTTP failures (for example `400`, `401`, `404`, `409`) return immediately without retry.

`embeddings(...)` follows the same retry policy and honors `max_retries`, `retry_budget`, `retry_delay_ms`, `max_retry_delay_ms`, and `retry_jitter_ms`.

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
- `max_raw_response_bytes`: `0` (disabled unless set)

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
- `structured_output_schema`: enforce JSON object outputs with required fields (`structured_output_invalid` on violations). When set (or when a JSON `response_format` is requested) against a provider that does not advertise `json_mode`, the request fails fast with `unsupported_feature` before any transport call.
- `max_raw_response_bytes`: optional guardrail that rejects oversized provider responses with a deterministic, redacted `response_too_large` error before the body is parsed or retained.
- `fallback_providers`: fail over to alternate provider configs for both chat and embeddings when primary failures remain retryable.
- `max_prompt_characters`: fails fast with `request_budget_exceeded` when chat prompt or embeddings input content is too large.
- `max_tools_per_request`: fails fast when tools exceed configured request budget.
- `max_in_flight_requests`: returns `concurrency_limit_exceeded` when client in-flight slot budget is saturated.
- `queue_wait_timeout_ms` + `queue_poll_interval_ms`: optional queue-wait admission control before returning `concurrency_queue_timeout`.
- `max_total_tokens_per_request`: per-request token governance cap.
- `rolling_token_budget_tokens` / `rolling_cost_budget_cents` / `estimated_cost_per_1k_tokens_cents`: rolling governance budgets for chat and embeddings returning `governance_budget_exceeded` on exceedance.

## Header Override Policy

Request options can include `headers`, but the SDK protects `Authorization` and `Content-Type` by default.

- Default behavior: protected headers cannot be overridden.
- Protected header matching treats common casing variants (`Authorization`, `authorization`, `AUTHORIZATION`, `Content-Type`, `content-type`, `CONTENT-TYPE`) as the same header.
- Explicit opt-in: set `allow_unsafe_header_override: true` to allow overriding protected headers.

Custom non-protected headers (for example `X-Trace`) are always merged.

Any custom header whose name or value contains a carriage return or line feed is dropped during the merge, even when protected-header override is enabled. This prevents header injection and request smuggling through newline-bearing custom headers.

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

Raw success/error payloads are recursively redacted for common and alias secret-bearing keys (for example `api-key`, `clientSecret`, `private_key`, credential/token variants) plus bearer/private-key/token-like value patterns before returning normalized contracts. Token-count governance fields such as `used_tokens`, `request_tokens`, and `rolling_token_budget_tokens` remain visible because they are operational counters, not credentials.

OpenTelemetry-style mapping guidance and a runnable bridge example are available in [docs/TELEMETRY_INTEROPERABILITY.md](docs/TELEMETRY_INTEROPERABILITY.md).

For Watchdog, import `src/watchdog_telemetry.kujo` and map normalized results
with `watchdog_model_event`. The adapter is provider-neutral and metadata-only:
it never accepts prompts, responses, raw provider payloads, headers, or
credentials. It preserves cache, cache-write, reasoning, and provider-native
usage distinctions through the normalized usage contract.

Production defaults and incident procedures are documented in [docs/PRODUCTION_PROFILE_AND_RUNBOOK.md](docs/PRODUCTION_PROFILE_AND_RUNBOOK.md).

## Custom Provider Endpoint Validation

`custom_openai_compatible_provider(...)` validates `base_url` at creation time:

- `https://...` endpoints are accepted by default.
- `http://localhost...` and `http://127.0.0.1...` require explicit local-dev opt-in.
- Other `http://...` endpoints are rejected.
- URLs with embedded credentials (for example `https://user:pass@example.com/...`) are rejected.
- Query-string and fragment URL forms are rejected; use `https://host[/optional-path]` (or opted-in localhost HTTP) without `?query` or `#fragment` suffixes.

When `endpoint_allowlist_enabled` is on, provider hosts are normalized before comparison: matching is case-insensitive and tolerates a fully-qualified trailing dot, so `https://API.OpenAI.Com/v1` and an allowlist entry of `api.openai.com.` both resolve to `api.openai.com`. Lookalike hosts (for example `api.openai.com.evil.test`) are still rejected.

`provider_metadata(provider)` returns a safe-to-log view of provider identity — `name`, `base_url`, `host`, `chat_path`, `embeddings_path`, `default_model`, `api_key_env`, `capabilities`, and `validation_error` — and never includes a resolved API key.

Local-dev opt-in options:

- Set environment variable `KUJO_AI_SDK_ALLOW_INSECURE_LOCALHOST=1` and call `custom_openai_compatible_provider(...)`.
- Or call `custom_openai_compatible_provider_with_options(..., true)` explicitly.

## Project Structure

The root directory intentionally contains only package metadata, license/changelog/readme files, and organized project folders. SDK implementation lives under `src/`; examples, scripts, tests, schemas, docs, and workflows stay in their own directories.

- [src/ai_sdk.kujo](src/ai_sdk.kujo): Core SDK behavior (normalization, retries, streaming, fixture mode)
- [src/providers.kujo](src/providers.kujo): Provider presets/capabilities
- [examples/main.kujo](examples/main.kujo): Runnable example
- [examples/telemetry_bridge.kujo](examples/telemetry_bridge.kujo): Telemetry hook bridge example
- [examples/production_profile.kujo](examples/production_profile.kujo): Operational defaults example
- [examples/model_preferences.kujo](examples/model_preferences.kujo): Provider-owned model preference resolution example
- [.github/workflows/ci.yml](.github/workflows/ci.yml): Pinned-runtime CI checks and release-gate execution
- [.github/workflows/release-validation.yml](.github/workflows/release-validation.yml): Release validation, live-provider evidence, SBOM, and provenance workflow
- [.github/workflows/compatibility-matrix.yml](.github/workflows/compatibility-matrix.yml): Runtime compatibility checks across pinned runtime refs
- [scripts/stress_harness.kujo](scripts/stress_harness.kujo): High-iteration fixture stability runner
- [scripts/release_quality_gates.sh](scripts/release_quality_gates.sh): Aggregate local/release validation gate
- [scripts/supply_chain_policy_check.sh](scripts/supply_chain_policy_check.sh): Workflow pinning and supply-chain policy checks
- [tests/sdk_contract_tests.kujo](tests/sdk_contract_tests.kujo): Core contract tests
- [tests/sdk_contract_resilience_tests.kujo](tests/sdk_contract_resilience_tests.kujo): Resilience, governance, and fallback contract tests
- [tests/sdk_contract_embeddings_tests.kujo](tests/sdk_contract_embeddings_tests.kujo): Embeddings contract and governance tests
- [tests/security_redaction_tests.kujo](tests/security_redaction_tests.kujo): Redaction/security regression tests
- [tests/reliability_failure_modes_tests.kujo](tests/reliability_failure_modes_tests.kujo): Retry, malformed response, and failure-mode tests
- [tests/parser_fuzz_smoke_tests.kujo](tests/parser_fuzz_smoke_tests.kujo): Parser fuzz/smoke tests
- [tests/feature_smoke_tests.kujo](tests/feature_smoke_tests.kujo): End-to-end feature smoke tests
- [tests/live_provider_smoke_tests.kujo](tests/live_provider_smoke_tests.kujo): Opt-in live-provider smoke test
- [schemas/contracts/1.0.0](schemas/contracts/1.0.0): Machine-readable response contract schemas for `contract_version` `1.0.0`
- [docs/ADOPTION_GUIDE.md](docs/ADOPTION_GUIDE.md): Feature-to-enterprise-concern map, including provider-key and secret hygiene guidance
- [docs/BUILD_YOUR_FIRST_PROVIDER.md](docs/BUILD_YOUR_FIRST_PROVIDER.md): One-page walkthrough from custom provider to fixture/live validation
- [docs/RELEASE_CANDIDATE_CHECKLIST.md](docs/RELEASE_CANDIDATE_CHECKLIST.md): Exact local command sequence for validating a release
- [docs/PROVIDER_EXTENSION_GUIDE.md](docs/PROVIDER_EXTENSION_GUIDE.md): How to add provider presets and validate capabilities
- [docs/API_CONTRACT_POLICY.md](docs/API_CONTRACT_POLICY.md): Contract versioning and deprecation policy
- [docs/TELEMETRY_INTEROPERABILITY.md](docs/TELEMETRY_INTEROPERABILITY.md): Hook/event mapping to observability backends
- [docs/PRODUCTION_PROFILE_AND_RUNBOOK.md](docs/PRODUCTION_PROFILE_AND_RUNBOOK.md): Recommended operational defaults and incident playbooks
- [docs/ARCHITECTURE_DATA_FLOW.md](docs/ARCHITECTURE_DATA_FLOW.md): Request lifecycle diagram and reliability/safety data-flow narrative
- [docs/PROVIDER_COMPATIBILITY_MATRIX.md](docs/PROVIDER_COMPATIBILITY_MATRIX.md): Provider capability matrix with caveats for chat/streaming/tool-calls/embeddings
- [docs/SDK_ENTERPRISE_READINESS_V4_CHECKLIST.md](docs/SDK_ENTERPRISE_READINESS_V4_CHECKLIST.md): Next-session enterprise hardening backlog
- [docs/SDK_ENTERPRISE_READINESS_V3_CHECKLIST.md](docs/SDK_ENTERPRISE_READINESS_V3_CHECKLIST.md): Completed v3 hardening log
- [CHANGELOG.md](CHANGELOG.md): Versioned release history and notable changes
- [LICENSE](LICENSE): Project license text (MIT)
- [kujo.toml](kujo.toml): Package metadata
- [docs/SDK_ENTERPRISE_READINESS_V2_CHECKLIST.md](docs/SDK_ENTERPRISE_READINESS_V2_CHECKLIST.md): Completed enterprise hardening log

## Agent and Contributor Search Hygiene

- Treat [examples/main.kujo](examples/main.kujo), [examples/telemetry_bridge.kujo](examples/telemetry_bridge.kujo), [examples/production_profile.kujo](examples/production_profile.kujo), and the README snippets as canonical copyable examples.
- Treat `tests/` as behavior contracts and regression fixtures; keep explicit payloads and expected shapes when they clarify edge cases.
- See `docs/audits/repository-hardening.md` for the current hardening receipt and remaining work; use the examples above for canonical usage.
- Exclude generated/bulk paths from the main sweep unless the task explicitly targets them; for this repo, start searches with `rg --glob '!artifacts/**' --glob '!schemas/contracts/**' ...`.
- Keep example helpers local and boring (`kv`, `section`, `print_lines`) so agents can copy the demonstrated SDK call without importing extra abstractions.

## Metadata Ownership

- [kennel.toml](kennel.toml) is the source of truth for package metadata, entry points, scripts, exports, and build settings.
- [kujo.toml](kujo.toml) is a lightweight compatibility manifest and should keep only aligned package identity fields.

## Testing

Core contract suite:

```bash
kujo test-run tests/sdk_contract_tests.kujo
```

Contract resilience suite:

```bash
kujo test-run tests/sdk_contract_resilience_tests.kujo
```

Contract embeddings suite:

```bash
kujo test-run tests/sdk_contract_embeddings_tests.kujo
```

Security redaction suite:

```bash
kujo test-run tests/security_redaction_tests.kujo
```

Reliability failure-mode suite:

```bash
kujo test-run tests/reliability_failure_modes_tests.kujo
```

Parser fuzz/smoke suite:

```bash
kujo test-run tests/parser_fuzz_smoke_tests.kujo
```

Feature smoke suite:

```bash
kujo test-run tests/feature_smoke_tests.kujo
```

Telemetry bridge example:

```bash
kujo run examples/telemetry_bridge.kujo --interpreter
```

Production profile example:

```bash
kujo run examples/production_profile.kujo
```

Live-provider smoke test (used by release validation workflow):

```bash
kujo test-run tests/live_provider_smoke_tests.kujo
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
The aggregate release-gate floor is currently 95 tests.
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

For each release candidate, follow [docs/RELEASE_CANDIDATE_CHECKLIST.md](docs/RELEASE_CANDIDATE_CHECKLIST.md) for the exact local command sequence. In summary:

1. Update package version fields in `kennel.toml` and `kujo.toml`.
2. Add release notes under the matching version heading in `CHANGELOG.md`.
3. If response contracts changed, apply `docs/API_CONTRACT_POLICY.md` rules and update contract tests accordingly.
4. Run `bash scripts/supply_chain_policy_check.sh` and `bash scripts/release_quality_gates.sh`.
5. Publish a GitHub release after CI/release workflows pass.

## Stress Harness

```bash
kujo run scripts/stress_harness.kujo
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

## Repository verification

Run `KUJO_BIN="$(command -v kujo)" bash scripts/release_quality_gates.sh` for all offline contract suites, wrapper cleanup regressions, documentation checks, schemas, examples, and benchmark gates. Live-provider smoke skips when credentials are absent; release validation still requires live evidence. Use `kujo run scripts/benchmark_model_catalog.kujo --interpreter` for an advisory catalog lookup measurement; compare on the same runtime and machine.

The `./kujo` compatibility wrapper stages execution into a temporary repository copy and removes it on normal success/failure. Generated files in that copy are temporary; use the installed `kujo` command to keep generated outputs in this checkout.

Shared `state_backend` hooks currently fall back to client-local state when reads fail and ignore write-hook exceptions. Their read/modify/write sequence is not atomic across processes. Treat these controls as best-effort accounting, not a strict distributed spending limit; use external serialized admission when strict enforcement is required.
