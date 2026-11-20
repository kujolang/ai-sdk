# Configure a Kujo provider

Use Kujo 1.9.0 for the setup and connectivity checks below. From the AI SDK
checkout, set `KUJO_MODULE_PATH="$PWD/src"` so the examples can import SDK modules.
The published SDK 1.2.0 predates these presets.

```sh
export KUJO_MODULE_PATH="$PWD/src"
kujo run examples/provider_quickstart.kujo -- list
kujo run examples/provider_quickstart.kujo -- llama-cpp inspect
kujo run examples/provider_quickstart.kujo -- llama-cpp models YOUR_MODEL_ID
kujo run examples/provider_quickstart.kujo -- llama-cpp chat YOUR_MODEL_ID
```

List and inspect work offline. The other commands make an actual request and
print a short JSON outcome. Use a model identifier from your account or server.
For the existing standalone packages, inspect lists their repository and API docs.

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
