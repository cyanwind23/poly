#!/usr/bin/env bash
# ==============================================================================
# Poly Helm Chart - Regression Test Suite Runner
# Usage:
#   ./tests/run-tests.sh          # Run all tests and compare with expected output
#   ./tests/run-tests.sh --update # Update expected golden files with current output
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
CHART_DIR="${REPO_ROOT}/charts/poly"
CASES_DIR="${SCRIPT_DIR}/cases"

UPDATE_MODE=false
if [[ "${1:-}" == "--update" ]]; then
  UPDATE_MODE=true
  echo "🔄 Update mode enabled: Golden expected files will be overwritten."
fi

FAILED_COUNT=0
PASSED_COUNT=0

echo "🚀 Starting Poly Helm Template Regression Tests..."
echo "--------------------------------------------------------"

for test_dir in "${CASES_DIR}"/*; do
  if [[ -d "${test_dir}" ]]; then
    case_name="$(basename "${test_dir}")"
    values_file="${test_dir}/values.yaml"
    expected_file="${test_dir}/expected.yaml"
    actual_file="${test_dir}/actual.yaml"

    if [[ ! -f "${values_file}" ]]; then
      echo "⚠️ Skipping ${case_name}: values.yaml not found."
      continue
    fi

    echo -n "🧪 Testing case: [${case_name}] ... "

    # Render helm template and save to actual.yaml for inspection
    helm template test-release "${CHART_DIR}" -f "${values_file}" > "${actual_file}" 2>/dev/null

    if [[ "${UPDATE_MODE}" == true ]]; then
      cp "${actual_file}" "${expected_file}"
      echo "✅ [UPDATED expected.yaml]"
      ((PASSED_COUNT++))
    else
      if [[ ! -f "${expected_file}" ]]; then
        echo "❌ [FAILED] (expected.yaml missing! Run with --update to generate)"
        ((FAILED_COUNT++))
        continue
      fi

      if diff -u "${expected_file}" "${actual_file}" > /dev/null 2>&1; then
        echo "✅ [PASSED]"
        ((PASSED_COUNT++))
      else
        echo "❌ [FAILED]"
        echo "--------------------------------------------------------"
        echo "Diff detected for case: ${case_name}"
        diff -u "${expected_file}" "${actual_file}" || true
        echo "--------------------------------------------------------"
        ((FAILED_COUNT++))
      fi
    fi
  fi
done

echo "--------------------------------------------------------"
if [[ ${FAILED_COUNT} -gt 0 ]]; then
  echo "❌ Tests completed: ${PASSED_COUNT} passed, ${FAILED_COUNT} failed."
  exit 1
else
  echo "🎉 All ${PASSED_COUNT} test cases passed successfully!"
  exit 0
fi
