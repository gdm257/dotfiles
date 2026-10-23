#!/usr/bin/env bash
# 从仓库根运行，仅使用 task CLI 与 bash builtins，接收方仅 echo。
set -eu
failures=0
output=''
code=0
capture() {
  code=0
  output=$(task --silent manifest:dispatch "MANIFEST=fixtures/manifest-dispatch/$1.yaml" "CALL=${3:-echo:replay}" "CONTINUE_ON_ERROR=${2:-true}" 2>&1) || code=$?
}
check() {
  if ! "$@"; then
    printf 'FAIL: %s\n%s\n' "$*" "$output" >&2
    failures=$((failures + 1))
  fi
}

capture group-coe-false
check test "$code" = 201
check test "${output#*'json={"continue_on_error":false,"kind":"echo","name":"strict-marker"}'}" != "$output"
check test "${output#*item=never-strict }" = "$output"
check test "${output#*item=after-strict }" = "$output"

capture group-coe-member-override
check test "$code" = 201
check test "${output#*item=after-member }" != "$output"
check test "${output#*failed: member-tolerated}" != "$output"

capture group-coe-repeated
check test "$code" = 0
expected=''
nl='
'
for flag in true false absent false true; do
  field="\"continue_on_error\":$flag,"
  if [ "$flag" = absent ]; then field=''; fi
  line="item=repeated kind=echo flag=false json={${field}\"kind\":\"echo\",\"name\":\"repeated\"}"
  expected="${expected}${expected:+$nl}$line"
done
check test "$output" = "$expected"

capture group-state-propagation false
check test "$code" = 0
expected='item=prop-1 kind=echo flag=false json={"kind":"echo","name":"prop-1","state":"absent"}
item=prop-2 kind=echo flag=false json={"kind":"echo","name":"prop-2","state":"absent"}
item=after-group kind=echo flag=false json={"kind":"echo","name":"after-group"}'
check test "$output" = "$expected"

capture group-state-member-override false
check test "$code" = 0
expected='item=implicit kind=echo flag=false json={"kind":"echo","name":"implicit","state":"absent"}
item=explicit-present kind=echo flag=false json={"kind":"echo","name":"explicit-present","state":"present"}'
check test "$output" = "$expected"

capture group-field-propagation false
check test "$code" = 0
expected='item=inherits kind=echo flag=false json={"kind":"echo","name":"inherits","tier":"gold"}
item=overrides kind=echo flag=false json={"kind":"echo","name":"overrides","tier":"silver"}
item=after-group kind=echo flag=false json={"kind":"echo","name":"after-group"}'
check test "$output" = "$expected"

capture group-field-repeated false
check test "$code" = 0
expected='item=repeated kind=echo flag=false json={"kind":"echo","name":"repeated","tier":"gold"}
item=repeated kind=echo flag=false json={"kind":"echo","name":"repeated"}'
check test "$output" = "$expected"

for scenario in unknown-top-key unknown-group nested-group missing-kind non-scalar-kind non-map-item invalid-platform-segments invalid-platform-os empty-platform-arch-inline empty-platform-arch-member empty-platform-arch-group; do
  case "$scenario" in
    unknown-top-key) message="item #1 unknown top-level key 'extra'" ;;
    unknown-group) message="item #1 unknown group 'nope'" ;;
    nested-group) message="item #2 nested group 'inner'" ;;
    missing-kind|non-scalar-kind) message='item #2 missing or non-scalar kind' ;;
    non-map-item) message='item #2 not a map' ;;
    invalid-platform-segments) message="item #2 invalid platform 'windows/amd64/extra'" ;;
    invalid-platform-os) message="item #2 invalid platform 'foo'" ;;
    *) message="item #2 invalid platform 'windows/'" ;;
  esac
  capture "structure/$scenario"
  check test "$code" = 1
  check test "${output#*"$message"}" != "$output"
  check test "${output#*"fixtures/manifest-dispatch/structure/$scenario.yaml"}" != "$output"
  check test "${output#*item=}" = "$output"
done

capture bool-fidelity false
check test "$code" = 0
check test "${output#*'item=bool-true kind=echo flag=true'}" != "$output"
check test "${output#*'item=bool-false kind=echo flag=false'}" != "$output"
check test "${output#*'"opts":{"deep":{"x":1}},"tags":["a","b"]'}" != "$output"

capture filtering false
check test "$code" = 0
check test "${output#*item=always }" != "$output"
case "$OSTYPE" in
  msys*|cygwin*) present=win-only; absent=linux-only ;;
  linux*) present=linux-only; absent=win-only ;;
  darwin*) present=dg-2; absent=win-only ;;
  *) printf 'Unsupported test platform: %s\n' "$OSTYPE" >&2; exit 1 ;;
esac
check test "${output#*"item=$present "}" != "$output"
check test "${output#*"item=$absent "}" = "$output"

for scenario in empty all-filtered; do
  capture "$scenario" false
  check test "$code" = 0
  check test "$output" = ''
done
capture fail-fast false
check test "$code" = 201
check test "${output#*item=ok-1 }" != "$output"
check test "${output#*item=never }" = "$output"
capture fail-log-summary false
check test "$code" = 201
check test "${output#*item=ok-2 }" != "$output"
check test "${output#*'manifest:dispatch: failed items:'}" != "$output"
check test "${output#*'failed: tolerated'}" != "$output"
capture group-coe-propagation false
check test "$code" = 201
check test "${output#*item=prop-2 }" != "$output"
check test "${output#*item=never-reached }" = "$output"
check test "${output#*item=after-group }" = "$output"
capture v1-form false
check test "$code" = 1
check test "${output#*"item #1 unknown top-level key 'command'"}" != "$output"
check test "${output#*fixtures/manifest-dispatch/v1-form.yaml}" != "$output"
capture bool-fidelity false no-such-task
case $code in 200|201) ;; *) check test "$code" = '200|201' ;; esac
check test "${output#*'manifest:no-such-task'}" != "$output"
code=0
output=$(task --silent manifest:echo:replay 'ITEM_JSON={"kind":"echo","name":"x"}' 2>&1) || code=$?
check test "$code" = 202
check test "${output#*'is internal'}" != "$output"

if [ "$failures" != 0 ]; then
  printf 'FAIL: %s dispatch assertions\n' "$failures" >&2
  exit 1
fi
printf 'PASS: 28 dispatch CLI scenarios including all fixtures, state and neutral field propagation, group precedence/isolation, locations and empty arch\n'
