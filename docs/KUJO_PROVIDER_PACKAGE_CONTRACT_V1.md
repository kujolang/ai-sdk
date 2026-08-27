# Kujo Provider Package Contract v1

Status: normative ecosystem specification  
Version: `1.0.0`  
Canonical home: `kujolang/ai-sdk/docs/KUJO_PROVIDER_PACKAGE_CONTRACT_V1.md`  
Evidence base: `kujolang/ollama` and `kujolang/anthropic`, reviewed 2026-08-27

This contract standardizes provider-package architecture and release quality. It does not standardize provider APIs. A conforming package preserves the real capabilities and semantics of its provider while offering an optional normalized AI SDK integration.

## Normative language

**MUST** is a blocking conformance requirement. **MUST NOT** is a prohibited behavior. **SHOULD** is recommended unless a documented provider-specific or platform reason justifies deviation. **SHOULD NOT** is a recommendation against a pattern. **MAY** is optional.

## Evidence classifications

- **VALIDATED BY BOTH** — independently demonstrated by Ollama and Anthropic.
- **PLATFORM REQUIREMENT** — required by current Kujo, AI SDK, or Kennel behavior.
- **SECURITY REQUIREMENT** — required to preserve an established security boundary.
- **PROVIDER-SPECIFIC** — intentionally belongs to one provider implementation.
- **RECOMMENDED** — useful practice not proven mandatory by both references.

## 1. Version independence

This contract is version `1.0.0`. Its version is independent of the AI SDK package version, AI SDK normalized response contract, AI SDK provider-driver contract, model-catalog contract, provider API version, and individual provider package version. A package MUST record its conformance to this contract in its implementation report and SHOULD record `provider_package_contract = "1.0.0"` in manifest metadata when the supported Kennel schema permits it.

## 2. Repository structure

The following baseline is intentionally small:

| Artifact | Requirement | Evidence/classification |
|---|---|---|
| `README.md` | MUST exist and lead with install, first request, and native/AI SDK distinction. | VALIDATED BY BOTH |
| `LICENSE` | MUST exist under organization licensing policy. | PLATFORM REQUIREMENT |
| `kennel.toml` | MUST describe the installable package and its public exports. | PLATFORM REQUIREMENT |
| `CHANGELOG.md` | SHOULD record package releases and material behavior changes. | VALIDATED BY BOTH |
| `kujo.toml` | SHOULD exist when used by the package's Kujo conventions. | VALIDATED BY BOTH |
| `src/` | MUST contain the native implementation and, when integrated, the driver. | VALIDATED BY BOTH |
| `tests/` | MUST contain deterministic conformance tests. | VALIDATED BY BOTH |
| `examples/` | SHOULD contain concise copyable usage examples. | VALIDATED BY BOTH |
| `scripts/` | SHOULD contain the package release gate and installed-package gate. | VALIDATED BY BOTH |
| `AGENTS.md` | SHOULD give operational guidance to future agents. | RECOMMENDED |
| `docs/` | MAY contain provider-specific guides and evidence. | PROVIDER-SPECIFIC |

Packages MUST NOT add empty boilerplate directories merely to match this table. Files MAY be combined when that keeps the architecture obvious.

## 3. Required architectural layers

An integrated provider package MUST have two explicit responsibilities:

```text
Provider package
├── native provider layer  → provider-native protocol and capabilities
└── AI SDK adapter layer   → public provider driver and normalized semantics
```

The native layer MUST preserve provider-native request, response, error, and stream fidelity. The AI SDK adapter MUST normalize only provider-neutral semantics supported by the AI SDK. A package MUST NOT force unsupported or provider-specific features into generic abstractions.

A native-only package MAY omit the AI SDK adapter, but it is not an AI SDK-integrated or release-ready provider package under this contract.

## 4. Native client contract

The native layer MUST provide a clear client construction path, safe endpoint and credential configuration, provider-native operations that the package claims, and predictable native errors. It MAY expose a default convenience client when that matches the official provider ergonomics. It SHOULD support transport injection where Kujo runtime conventions make that practical, because deterministic tests must not depend on provider availability.

Function names and native operations are provider-owned. Providers MUST NOT be required to expose identical functions. Ollama model lifecycle and embeddings, Anthropic count-tokens and content blocks, and future provider-specific jobs are valid differences.

## 5. Onboarding

Every package MUST make the path “install → import → first request” obvious within its README and include one short first-request example. The example SHOULD mirror the mental model of the official provider SDK without introducing unrelated framework ceremony. Native imports MAY differ by provider, for example `from ollama import chat` or `from anthropic import messages`.

## 6. AI SDK provider driver

An integrated package MUST use only the public AI SDK provider-driver boundary and MUST expose a provider factory that attaches an explicit native driver. The driver MUST satisfy the current public driver contract: a contract identifier, driver contract version, non-empty ID, `describe`, `validate`, `encode_chat`, `decode_chat`, and `decode_error`; `decode_stream` is required when streaming is declared; paired embedding hooks are required only when embeddings are declared.

Driver hooks MUST be deterministic functions over their inputs. They MUST NOT perform network I/O, choose or execute a transport, construct unchecked final AI SDK envelopes, control retries/fallbacks/budgets/concurrency, bypass endpoint or header policy, disable redaction, or mint arbitrary public AI SDK error codes. They return request descriptors or semantic intermediates; AI SDK core constructs final normalized results.

## 7. AI SDK core ownership

AI SDK core owns transport execution, timeout/deadline handling, retries and retryability, circuit breakers, fallback, governance, budgets, concurrency and queue behavior, observability/state, endpoint policy, protected-header merging, response-size limits, redaction, and final normalized contracts. Provider packages MUST NOT add provider-name branches to core or duplicate these controls in the adapter path.

## 8. Driver ownership

The provider driver owns provider-specific request encoding, response decoding, provider-auth representation, required provider headers and API-versioning, native stream parsing, native error extraction, supported tool-call mapping, reliable usage mapping, meaningful finish/stop mapping, and capability metadata. These responsibilities are **VALIDATED BY BOTH** except where a provider does not offer the capability.

## 9. Capabilities

Drivers MUST declare only capabilities implemented by the provider and covered by tests. A package MUST NOT advertise embeddings, tools, structured output, vision, reasoning, or streaming merely because AI SDK supports the concept. Unsupported operations SHOULD fail through existing AI SDK capability/error mechanisms. Capability metadata MAY be model-dependent and MUST not imply that every model supports every provider capability.

## 10. Authentication and headers

Authentication is provider-owned. The contract permits Bearer, `x-api-key`, other provider headers, anonymous local endpoints, multiple required headers, or future signed schemes supported by the platform.

Every package MUST ensure that credentials are never committed, placed in fixtures/examples, emitted in metadata, printed in diagnostics, or retained in unredacted errors. It MUST reject embedded URL credentials and unsafe remote HTTP unless explicitly permitted by current platform policy. Credentials MUST NOT be forwarded to an unexpected host. Required provider headers MUST be represented as protected headers so AI SDK core can enforce its generic header policy.

Provider-specific API-version semantics belong in the package/driver. They MUST be documented, have an explained default where applicable, and MUST NOT require provider-specific AI SDK core branches.

## 11. Message translation and native fidelity

Drivers MAY structurally translate normalized AI SDK messages. They are not limited to URL or field substitution. Examples include a normalized system message becoming a provider top-level system field, a generic tool definition becoming a provider schema, and text becoming ordered provider content blocks.

Native packages MUST preserve provider-native response structures where practical. Native fidelity is authoritative for native use; normalized `output_text`, tool calls, usage, and finish reasons are only the portable semantic subset. Native packages MUST NOT prematurely flatten heterogeneous content, thinking, citations, tool-use, timing, or provider metadata into one string.

## 12. Streaming

Each provider MUST parse its actual native stream protocol. The contract prescribes no framing: Ollama uses NDJSON and Anthropic uses named SSE events. Native parsers SHOULD preserve provider event names and data, tolerate safely ignorable additive event types, contain malformed frames, and bound accumulated data where practical.

The AI SDK adapter MUST map supported native stream semantics into the unchanged AI SDK callback contract. It MUST NOT redesign AI SDK streaming. Tests MUST cover framing/chunk boundaries, normal completion, provider errors, malformed input, and usage/final metadata where the provider supplies them.

## 13. Tools and structured output

Native packages MUST preserve provider-native tool schemas, tool-use blocks, tool results, and model-dependent constraints when those capabilities are implemented. Drivers MUST map supported tool calls to existing AI SDK normalized semantics and retain useful native data in safe raw-provider data. Packages MUST NOT invent support for undocumented or unavailable tool behavior.

Provider-specific structured-output mechanisms belong in the native package/driver. AI SDK core owns final normalized schema validation when an AI SDK structured-output feature is used. Providers MUST NOT be forced into OpenAI-specific JSON shapes.

## 14. Thinking and multimodal content

Provider-native reasoning/thinking controls remain provider-owned unless AI SDK defines an explicit provider-neutral equivalent. Native packages MAY expose multimodal or heterogeneous content blocks and SHOULD avoid text-only assumptions. No universal media or reasoning abstraction is required by this contract.

## 15. Usage and finish reasons

Where reliable, drivers MUST map provider input and output token counts to AI SDK `input_tokens` and `output_tokens` without fabrication. Additional cache, reasoning, server-tool, or timing categories MUST remain native or in safe provider raw data. Drivers SHOULD map provider stop semantics to `finish_reason` only where meaningful, MUST document and test the mapping, and SHOULD preserve the native stop reason.

## 16. Errors

Native errors MUST preserve useful provider status, type/code, message, request ID, safe endpoint information, and provider payload subject to redaction. Driver errors MUST map into established AI SDK error categories and use supported provider metadata such as `provider_code` for provider-native detail. Packages MUST NOT mint arbitrary AI SDK public error codes. Retryability remains an AI SDK core decision.

## 17. Kennel and dependencies

An installable package MUST provide a valid `kennel.toml` using only currently supported Kennel fields. It MUST include package name/version/description/license/repository, minimum Kujo version, source/include/exclude boundaries, public exports, and status/stability metadata where supported. Scripts and dependencies MUST be explicit and minimal.

Any AI SDK dependency MUST use an immutable, reproducible, Kennel-resolvable ref such as `github:kujolang/ai-sdk@v1.1.0`. Mutable `main`, `master`, `HEAD`, `latest`, or equivalent release dependencies MUST NOT be used. A lockfile MUST resolve exact source identities during distribution validation.

## 18. Public exports and runtime imports

Package-root shims SHOULD explicitly export imported public symbols, allowing familiar imports such as `from provider_package import primary_function`. Generic module names MAY be used only when they do not create an avoidable collision; provider-qualified modules are preferred for discoverability.

Current Kujo runtime behavior requires installed Kennel package roots to be supplied through `KUJO_MODULE_PATH` for consumer execution. Clean-room tests MUST configure this explicitly and MUST document it. This is a **PLATFORM REQUIREMENT**, **NOT IDEAL LONG-TERM UX**, and **NOT A PROVIDER RESPONSIBILITY**. Packages MUST NOT add provider-specific runtime hacks to conceal it.

## 19. Deterministic testing

Default tests and release gates MUST be offline, credential-free, deterministic, and safe without a daemon, model, GPU, network inference, large download, or paid API. Fixtures SHOULD derive from official protocol shapes and MUST contain no secrets.

At minimum, applicable packages MUST test:

- native client configuration, endpoint validation, and auth behavior;
- request encoding and native response decoding;
- native error parsing and redaction;
- native stream framing and aggregation when streaming exists;
- tools, structured output, thinking, multimodal, usage, and finish semantics when claimed;
- AI SDK driver descriptor, hooks, normalization, and security boundary;
- manifest validation and installed consumer behavior.

## 20. Clean-room distribution validation

Distribution validation is blocking for a release-ready package. It MUST execute outside the provider and dependency source checkouts:

```text
fresh directory
→ Kennel add provider@immutable-ref
→ resolve provider and transitive dependencies
→ install
→ generate deterministic lockfile
→ reinstall from lockfile
→ validate manifest
→ configure installed package roots
→ import installed public package
→ run installed consumer smoke
```

The test MUST prove no local-path, source-checkout, copied-dependency, pre-existing package-store, or environment leakage made it pass. The lockfile MUST record exact provider and transitive dependency refs/commits. The installed consumer smoke MUST prove package-root export resolution, native client/module resolution, provider factory resolution, transitive AI SDK resolution where applicable, and at least one deterministic public operation.

## 21. Live and destructive operations

Live tests SHOULD be opt-in, model-configurable, low-cost, and non-destructive. If unavailable, reports MUST say `PASS`, `FAIL`, or `SKIPPED — environment/credentials unavailable`; a skipped live test MUST NOT be represented as a pass. Destructive operations such as delete, push, publish, model mutation, or large pulls MUST never run against user resources in default tests.

## 22. Security contract

Packages MUST enforce secret redaction, safe host validation, remote HTTPS, embedded-credential rejection, header injection protection, credential host binding, bounded parsing where practical, malformed-response containment, and driver-exception containment. The package owns provider-specific validation; AI SDK core remains authoritative for generic transport and security policy. A driver MUST NOT select transport or bypass core protections.

## 23. CI and release readiness

Default CI MUST be deterministic and credential-free. A package SHOULD expose one release-quality gate aggregating blocking offline tests and report exact totals. A release-ready package MUST verify its tag/ref, commit, manifest version, clean working tree, remote availability, source gate, clean-room install/reinstall, installed consumer smoke, and documentation reality. Provider package versions are independent semantic versions and MAY remain `0.x` while early.

## 24. Documentation and reports

README first screen MUST answer what the package is, how to install it, and how to make a first request. It SHOULD distinguish native use from AI SDK normalized use and claim only tested/current capabilities. Examples SHOULD cover the primary native operation, streaming/tools/structured output when applicable, and AI SDK integration.

Every implementation SHOULD provide `<PROVIDER>_IMPLEMENTATION_REPORT.md` with: Executive Summary, Official API Evidence/date, Architecture, Native API Coverage, Public Exports, Kennel Dependency, Authentication, Native Semantics, Streaming, AI SDK Driver, Error Mapping, Security, Tests, Clean-Room Installation, Installed Consumer Smoke, Live Validation, AI SDK Changes, Kennel Changes, Limitations, and Provider Pattern Notes.

Each package SHOULD include concise `AGENTS.md` guidance naming its public API, native layer, driver, fixtures, blocking tests, security boundaries, exports, and the prohibition on provider logic in AI SDK core.

## 25. Forbidden patterns

A conforming package MUST NOT:

- add provider-specific branches to AI SDK core;
- use mutable release dependencies;
- perform network I/O inside driver hooks;
- include secrets in fixtures, examples, metadata, logs, or committed files;
- claim unsupported capabilities;
- flatten native provider data prematurely;
- rely only on source-checkout tests;
- claim live validation when it was skipped;
- require identical native APIs across providers;
- bypass AI SDK transport, endpoint policy, protected headers, retries, budgets, concurrency, or redaction;
- mutate or delete user provider resources in default tests;
- solve current `KUJO_MODULE_PATH` ergonomics with provider-specific hacks.

## 26. Provider-specific extension freedom

Packages MAY expose any native operations useful to their provider: Ollama model lifecycle, Anthropic count tokens, Gemini media/files, or Replicate prediction jobs are all valid. Conformance concerns architecture, security, capability honesty, native fidelity, and distribution—not identical function lists or wire protocols.

## 27. Platform ergonomics debt

The following are current platform requirements, not provider obligations:

| Friction | Classification | Follow-up |
|---|---|---|
| Installed package roots require `KUJO_MODULE_PATH`. | CURRENT PLATFORM REQUIREMENT; NOT IDEAL LONG-TERM UX; NOT A PROVIDER RESPONSIBILITY. | Separate Kujo/Kennel investigation. |
| Root shims must explicitly export imported symbols. | CURRENT RUNTIME/PACKAGE BEHAVIOR. | Keep shims explicit until namespace/export ergonomics improve. |

This contract does not redesign Kujo or Kennel.

## 28. Conformance levels

For clear reporting, packages MAY use these levels:

1. **Native Package Conformant** — native layer, security, fixtures, README, and applicable tests pass.
2. **AI SDK Integrated** — public native driver, capability declarations, normalization, and driver tests pass.
3. **Distribution Validated** — immutable dependency, clean-room Kennel install/reinstall, lockfile, and installed consumer smoke pass.
4. **Release Ready** — all applicable MUST requirements, offline gate, documentation, remote release checks, and reports pass.

The highest claimed level MUST be supported by evidence in the implementation report.

## 29. Conformance checklist

### Architecture

- [ ] Native provider layer is explicit.
- [ ] AI SDK adapter/driver is separate from native fidelity.
- [ ] Provider-specific behavior is absent from AI SDK core.
- [ ] Provider-native operations are not artificially made symmetrical.

### Native client

- [ ] Clear install/import/first-request path exists.
- [ ] Client configuration and endpoint validation are safe.
- [ ] Applicable provider operations and native response data are preserved.
- [ ] Native errors and request IDs are handled where available.

### AI SDK driver

- [ ] Public driver boundary only; no private imports.
- [ ] Required hooks and contract version are present.
- [ ] Hooks perform no network I/O and return descriptors/intermediates.
- [ ] Chat, stream, tools, usage, finish, and embeddings hooks match declared capabilities.
- [ ] Final normalized envelopes remain AI SDK core's responsibility.

### Capabilities and semantics

- [ ] Only implemented/tested capabilities are advertised.
- [ ] Structural message conversion is tested where needed.
- [ ] Native content and stream fidelity is preserved.
- [ ] Provider-specific reasoning, multimodal, caching, and structured output remain provider-owned.

### Auth and security

- [ ] Provider auth scheme and required headers are documented/protected.
- [ ] Secrets are absent from fixtures, logs, metadata, and commits.
- [ ] Remote HTTP, embedded credentials, injection, and unexpected-host forwarding are handled safely.
- [ ] Driver cannot choose transport or bypass AI SDK policy.
- [ ] Malformed responses and driver exceptions are contained.

### Kennel and release

- [ ] Manifest and exports validate.
- [ ] AI SDK dependency is immutable and reproducible.
- [ ] Clean-room add/install/reinstall/validate succeeds outside source checkouts.
- [ ] Lockfile records exact provider and transitive sources.
- [ ] Installed consumer smoke passes with explicit current module-path setup.
- [ ] Default gate is offline and reports exact totals.
- [ ] Remote tag/ref, commit, manifest version, and clean tree are verified.

### Documentation and evidence

- [ ] README onboarding is prominent and accurate.
- [ ] Applicable examples and `AGENTS.md` exist.
- [ ] Implementation report records official evidence, tests, live status, limits, and changes.
- [ ] Provider-specific exceptions and platform friction are identified.
- [ ] No claim of live validation is made when it was skipped.

## 30. Scope boundary

This contract is the evidence-backed v1 standard for provider packages. It does not build a provider generator, redesign AI SDK or Kennel, define a universal native API/auth/stream/message/model/embedding/tool/media/reasoning abstraction, or begin provider #3 work. Future providers may reveal amendments; such amendments require a new contract version or an explicitly governed erratum.
