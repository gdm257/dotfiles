"""Safe Task CLI rendering checks. Run from the repository root; never installs."""
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile

TASK = shutil.which("task")
assert TASK, "task is required"
CASES = [
    ("volta", {"kind": "volta-tool", "name": "node"}, "volta install node"),
    ("vfox-plugin", {"kind": "vfox-plugin", "name": "java"}, "vfox add java"),
    ("vfox-sdk", {"kind": "vfox-sdk", "name": "java@17"}, "vfox install java@17"),
    ("vfox-globalize", {"kind": "vfox-sdk", "name": "java@17"}, "vfox use --global java@17"),
    ("pipx", {"kind": "pipx-package", "name": "ansible", "include_deps": True, "preinstall": ["netaddr"]}, "pipx install --include-deps --preinstall netaddr ansible"),
    ("npm", {"kind": "npm-package", "name": "eslint"}, "npm install -g eslint"),
    ("cargo", {"kind": "cargo-crate", "name": "sd"}, "cargo install sd"),
    ("go", {"kind": "go-package", "name": "example.org/tool@latest"}, "go install example.org/tool@latest"),
    ("conda-create", {"kind": "conda-environment", "name": "python3", "channel": "conda-forge", "packages": ["python=3.11.*", "pipx"]}, "micromamba create -y --channel conda-forge --name python3 python=3.11.* pipx"),
    ("rye", {"kind": "rye-toolchain", "version": "3.11.6"}, "rye toolchain fetch 3.11.6"),
    ("stack", {"kind": "stack-package", "name": "BNFC"}, "stack install BNFC"),
    ("pi", {"kind": "pi-package", "name": "npm:pi-subagents"}, "pi install npm:pi-subagents"),
    ("astro", {"kind": "astro-integration", "name": "react"}, "pnpm run astro -- add react"),
    ("x-cmd", {"kind": "x-cmd-package", "name": "brew"}, "x install brew"),
]


def dry(task, *args, success=True):
    result = subprocess.run([TASK, "--dry", task, *args], capture_output=True, text=True, encoding="utf-8")
    output = result.stdout + result.stderr
    assert (result.returncode == 0) == success, output
    return output


VERBS = {"vfox-plugin": "add", "vfox-globalize": "use", "conda-create": "create", "rye": "fetch", "astro": "add"}
for family, item, command in CASES:
    task = f"manifest:{family}:{VERBS.get(family, 'install')}"
    def render(value, *args):
        return dry(task, "ITEM_JSON=" + json.dumps(value), *args)
    assert command in render({**item, "unknown_field": {"flag": False}})
    assert "||" not in render({**item, "continue_on_error": False}, "CONTINUE_ON_ERROR=true")
    assert '>> "custom-fail.log"' in render({**item, "continue_on_error": True}, "FAIL_LOG=custom-fail.log")
    assert '>> "custom-fail.log"' in render(item, "CONTINUE_ON_ERROR=true", "FAIL_LOG=custom-fail.log")
    assert '>> "${TMPDIR:-${TEMP:-/tmp}}/manifest-dispatch-faillog"' in render({**item, "continue_on_error": True})
    dry(task, 'ITEM_JSON={"kind":"unknown"}', success=False)

PKGS = [
    ("manifest:winget:install", "manifest:winget:uninstall", {"kind": "winget-app", "id": "stub-app"}, "winget install --source winget --id stub-app", "winget install --source winget --id stub-app --version 1.2.3", "winget uninstall --source winget --id stub-app"),
    ("manifest:scoop:install", "manifest:scoop:uninstall", {"kind": "scoop-app", "name": "stub-app"}, "scoop install stub-app", "scoop install stub-app@1.2.3", "scoop uninstall stub-app"),
    ("manifest:choco:install", "manifest:choco:uninstall", {"kind": "choco-package", "name": "stub-app"}, "choco install -y stub-app", "choco install -y stub-app --version 1.2.3", "choco uninstall -y stub-app"),
]
STUBS = Path(__file__).with_name("stubs")


def live(task, value):
    log = Path(tempfile.gettempdir()) / "manifest-runtimes-stub.log"
    fail = Path(tempfile.gettempdir()) / "manifest-runtimes-faillog"
    log.write_text("", encoding="utf-8")
    fail.write_text("", encoding="utf-8")
    env = {**os.environ, "PATH": str(STUBS) + os.pathsep + os.environ["PATH"], "STUB_LOG": str(log)}
    result = subprocess.run([TASK, "--silent", task, "ITEM_JSON=" + json.dumps(value), f"FAIL_LOG={fail}"], capture_output=True, text=True, encoding="utf-8", env=env)
    return result.returncode, result.stdout + result.stderr, log.read_text(encoding="utf-8").splitlines(), fail.read_text(encoding="utf-8")


for install_task, uninstall_task, item, install, install_version, uninstall in PKGS:
    key = "id" if "id" in item else "name"
    code, output, lines, failed = live(install_task, item)
    assert code == 0 and lines == [install], output
    code, output, lines, failed = live(install_task, {**item, "state": "present", "version": "1.2.3"})
    assert code == 0 and lines == [install_version], output
    code, output, lines, failed = live(install_task, {**item, "state": "absent"})
    assert code != 0 and lines == [] and "absent" in output and item["kind"] in output, output
    code, output, lines, failed = live(uninstall_task, {**item, "state": "absent", "version": "1.2.3"})
    assert code == 0 and lines == [uninstall], output
    code, output, lines, failed = live(uninstall_task, {**item, key: "missing-app", "state": "absent"})
    assert code == 0 and lines == [] and failed == "", output
    code, output, lines, failed = live(uninstall_task, {**item, key: "failing-app", "state": "absent", "continue_on_error": True})
    assert code == 0 and lines == [uninstall.replace("stub-app", "failing-app")] and uninstall.replace("stub-app", "failing-app") in failed, output
    code, output, lines, failed = live(uninstall_task, {**item})
    assert code != 0 and lines == [] and "present" in output and item["kind"] in output, output
    code, output, lines, failed = live(uninstall_task, {**item, "state": "removed"})
    assert code != 0 and lines == [] and "removed" in output and item["kind"] in output, output

for item in ({"kind": "scoop-bucket", "name": "main", "state": "absent"}, {"kind": "scoop-config", "key": "use_lessmsi", "value": "true", "state": "present"}):
    code, output, lines, failed = live("manifest:scoop:install", item)
    assert code != 0 and lines == [] and item["state"] in output and item["kind"] in output, output

names = [case[0] for case in CASES] + ["volta-unix", "pipx-unix", "cargo-unix"]
wrappers = Path("taskfile.yaml").read_text(encoding="utf-8")
for name in names:
    manifest = Path(f"manifests/{name}.yaml").read_text(encoding="utf-8")
    assert not re.search(r"^(run|presets):", manifest, re.M), name
    verb = "install" if name.endswith("-unix") else VERBS.get(name, "install")
    block = re.search(rf"^  manifests:{name}:{verb}:\n(.*?)(?=^  \S|\Z)", wrappers, re.M | re.S).group(1)
    assert "manifest:run" not in block, name
    assert "manifest:dispatch" in block and "CALL:" in block, name
    dry(f"manifests:{name}:{verb}")
    if name.endswith("-unix"):
        assert "platforms: [linux, darwin]" in manifest
print("PASS: 14 receivers x 6 cases; 3 package install receivers x 3 cases + 3 uninstall receivers x 6 cases via PATH stubs; 2 no-removal kinds; 17 wrapper dry runs; batch double-zero checks")
