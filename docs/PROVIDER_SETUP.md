# Configure a Kujo provider

Use the provider registry in this AI SDK source checkout with Kujo 1.9.0.
The published SDK 1.2.0 predates the registry.

From your application directory, point Kujo at the SDK checkout and your
project's installed packages:

```sh
export AI_SDK_ROOT=/path/to/ai-sdk
export KENNEL_SCRIPT=/path/to/kennel/kennel.kujo
export KUJO_MODULE_PATH="$AI_SDK_ROOT/src:$PWD/kennel_packages"
kujo run "$AI_SDK_ROOT/examples/provider_quickstart.kujo" -- list
kujo run "$AI_SDK_ROOT/examples/provider_quickstart.kujo" -- anthropic inspect
kujo run "$AI_SDK_ROOT/examples/provider_quickstart.kujo" -- anthropic setup
```

`setup` returns the pinned install commands, the package import if needed,
and starter code. Set the model from your deployment or account. For a
package-backed integration, run the returned Kennel commands in your project
directory. If the project has no Kennel manifest yet, initialize it first:

```sh
kujo run "$KENNEL_SCRIPT" -- init --name my-app
kujo run "$AI_SDK_ROOT/examples/provider_quickstart.kujo" -- anthropic setup | jq -r '.install[]'
kujo run "$AI_SDK_ROOT/examples/provider_quickstart.kujo" -- anthropic setup | jq -r '.starter' > first_provider.kujo
```

## Use the common configuration call

The built-in presets take `configure_provider(id, model, {})`. A packaged
driver adds one import and supplies its factory:

```kujo
from anthropic.src.provider import anthropic_provider
from provider_registry import configure_provider
from ai_sdk import create_client, create_message, chat_completion

configured := configure_provider("anthropic", "YOUR_MODEL_ID", {"package_factory": anthropic_provider})
if !configured["ok"] { print(configured["error"]); exit(1) }
client := create_client(configured["provider"], null)
result := chat_completion(client, [create_message("user", "Say hello.")], {"max_retries": 0})
if !result["ok"] { print(result["error"]["code"]); exit(1) }
print(result["output_text"])
```

The 20 packaged SDK drivers reuse their protocol-specific encoders and
decoders. Pass provider-specific settings through `package_options`, such as
Cloudflare's `account_id` or Ollama's `host`. Check
`require_provider_capabilities(configured["provider"], ["embeddings"])`
before choosing an operation. Use package-native APIs for features absent
from its normalized driver. The registry reports `kind: "sdk"` for both the
built-in presets and the package drivers.

## Use a native client

The same configuration call returns `kind: "native"` and `client` for these
packages. Pass the package's `create_client` as `package_factory` and use
`package_options` for its deployment and credential settings. The setup
command shows the qualified package import.

| Provider | Model argument to `configure_provider` | Package settings | Operations |
| --- | --- | --- | --- |
| Amazon Bedrock | Bedrock model ID | Region and request-specific SigV4 material | `converse`, `invoke_model` |
| Azure AI | Azure deployment name | Endpoint, API version and key or access token | `chat` |
| Vertex AI | Vertex model ID | Project, location and Google access token | `generate_content`, `predict` |
| Replicate | Prediction version ID | `REPLICATE_API_TOKEN` or explicit token | `create_prediction`, `get_prediction`, `cancel_prediction` |
| fal.ai | Queue model path | `FAL_KEY` or explicit key | `submit`, `status`, `result`, `cancel` |

For example, configure Replicate and submit an explicit prediction:

```kujo
from replicate.src.replicate import create_client, create_prediction
from provider_registry import configure_provider

configured := configure_provider("replicate", "YOUR_VERSION_ID", {"package_factory": create_client})
if !configured["ok"] { print(configured["error"]); exit(1) }
prediction := create_prediction(configured["client"], {"input": {"prompt": "Say hello."}})
if !prediction["ok"] { print("Prediction request failed."); exit(1) }
print(prediction["data"]["id"])
```

For Vertex `generate_content`, pass `configured["model"]` as the request's
`model` field. For fal.ai, pass the configured model and returned request ID
to the status, result, or cancel operation. Keep each native client in
memory and log only selected response fields. The native packages own
their HTTP and authorization behavior.

## Built-in preset defaults

Use the same provider quickstart to call a built-in preset directly:

```sh
kujo run "$AI_SDK_ROOT/examples/provider_quickstart.kujo" -- llama-cpp models YOUR_MODEL_ID
kujo run "$AI_SDK_ROOT/examples/provider_quickstart.kujo" -- llama-cpp chat YOUR_MODEL_ID
```

| Provider ID | Default base URL | Credential | Connectivity and optional operations |
| --- | --- | --- | --- |
| `lm-studio` | `http://127.0.0.1:1234/v1` | `LM_STUDIO_API_KEY` optional | `models`, `chat`, `stream`, `studio-models`. Enable embeddings for a suitable loaded model. |
| `vllm` | `http://127.0.0.1:8000/v1` | `VLLM_API_KEY` optional | `models`, `chat`, `stream`, `schema`, `tools`. Use the served alias and select the appropriate tool parser and runner. |
| `llama-cpp` | `http://127.0.0.1:8080/v1` | `LLAMA_CPP_API_KEY` optional | `models`, `chat`, `stream`, `schema`, `cancel`. For `embed`, enable embeddings with a supported pooling mode. Tools depend on the model and Jinja template. |
| `sglang` | `http://127.0.0.1:30000/v1` | `SGLANG_API_KEY` optional | `models`, `chat`, `stream`, `schema`, `tools`. Use the appropriate backend, tool parser and model. |
| `moonshot` | `https://api.moonshot.ai/v1` | `MOONSHOT_API_KEY` | `models`, `chat`, `stream`, `tools`. Thinking models may require retaining their assistant `reasoning_content` on tool turns. |
| `minimax` | `https://api.minimax.io/v1` | `MINIMAX_API_KEY` | `chat`, `stream`, `tools`, `speech`. Set `KUJO_PROVIDER_VOICE` for the speech example. |
| `siliconflow` | `https://api.siliconflow.com/v1` | `SILICONFLOW_API_KEY` | `models`, `chat`, `stream`, `tools`, `embed`. Account region and model determine supported features. |
| `novita` | `https://api.novita.ai/openai/v1` | `NOVITA_API_KEY` | `chat`, `stream`, `schema`, `tools`. Select a model with the requested capabilities. |
| `voyage` | `https://api.voyageai.com/v1` | `VOYAGE_API_KEY` | `embed`, `rerank`. Choose a separate model for each operation. |
| `jina` | `https://api.jina.ai/v1` | `JINA_API_KEY` | `embed`, `rerank`, `reader`. Reader uses `r.jina.ai` and accepts a key if anonymous access is unavailable. |

For a self-hosted override, use `KUJO_PROVIDER_BASE_URL` and optionally
`KUJO_PROVIDER_API_KEY` with the example. Trusted application code can set
`base_url` and `api_key_env` on `configure_provider`. These presets allow
HTTPS and explicit loopback HTTP. Hosted presets scope credentials to the
fixed official origin. An anonymous local request omits Authorization.

## Chat and required capabilities

```kujo
from provider_registry import configure_provider, require_provider_capabilities
from ai_sdk import create_client, create_message, chat_completion

configured := configure_provider("llama-cpp", "YOUR_MODEL_ID", {})
if !configured["ok"] { print(configured["error"]); exit(1) }
requirement := require_provider_capabilities(configured["provider"], ["chat"])
if !requirement["ok"] { print(requirement["missing"]); exit(1) }
client := create_client(configured["provider"], null)
result := chat_completion(client, [create_message("user", "Say hello.")], {"timeout": 30, "max_retries": 0})
if !result["ok"] { print(result["error"]["code"]); exit(1) }
print(result["output_text"])
```

Set `enable_capabilities` for deployment-specific tools, schema, embedding or
reasoning support after checking the chosen model. The certification manifest
distinguishes documented candidates from features observed live. A JSON schema
request needs the normal OpenAI-shaped `response_format`; the SDK also validates
the output with the Kujo JSON Schema subset. Named and required tool calls
require a valid tool envelope with JSON object arguments.

Set `stream_usage: true` in the provider options only for servers that accept
`stream_options.include_usage`. Check normalized `usage.usage_source` before
using counts for billing or reporting. For transport cancellation on supported
runtimes, return false from `on_transport_chunk`. The normalized SDK response
retains buffered stream events within the configured response bound.

## Embeddings and reranking

```sh
kujo run examples/provider_quickstart.kujo -- voyage embed YOUR_EMBEDDING_MODEL
kujo run examples/provider_quickstart.kujo -- jina rerank YOUR_RERANKING_MODEL
```

The `embeddings(client, texts, options)` contract accepts one string or a batch,
and validates row count, index uniqueness and vector dimensions. Use
`dimensions` for supported models, `input_type: "query"` or `"document"` for
Voyage, and an appropriate `task` for Jina. Keep embedding model, dimensions
and retrieval task consistent with the index. Choose the ranking provider
separately and call `rerank(client, model, query, documents, {"top_n": 3})`.
Ranking indices refer to the original input positions. Scores are specific
to the selected model.

`jina_read`, `minimax_speech`, and `lm_studio_models` are explicit operations
in `provider_operations`. Reader sends a public URL to Jina. Speech returns
hex MP3 bytes. LM Studio REST v1 manages model keys and loaded instance IDs.
Only invoke load or unload in code that owns the server lifecycle.

## Troubleshooting

- Connection failure or timeout. Check server readiness, base URL, the
  requested model and the request timeout.
- Authentication error. Set the provider-specific key using a trusted secret
  source. For a fallback, set its own key or explicit `api_key`, and move
  custom headers into its own `options.headers`.
- Unsupported capability. Check the provider's model and server options.
  Enable the capability explicitly after verifying that deployment.
- Malformed response or interrupted stream. Check the server protocol
  version, model template and OpenAI-compatible endpoint.
- Private egress. Use Kujo's `--deny-private-net` or
  `KUJO_NET_DESTINATION_POLICY=deny_private` for managed workloads. Those
  controls intentionally disallow loopback. Configure an endpoint host
  allowlist in managed SDK calls as an additional control.

Run `bash scripts/verify_provider_live.sh` with only the model variables and
credentials you want exercised. Set `KUJO_BIN` for a pinned runtime. Missing
prerequisites produce `Not Tested` rows. Fixture contract tests use
`kujo test-run tests/provider_ecosystem_tests.kujo`.


Run the package consumer test with the 25 pinned package trees on one module
root. Name each directory after its `setup.alias` from the certification
manifest. Use the matching tag recorded in `setup.source`. The test uses
fixture transports for every request:

```sh
KUJO_MODULE_PATH="$PWD/src:/path/to/package-root" kujo run tests/provider_package_consumer.kujo
```
