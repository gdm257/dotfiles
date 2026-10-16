#!/usr/bin/env bash
# 从仓库根运行，仅实跑 echo / shell，不执行安装命令。
set -eu

output=''
code=0
capture() {
  code=0
  if [ "${1:-}" = --dry ]; then
    output=$(task "$@" 2>&1) || code=$?
  else
    output=$(task --silent "$@" 2>&1) || code=$?
  fi
}
check() {
  if ! "$@"; then
    printf 'FAIL: %s\n%s\n' "$*" "$output" >&2
    exit 1
  fi
}

capture manifest:dispatch MANIFEST=fixtures/manifest-dispatch/group-coe-propagation.yaml CALL=echo:apply CONTINUE_ON_ERROR=true
check test "$code" = 201
check test "${output#*item=prop-2 }" != "$output"
check test "${output#*item=never-reached }" = "$output"
check test "${output#*item=after-group }" = "$output"
printf 'PASS: explicit false stops group with global true\n'

capture manifest:dispatch MANIFEST=fixtures/manifest-dispatch/fail-fast.yaml CALL=echo:apply CONTINUE_ON_ERROR=true
check test "$code" = 201
check test "${output#*item=never }" != "$output"
check test "${output#*failed: boom}" != "$output"
printf 'PASS: absent item flag inherits global true\n'

fixture=fixtures/manifest-dispatch/receivers.taskfile.yaml
capture --taskfile "$fixture" shell 'ITEM_JSON={"kind":"shell","cmd":"echo standalone-shell"}'
check test "$code" = 0
check test "$output" = standalone-shell
capture --taskfile "$fixture" shell 'ITEM_JSON={"kind":"shell","cmd":"false","continue_on_error":false}' CONTINUE_ON_ERROR=true
check test "$code" = 201
capture --taskfile "$fixture" shell 'ITEM_JSON={"kind":"shell","cmd":"false","continue_on_error":true}' CONTINUE_ON_ERROR=false
check test "$code" = 0
capture --taskfile "$fixture" shell:fail-log "FAIL_LOG=${TMPDIR:-${TEMP:-/tmp}}/receiver contract faillog"
check test "$code" = 0
check test "$output" = 'failed: false'
printf 'PASS: standalone shell and incoming FAIL_LOG with spaces\n'

for receiver in windows-feature scoop winget apt yum choco; do
  case "$receiver" in
    windows-feature) item='"kind":"windows-feature","feature":"fixture"' ;;
    scoop) item='"kind":"scoop-app","name":"fixture"' ;;
    winget) item='"kind":"winget-app","id":"fixture"' ;;
    *) item="\"kind\":\"$receiver-package\",\"name\":\"fixture\"" ;;
  esac
  capture --dry "manifest:$receiver:apply" "ITEM_JSON={$item,\"continue_on_error\":false}" CONTINUE_ON_ERROR=true
  check test "$code" = 0
  check test "${output#*'|| {'}" = "$output"
  capture --dry "manifest:$receiver:apply" "ITEM_JSON={$item,\"continue_on_error\":true}" CONTINUE_ON_ERROR=false 'FAIL_LOG=fixture log'
  check test "$code" = 0
  check test "${output#*'>> "fixture log"'}" != "$output"
  capture --dry "manifest:$receiver:apply" "ITEM_JSON={$item}" CONTINUE_ON_ERROR=true
  check test "$code" = 0
  check test "${output#*manifest-dispatch-faillog}" != "$output"
  printf 'PASS: %s precedence and FAIL_LOG dry-run only\n' "$receiver"
done
