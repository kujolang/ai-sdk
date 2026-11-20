#!/usr/bin/env bash
# Only explicitly configured models can trigger billable requests.
set -uo pipefail
cd "$(dirname "$0")/.."
export KUJO_MODULE_PATH="$PWD/src${KUJO_MODULE_PATH:+:$KUJO_MODULE_PATH}"
kujo_bin="${KUJO_BIN:-kujo}"
failures=0
while read -r provider key model_var operations; do
  model="${!model_var:-}"
  if [[ "$key" != "-" && -z "${!key:-}" ]]; then
    printf '%s\tNot Tested\t%s not configured\n' "$provider" "$key"
    continue
  fi
  if [[ -z "$model" ]]; then
    printf '%s\tNot Tested\t%s not configured\n' "$provider" "$model_var"
    continue
  fi
  for operation in $operations; do
    if ! "$kujo_bin" run examples/provider_quickstart.kujo -- "$provider" "$operation" "$model"; then failures=$((failures + 1)); fi
  done
done <<'PROVIDERS'
lm-studio - LM_STUDIO_MODEL models studio-models chat stream
vllm - VLLM_MODEL models chat stream schema tools
llama-cpp - LLAMA_CPP_MODEL models chat stream schema cancel tools
llama-cpp - LLAMA_CPP_EMBED_MODEL embed
sglang - SGLANG_MODEL models chat stream schema tools
moonshot MOONSHOT_API_KEY MOONSHOT_MODEL models chat stream tools
minimax MINIMAX_API_KEY MINIMAX_MODEL chat stream tools
siliconflow SILICONFLOW_API_KEY SILICONFLOW_MODEL models chat stream tools
novita NOVITA_API_KEY NOVITA_MODEL chat stream schema tools
voyage VOYAGE_API_KEY VOYAGE_EMBED_MODEL embed
voyage VOYAGE_API_KEY VOYAGE_RERANK_MODEL rerank
jina JINA_API_KEY JINA_EMBED_MODEL embed
jina JINA_API_KEY JINA_RERANK_MODEL rerank
minimax MINIMAX_API_KEY MINIMAX_SPEECH_MODEL speech
PROVIDERS
if [[ "$failures" != 0 ]]; then exit 1; fi
