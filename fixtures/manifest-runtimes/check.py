"""Safe Task CLI rendering checks. Run from the repository root; never installs."""
import json
from pathlib import Path
import re
import shutil
import subprocess

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


for family, item, command in CASES:
    task = f"manifest:runtime:{family}:apply"
    def render(value, *args):
        return dry(task, "ITEM_JSON=" + json.dumps(value), *args)
    assert command in render({**item, "unknown_field": {"flag": False}})
    assert "||" not in render({**item, "continue_on_error": False}, "CONTINUE_ON_ERROR=true")
    assert '>> "custom-fail.log"' in render({**item, "continue_on_error": True}, "FAIL_LOG=custom-fail.log")
    assert '>> "custom-fail.log"' in render(item, "CONTINUE_ON_ERROR=true", "FAIL_LOG=custom-fail.log")
    assert ">&2" in render({**item, "continue_on_error": True})
    dry(task, 'ITEM_JSON={"kind":"unknown"}', success=False)

names = [case[0] for case in CASES] + ["volta-unix", "pipx-unix", "cargo-unix"]
wrappers = Path("taskfile.yaml").read_text(encoding="utf-8")
for name in names:
    manifest = Path(f"manifests/{name}.yaml").read_text(encoding="utf-8")
    assert not re.search(r"^(run|presets):", manifest, re.M), name
    block = re.search(rf"^  manifest:{name}:\n(.*?)(?=^  \S|\Z)", wrappers, re.M | re.S).group(1)
    assert "manifest:run" not in block, name
    assert "manifest:dispatch" in block and "CALL:" in block, name
    dry(f"manifest:{name}")
    if name.endswith("-unix"):
        assert "platforms: [linux, darwin]" in manifest
print("PASS: 14 receivers x 6 cases; 17 wrapper dry runs; batch double-zero checks")
