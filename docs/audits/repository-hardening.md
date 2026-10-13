## Repeat hardening sweep — 2026-10-13

Repository: `kujolang/ai-sdk`, branch `main`. Starting SHA: `cd71f68184318eee9f57e4ca8840dca087f01c83`. Implementation ending SHA: `c23781d9f0d71a614ffc30078c5c3bbc7686c169`; the following documentation-only commit records this receipt. Scope remains the SDK; no sibling repository or published runtime was changed.

The SDK normalizes provider chat/embeddings, streaming, retries, governance, model metadata and Watchdog telemetry. This pass rechecked the request/fallback lifecycle, strict and legacy state ownership, native HTTP policy, provider descriptors and credentials, stream parsing/normalization, catalog generation, telemetry projection, wrapper staging/cleanup, dependency manifests, CI and release scripts. Existing public decoders and legacy best-effort semantics remain compatibility boundaries. Drivers are trusted executable dependencies; core owns transport and accounting. Kujo supplies HTTP and process-local shared storage; there are no package dependencies to remove.

### Verified changes

| Problem / root cause | Implementation and files | Proof / compatibility |
| --- | --- | --- |
| **P1 resolved:** fallback entry options could select strict governance, an atomic-only backend in best-effort mode, or an unknown mode while bypassing the public guard. Direct recursion into the request implementation allowed provider calls and accounting despite another owner holding the backend | Route chat and embedding fallback through a common `fallback_request` boundary in `src/ai_sdk.kujo`. Reject strict fallback and reuse public mode/backend validation | `tests/fallback_governance_tests.kujo`: chat, embeddings and normalized streaming each exercise all three override modes. Assert terminal `state_backend_error`, zero fallback transport calls, no usage write, preserved lock ownership and no later-provider escape. All three tests fail on the starting SHA on both published runtimes and pass after the fix |
| Runtime compatibility CI omitted recent state and transport regressions | Add persistence, atomic accounting, fallback governance and transport-policy suites to `.github/workflows/compatibility-matrix.yml`; add the new suite to `scripts/release_quality_gates.sh`, raising aggregate floor 182 → 185 | Existing tests/thresholds are retained. The local full gates pass on both versions; hosted CI was not executed locally |

README and API contract policy now make the fallback override boundary explicit. Public signatures, exports, contract versions, CLI behavior, file formats, schemas, environment variables, dependency surface and accepted configuration keys are unchanged. Only invalid fallback governance combinations now fail closed. A primary request may already have failed before a fallback is reached; valid best-effort fallback still works. No changes are required in consumers or Kujo backports.

### Verification and measurements

Evidence directory: ignored local `artifacts/sweep-2026-10-13/`. Published runtime paths and hashes are the same as the transport receipt below.

| Check | Baseline | Final |
| --- | --- | --- |
| Full release gates, Kujo 1.5.0 | 182 Kujo tests pass | 185 pass |
| Full release gates, Kujo 1.6.0 | 182 Kujo tests pass | 185 pass |
| New fallback regressions staged into starting SHA | 0/3 on each runtime | 3/3 on each runtime, covering nine combinations |
| Wrapper / native HTTP harness, each published runtime | 2 wrapper tests; 4 HTTP tests pass, 2 readable-consumer-only skips | Same passes and explicit capability skips |
| Docs, examples, response schemas, six benchmark gates | Pass | Pass with unchanged thresholds |

The source-backport binaries from the preceding transport task additionally pass all three new fallback regressions and all six native HTTP tests each, with readable collection required (no skips). Those HTTP tests include VM/interpreter execution. Backport binaries were reused by exact path under `/tmp/ai-sdk-transport-binaries/`; no rebuild or new runtime claim is implied. Their focused Kujo tests use the already documented `RUST_MIN_STACK=16777216` debug-build setting.

Representative existing benchmark latency (ms per operation; baseline → final):

| Case | Kujo 1.5 | Kujo 1.6 | Existing maximum |
| --- | --- | --- | --- |
| Chat normalization | 8.837 → 2.977 | 5.330 → 2.283 | 30 |
| Stream parsing/normalization | 13.420 → 3.820 | 7.527 → 3.150 | 40 |
| Chat retry | 8.515 → 1.970 | 3.650 → 1.665 | 50 |

These are load-sensitive verification samples, **not a speedup claim**: the change only adds validation to fallback attempts. No token savings, memory reduction, payload reduction or throughput improvement is claimed. Existing response-size bounds and explicit memory lifecycle remain. Wrapper staging still preserves arbitrary repository inputs; excluding ignored files without a compatibility contract was not justified. No new cache, dependency, log channel or model-visible context was added; verbose evidence stays in artifacts.

Commands (exit 0 unless explicitly noted):

```sh
# Each command ran before and after the change, serially.
KUJO_BIN=/Users/robertdevore/.local/bin/kujo bash scripts/release_quality_gates.sh
KUJO_BIN="$PWD/artifacts/audit-2026-10-12/runtime16/kujo" bash scripts/release_quality_gates.sh
# New tests copied into a temporary git archive of the starting SHA:
# both published binaries: test-run tests/fallback_governance_tests.kujo
# Expected exit 1, 0/3 passing; logs fallback-final-before15.log / ...16.log.
KUJO_BIN=/Users/robertdevore/.local/bin/kujo ./kujo test-run tests/fallback_governance_tests.kujo
KUJO_BIN="$PWD/artifacts/audit-2026-10-12/runtime16/kujo" ./kujo test-run tests/fallback_governance_tests.kujo
# For version=15 and version=16:
KUJO_BIN="/tmp/ai-sdk-transport-binaries/kujo${version}-patched" RUST_MIN_STACK=16777216 ./kujo test-run tests/fallback_governance_tests.kujo
KUJO_BIN="/tmp/ai-sdk-transport-binaries/kujo${version}-patched" KUJO_REQUIRE_STREAM_COLLECT=1 python3 tests/runtime_transport_tests.py
bash scripts/supply_chain_policy_check.sh
bash scripts/verify_docs.sh
bash -n scripts/release_quality_gates.sh
git diff --check
KUJO_BIN=/Users/robertdevore/.local/bin/kujo ./kujo run examples/model_preferences.kujo
KUJO_BIN=/Users/robertdevore/.local/bin/kujo ./kujo run scripts/generate_model_catalog.kujo --interpreter -- examples/dispatch-model-catalog.config.json --output /tmp/ai-sdk-sweep-catalog.json
KUJO_BIN=/Users/robertdevore/.local/bin/kujo ./kujo run examples/telemetry_bridge.kujo --interpreter
```

### Remaining scope

- No unresolved P0/P1/P2 finding or cross-repository requirement was admitted by this repeat sweep. This is not a claim of exhaustive absence of defects.
- **Needs more evidence:** hosted CI/other operating systems, paid-provider conformance and external distributed backend fencing were not exercised. The local suite's live-provider smoke remains fixture-safe when secrets are absent.
- **Not worth changing in this pass:** broad decoder/module rewrites, public compatibility API removal, catalog sorting changes without a measured workload, or wrapper exclusions that could omit runtime assets.
- No new SignalBox capture is warranted for the completed fix or routine verification. Earlier report sections retain historical findings and are superseded by their corresponding follow-ups.

---

## Runtime transport follow-up — 2026-10-13

Scope: `kujolang/ai-sdk` main, starting `e28a57469e366b3f8265270f05f5cb00eee9b3a3`, implementation ending `541bcd2`; the user explicitly authorized Kujo runtime changes and source backports. Runtime main starts at `6695bd9beac4787c9d2db768e9f61dfdb26a95a5` and ends at `d6ed9c0cfa76a1f17fb87020b9e9a77950c7fc25`. Source backports are `302bbb19ac4fb661843e4e2e3d633f7bae5d794b` on `codex/http-stream-consumer-1.5` (base `v1.5.0`, `cc2d7dbb59a8dc05f00d629e100932f56f4062f6`) and `92e0e0a8125da5d005c1e4f5f9a9784f436158a9` on `codex/http-stream-consumer-1.6` (base `v1.6.0`, `44af277848173664f72ca85f2a1b3b98d634ecdd`). Release tags and published binaries are unchanged.

| Problem and root cause | Implementation | Evidence and compatibility |
| --- | --- | --- |
| SDK endpoint allowlists validated only the first URL while native HTTP followed redirects | Forward explicit redirect policy; force `none` under endpoint allowlists | Real 307 redirect to a different host is not followed under the allowlist in VM/interpreter. Default `follow` remains without an allowlist; explicit `none` is additive |
| Configured raw response limits were applied after native download | Forward positive integer byte limits before native reading, preserving the 8 MiB ceiling; normalize size failures as terminal `response_too_large` | Content-Length and chunked overflow, chat and embeddings, one request despite configured retries |
| Runtime incremental bodies could be forwarded by a server but not consumed by SDK code | Add capability-gated `http_stream_collect(response, callback)` and `http_request(..., {response_stream:"collect"}, callback)` in Kujo; SDK `on_transport_chunk` opts into it | Server withholds the rest of its body until a callback marker appears. Split UTF-8, cancellation, thrown callbacks, reentrant aliases, single use, and denied capabilities are covered |
| Native HTTP error dictionaries included non-JSON byte buffers | Omit native byte values in raw error envelopes | Non-JSON 307 responses now remain serializable in the existing error schema |
| Retrying a failed incremental request could replay already-observed text | Native incremental failures and final structured-output failures are terminal | Callback cancellation/exception, byte overflow, and invalid final structured output cause no replay; legacy custom `Err` transport behavior stays retryable |

Source changes are in `src/ai_sdk.kujo`; regression coverage is in `tests/transport_policy_tests.kujo` and `tests/runtime_transport_tests.py`, with the release gate floor raised from 179 to 182. The Python standard-library harness provides an independent loopback server only; actual SDK behavior remains Kujo. Runtime changes are limited to HTTP collection, builtin registration, type/arity metadata, capability mapping, unit tests, and API documentation. No new dependency, response-schema version, CLI flag, file format, or SDK environment variable was introduced. Custom transports keep their two-argument signature and must enforce forwarded transport limits themselves.

The new hook exposes transport text fragments, not normalized semantic deltas. Existing normalized streaming callback timing is unchanged. Collection retains the bounded complete body for final decoding; no constant-memory sink claim is made. Cancellation cannot establish provider billing completion. Unpatched published 1.5/1.6 reject opt-in collection before I/O with `unsupported_feature`; their redirect/download fixes work without a runtime upgrade. Signed/query authentication remains outside the existing descriptor contract.

### Verification

| Runtime / check | Result |
| --- | --- |
| Published 1.5.0, final serial `scripts/release_quality_gates.sh` | Pass: 182 Kujo contracts, 2 wrapper tests, 4 HTTP harness tests with 2 consumer-only skips, examples, schemas, docs, and unchanged benchmark gates |
| Published 1.6.0, final serial release gate | Pass: the same 182 contracts, 2 wrapper tests, 4 HTTP tests with 2 consumer-only skips, examples, schemas, docs, and unchanged benchmark gates |
| Source backports 1.5.0 and 1.6.0 | Each passes all 182 contracts and all 6 live HTTP harness tests; consumer capability is required, so none skip |
| Current runtime 1.8.1 source | 6 HTTP harness tests, 3 transport policy tests, 31 core SDK contracts, 2 new collector unit tests, 2 existing incremental HTTP unit tests, and all 5 standard-library inventory tests pass |
| Formatting / ancillary checks | `cargo fmt --check` passes on all three source checkouts; SDK docs, supply-chain checks, model preferences, catalog generation and telemetry examples pass |

Before/after proof: staging only the three new policy regressions into starting SDK `e28a574` yields **0/3 passing on both published runtimes**; the completed SDK passes 3/3. The published runtimes lack the readable consumer API; opt-in rejection before any server request is separately asserted. Actual incremental delivery is proven on each patched runtime by the server waiting for the first callback before sending the remainder, in both VM and interpreter modes.

Build commands were `CARGO_PROFILE_DEV_DEBUG=0 cargo build --manifest-path ../kujo/Cargo.toml --no-default-features --features runtime-network,runtime-db --bin kujo` for current Kujo and `CARGO_PROFILE_DEV_DEBUG=0 CARGO_BUILD_JOBS=2 CARGO_TARGET_DIR=/tmp/kujo-backport-target cargo build --manifest-path /tmp/ai-sdk-kujo15/Cargo.toml --no-default-features --features runtime-db --bin kujo` for 1.5. The 1.6 command uses its corresponding source path and additionally `--locked`. No lockfile changed. Backports were checked out from the exact tags above, committed on separate branches, and never substituted for installed runtimes.

Run HTTP verification with `KUJO_BIN=<binary> python3 tests/runtime_transport_tests.py`; add `KUJO_REQUIRE_STREAM_COLLECT=1` for each patched binary. The 19 contract suites listed in `scripts/release_quality_gates.sh` were run individually through `./kujo test-run`, with their existing floors and zero failures enforced by local `artifacts/runtime-transport/backport_contracts.py`. Unoptimized backport contract runs use the existing Rust setting `RUST_MIN_STACK=16777216`: the default debug worker stack overflowed in the atomic suite, including with the starting SDK on the same binary; the 16 MiB setting passes all 12 atomic tests. This is a test-build qualification, not a new SDK setting or a claim that default debug worker stacks support every workload. Published optimized runtime gates use normal stack settings. Native HTTP tests pass without this adjustment.

Current runtime unit/inventory commands use `CARGO_PROFILE_DEV_DEBUG=0 CARGO_BUILD_JOBS=2 cargo test --manifest-path ../kujo/Cargo.toml --no-default-features --features runtime-network,runtime-db`, followed respectively by `--lib stream_collect`, `--lib http_request_incremental`, and `--test stdlib_reference_contract`. Full runtime-wide/JIT suites were not run; verification targets the changed HTTP boundary and SDK consumers.

Early simultaneous published gates passed contracts but failed stream-parsing benchmarks under compilation load (1.5: 43.203 ms; 1.6: 51.723 ms, threshold 40 ms). Those failures remain in the logs. Final gates pass serially after this task's builds, with unchanged thresholds: stream parsing measures 13.747 ms on 1.5 and 18.717 ms on 1.6. No speedup is inferred from these load-sensitive measurements. Temporary build caches/worktrees were removed after verification; frozen patched binaries moved to `/tmp/ai-sdk-transport-binaries/` so the SDK wrapper does not repeatedly stage them.

| Binary evidence | SHA-256 |
| --- | --- |
| Published 1.5.0 | `3e1e475ea165c8b4a714495596fe8661ad970b27119ad44f1db4d9779f7f05d4` |
| Published 1.6.0 | `930e0da1fec2562f6990d1226a479330640c8c78eb4c36c148cee3f950b29a47` |
| Patched current source | `3e59516bd9647b336867c8203c82c9cb33582ebdeee57df90c9cb891c0a1226d` |
| Patched 1.5.0 source | `49dac28f3f6413067ce63c637b45fc6df9e1eb5917900cd546657c71d293ac85` |
| Patched 1.6.0 source | `f78c6f324ee36c305d4112e6d17ffab2a692d0d23a769a66ad21e0b39fd0509f` |

Evidence is under ignored local `artifacts/runtime-transport/`. Earlier report sections below retain their historical status; this section supersedes their open redirect/download/incremental-consumption limitations. No throughput, memory-reduction, or model-token savings claim is made. Hosted CI, other operating systems, JIT execution, and paid provider conformance were not exercised in this local transport pass.

---

## Atomic concurrent accounting follow-up — 2026-10-12

Implemented the opt-in fail-closed contract requested by governance SignalBox `sig_7a8e3644-16cf-4024-a23f-6eab0be037cc`. `governance_mode: "strict"` takes backend ownership before preflight and retains it through provider execution, retries and both counter writes. Contention and hook failures produce non-retryable, redacted `state_backend_error` in the existing error schema. A failed operation releases with an unhealthy flag, requiring quarantine before another acquisition. Admitted chat state is finalized when accounting throws. Stream calls use the same guard.

`atomic_memory_backend()` implements atomic admission using the Kujo runtime's locked integer increment, with owner checking, authoritative state and quarantine after uncertain writes. Initialize one handle and share it with participating clients. Reset is explicit and refuses active owners. External backends receive a documented acquire/get/set/release contract with fencing and durable quarantine requirements. Legacy best-effort behavior, signatures, key formats, version 1.0.0 response schemas and the minimum runtime version remain unchanged; strict mode rejects legacy memory-backend fields and provider fallback to prevent unguarded scope changes.

Verification on installed Kujo 1.5.0 and checksum-verified published 1.6.0:

- Full `scripts/release_quality_gates.sh`: **179 Kujo tests, 2 Python wrapper tests**, examples, schemas, docs and unchanged benchmark thresholds pass on each runtime.
- Twelve focused atomic-accounting tests pass on each runtime, including spawned-thread overlap with an explicit barrier, reentrant contention, token/cost totals, authoritative zero defaults despite local seeds, lock ownership, partial writes, outage quarantine/reset, malformed counters, throwing lock hooks, streaming and live-state cleanup after accounting exceptions.
- A staged copy of starting commit `17bb65d` with only the new backend fixture exposed fails 9 of those 12 tests on both runtimes. The three passing cases exercise the standalone factory or retained legacy behavior; the nine failures establish missing guarded accounting behavior in the old SDK.
- Final strengthened focused tests pass after the full gates; docs, supply-chain policy, model preference/catalog generation and telemetry examples pass. Evidence: `artifacts/concurrent-accounting/` (local ignored logs and probes). No sibling repository code changed.

Scope: concurrent lost updates and preflight races are closed for requests participating in the strict contract. Existing best-effort clients remain best-effort for compatibility. Serialization is not a provider-side hard cap: one completed request can exceed the remaining budget and is still charged before rejection. Unknown transport completion, process loss and incorrectly implemented external locks require external reconciliation; no live distributed service or hosted-CI validation is claimed. The unrelated runtime transport follow-up remains separate. Earlier report sections below retain their historical status and are superseded by this opt-in contract where applicable.

---

## In-memory persistence follow-up — 2026-10-12

The single-process persistence finding below is resolved. Runtime `shared_get`/`shared_set` storage retains explicit counter buckets on both Kujo 1.5.0 and 1.6.0 despite dictionary value copying. New clients receive opaque identities; copies share that identity, independently created clients do not. Dictionary backends seed per-client/namespace state, and explicit registry IDs share backend counters across clients. Existing hook precedence, key formats, error/response schemas and seed overrides remain compatible. New state inspection and cleanup exports document lifecycle ownership; no disk persistence, automatic eviction, credentials or payload storage is introduced.

Validation: 7 of the initial 8 focused regressions failed against the original implementation on both runtimes. The completed 12-case suite passes on both, covering local tokens, all three cost-backend modes, dictionary seeds and isolation, registry sharing/namespaces, breaker persistence, seed overrides, reentrant admission, trace sequences, snapshots and cleanup. Existing transport/descriptor cleanup regressions now inspect live state rather than unchanged caller dictionaries. Full release gates pass on each runtime: **167 Kujo tests, 2 Python wrapper tests**, examples, contract schemas, documentation and six benchmark thresholds. Supply-chain policy and whitespace checks pass. Logs: `artifacts/state-persistence/`; runtime binaries/checksums are the same as the preceding audit.

`client_state` reports local counters, not a fresh external-backend read. Client cleanup restores seeds but leaves shared registries intact; registry cleanup requires quiescent users and does not erase their local fallback counters. Compound updates remain non-atomic; persistent hook failures still fail open. These existing distributed-governance concerns remain open in SignalBox `sig_7a8e3644-16cf-4024-a23f-6eab0be037cc`. The narrower persistence signal `sig_1ef6f2be-06c2-46eb-b46f-0f7303e2c093` is resolved by this follow-up. Earlier sections below are retained as historical evidence, including their original unresolved status. No live-provider or hosted-CI validation is claimed.

---

# AI SDK hardening audit — October 12, 2026

- Repository: `kujolang/ai-sdk`, branch `main`; write scope: this repository.
- Starting SHA: `71bad1468fbc97eab830a27c185c032f07fd76cf` (clean).
- Ending implementation/documentation SHA: `56d6b4ca7baec07c4abec00c1f5bec10260be2da`; the subsequent report-only commit is identified by `git log -1 --format=%H -- docs/audits/repository-hardening.md`. This avoids a self-referential commit hash.
- Integration: initial push was rejected because remote `main` already contained release commits. Merged `origin/main` at `1f4c7678506d2ce76e26e67e4697e08ceca108c2` without conflicts in merge `9ef1bbf4a7314f45d08cff5da9bc1130a005652f`. The upstream changes set package 1.1.1 / minimum Kujo 1.6.0, use pinned setup actions and preserve a maintainer-authorized live-provider waiver for v1.1.1 only. No runtime source changed in this merge.
- Runtime: installed `/Users/robertdevore/.local/bin/kujo`, `kujo 1.5.0`.
- Purpose: library for normalized chat/embeddings, native provider drivers, model catalogs, governance and metadata telemetry. No standalone SDK CLI.
- Dependencies: zero Kennel runtime/dev packages before and after. Kujo owns HTTP, JSON, value semantics and execution. Verification uses Bash, Python standard library, rsync, Git and shasum. No dependencies added or updated.
- Integrations inspected: public provider-package contract, Ollama embedding encoder (reads `context["input"]`), Anthropic provider adapter, Agents SDK adapter/stream contracts, Dispatch catalog and Watchdog metadata contracts. No sibling files changed; no downstream update required for these fixes.

## Baseline and audit coverage

Read all six implementation modules, exports/manifests, README, architecture/runbook and public contracts; inspected tests/fixtures, examples, scripts, eval configuration, schema checks, CI/release/compatibility workflows, wrapper and artifact policy. Reviewed hot paths, resource lifetime, error boundaries, provider/descriptor input, protected headers, endpoint host checks, credential redaction, response limits, retries/fallbacks, state persistence, shared governance, shell/process operations and generated catalog output.

The original full release gate passed **150 Kujo tests plus 2 Python wrapper tests**, documentation command checks, schemas, examples and all six performance thresholds. The live-smoke test selected the credential-free skip branch; this is not live-provider evidence. No separate package build, lint, formatter or type-check script is configured. Smoke/benchmark commands are warning-gated. Hosted pinned-runtime workflows were not executed locally.

Baseline deficiencies reproduced in an isolated archive of the starting commit with the final new tests copied in: five hardening regressions failed and the strengthened native embedding test failed. Existing tests remained unchanged apart from strengthening the native request assertion. Six local documentation links pointed to four deleted files; existing docs checks missed them. Raw logs and reproduction scripts are ignored local evidence under `artifacts/audit-2026-10-12/`.

## Changes and proof

| Problem / root cause | Implementation / files | Regression evidence | Compatibility / impact |
| --- | --- | --- | --- |
| Native embeddings received null: request-context wrapper discarded the payload input | Forward payload input in `src/ai_sdk.kujo` | `tests/external_driver_fixture_tests.kujo` asserts actual encoded passages, not only response vectors; failed before, passes after | Restores documented driver contract; Ollama reads this field. No provider rewrite |
| Usage metadata erased by each stream frame lacking usage | Initialize usage once; only normalize usage-bearing frames in core | New hardening test preserves cache/reasoning counters, provider usage and total semantics after a null-usage frame | Existing normalized keys and counts preserved; no context truncation |
| Already-consumed usage lost when token/cost overrun rejected the result; chat/embedding accounting duplicated | One shared post-response accounting helper persists both counters before budget rejection | New persistent `get`/`set` fixture plus chat-token and embedding-cost overrun tests verify storage and next-client rejection | Persistent backends now record accurate consumed usage; unchanged field shapes/error codes. No atomic reservation claim |
| Structured-output failures escaped accounting and retries reused stale preflight | Account successful provider usage before structured validation; recheck governance before retry | Two 5-token invalid responses exhaust a 10-token limit and prevent a third transport call | Budget enforcement can stop retries earlier; expected correction for configured limits |
| Descriptor rejection bypassed chat finalization | Use common finalizer with zero attempted calls | Repeated rejection has stable policy error and zero-attempt observability | Additive observability; persistent admission leak was **not** reproduced on the installed value-copying runtime |
| Docs linked deleted release/backlog files and stated obsolete test floor; new regressions needed a ratchet | README, adoption/API/architecture/runbook/changelog; `verify_docs.sh` checks guide file targets; release gate raises hardening floor 2→7 and aggregate floor 125→155 | Docs pass; injected missing target fails; full release gate passes | File-target checks are offline and limited to inline links in README/top-level guides; no anchor/network claims |

Core accounting duplication was removed only where chat and embeddings had identical behavior; operation-specific fallback estimates remain separate. Exported compatibility decoders and the larger core were retained: downstream uses and protocol differences do not justify a broad rewrite. No dead public API or dependency removal was proven safe.

## Measurements

Paired serial baseline/final runs on the same installed runtime, three trials each, using the unchanged `scripts/benchmark_quality_gate.kujo`. Values are workload milliseconds (300 iterations for normalization, 200 for retry arithmetic), not request network latency:

| Workload | Baseline trials / median | Final trials / median |
| --- | --- | --- |
| Chat fixture | 499, 617, 604 / 604 | 476, 524, 603 / 524 |
| Embedding fixture | 492, 453, 617 / 492 | 448, 478, 479 / 478 |
| Chat parsing | 659, 626, 934 / 659 | 640, 676, 683 / 676 |
| Stream parsing | 919, 895, 1539 / 919 | 903, 865, 903 / 903 |
| Chat retry arithmetic | 326, 337, 481 / 337 | 335, 337, 351 / 337 |
| Embedding retry arithmetic | 322, 332, 448 / 332 | 329, 321, 426 / 329 |

All unchanged thresholds passed. Variation is substantial; **no general speedup is claimed**. Streaming no longer reconstructs unused usage metadata on every non-usage frame (code-supported reduction of work). Test coverage grew 150→155 Kujo cases plus the strengthened native test; wrapper coverage remains 2 cases. Stress: 3,000 successes / 0 errors.

No model prompt/tool schema/context policy changed; no token savings are claimed. Raw responses and callback event retention remain for compatibility. Gate output remains inspectable and logs are saved to files rather than copied into the final chat. Build size/RSS were not meaningful measurements for this library-only pass; dependency surface remains 0/0.

## Security, resources and remaining work

Security review preserved host binding, HTTPS/local opt-in, protected headers, driver exception containment, configured response-size guards, redaction and bounded retries. This pass hardens accounting and failure lifecycle; it does not certify every provider or the runtime HTTP implementation. Drivers remain trusted executable code. Response limits apply after receipt; buffered callbacks do not establish bounded download memory or incremental network delivery. Existing transport follow-up remains `cap_4c3353ba-2dd7-4ad1-aa9f-00c260e8907d`.

- **P0:** none established.
- **P1:** In-memory state does not persist across calls on installed Kujo 1.5.0 or the checksum-verified published Kujo 1.6.0 binary. With budget 20 and fixture usage 20, two calls both succeed for a reused client with null, `{state:{}}`, and `{registry_id:"audit-state-probe"}` backends. Client counter remains absent. See `state-probe.kujo`/`.log` in local evidence. Explicit persistent backend hooks work in the new regressions. Portable state handles and runtime compatibility require a deliberate contract; silently changing client value semantics or adding hidden filesystem persistence is not safe. Documented mitigation: persistent hooks and externally serialized admission. This extends the existing non-atomic/fail-open backend design concern; hook failures and distributed races remain unresolved.
- **P2:** no further implementation change admitted without more evidence.
- **P3 / not worth changing:** whole-core rewrite, removal of public compatibility adapters, dependency substitution and arbitrary response/token truncation.
- **Needs more evidence:** hosted CI against pinned runtime refs, live provider conformance and runtime redirect/download/streaming guarantees. No secrets/network inference required by local verification.

Cross-repository review: Kujo runtime/state contract owners should agree on supported mutable state handles and verify runtime modes before promising local admission/counter persistence. Current fixes do not require a runtime change. Existing HTTP follow-up requires runtime capability evidence before SDK redirect/download guarantees. Compatibility concern: preserve current value semantics and backend hooks rather than introducing implicit shared state. Native package owners can consume the embedding fix through an ordinary SDK revision update; no source rewrite required.

## Contract statement

The audit fixes leave public exports/signatures, CLI commands, file formats, schemas, config fields, environment variables and contract versions unchanged. Integrated upstream release metadata sets package 1.1.1 and minimum Kujo 1.6.0. Descriptor errors gain zero-attempt observability; normalized usage metadata is preserved. Configured persistent governance records usage previously lost on rejection, so external consumers may observe higher accurate totals and earlier retry termination. Failed transport/HTTP calls with no normalized successful usage are not assigned fabricated token charges.

## Exact verification commands

All run from repository root unless stated. Logs are under `artifacts/audit-2026-10-12/`.

| Command | Result |
| --- | --- |
| `KUJO_BIN=/Users/robertdevore/.local/bin/kujo bash scripts/release_quality_gates.sh` before / after | PASS: 150→155 Kujo tests, 2 Python tests, examples, docs, schema checks and six benchmark thresholds |
| `kujo test-run tests/hardening_regression_tests.kujo -v` | PASS 7/7; final tests against original archive: 5 failures |
| `kujo test-run tests/external_driver_fixture_tests.kujo -v` | PASS 5/5; strengthened test fails on original archive |
| `python3 artifacts/audit-2026-10-12/verify-baseline.py` | Confirmed expected original-source failures; initial Python 3.9 invocation rejected newer tarfile filter keyword, corrected for trusted local Git archive |
| `python3 artifacts/audit-2026-10-12/compare-benchmarks.py` | PASS: six paired benchmark processes; underlying command `kujo run scripts/benchmark_quality_gate.kujo --interpreter` |
| `kujo run artifacts/audit-2026-10-12/state-probe.kujo --interpreter` | Reproduces unresolved in-memory persistence limitation in all three modes |
| `kujo run examples/model_preferences.kujo` | PASS |
| `./kujo run examples/telemetry_bridge.kujo --interpreter` | PASS |
| `kujo run scripts/generate_model_catalog.kujo --interpreter -- examples/dispatch-model-catalog.config.json --output artifacts/audit-2026-10-12/catalog.json` | PASS |
| `kujo run scripts/stress_harness.kujo --interpreter` | PASS: 3000/3000 |
| `bash scripts/verify_docs.sh` | PASS; isolated copy with appended missing-file link correctly fails |
| `bash scripts/supply_chain_policy_check.sh` | PASS; immutable action/runtime ref policy, not a current CVE certification |
| `bash -n kujo scripts/*.sh .github/scripts/*.sh` | PASS |
| `bash scripts/generate_integrity_manifest.sh artifacts/audit-2026-10-12` then `shasum -a 256 -c artifacts/audit-2026-10-12/integrity-manifest.sha256` | PASS; local manifest only, no new SBOM/attestation claim |
| `./kujo run examples/main.kujo`, `./kujo run examples/production_profile.kujo`, existence of `kennel.toml` and `kujo.toml` | All four `tests/ai_sdk_eval.json` checks PASS |
| `git diff --check` | PASS after removing one introduced trailing space |

An intermediate persistence fixture omitted `write_file(..., true)` and therefore failed on overwriting its JSON state. Explicit overwrite fixed the test-only backend; no production errors were concealed or timeouts relaxed.

## Remote integration verification

Downloaded `kujo-v1.6.0-macos-x64.tar.gz` and its `.sha256` via `gh release download v1.6.0 --repo kujolang/kujo --pattern kujo-v1.6.0-macos-x64.tar.gz --pattern kujo-v1.6.0-macos-x64.tar.gz.sha256 --dir artifacts/audit-2026-10-12/runtime16`. `shasum -a 256 -c kujo-v1.6.0-macos-x64.tar.gz.sha256` passed in that directory before extraction. Binary hash `930e0da1fec2562f6990d1226a479330640c8c78eb4c36c148cee3f950b29a47` matches the upstream release evidence.

The merged source was verified with `KUJO_BIN="$PWD/artifacts/audit-2026-10-12/runtime16/kujo" bash scripts/release_quality_gates.sh`: 155 Kujo tests, 2 Python tests, documentation, schemas, examples and benchmarks passed. `artifacts/audit-2026-10-12/runtime16/kujo run artifacts/audit-2026-10-12/state-probe.kujo --interpreter` reproduced the same in-memory limitation. Updated supply-chain policy, documentation links and `git diff --check` passed. The source artifact guard passed for the three audit commits before integration; final range is checked against upstream release head. Hosted execution and live inference remain unverified.

## Durable records

SignalBox: Capture `cap_13039d36-b35a-4d0c-8325-6975a52026ca`; Signal `sig_1ef6f2be-06c2-46eb-b46f-0f7303e2c093` for in-memory state persistence. Exact-ID retrieval and concept search `in-memory` returned both. Existing distributed-governance and HTTP follow-ups were not duplicated; the new capture explicitly links the earlier governance capture because it adds single-process evidence. Completed fixes, routine results, and speculative rewrites were rejected as capture material. Strata receives the final handoff/current-state timeline with this report and final Git identity.

---

# Historical September 2026 audit

# AI SDK repository hardening receipt

## Repository

- Repository: `kujolang/ai-sdk`; implementation scope was this checkout only.
- Branch: `main`.
- Starting SHA: `0bb4b313867d6dd341f91da852afcc5ea25606bf` (clean tree).
- Ending implementation SHA: `62aaaeafe573c9f0dd69b93293b696de916d025f`; the final report-only commit is available with `git log -1 --format=%H -- docs/audits/repository-hardening.md`.
- Audit date: September 4–5, 2026, America/Detroit / UTC boundary.
- Purpose: Kujo library for provider-neutral chat, embeddings, driver descriptors, model catalogs, governance, and Watchdog telemetry. No standalone SDK CLI; examples and catalog generation are runnable commands.
- Dependencies: zero Kennel runtime or development packages. Kujo supplies HTTP, JSON, hashing, state/value semantics, and execution. Shell verification uses Bash, rsync, Python standard library, shasum and Git. Package metadata remains 1.1.0; response, driver and model-catalog contracts remain 1.0.0.
- Integrations reviewed from local contracts: native provider packages, Dispatch model routing, Watchdog telemetry, AI Chat / Agents SDK consumers. No sibling repository was modified.

## Baseline

Read the implementation of all six source modules, package manifests, source exports, public contracts, examples, tests, benchmark/stress scripts, shell tooling, CI/release workflows and repository artifact policy. The SDK has no separate build, formatter, linter, dependency install or static-type command configured. Runtime command warning gates supply the existing example/static-warning check. No runtime dependency upgrade was justified.

Local runtime: `/Users/robertdevore/.local/bin/kujo`, reporting `kujo 1.0.0`. This is a local verification result, not proof that the historical CI runtime commits behave identically.

Before changes:

- `KUJO_BIN="$(command -v kujo)" bash scripts/release_quality_gates.sh`: passed 138 Kujo tests, schema checks, two examples, six benchmark thresholds. The live-smoke test takes its no-key skip branch locally (reported as passed by Kujo).
- `kujo test-run tests/model_catalog_tests.kujo`: 7/7 passed, but this suite was absent from release gates.
- `bash scripts/supply_chain_policy_check.sh`: passed.
- CI documentation step was deterministically broken: it required a deleted `docs/SDK_IMPROVEMENT_CHECKLIST.md` and obsolete README wrapper/setup strings. The local release gate did not execute this step.
- New behavioral probes failed on the original source for thrown transports, leaked credentials in normalized provider error fields, malformed catalog authoring and colliding provider/model identities. Original/new raw logs are local under `artifacts/hardening/`.
- A controlled wrapper invocation leaked one staging directory on success. Code evidence: `exec` replaced the shell owning the EXIT trap; staging also happened before trap registration.

## Findings

| ID | Priority | Area | Finding | Evidence | Action | Status |
| -- | -------- | ---- | ------- | -------- | ------ | ------ |
| H01 | P1 | Resources | Wrapper leaked staged repository copies and could lose staging failure semantics | Original wrapper `exec`; controlled runtime probe | Keep owning shell alive; register trap before rsync; test success, exit 7, rsync exit 23 | Fixed |
| H02 | P1 | Reliability | Thrown custom transports escaped normalized failure handling and chat slot cleanup | New throwing-transport regression failed on original source | Contain exceptions, return terminal `transport_error`, run normal finalization without replay | Fixed |
| H03 | P1 | Security | Error message/type/param/provider-code fields bypassed redaction; generic raw strings could echo the configured credential | Credential fixture probe; normalization source | Redact error diagnostics and raw errors using secret patterns plus exact configured credential | Fixed |
| H04 | P1 | Catalog correctness | `provider + "::" + model` conflated distinct identities | `a::b/c` versus `a/b::c` regression | JSON tuple duplicate keys, component-wise lookup, deterministic tie order | Fixed |
| H05 | P2 | Catalog validation | Malformed authoring shapes were normalized away into valid defaults | Config with string models/metadata accepted | Validate authoring identity/container shape before constructing; retain lower-level constructor defaults | Fixed |
| H06 | P2 | Efficiency | Lookup eagerly recomputed a validated hash; sorting recomputed incoming identity per comparison | Source call path; same-workload benchmark | Reuse present validated hash and incoming sort key; avoid hashing structurally invalid catalogs | Fixed |
| H07 | P1 | CI | CI required deleted docs and missed the entire catalog suite | Workflow and release gate inspection | Shared docs check; catalog/hardening/wrapper regressions in release gates | Fixed |
| H08 | P2 | Diagnostics / portability | Failed gate output was captured then lost under `set -e`; eval commands embedded one machine path | Injected failing runtime; eval JSON | Preserve failed output and status; use repository-relative eval commands; replace dead checklist references | Fixed |
| H09 | P1 | Governance | Shared state hooks silently fall back / ignore write failures; accounting is not atomic | `state_backend_get`, `state_backend_set`, post-response accounting | Document best-effort semantics; preserve compatibility pending explicit atomic/fail-closed backend contract | Open design work |
| H10 | Needs more evidence | Transport | Buffered SDK callbacks do not establish incremental delivery, download bounds or redirect enforcement in runtime | SDK transports return complete bodies/chunk arrays; existing provider-driver fact-finding | Clarify buffer/limit scope; retain existing runtime follow-up | Existing follow-up |

## Changes implemented

- **Temporary workspace ownership:** `kujo`, `tests/wrapper_regression_tests.py`. Preserve arguments, stdout/stderr and process status while cleaning staging on normal success/failure and rsync failure. Generated staged files remain temporary; installed `kujo` is the documented path for persistent generation. No cache or staging exclusions were introduced that might hide required files.
- **Transport exceptions and error safety:** `src/ai_sdk.kujo`, `tests/hardening_regression_tests.kujo`. Both chat and embeddings contain a throwing injected transport. A thrown callback has unknown completion state, so it is terminal; existing `Ok`/`Err` retries are preserved. Chat finalization releases its slot. Diagnostics retain codes and useful messages but scrub configured credentials, including nested raw error values and native-driver metadata. No claim of arbitrary secret detection in all successful model content is made.
- **Catalog correctness and efficiency:** `src/model_catalog.kujo`, `tests/model_catalog_tests.kujo`, `scripts/benchmark_model_catalog.kujo`. The new authoring checks reject invalid identity/container types before defaults conceal them. Pair identity no longer depends on ambiguous delimiter concatenation. Ordinary catalog ordering/hashes remain stable; previously ambiguous tied identities get a deterministic tie order. Hash verification remains mandatory before a successful lookup; no cache/invalidation model was added.
- **Verification / documentation:** release gate now includes all top-level Kujo suites plus wrapper regression tests and the shared `scripts/verify_docs.sh` check. Failed commands retain diagnostics and original status. CI invokes the same documentation check instead of duplicating stale assertions. Integrity-manifest inputs reference a real architecture document. Eval commands run from the repository root rather than a machine-specific directory. README, API policy and provider extension guide explain changed behavior and limitations.

## Performance and efficiency

Same local runtime, 20-model catalog, 20 successful lookups, three serial runs, using `kujo run scripts/benchmark_model_catalog.kujo --interpreter` against original source and changed source:

| Measurement | Before | After |
| -- | -- | -- |
| Catalog lookup workload elapsed ms | 976, 1035, 992 | 453, 503, 432 |
| Median workload elapsed ms | 992 | 453 |
| Staging directories retained per successful controlled wrapper invocation | 1 | 0 |
| Release-gated Kujo tests | 138 | 150 |
| Additional Python wrapper regression tests | 0 | 2 |
| Kennel runtime / dev dependencies | 0 / 0 | 0 / 0 |

Timing is advisory: a busy shared host and interpreter variability prevent universal throughput claims. An intermediate version before sort-key reuse measured 1037/1004/1013 ms; this did not support an improvement and was optimized further. The catalog remains insertion-sorted; no large-catalog asymptotic improvement is claimed. Existing six-path benchmark thresholds are unchanged. Full-gate elapsed milliseconds (before → after): chat fixture 3086 → 1889; embeddings fixture 2807 → 1972; chat parsing 3475 → 2941; stream parsing 4661 → 4006; chat retry arithmetic 1997 → 2095; embeddings retry arithmetic 1793 → 1780. These single runs are regression evidence, not causal performance claims for untouched paths.

No model prompt, tool schema, token budget, normalized success payload, or callback event collection was removed. Token savings were not measured or claimed. Failure output remains inspectable; this report links the local evidence directory rather than embedding full test logs. No memory/RSS or build-size claim is justified for this library-only change.

## Security and state review

Reviewed provider configuration, descriptor URL/host policy, protected headers and CR/LF rejection, credential placement, redaction, untrusted response parsing, callback exceptions, response retention limits, request/token/retry budgets, state backends, fallback paths, shell staging, catalog JSON/hash boundaries and telemetry allowlisted fields. SDK core does not run model tool calls or shell commands; drivers are trusted executable Kujo code, not a sandbox.

New coverage exercises terminal thrown transports and error credential redaction. Existing driver security, redaction, parser fuzz, response-size, retry, fallback and structured-output suites remain enabled. CI actions/runtime refs are pinned; Rust runtime builds use `--locked`. No package dependency tree exists to trim. Current upstream vulnerability status and hosted action execution were not independently certified.

Concurrency controls are synchronous client admission plus optional shared state. A breaking backend redesign was not attempted: strict distributed reservations need atomic operations and explicit failure policy. Streaming callbacks still replay buffered results and keep `emitted_events` for contract compatibility. Response size rejection occurs after transport receipt and does not bound network download memory.

## Compatibility

- Public exports/signatures: unchanged.
- Normalized response, driver and catalog versions/schemas: unchanged.
- Config/environment/request options: unchanged for valid inputs; catalog authoring rejects malformed identity/container shapes. Constructor defaults are preserved.
- CLI: SDK still has none; eval commands are portable from repository root. Wrapper runtime exit codes/arguments are preserved and temp copies cleaned. No file format changed.
- Errors: throwing transports return non-retryable `transport_error` instead of escaping. Error text/metadata/raw may now contain `[REDACTED]` where credentials were previously exposed.
- Catalog hashes: unchanged for unambiguous existing identities; a catalog containing previously colliding identity pairs was rejected before and is now valid with deterministic ordering.
- Consumers: normal provider factories, fixture mode, `Ok`/`Err` transport injection, Watchdog telemetry and model preference APIs are preserved. No ecosystem rewrite or dependency upgrade is required.

## Cross-repository follow-ups

Kujo runtime transport: existing driver audit asks for verified redirect control and incremental chunk delivery. The SDK can inspect only returned bodies/chunk arrays; it cannot prove a transport-level download bound or redirect-hop allowlist from that interface. A runtime capability/prototype and compatibility tests would be required before promising those features. This pass does not depend on a runtime change. Existing SignalBox capture `cap_4c3353ba-2dd7-4ad1-aa9f-00c260e8907d` already records this scope; no duplicate capture was created.

## Remaining work

- **P0:** none established in this pass.
- **P1:** H09 — design an opt-in fail-closed atomic governance backend contract before using SDK counters as a strict distributed spending limit. Existing behavior is explicitly documented; silently changing it would break backend compatibility.
- **P2:** none additional admitted.
- **P3 / not worth changing:** broad core-module rewrite, merging native/legacy decoding implementations without fidelity evidence, deleting exported compatibility paths, and arbitrary context/output truncation.
- **Needs more evidence:** live provider responses; hosted CI on pinned runtime/compatibility-matrix refs; runtime redirect/download/incremental streaming capabilities. Default local verification requires no secrets.

## Verification receipt

Local evidence directory: `artifacts/hardening/` (ignored, not shipped). Logs include baseline release/catalog, intentionally failing probes, final release, catalog timings, wrapper measurements, stress and integrity checks.

| Exact command / check | Result |
| -- | -- |
| `KUJO_BIN="$(command -v kujo)" bash scripts/release_quality_gates.sh` (baseline) | Passed, 138 Kujo tests plus existing gates |
| `kujo test-run tests/model_catalog_tests.kujo` (baseline) | Passed, 7 tests |
| `kujo test-run tests/hardening_regression_tests.kujo -v` | Passed, 2 tests after fix; failed before fix |
| `kujo test-run tests/model_catalog_tests.kujo -v` | Passed, 10 tests after fix; new bug probes failed before fix |
| `python3 tests/wrapper_regression_tests.py` | Passed, 2 tests covering success, runtime failure, staging failure |
| `KUJO_BIN=/Users/robertdevore/.local/bin/kujo bash scripts/release_quality_gates.sh` (final) | Passed, 150 Kujo tests + 2 Python tests, examples, schemas and all six benchmark thresholds |
| `kujo run examples/model_preferences.kujo` | Passed |
| `./kujo run examples/telemetry_bridge.kujo --interpreter` | Passed, fixture retry then success |
| `kujo run scripts/stress_harness.kujo --interpreter` | Passed, 3000 success / 0 errors |
| `kujo run scripts/benchmark_model_catalog.kujo --interpreter` | Passed; timings above |
| `kujo run scripts/generate_model_catalog.kujo --interpreter -- examples/dispatch-model-catalog.config.json --output artifacts/hardening/generated-catalog.json` | Passed, JSON artifact created |
| `bash scripts/verify_docs.sh` | Passed |
| `bash scripts/verify_contract_schemas.sh` | Passed |
| `bash scripts/supply_chain_policy_check.sh` | Passed |
| `bash -n kujo scripts/*.sh .github/scripts/*.sh` | Passed |
| `git diff --check` | Passed |
| `bash scripts/generate_integrity_manifest.sh artifacts/hardening` and `shasum -a 256 -c artifacts/hardening/integrity-manifest.sha256` | Passed; local integrity only, no SBOM/provenance attestation |
| All four checks in `tests/ai_sdk_eval.json`, executed from repository root | Passed |
| Controlled runtime failure in release gate | Exit 9 preserved and `diagnostic-marker` emitted |

An intermediate implementation used the same local variable name for dict and array recursion and failed one allowlist contract test; separate accumulator names fixed it and that suite passed 31/31. A later whole-gate attempt stopped with host `fork: Resource temporarily unavailable`; process inventory showed hundreds of unrelated CUA node processes. No unrelated processes were killed and no timeouts were increased. The gate was rerun after confirming wrapper behavior and normal process creation.

## Durable follow-up record

SignalBox: stored governance Capture `cap_96469698-b216-4043-93d0-a8f59f7f7eb1` and Signal `sig_7a8e3644-16cf-4024-a23f-6eab0be037cc`; exact-ID and concept retrieval passed. Skipped the existing runtime transport follow-up as a duplicate. Rejected completed fixes, ordinary verification results and speculative rewrites as capture material. Strata handoff/current-state timeline is saved after final commit verification; it points here for the detailed engineering record.
