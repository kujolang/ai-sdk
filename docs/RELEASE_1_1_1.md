# AI SDK 1.1.1

Use Kujo 1.6.0 or newer. Provider-driver, response and model-catalog contracts
retain their existing 1.0.0 identities. This release distributes transport
failure containment, credential-error redaction, wrapper cleanup, model-catalog
validation and bounded Watchdog metadata mapping. Streaming remains buffered;
telemetry is observational and supplies no execution/replay authority.

## One-release live-provider waiver

On September 28, 2026, the maintainer explicitly authorized releasing 1.1.1
without live-provider validation and deferred it to the next pass. This is a
waiver, not successful live-provider evidence. Offline contract, benchmark,
compatibility, integrity-manifest and SBOM/provenance checks remain required.

The published-release workflow skips the live-provider job only for tag
`v1.1.1`. Manual validation uses the existing explicit
`allow_live_provider_skip=true` input. Other release tags still require provider
credentials and live validation; the default manual input remains false.

No participant SDK publication or experimental-contract stabilization is included.
