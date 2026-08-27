# Kujo Provider Package Contract v1 Conformance

Contract under review: [`KUJO_PROVIDER_PACKAGE_CONTRACT_V1.md`](KUJO_PROVIDER_PACKAGE_CONTRACT_V1.md)  
Evidence reviewed: remote `main` branches and release tags, 2026-08-27

This matrix tests the current references without imposing provider-specific API symmetry. `N/A` means the capability is not claimed by that provider; it is not a failure.

| MUST requirement | Ollama result | Anthropic result | Evidence | Applicability/notes |
|---|---|---|---|---|
| Explicit native layer | PASS | PASS | `src/ollama.kujo`; `src/anthropic.kujo` | Validated by both. |
| Separate public AI SDK driver | PASS | PASS | `src/provider.kujo`; driver IDs `ollama-native`/`anthropic-native` | Validated by both. |
| No provider branch in AI SDK core | PASS | PASS | AI SDK v1.1.0 source unchanged | Security/architecture. |
| Familiar install/import/first request | PASS | PASS | README quickstarts | Validated by both. |
| Safe client and endpoint validation | PASS | PASS | Native tests and reports | Provider host rules differ. |
| Native response fidelity | PASS | PASS | Native reports and fixture payloads | NDJSON vs content blocks. |
| Public driver contract | PASS | PASS | Driver tests `4/4` and `6/6` | Required hooks match capabilities. |
| No driver-owned network I/O | PASS | PASS | Driver descriptors plus AI SDK core transport | Validated by both. |
| Accurate capability declarations | PASS | PASS | Ollama embeddings; Anthropic explicitly omits embeddings | Optionality proven by Anthropic. |
| Provider-owned authentication/headers | PASS | PASS | Ollama local/cloud; Anthropic `x-api-key`/version | Validated by both. |
| Secret redaction and host safety | PASS | PASS | Security fixtures/reports | Security requirement. |
| Native stream parser when supported | PASS | PASS | Ollama NDJSON; Anthropic SSE | Both support streaming. |
| AI SDK stream normalization | PASS | PASS | Driver tests and reports | Existing AI SDK callback contract unchanged. |
| Tool mapping when supported | PASS | PASS | Native/driver tool fixtures | Model capability remains conditional. |
| Reliable usage mapping | PASS | PASS | Ollama eval counts; Anthropic token counts | No fabricated values. |
| Documented finish mapping | PASS | PASS | `done_reason`/`stop_reason` tests | Provider-specific mappings. |
| Native/AI SDK error layers | PASS | PASS | Driver error hooks and reports | Existing AI SDK categories used. |
| Valid Kennel manifest and exports | PASS | PASS | Manifest validation reports | Platform requirement. |
| Immutable AI SDK dependency | PASS | PASS | `github:kujolang/ai-sdk@v1.1.0` | Validated by both. |
| Clean-room install outside checkouts | PASS | PASS | Phase 2/Anthropic reports | Blocking distribution requirement. |
| Lockfile reinstall | PASS | PASS | Both installed gates | Deterministic source refs recorded. |
| Installed consumer smoke | PASS | PASS | Ollama `1/1`; Anthropic `1/1` | `KUJO_MODULE_PATH` explicitly configured. |
| Offline default gate | PASS | PASS | Ollama `10/10`; Anthropic `12/12` | Credential/network free. |
| Live status honestly reported | PASS | PASS | Both report skipped environments | Skips are not claimed as passes. |
| No destructive default operations | PASS | PASS | Fixture-only lifecycle/tool tests | Security requirement. |
| README/report evidence | PASS | PASS | Required artifacts in both repos | Validated by both. |

## Results

- Ollama: **CONFORMANT** — Native Package, AI SDK Integrated, Distribution Validated, Release Ready.
- Anthropic: **CONFORMANT** — Native Package, AI SDK Integrated, Distribution Validated, Release Ready.

The `KUJO_MODULE_PATH` requirement is recorded as current platform ergonomics debt, not provider non-conformance. Live provider execution was skipped in both environments and is optional under the contract when deterministic gates pass.
