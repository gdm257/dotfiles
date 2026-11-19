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

capture --dry manifest:acl:apply 'ITEM_JSON={"kind":"acl-path","path":"fixture dir","inheritance":"disable","grants":["user1:F"]}'
check test "$code" = 0
check test "${output#*icacls \"fixture dir\" /inheritance:d && icacls \"fixture dir\" /grant:r \"user1:F\"}" != "$output"
check test "${output#*/reset}" = "$output"
printf 'PASS: acl:apply inheritance disable precedes grants convergence\n'

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

capture --dry manifest:acl:lock 'ITEM_JSON={"kind":"acl-lock","path":"fixture dir"}'
check test "$code" = 0
check test "${output#*'if ! net session'}" != "$output"
check test "${output#*'acl:lock: administrator required, rerun from an elevated terminal'}" != "$output"
check test "${output#*'acl:lock: path not found: fixture dir'}" != "$output"
check test "${output#*powershell -NoProfile -Command}" != "$output"
check test "${output#*'$p="fixture dir"'}" != "$output"
check test "${output#*'$acl.SetAccessRuleProtection($true, $false)'}" != "$output"
check test "${output#*'$acl.RemoveAccessRule($_)'}" != "$output"
check test "${output#*'@("S-1-5-18","S-1-5-32-544")'}" != "$output"
check test "${output#*ReadAndExecute}" != "$output"
check test "${output#*ContainerInherit,ObjectInherit}" != "$output"
check test "${output#*'$acl.SetOwner'}" != "$output"
check test "${output#*'Set-Acl -LiteralPath $p -AclObject $acl'}" != "$output"
check test "${output#*'[ -d "fixture dir" ]'}" != "$output"
check test "${output#*'$converged=$false'}" != "$output"
check test "${output#*'AreAccessRulesProtected'}" != "$output"
check test "${output#*'$good.Count -eq 2'}" != "$output"
check test "${output#*'CreateDirectory'}" = "$output"
printf 'PASS: acl:lock assembles fixed lockdown recipe with guards and converge skip\n'

capture --dry manifest:acl:lock 'ITEM_JSON={"kind":"acl-lock","path":"fixture dir","create":true}'
check test "$code" = 0
check test "${output#*'[System.IO.Directory]::CreateDirectory($p)'}" != "$output"
check test "${output#*'acl:lock: path not found'}" = "$output"
check test "${output#*'[ -d "fixture dir" ]'}" = "$output"
printf 'PASS: acl:lock declared create skips not-found guard and pre-creates via powershell\n'

capture --dry manifest:acl:lock 'ITEM_JSON={"kind":"acl-path","path":"fixture dir"}'
check test "$code" != 0
check test "${output#*'acl:lock: unknown kind acl-path'}" != "$output"
printf 'PASS: acl:lock self-validates kind\n'

faillog="${TMPDIR:-${TEMP:-/tmp}}/acl-lock-receiver-faillog"
rm -f "$faillog"
capture manifest:acl:lock 'ITEM_JSON={"kind":"acl-lock","path":"fixture-dir-missing","continue_on_error":true}' "FAIL_LOG=$faillog"
check test "$code" = 0
check read -r logged < "$faillog"
check test "${logged#failed: }" != "$logged"
check test "${logged#*'failed: acl:lock '}" != "$logged"
printf 'PASS: acl:lock missing path with continue_on_error logs FAIL_LOG and continues\n'

capture --dry manifest:link:apply 'ITEM_JSON={"kind":"sym-link","src":"apps/*","dst":"~/AppData/Roaming/"}'
check test "$code" = 0
check test "${output#*pwsh -NoProfile -Command}" != "$output"
check test "${output#*\$src=\"apps/*\"}" != "$output"
check test "${output#*'Get-ChildItem -Path $src -Force'}" != "$output"
check test "${output#*'ErrorActionPreference="Stop"'}" != "$output"
check test "${output#*'New-Item -ItemType SymbolicLink -Path $t -Value $m.FullName'}" != "$output"
check test "${output#*'Join-Path $dst $m.Name'}" != "$output"
check test "${output#*'$dst.EndsWith("/")'}" != "$output"
check test "${output#*'-replace "^~", $env:USERPROFILE'}" != "$output"
check test "${output#*'link:apply: exists and is not a symbolic link: $t'}" != "$output"
check test "${output#*'Remove-Item -LiteralPath $t -Force'}" != "$output"
check test "${output#*'New-Item -ItemType Directory -Path $pp -Force'}" != "$output"
check test "${output#*'link:apply: dst must be ~/-anchored'}" != "$output"
check test "${output#*'[IO.Path]::GetFullPath($cur) -ieq [IO.Path]::GetFullPath($m.FullName)'}" != "$output"
printf 'PASS: link:apply assembles dotglob symlink convergence\n'

capture --dry manifest:link:apply 'ITEM_JSON={"kind":"sym-link","src":"dotfiles/*"}'
check test "$code" = 0
check test "${output#*\$src=\"dotfiles/*\"}" != "$output"
check test "${output#*\$dst=\"~/\"}" != "$output"
printf 'PASS: link:apply defaults dst to home directory\n'

capture --dry manifest:link:apply 'ITEM_JSON={"kind":"scoop-app","name":"fixture"}'
check test "$code" != 0
check test "${output#*'link: unknown kind scoop-app'}" != "$output"
printf 'PASS: link:apply self-validates kind\n'

capture --dry manifest:link:apply 'ITEM_JSON={"kind":"sym-link","src":"x","state":"absent"}'
check test "$code" != 0
check test "${output#*'link:apply: unexpected state absent'}" != "$output"
printf 'PASS: link:apply rejects absent state\n'

capture manifest:link:apply 'ITEM_JSON={"kind":"sym-link","src":"fixtures/*.no-such-glob","dst":"~/no-such-dir/"}'
check test "$code" = 0
check test -z "$output"
printf 'PASS: link:apply zero-match glob succeeds silently\n'

capture manifest:link:apply 'ITEM_JSON={"kind":"sym-link","src":"fixtures/no-such-file","dst":"~/no-such-file"}'
check test "$code" != 0
check test "${output#*Get-ChildItem}" != "$output"
printf 'PASS: link:apply fails loudly on missing exact-path src\n'

capture --dry manifest:logon-task:register 'ITEM_JSON={"kind":"logon-task","name":"fixture task","cmd":"C:/home/system/oobe/per-user.cmd","args":"--quiet"}'
check test "$code" = 0
check test "${output#*powershell -NoProfile -Command}" != "$output"
check test "${output#*'Get-CimClass -Namespace Root/Microsoft/Windows/TaskScheduler -ClassName MSFT_TaskLogonTrigger'}" != "$output"
check test "${output#*'New-ScheduledTaskPrincipal -GroupId "S-1-5-32-545" -LogonType Interactive'}" != "$output"
check test "${output#*'-Execute "C:/home/system/oobe/per-user.cmd" -Argument "--quiet"'}" != "$output"
check test "${output#*'Register-ScheduledTask -TaskName "fixture task"'}" != "$output"
printf 'PASS: logon-task:register assembles any-user logon task with interactive group principal\n'

capture --dry manifest:logon-task:register 'ITEM_JSON={"kind":"logon-task","name":"fixture","cmd":"C:/per-user.cmd"}'
check test "$code" = 0
check test "${output#*-Argument}" = "$output"
printf 'PASS: logon-task:register omits argument without declared args\n'

capture --dry manifest:logon-task:register 'ITEM_JSON={"kind":"logon-task","name":"fixture"}'
check test "$code" != 0
check test "${output#*'logon-task: missing cmd'}" != "$output"
printf 'PASS: logon-task:register rejects item without cmd\n'

capture --dry manifest:logon-task:register 'ITEM_JSON={"kind":"scoop-app","name":"fixture"}'
check test "$code" != 0
check test "${output#*'logon-task: unknown kind scoop-app'}" != "$output"
printf 'PASS: logon-task:register self-validates kind\n'

capture --dry manifest:registry:set 'ITEM_JSON={"kind":"registry-value","path":"HKLM\\SOFTWARE\\fixture","name":"FixtureValue","type":"REG_DWORD","value":"1"}'
check test "$code" = 0
check test "${output#*'/t REG_DWORD /d "1" /f'}" != "$output"
printf 'PASS: registry:set assembles reg add with declared type and value\n'

capture --dry manifest:registry:set 'ITEM_JSON={"kind":"registry-value","path":"HKLM\\SOFTWARE\\fixture","name":"FixtureValue"}'
check test "$code" = 0
check test "${output#*'/t REG_SZ '}" != "$output"
printf 'PASS: registry:set defaults type to REG_SZ\n'

capture --dry manifest:registry:set 'ITEM_JSON={"kind":"registry-value","path":"HKCU\\Software\\fixture","name":"v","value":"1"}'
check test "$code" != 0
check test "${output#*'registry:set: non-HKLM path rejected: HKCU'}" != "$output"
printf 'PASS: registry:set rejects non-HKLM path\n'

capture --dry manifest:registry:set 'ITEM_JSON={"kind":"registry-value","path":"HKLM\\SOFTWARE\\fixture","name":"v","type":"REG_BOGUS","value":"1"}'
check test "$code" != 0
check test "${output#*'registry:set: unknown type REG_BOGUS'}" != "$output"
printf 'PASS: registry:set rejects unknown type\n'

capture --dry manifest:registry:set 'ITEM_JSON={"kind":"scoop-app","name":"fixture"}'
check test "$code" != 0
check test "${output#*'registry: unknown kind scoop-app'}" != "$output"
printf 'PASS: registry:set self-validates kind\n'

# registry:set 收敛语义经 PATH stub reg（fixtures/manifest-runtimes/stubs）实跑，REG_STUB_STATE 文件即注册表
regstate="${TMPDIR:-${TEMP:-/tmp}}/registry-receiver-state"
export REG_STUB_STATE="$regstate"
regitem='ITEM_JSON={"kind":"registry-value","path":"HKLM\\SOFTWARE\\home-fixture","name":"FixtureValue","type":"REG_DWORD","value":"1"}'
: > "$regstate"
PATH="$(pwd)/fixtures/manifest-runtimes/stubs:$PATH" capture manifest:registry:set "$regitem"
check test "$code" = 0
check test "$(cat "$regstate")" = 'HKLM\SOFTWARE\home-fixture|FixtureValue=1'
PATH="$(pwd)/fixtures/manifest-runtimes/stubs:$PATH" capture manifest:registry:set "$regitem"
check test "$code" = 0
check test "$(cat "$regstate")" = 'HKLM\SOFTWARE\home-fixture|FixtureValue=1'
printf 'PASS: registry:set writes value and rerun converges unchanged\n'

printf 'HKLM\\SOFTWARE\\home-fixture|FixtureValue=99\n' > "$regstate"
PATH="$(pwd)/fixtures/manifest-runtimes/stubs:$PATH" capture manifest:registry:set "$regitem"
check test "$code" = 0
check test "$(cat "$regstate")" = 'HKLM\SOFTWARE\home-fixture|FixtureValue=1'
printf 'PASS: registry:set pulls drifted value back to declared\n'

capture --dry manifest:winget:install 'ITEM_JSON={"kind":"winget-app","id":"fixture","scope":"machine"}'
check test "$code" = 0
check test "${output#*'--id fixture --scope machine'}" != "$output"
printf 'PASS: winget:install appends declared scope\n'

capture --dry manifest:winget:install 'ITEM_JSON={"kind":"winget-app","id":"fixture"}'
check test "$code" = 0
check test "${output#*--scope}" = "$output"
printf 'PASS: winget:install without scope adds no flag\n'

for receiver in windows-feature:set scoop:install winget:install apt:install yum:install choco:install acl:apply acl:lock link:apply logon-task:register registry:set; do
  case "$receiver" in
    windows-feature:set) item='"kind":"windows-feature","feature":"fixture"' ;;
    acl:apply) item='"kind":"acl-path","path":"fixture-dir"' ;;
    acl:lock) item='"kind":"acl-lock","path":"fixture-dir"' ;;
    link:apply) item='"kind":"sym-link","src":"fixture/*"' ;;
    logon-task:register) item='"kind":"logon-task","name":"fixture","cmd":"fixture-cmd"' ;;
    scoop:install) item='"kind":"scoop-app","name":"fixture"' ;;
    winget:install) item='"kind":"winget-app","id":"fixture"' ;;
    registry:set) item='"kind":"registry-value","path":"HKLM\\SOFTWARE\\fixture","name":"v","value":"1"' ;;
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
