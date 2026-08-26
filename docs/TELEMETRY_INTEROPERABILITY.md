# Telemetry Interoperability Guide

Driver adoption does not change hook payloads or normalized telemetry fields. Drivers may provide secret-free identity/protocol metadata, but credentials and unredacted native payloads must not be surfaced through descriptions, hooks, logs, or model metadata. Core remains responsible for redaction and observability lifecycle.

## Purpose

This guide shows how to map AI SDK lifecycle hooks to common observability systems, including OpenTelemetry-style traces and metrics.

## Available Hook Signals

Request option hooks:
- `on_request_start(event)`
- `on_retry(event)`
- `on_request_complete(event)`

Response-level deterministic counters:
- `result["observability"]["start_count"]`
- `result["observability"]["complete_count"]`
- `result["observability"]["retry_count"]`

## Event Field Mapping

`on_request_start(event)` emits:
- `attempt`
- `provider`
- `url`
- `stream`
- `started_at`

Suggested OpenTelemetry mapping:
- span name: `ai_sdk.chat_completion`
- span attributes:
  - `ai.provider` <- `provider`
  - `http.url` <- `url`
  - `ai.stream` <- `stream`
  - `ai.attempt` <- `attempt`

`on_retry(event)` emits:
- `attempt`
- `next_attempt`
- `delay_ms`
- `status_code`
- `error_code`

Suggested OpenTelemetry mapping:
- span event name: `retry`
- event attributes:
  - `ai.retry.attempt` <- `attempt`
  - `ai.retry.next_attempt` <- `next_attempt`
  - `ai.retry.delay_ms` <- `delay_ms`
  - `http.status_code` <- `status_code`
  - `error.code` <- `error_code`

`on_request_complete(event)` emits:
- `attempt`
- `ok`
- `status_code`
- `error_code`
- `started_at`
- `finished_at`

Suggested OpenTelemetry mapping:
- span status: success or error based on `ok`
- span attributes:
  - `http.status_code` <- `status_code`
  - `error.code` <- `error_code`
  - `ai.attempt` <- `attempt`

## Metric Recommendations

Counters:
- `ai_sdk.requests_started_total`
- `ai_sdk.requests_completed_total`
- `ai_sdk.retries_total`
- `ai_sdk.errors_total` (by `error.code`)

Histograms:
- `ai_sdk.retry_delay_ms`
- `ai_sdk.request_duration_ms` (derived from `started_at` to `finished_at`)

Dimensions/tags:
- `provider`
- `model`
- `status_code`
- `error_code`
- `stream`

## Runnable Example

Use the telemetry bridge example:

```bash
./kujo run examples/telemetry_bridge.kujo --interpreter
```

The example emits OpenTelemetry-style JSON payloads for start, retry, and completion hook events and demonstrates retry behavior with an injected flaky transport.
