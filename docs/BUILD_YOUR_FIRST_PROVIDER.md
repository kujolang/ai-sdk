# Build Your First Provider

Use the existing custom OpenAI-compatible factory when the service accepts OpenAI Chat Completions and embeddings shapes. Use a native driver only when authentication, request, response, error, or stream formats differ. A native package returns the ordinary provider dictionary with a `driver` field; applications still call the existing AI SDK functions unchanged.

Any OpenAI-compatible chat/embeddings endpoint can be wired up in a few lines.
This walkthrough takes you from `custom_openai_compatible_provider(...)` to a
validated, fixture-tested, optionally live-smoked provider.

## 1. Create the Provider

```kujo
from src.providers import custom_openai_compatible_provider
from src.ai_sdk import create_client, create_message, chat_completion, provider_metadata

provider := custom_openai_compatible_provider(
	"https://api.your-host.com/v1",
	"YOUR_HOST_API_KEY",
	"your-default-model"
)
```

`custom_openai_compatible_provider(base_url, api_key_env, default_model)` builds a
provider preset whose capabilities default to streaming, tool calls, JSON mode,
and embeddings. The second argument is the *name* of the environment variable the
key is read from — not the key itself.

## 2. Confirm Validation Passed

The base URL is validated at creation time. Inspect the result before using it:

```kujo
metadata := provider_metadata(provider)
if metadata["validation_error"] != "" {
	print("provider invalid:", metadata["validation_error"])
} else {
	print("provider ready:", metadata["host"], metadata["default_model"])
}
```

Validation rules:

- `https://...` is accepted; plain `http://...` is rejected.
- `http://localhost...` / `http://127.0.0.1...` require explicit opt-in via
  `custom_openai_compatible_provider_with_options(..., true)` or the
  `KUJO_AI_SDK_ALLOW_INSECURE_LOCALHOST=1` environment flag.
- Embedded credentials, query strings, and URL fragments are rejected.

`provider_metadata(...)` never returns a resolved API key, so it is safe to log.

## 3. Test Offline With a Fixture

You can exercise the full contract with no network and no key:

```kujo
client := create_client(provider, env("YOUR_HOST_API_KEY"))
messages := [create_message("user", "Say hello.")]

result := chat_completion(client, messages, {"offline_fixture": true})
print(result["ok"], result["output_text"])
```

## 4. Test the Full Request Path With an Injected Transport

To validate the real parse/normalize path deterministically, inject a transport
instead of calling the network. This is how the SDK's own contract tests run:

```kujo
fake_transport := func(url, request_options) {
	return Ok({
		"_status": 200,
		"_body": "{\"id\":\"t-1\",\"choices\":[{\"message\":{\"content\":\"hi\"},\"finish_reason\":\"stop\"}],\"usage\":{\"prompt_tokens\":1,\"completion_tokens\":1,\"total_tokens\":2}}"
	})
}

result := chat_completion(client, messages, {
	"transport": fake_transport,
	"max_retries": 0
})
assert_true(result["ok"])
```

Add a test like this to a `tests/*.kujo` file and run it with
`./kujo test-run tests/your_provider_tests.kujo`.

## 5. Smoke Against the Live Endpoint (Opt-In)

When you have a real key, drop `offline_fixture`/`transport` and let the SDK call
the endpoint:

```bash
export YOUR_HOST_API_KEY="..."
./kujo run examples/main.kujo
```

Follow the pattern in [tests/live_provider_smoke_tests.kujo](../tests/live_provider_smoke_tests.kujo):
the smoke test exits as a documented skip when no key is configured, so it is safe
to keep in CI.

## 6. Harden for Deployment

Before shipping, layer on the operational controls:

```kujo
options := {
	"endpoint_allowlist_enabled": true,
	"endpoint_allowlist_hosts": ["api.your-host.com"],
	"overall_timeout_ms": 20000,
	"retry_budget": 2,
	"max_total_tokens_per_request": 4000,
	"max_raw_response_bytes": 1048576
}
```

See [ADOPTION_GUIDE.md](ADOPTION_GUIDE.md) for the full feature-to-concern map and
[PROVIDER_EXTENSION_GUIDE.md](PROVIDER_EXTENSION_GUIDE.md) for adding a named
preset with explicit capability metadata.
