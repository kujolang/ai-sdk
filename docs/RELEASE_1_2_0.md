# AI SDK 1.2.0

AI SDK 1.2.0 fixes state persistence, concurrent accounting, and native transport limits. It adds state inspection and cleanup APIs without changing response, provider-driver, or model-catalog contract 1.0.0.

## Install and upgrade

Use Kujo 1.6.0 or newer and Kennel 1.1.0 or newer:

```bash
kennel add ai-sdk@1.2.0
kennel install
```

Existing provider dictionaries, native drivers, injected two-argument transports, and buffered stream callbacks keep their contracts. No new environment variable is required. Completed provider usage is now retained even when a budget or structured-output check rejects the result; budgets may therefore block subsequent calls sooner.

## State and concurrent accounting

Client copies share process-local counters through an opaque identity created by `create_client`. Use `client_state` to inspect current counters and the documented reset APIs to clean up idle state. Memory state is not durable across process restarts.

Set `governance_mode: "strict"` and share one `atomic_memory_backend()` handle to serialize concurrent requests and accounting. Strict mode fails closed when the backend is busy or uncertain. Reconcile usage before resetting quarantine. External backends must implement the documented fenced acquire/get/set/release contract. Strict mode rejects provider fallback, including fallback entry overrides. Legacy best-effort accounting remains the default.

## Transport compatibility

Native HTTP enforces positive `max_raw_response_bytes` while downloading, up to the existing 8 MiB runtime ceiling. Endpoint allowlists disable redirects. Custom transports receive these options and must enforce them themselves.

`on_transport_chunk` requires a Kujo runtime containing `http_stream_collect`. The SDK does not install or replace a runtime. Published Kujo 1.5.0 and 1.6.0 reject this option with `unsupported_feature` before network I/O; ordinary calls, redirect controls, download limits, and buffered streaming work on those releases.

Readable collection was verified against Kujo source backports `302bbb19ac4fb661843e4e2e3d633f7bae5d794b` (1.5.0) and `92e0e0a8125da5d005c1e4f5f9a9784f436158a9` (1.6.0), and current runtime source `d6ed9c0cfa76a1f17fb87020b9e9a77950c7fc25`. These source checks do not claim that a published runtime includes the feature. Callback text arrives at transport chunk boundaries; the bounded complete body remains available for final decoding. Cancellation and failures after partial delivery are terminal.

## Verification

The 185-test local release gate passes on both published Kujo 1.5.0 and 1.6.0, with unchanged benchmark thresholds. Each run also passes two wrapper tests, four native HTTP tests, schemas, examples, and documentation checks. Two readable-collection tests skip on those published runtimes and pass on both source backports. CI and the compatibility matrix passed at the pre-release source `d6ad6ede236c83e54bf310e0d7040c1b92b3d9d1`.

See [the hardening audit](audits/repository-hardening.md) for exact commands, commits, runtime hashes, and before/after regression evidence.

## One-release live-provider waiver

On October 13, 2026, the maintainer explicitly authorized publishing 1.2.0 without live-provider smoke evidence. This waiver applies only to tag `v1.2.0`. No live-provider success is claimed. Contract, compatibility, benchmark, schema, documentation, and supply-chain checks remain required. Other future release tags still require configured-provider evidence unless separately authorized.

## Publication record

Tag `v1.2.0` points to `de027d681d744aabcc21e025e111693500a99b1d`, 16 commits after `v1.1.1`. The [GitHub release](https://github.com/kujolang/ai-sdk/releases/tag/v1.2.0) was published on October 13, 2026, with SPDX SBOM and integrity-manifest assets.

The final [release workflow](https://github.com/kujolang/ai-sdk/actions/runs/38400381006), [CI](https://github.com/kujolang/ai-sdk/actions/runs/38400070672), and [compatibility matrix](https://github.com/kujolang/ai-sdk/actions/runs/38400070798) passed. The live-provider waiver above remains explicit; these results do not imply a paid-provider run.

The [Kennel publisher](https://github.com/kujolang/kennel-registry/actions/runs/38400384070) passed, including deployed package discovery. Public 1.2.0 metadata identifies the release commit, and the downloaded package archive has SHA-256 `1622b676ef34350d541d5754a7f23922657e6f1aa8b876a84d26805bf44ecceb`. Its packaged manifest reports 1.2.0. A separate clean-project install attempt on the maintainer machine stopped at an HTTP connection error before dependency resolution; no local clean-install success is claimed.

The [docs build](https://github.com/kujolang/docs.kujolang.ai/actions/runs/38400639636) passed at `4889eaba6f4155bd3788f573ae7aad0bfbd9c65a`. The published `gh-pages` tree `6fe6cff9013157b27941401ec42fce70cc0db575` exactly matches that artifact, and the public SDK guide and release inventory show 1.2.0.

The MCP catalog update passed [CI](https://github.com/kujolang/kujolang-mcp/actions/runs/38400681354) at `466ce3f5660521e83af9a564255e504cfde2a36a`. Worker deployment `7dade0bc-4482-42c3-a24e-7851e9769ad8` passed live parity checks for all 234 catalog items and six installer profiles, plus a direct AI SDK lookup at `https://mcp.kujolang.ai/mcp`.
