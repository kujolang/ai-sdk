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
