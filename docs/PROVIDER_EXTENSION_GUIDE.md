# Provider Extension Guide

For the complete normative package, distribution, security, and clean-room requirements, see [Kujo Provider Package Contract v1](KUJO_PROVIDER_PACKAGE_CONTRACT_V1.md).

## Native provider drivers

A driver has `contract: "ai-sdk-provider-driver"`, `version: "1.0.0"`, a non-empty `id`, and required `describe`, `validate`, `encode_chat`, `decode_chat`, and `decode_error` functions. Streaming requires `decode_stream`; embeddings require paired `encode_embeddings` and `decode_embeddings` hooks.

Encode hooks receive operation, provider, scoped credential, normalized payload/messages/input, raw options, and resolved options. They return `{url, method:"POST", headers, protected_headers, body, stream_mode}` and perform no I/O. Decode hooks receive bounded status/body/data/chunks and return semantic values. Core validates descriptors and semantic results and remains authoritative for public errors and retryability.

External packages import only the public `driver` and, when useful, `openai_compatible_driver` Kennel exports. Conformance requires deterministic offline and malicious-descriptor tests plus the full release gate.

This guide explains how to add a new provider preset and validate capability behavior in the AI SDK.

## 1) Add a Provider Preset

Edit `src/providers.kujo` and add a new exported provider function.

Required fields:
- `name`
- `base_url`
- `chat_path`
- `api_key_env`
- `default_model`
- `capabilities`

Example shape:

```kujo
export my_provider := func() {
	return {
		"name": "my-provider",
		"base_url": "https://api.example.com/v1",
		"chat_path": "/chat/completions",
		"api_key_env": "MY_PROVIDER_API_KEY",
		"default_model": "my-model",
		"capabilities": {
			"streaming": true,
			"tool_calls": true,
			"json_mode": true
		}
	}
}
```

## 2) Set Capabilities Correctly

Capabilities are used by `chat_completion(...)` and `chat_completion_stream(...)` to gate features.

- `streaming`: must be `true` only if streaming responses are supported.
- `tool_calls`: must be `true` only if provider supports tool/function calls.
- `json_mode`: set according to provider support.

Incorrect capability flags can cause runtime contract errors or unsupported feature failures.

## 3) Add Contract Tests

Update `tests/sdk_contract_tests.kujo` with provider-focused tests:
- Preset shape test (required keys exist)
- Capability checks using `provider_supports(...)`
- Auth error behavior (`auth_error`) when key is missing
- Optional fixture or normalization tests when behavior differs

## 4) Validate End-to-End

Run:

```bash
export KUJO_BIN="${KUJO_BIN:-kujo}"
./kujo test-run --help >/dev/null
./kujo test-run tests/sdk_contract_tests.kujo
./kujo run examples/main.kujo
```

If your change affects streaming/retry behavior, also run:

```bash
./kujo run scripts/stress_harness.kujo
```

## 5) README and Checklist Updates

When a provider is added or capability behavior changes:
- Update provider list in `README.md`
- Update examples if needed
- Add checklist/session log evidence in `docs/SDK_IMPROVEMENT_CHECKLIST.md`

## Repeatable Provider Addition Checklist

- [ ] Added provider export in `src/providers.kujo`
- [ ] Included full required provider fields
- [ ] Set accurate capability flags
- [ ] Added/updated contract tests
- [ ] Ran contract tests and example smoke run
- [ ] Updated README provider/API docs
