#!/usr/bin/env bash
# 从仓库根运行，仅实跑 echo / shell，不执行安装命令。
set -eu

output=''
code=0
# manifest include 在根 taskfile 中 internal:true，CLI 不可直呼；改经 taskfile.d/manifest.yaml 调用
task() {
  _args=()
  for _a in "$@"; do
    case $_a in
      manifest:*) _args+=(--taskfile taskfile.d/manifest.yaml --dir . "${_a#manifest:}") ;;
      *) _args+=("$_a") ;;
    esac
  done
  command task "${_args[@]}"
}
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

capture manifest:dispatch MANIFEST=fixtures/manifest-dispatch/group-coe-propagation.yaml CALLS=echo=echo:replay CONTINUE_ON_ERROR=true
check test "$code" = 201
check test "${output#*item=prop-2 }" != "$output"
check test "${output#*item=never-reached }" = "$output"
check test "${output#*item=after-group }" = "$output"
printf 'PASS: explicit false stops group with global true\n'

capture manifest:dispatch MANIFEST=fixtures/manifest-dispatch/fail-fast.yaml CALLS=echo=echo:replay CONTINUE_ON_ERROR=true
check test "$code" = 201
check test "${output#*item=never }" != "$output"
check test "${output#*failed: boom}" != "$output"
printf 'PASS: absent item flag inherits global true\n'

fixture=fixtures/manifest-dispatch/receivers.taskfile.yaml
capture --dry manifest:scoop:uninstall 'ITEM_JSON={"kind":"scoop-app","name":"gdm257/starpie","state":"absent"}'
check test "$code" = 0
check test "${output#*scoop list starpie }" != "$output"
check test "${output#*scoop list gdm257/starpie}" = "$output"
printf 'PASS: scoop:uninstall probes installed list by bare name\n'

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

capture --dry manifest:acl:apply 'ITEM_JSON={"kind":"acl-path","path":"fixture dir","grants":["user1:(OI)(CI)F","S-1-5-32-545:(OI)(CI)RX"]}'
check test "$code" = 0
check test "${output#*'icacls "fixture dir" /grant:r "user1:(OI)(CI)F" /grant:r "S-1-5-32-545:(OI)(CI)RX"'}" != "$output"
check test "${output#*icacls}" != "$output"
check test "${output#*'if ! net session'}" != "$output"
check test "${output#*'if ! [ -e "fixture dir" ]'}" != "$output"
check test "${output#*'acl:apply: administrator required, rerun from an elevated terminal'}" != "$output"
check test "${output#*'acl:apply: path not found: fixture dir'}" != "$output"
printf 'PASS: acl:apply assembles single icacls with admin and path guards\n'

capture --dry manifest:acl:apply 'ITEM_JSON={"kind":"acl-path","path":"fixture dir"}'
check test "$code" = 0
check test "${output#*icacls}" = "$output"
printf 'PASS: acl:apply without grants runs no icacls\n'

capture --dry manifest:acl:apply 'ITEM_JSON={"kind":"acl-path","path":"fixture dir","grants":["user1:(OI)(CI)F","no-colon"]}'
check test "$code" != 0
check test "${output#*"acl:apply: grant 'no-colon' missing ':'"}" != "$output"
printf 'PASS: acl:apply rejects grant without colon\n'

capture --dry manifest:acl:apply 'ITEM_JSON={"kind":"acl-path","path":"fixture dir","owner":"some-user"}'
check test "$code" = 0
check test "${output#*takeown /f \"fixture dir\" /u \"some-user\"}" != "$output"
check test "${output#*icacls}" = "$output"
check test "${output#*takeown /r}" = "$output"
printf 'PASS: acl:apply owner-only runs takeown without recursion or icacls\n'

capture --dry manifest:acl:apply 'ITEM_JSON={"kind":"acl-path","path":"fixture dir","owner":"S-1-5-32-544","grants":["user1:F"],"recursive":true}'
check test "$code" = 0
check test "${output#*powershell -NoProfile -Command}" != "$output"
check test "${output#*GetAccessControl().AreAccessRulesProtected}" != "$output"
check test "${output#*'{ rc=0; while read -r p; do { takeown /f "$p" /u "S-1-5-32-544" && icacls "$p" /grant:r "user1:F"; } || rc=1; done; exit "$rc"; }'}" != "$output"
check test "${output#*'} || rc=1;'}" != "$output"
check test "${output#*'exit "$rc"'}" != "$output"
check test "${output#*/t /c}" = "$output"
printf 'PASS: acl:apply recursive converges per path and propagates loop failures\n'

capture --dry manifest:acl:apply 'ITEM_JSON={"kind":"acl-path","path":"fixture dir","owner":"some-user","grants":["user1:F"]}'
check test "$code" = 0
check test "${output#*takeown /f \"fixture dir\" /u \"some-user\" && icacls \"fixture dir\" /grant:r \"user1:F\"}" != "$output"
check test "${output#*/r}" = "$output"
check test "${output#*powershell}" = "$output"
check test "${output#*/reset}" = "$output"
printf 'PASS: acl:apply owner and grants default to top level only without inheritance\n'

capture --dry manifest:acl:apply 'ITEM_JSON={"kind":"acl-path","path":"fixture dir","owner":"some-user","grants":["user1:F"],"inheritance":"reset"}'
check test "$code" = 0
check test "${output#*icacls \"fixture dir\" /reset && takeown /f \"fixture dir\" /u \"some-user\" && icacls \"fixture dir\" /grant:r \"user1:F\"}" != "$output"
printf 'PASS: acl:apply inheritance reset precedes owner and grants convergence\n'

capture --dry manifest:acl:apply 'ITEM_JSON={"kind":"acl-path","path":"fixture dir","inheritance":"reset"}'
check test "$code" = 0
check test "${output#*icacls \"fixture dir\" /reset}" != "$output"
check test "${output#*takeown}" = "$output"
check test "${output#*/grant}" = "$output"
printf 'PASS: acl:apply reset only runs icacls reset and nothing else\n'

capture --dry manifest:acl:apply 'ITEM_JSON={"kind":"acl-path","path":"fixture dir","inheritance":"enforce"}'
check test "$code" != 0
check test "${output#*"acl:apply: unknown inheritance enforce"}" != "$output"
printf 'PASS: acl:apply rejects unknown inheritance value\n'

capture --dry manifest:acl:apply 'ITEM_JSON={"kind":"scoop-app","name":"fixture"}'
check test "$code" != 0
check test "${output#*'acl: unknown kind scoop-app'}" != "$output"
printf 'PASS: acl:apply self-validates kind\n'

faillog="${TMPDIR:-${TEMP:-/tmp}}/acl-path-receiver-faillog"
rm -f "$faillog"
capture manifest:acl:apply 'ITEM_JSON={"kind":"acl-path","path":"fixture-dir-missing","continue_on_error":true}' "FAIL_LOG=$faillog"
check test "$code" = 0
check read -r logged < "$faillog"
check test "${logged#failed: }" != "$logged"
printf 'PASS: acl:apply missing path with continue_on_error logs FAIL_LOG and continues\n'

for receiver in windows-feature:set scoop:install winget:install apt:install yum:install choco:install acl:apply; do
  case "${receiver%%:*}" in
    windows-feature) item='"kind":"windows-feature","feature":"fixture"' ;;
    acl) item='"kind":"acl-path","path":"fixture-dir"' ;;
    scoop) item='"kind":"scoop-app","name":"fixture"' ;;
    winget) item='"kind":"winget-app","id":"fixture"' ;;
    *) item="\"kind\":\"$receiver-package\",\"name\":\"fixture\"" ;;
  esac
  capture --dry "manifest:$receiver" "ITEM_JSON={$item,\"continue_on_error\":false}" CONTINUE_ON_ERROR=true
  check test "$code" = 0
  check test "${output#*'|| {'}" = "$output"
  capture --dry "manifest:$receiver" "ITEM_JSON={$item,\"continue_on_error\":true}" CONTINUE_ON_ERROR=false 'FAIL_LOG=fixture log'
  check test "$code" = 0
  check test "${output#*'>> "fixture log"'}" != "$output"
  capture --dry "manifest:$receiver" "ITEM_JSON={$item}" CONTINUE_ON_ERROR=true
  check test "$code" = 0
  check test "${output#*manifest-dispatch-faillog}" != "$output"
  printf 'PASS: %s precedence and FAIL_LOG dry-run only\n' "$receiver"
done
