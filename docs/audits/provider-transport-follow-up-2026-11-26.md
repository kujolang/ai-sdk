# Provider transport and diagnostics follow-up

Reviewed public AI SDK main `d69c4727ad84db4d5144e756600eda9dc5ab19ca`
during standalone provider integration on 2026-11-26.

- A trusted package stream can declare one fixed non-secret query pair.
  The SDK checks it against the complete query and still requires the
  configured origin. Regular chat, embedding and undeclared queries keep
  the existing validation boundary.
- An additional header identified as credential-bearing disables redirects
  for generic SDK clients. Registered and package-provider restrictions
  continue to apply. Ordinary bearer clients keep their existing redirect
  configuration when they supply no additional credential header.
- Diagnostic and normalized result paths scrub configured credential literals.
  Raw stream events are withheld when the normalized text or tool output
  reconstructs a credential from adjacent fragments. Typed token counts and
  bounded accounting details survive redaction, and malformed values do not
  become normalized usage. The opt-in native callback still observes transport
  text before normalization.
- DeepSeek uses the documented Flash model by default and lists V4 Pro as a
  selectable model. [DeepSeek API models](https://api-docs.deepseek.com/).

Four added fixture cases failed on the starting commit and all 206 offline
contract tests passed on checksum-verified released Kujo 1.6.0 and 1.10.0.
The full distribution gate also passed the wrapper, runtime loopback,
schema, certification, example and benchmark checks. Gemini's native package
driver passed end-to-end offline chat streaming and embeddings with both
runtime versions against this source. No provider inference was used.
