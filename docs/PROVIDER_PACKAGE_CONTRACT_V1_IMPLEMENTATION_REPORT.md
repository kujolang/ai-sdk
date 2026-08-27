# Provider Package Contract v1 Implementation Report

## Executive Summary

The two independent provider references—Ollama and Anthropic—were converted into one normative, provider-flexible Contract v1. The contract standardizes architecture, driver boundaries, capability honesty, security, deterministic testing, Kennel distribution, clean-room validation, installed consumer proof, documentation, and release evidence without standardizing provider APIs. A patch clarification (`1.0.1`) records Kujo's lockfile-driven discovery of installed Kennel roots.

## Evidence Reviewed

- `kujolang/ollama` remote `main` `80ad84b...`, tag `v0.1.8` peeled `6ba6019aaa6eec78c8e9ced6b938f70e92ae8687`.
- `kujolang/anthropic` remote `main` `5d0cab7...`, tag `v0.1.1` peeled `f6374405b99fd9f3edc74d575cbb79b1b2e6102f`.
- `kujolang/ai-sdk` remote `main` `acb7247...`, release tag `v1.1.0`, driver contract `1.0.0`, normalized contract `1.0.0`.
- `kujolang/kennel` current manifest, resolver, lockfile, export, and installed-package behavior.
- Ollama `PROVIDER_PACKAGE_PATTERN_DRAFT.md`, implementation and phase-2 reports.
- Anthropic implementation report and pattern validation report.

## Canonical Location

The single canonical copy is `kujolang/ai-sdk/docs/KUJO_PROVIDER_PACKAGE_CONTRACT_V1.md`. AI SDK owns the public provider-driver boundary and is the discoverable home for provider authors. Provider repositories retain historical evidence and link to this document; they do not duplicate the canonical standard.

## Contract Structure

The specification defines normative language and evidence classifications, then covers repository structure, native/driver layers, AI SDK ownership, capability optionality, provider-owned auth/headers/versioning, message/content/stream fidelity, tools, structured output, reasoning, usage, errors, Kennel, imports, fixtures, clean-room distribution, live safety, CI, docs, versioning, forbidden patterns, extensions, platform debt, conformance levels, and a checklist.

## Normative Requirements

Requirements were made MUST only when supported by both references, current platform behavior, or security boundaries. Provider API shape, auth scheme, stream framing, model lifecycle, embeddings, tools, media, and reasoning remain flexible. The clean-room install/reinstall and installed consumer smoke are blocking distribution requirements.

## Ollama Conformance

Ollama conforms across all applicable requirements. Its native `/api` and NDJSON behavior, local no-auth/cloud split, model lifecycle, and embeddings remain provider-specific. Its deterministic source gate passed `10/10`; installed-package smoke passed `1/1`; immutable AI SDK dependency and clean-room reinstall evidence are recorded in `OLLAMA_REFERENCE_PACKAGE_PHASE2_REPORT.md`.

## Anthropic Conformance

Anthropic conforms across all applicable requirements. Its native Messages API, `x-api-key`, API-version header, top-level system field, content blocks, named SSE events, count-tokens operation, and lack of embeddings remain provider-specific. Its deterministic source gate passed `12/12`; installed-package smoke passed `1/1`; immutable AI SDK dependency and clean-room reinstall evidence are recorded in `ANTHROPIC_IMPLEMENTATION_REPORT.md`.

## Provider-Specific Exceptions

Ollama-specific rules are localhost allowance, optional auth, NDJSON, `/api` model lifecycle, and Ollama usage/timing fields. Anthropic-specific rules are required remote API-key auth, `x-api-key`, `anthropic-version`, Messages content blocks/system semantics, named SSE events, `stop_reason`, thinking/cache/output options, and no embeddings capability. These exceptions are explicitly excluded from universal requirements.

## Platform Requirements

Current Kujo runtime consumers discover installed package roots from the nearest `kennel.lock`; package-root shims must still explicitly export imported symbols. Both references now validate this behavior without manual path wiring. `KUJO_MODULE_PATH` remains an explicit extension point. Kennel and AI SDK provider source were not modified for this platform change.

## Security Requirements

The contract preserves the established AI SDK boundary: provider drivers cannot perform I/O or bypass transport, endpoint policy, protected headers, retries, budgets, concurrency, response limits, or redaction. Package-owned provider auth and endpoint rules remain explicit. No secrets are permitted in reports, examples, fixtures, or manifests.

## Package Import Ergonomics Debt

The two clean-room validations independently exposed the same current runtime requirement. This is not a provider failure and should be investigated separately as Kujo/Kennel namespace/search-path ergonomics.

## Files Created

- `docs/KUJO_PROVIDER_PACKAGE_CONTRACT_V1.md`
- `docs/KUJO_PROVIDER_PACKAGE_CONTRACT_V1_CONFORMANCE.md`
- `docs/PROVIDER_PACKAGE_CONTRACT_V1_IMPLEMENTATION_REPORT.md`

## Files Modified

- AI SDK provider documentation: lightweight canonical-contract reference.
- Ollama pattern draft: superseded-by-v1 notice and canonical link.
- Anthropic pattern validation: canonical-contract reference.

## Remaining Unknowns

Provider #3 may reveal amendments, especially around non-chat jobs, media/file lifecycles, signed authentication, or asynchronous prediction APIs. The current public Kennel registry remains unoperated. These do not contradict Contract v1 or block its use for future provider validation.

## Recommendations Before Provider #3

Keep the contract canonical in AI SDK, use it to audit the next provider without duplicating provider APIs, and separately evaluate automatic installed-package namespace exposure and generated export namespaces in Kujo/Kennel. Do not solve those platform issues inside provider packages.

## Ready for Universal Provider Builder?

YES
