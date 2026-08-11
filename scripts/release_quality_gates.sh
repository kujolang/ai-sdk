#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WRAPPER_BIN="$ROOT_DIR/kujo"

if [[ -z "${KUJO_BIN:-}" ]]; then
	echo "Set KUJO_BIN to the Kujo runtime binary path."
	exit 1
fi

run_runtime_command_with_warning_gate() {
	local command_label="$1"
	shift

	echo "Running ${command_label}: $*"
	output="$(KUJO_BIN="$KUJO_BIN" "$WRAPPER_BIN" "$@" 2>&1)"
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
	output="$(KUJO_BIN="$KUJO_BIN" "$WRAPPER_BIN" test-run "$test_file")"
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
MIN_TOTAL_TEST_FLOOR=105

run_test_suite_with_floor tests/sdk_contract_tests.kujo 28
run_test_suite_with_floor tests/sdk_contract_resilience_tests.kujo 39
run_test_suite_with_floor tests/sdk_contract_embeddings_tests.kujo 14
run_test_suite_with_floor tests/security_redaction_tests.kujo 3
run_test_suite_with_floor tests/reliability_failure_modes_tests.kujo 9
run_test_suite_with_floor tests/parser_fuzz_smoke_tests.kujo 3
run_test_suite_with_floor tests/feature_smoke_tests.kujo 3
run_test_suite_with_floor tests/bugfix_regression_tests.kujo 10
run_test_suite_with_floor tests/live_provider_smoke_tests.kujo 1

if (( TOTAL_TEST_COUNT < MIN_TOTAL_TEST_FLOOR )); then
	echo "Aggregate quality floor violation: expected at least ${MIN_TOTAL_TEST_FLOOR} tests, got ${TOTAL_TEST_COUNT}."
	exit 1
fi

run_runtime_command_with_warning_gate "feature smoke command" run examples/main.kujo
run_runtime_command_with_warning_gate "feature smoke command" run examples/production_profile.kujo
echo "Running contract schema verification: scripts/verify_contract_schemas.sh"
bash scripts/verify_contract_schemas.sh
run_runtime_command_with_warning_gate "benchmark quality gate" run scripts/benchmark_quality_gate.kujo

echo "Release quality gates passed with aggregate test count: ${TOTAL_TEST_COUNT}."
