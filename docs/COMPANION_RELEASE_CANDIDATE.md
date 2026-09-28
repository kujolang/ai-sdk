# ai-sdk 1.1.1 companion release candidate

Status: candidate, not published. No release tag created by this preparation.

## Runtime evidence

Validated locally with the published macOS x64 Kujo 1.6.0 binary:
`930e0da1fec2562f6990d1226a479330640c8c78eb4c36c148cee3f950b29a47`.
Its source is `44af277848173664f72ca85f2a1b3b98d634ecdd`.
This does not certify other platforms; hosted candidate checks must be inspected separately.

Local release quality gate: 150 aggregate tests, schema checks, wrapper regressions, examples and benchmarks passed. Live-provider smoke was skipped by the local runner because no provider key was configured. This is not live-provider release evidence. Publication is blocked until the mandatory release provider smoke passes; the manual workflow skip option has not been authorized. Supply-chain policy passed. Compatibility CI covers immutable Kujo 1.5.0 and 1.6.0 release sources.

## Release completion checklist

- Inspect hosted checks for the exact candidate commit.
- Verify clean source-archive consumption and package version consistency.
- Review the candidate changelog and turn its candidate heading into a release date only when publishing.
- Create an immutable tag at the tested final source; do not move an existing tag.
- Publish the GitHub source release and reconcile the Kennel index if this package is distributed there.
- Retain experimental contract labels. Do not publish the separate participant SDK packages.
