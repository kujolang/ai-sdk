# Provider Compatibility Matrix

This matrix summarizes SDK-level capability expectations for built-in provider presets and custom OpenAI-compatible endpoints.

## Capability Matrix

| Provider preset | Chat completion | Streaming | Tool calls | Embeddings | Notes / caveats |
|---|---|---|---|---|---|
| `openai_provider()` | Yes | Yes | Yes | Yes | Baseline reference provider for examples and fixture parity.
| `openrouter_provider()` | Yes | Yes | Yes | Yes | Model naming and provider-side routing behavior can vary by upstream model family.
| `deepseek_provider()` | Yes | Yes | Yes | Yes | Verify model-level feature parity for selected model versions.
| `custom_openai_compatible_provider(...)` | Yes* | Yes* | Yes* | Yes* | Treated as OpenAI-compatible; actual support depends on remote implementation.

`*` Custom provider capabilities are declared as enabled in the preset shape, but runtime behavior still depends on remote API semantics and endpoint conformance.

## Security and Endpoint Caveats

- Custom endpoints must pass strict URL validation (HTTPS by default, optional localhost HTTP opt-in).
- Embedded credentials in URLs are rejected.
- Query-string and fragment URL forms are rejected for custom provider base URLs.
- Optional endpoint allowlist mode can block outbound calls to non-approved hosts.

## Operational Caveats

- Retry/fallback behavior is SDK-driven, but provider-side throttling and payload limits still vary.
- Structured output, tool-call schemas, and usage fields may differ subtly across providers; SDK normalization absorbs common variants but cannot guarantee provider-specific schema parity.
- Live-provider smoke tests should be part of release readiness when provider credentials are available.

## Guidance

- Start with fixture mode for deterministic contract integration.
- Validate deployment candidates with live smoke and release quality gates.
- Prefer explicit allowlist and budget controls in deployed environments.
