#!/usr/bin/env bash
set -euo pipefail

RUNTIME_BIN="${KUJO_BIN:-kujo}"
if ! command -v "$RUNTIME_BIN" >/dev/null 2>&1; then
	if command -v ruff >/dev/null 2>&1; then
		RUNTIME_BIN="ruff"
	fi
fi

run_runtime_command_with_warning_gate() {
	local command_label="$1"
	shift

	echo "Running ${command_label}: $*"
	output="$($RUNTIME_BIN "$@" 2>&1)"
	echo "$output"

	if echo "$output" | grep -q "Type checking warnings:"; then
		echo "Warning gate violation for ${command_label}: runtime emitted type checking warnings."
		exit 1
	fi
}

run_test_suite_with_floor() {
	local test_file="$1"
	local min_tests="$2"

	echo "Running quality gate suite: ${test_file}"
	output="$($RUNTIME_BIN test-run "$test_file")"
	echo "$output"

	total_tests="$(echo "$output" | sed -n 's/.*Tests:[[:space:]]*\([0-9][0-9]*\)[[:space:]]*total.*/\1/p' | tail -n 1)"
	if [[ -z "$total_tests" ]]; then
		echo "Could not parse test total for ${test_file}."
		exit 1
	fi

	if (( total_tests < min_tests )); then
		echo "Test floor violation for ${test_file}: expected at least ${min_tests}, got ${total_tests}."
		exit 1
	fi

	TOTAL_TEST_COUNT=$((TOTAL_TEST_COUNT + total_tests))
}

TOTAL_TEST_COUNT=0
MIN_TOTAL_TEST_FLOOR=57

run_test_suite_with_floor tests/sdk_contract_tests.ruff 20
run_test_suite_with_floor tests/sdk_contract_resilience_tests.ruff 34
run_test_suite_with_floor tests/sdk_contract_embeddings_tests.ruff 6
run_test_suite_with_floor tests/security_redaction_tests.ruff 2
run_test_suite_with_floor tests/reliability_failure_modes_tests.ruff 6
run_test_suite_with_floor tests/parser_fuzz_smoke_tests.ruff 3
run_test_suite_with_floor tests/feature_smoke_tests.ruff 3
run_test_suite_with_floor tests/live_provider_smoke_tests.ruff 1

if (( TOTAL_TEST_COUNT < MIN_TOTAL_TEST_FLOOR )); then
	echo "Aggregate quality floor violation: expected at least ${MIN_TOTAL_TEST_FLOOR} tests, got ${TOTAL_TEST_COUNT}."
	exit 1
fi

run_runtime_command_with_warning_gate "feature smoke command" run examples/main.ruff
run_runtime_command_with_warning_gate "feature smoke command" run examples/production_profile.ruff
echo "Running contract schema verification: scripts/verify_contract_schemas.sh"
bash scripts/verify_contract_schemas.sh
run_runtime_command_with_warning_gate "benchmark quality gate" run scripts/benchmark_quality_gate.ruff

echo "Release quality gates passed with aggregate test count: ${TOTAL_TEST_COUNT}."
