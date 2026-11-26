# Repository hardening on November 25, 2026

The baseline was `4316452`. The review covered the SDK request, transport, and response paths, the provider registry and operation adapters, redaction, fallback and accounting, the command wrapper, and release gates. This pass kept network checks on loopback and ran published provider contracts with fixtures.

- The baseline failed the external driver stream test because passing `null` invoked a nonexistent callback and converted a successful response into a callback error. The stream API now collects events with no callback and preserves callback failure behavior for supplied callbacks.
- Raw body and buffered chunk guardrails now count UTF-8 bytes. Registered operations apply the same units to serialized request bodies. A fixture response that exceeds the byte limit by one is rejected, and the identical response succeeds at the exact byte limit.
- The SSE parser assembles fragmented lines and multiline event data once. Fragmented and contiguous input produce the same result with CRLF, comments, Unicode, split completion markers, and trailing frames. The same local Kujo 1.10.0 binary parsed five copies per workload and verified decoded bytes on each iteration.

| Fragments | Decoded payload bytes | Baseline elapsed | Candidate elapsed |
| --- | ---: | ---: | ---: |
| 256 | 32,768 | 183 ms | 41 ms |
| 1,024 | 131,072 | 1,862 ms | 130 ms |
| 4,096 | 524,288 | 28,534 ms | 524 ms |

Reproduce the parser timings with `kujo run docs/audits/evidence/sse-fragmented-2026-11-25.kujo`. The timings measure buffered parsing on this host.

- Offline provider operations now require a transport supplied on the call. They skip the configured client and native transports when no fixture transport is supplied. Request-start hooks can consume the operation deadline, so the SDK recalculates the remaining time before dispatch and emits a completion event when the deadline expires.

`bash scripts/release_quality_gates.sh` passed on local Kujo 1.10.0 and the checksum-verified macOS x64 Kujo 1.6.0 publication. Each passed 202 Kujo tests, docs, schemas, wrapper tests, examples, and the existing benchmark gate. All six native loopback tests passed on 1.10.0. Two incremental-collector tests skipped on 1.6.0 because that publication predates their runtime API. The supply-chain policy and Git whitespace checks passed. Provider credentials were omitted from the test environment.
