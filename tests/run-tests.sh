#!/usr/bin/env bash
# ==============================================================================
# Poly Helm Chart - Regression Test Suite Runner
# Usage:
#   ./tests/run-tests.sh                        # Lint + run all positive & negative tests
#   ./tests/run-tests.sh <case_name>            # Run a specific test case (e.g. 02-job-cronjob-defaults)
#   ./tests/run-tests.sh --update               # Update golden expected files for all cases
#   ./tests/run-tests.sh <case_name> --update   # Update golden file for a specific case
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
CHART_DIR="${REPO_ROOT}/charts/poly"
CASES_DIR="${SCRIPT_DIR}/cases"
INVALID_CASES_DIR="${SCRIPT_DIR}/invalid-cases"

UPDATE_MODE=false
CASE_FILTER=""

for arg in "$@"; do
  if [[ "${arg}" == "--update" || "${arg}" == "-u" ]]; then
    UPDATE_MODE=true
  else
    CASE_FILTER="${arg}"
  fi
done

if [[ "${UPDATE_MODE}" == true ]]; then
  echo "🔄 Update mode enabled: Golden expected files will be overwritten."
fi

FAILED_COUNT=0
PASSED_COUNT=0

if [[ -z "${CASE_FILTER}" && "${UPDATE_MODE}" == false ]]; then
  echo "🔎 Running helm lint on ${CHART_DIR}..."
  if ! helm lint "${CHART_DIR}"; then
    echo "❌ helm lint failed!"
    exit 1
  fi
  echo "--------------------------------------------------------"
fi

echo "🚀 Starting Poly Helm Template Regression Tests..."
if [[ -n "${CASE_FILTER}" ]]; then
  echo "🔍 Filtering test case(s) matching: [${CASE_FILTER}]"
fi
echo "--------------------------------------------------------"

MATCH_FOUND=false
for test_dir in "${CASES_DIR}"/*; do
  if [[ -d "${test_dir}" ]]; then
    case_name="$(basename "${test_dir}")"

    # Apply filter if specified
    if [[ -n "${CASE_FILTER}" && "${case_name}" != *"${CASE_FILTER}"* ]]; then
      continue
    fi

    MATCH_FOUND=true
    values_file="${test_dir}/values.yaml"
    expected_file="${test_dir}/expected.yaml"
    actual_file="${test_dir}/actual.yaml"

    if [[ ! -f "${values_file}" ]]; then
      echo "⚠️ Skipping ${case_name}: values.yaml not found."
      continue
    fi

    echo -n "🧪 Testing case: [${case_name}] ... "

    # Render helm template and save to actual.yaml for inspection
    if ! helm template test-release "${CHART_DIR}" -f "${values_file}" > "${actual_file}" 2>/dev/null; then
      echo "❌ [FAILED] (helm template exited non-zero)"
      FAILED_COUNT=$((FAILED_COUNT + 1))
      continue
    fi

    if [[ "${UPDATE_MODE}" == true ]]; then
      cp "${actual_file}" "${expected_file}"
      echo "✅ [UPDATED expected.yaml]"
      PASSED_COUNT=$((PASSED_COUNT + 1))
    else
      if [[ ! -f "${expected_file}" ]]; then
        echo "❌ [FAILED] (expected.yaml missing! Run with --update to generate)"
        FAILED_COUNT=$((FAILED_COUNT + 1))
        continue
      fi

      if diff -u "${expected_file}" "${actual_file}" > /dev/null 2>&1; then
        echo "✅ [PASSED]"
        PASSED_COUNT=$((PASSED_COUNT + 1))
      else
        echo "❌ [FAILED]"
        echo "--------------------------------------------------------"
        echo "Diff detected for case: ${case_name}"
        diff -u "${expected_file}" "${actual_file}" || true
        echo "--------------------------------------------------------"
        FAILED_COUNT=$((FAILED_COUNT + 1))
      fi
    fi
  fi
done

if [[ "${MATCH_FOUND}" == false ]]; then
  echo "⚠️ No test case found matching filter: '${CASE_FILTER}'"
  exit 1
fi

if [[ -z "${CASE_FILTER}" && "${UPDATE_MODE}" == false && -f "${CHART_DIR}/values.schema.json" && -d "${INVALID_CASES_DIR}" ]]; then
  echo "--------------------------------------------------------"
  echo "🛡️ Running negative schema validation tests..."
  shopt -s nullglob
  invalid_files=("${INVALID_CASES_DIR}"/*.yaml)
  shopt -u nullglob
  for invalid_file in "${invalid_files[@]}"; do
    invalid_name="$(basename "${invalid_file}")"
    echo -n "🧪 Testing invalid case: [${invalid_name}] ... "
    if helm template test-release "${CHART_DIR}" -f "${invalid_file}" > /dev/null 2>&1; then
      echo "❌ [FAILED] (expected non-zero exit, but helm template succeeded)"
      FAILED_COUNT=$((FAILED_COUNT + 1))
    else
      echo "✅ [PASSED] (rejected as expected)"
      PASSED_COUNT=$((PASSED_COUNT + 1))
    fi
  done
fi

echo "--------------------------------------------------------"
if [[ ${FAILED_COUNT} -gt 0 ]]; then
  echo "❌ Tests completed: ${PASSED_COUNT} passed, ${FAILED_COUNT} failed."
  exit 1
else
  echo "🎉 All ${PASSED_COUNT} test cases passed successfully!"
  exit 0
fi
