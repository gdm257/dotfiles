"""Maintenance drift check: read-only comparison of declared machine-level
config (registry values, windows features) against live state via reg/dism.
Exit 0 clean / 10 drift / 232 tool missing."""
import os
import re
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
MANIFESTS = Path(os.environ.get("MTN_MANIFESTS_DIR", ROOT / "manifests"))


def run_tool(name, args):
    exe = shutil.which(name)
    if exe is None:
        sys.exit(232)
    cmd = [exe, *args]
    if exe.lower().endswith((".bat", ".cmd")):
        cmd = ["cmd", "/c", *cmd]
    return subprocess.run(cmd, capture_output=True, text=True, encoding="utf-8", errors="replace")


# shortcut: items-only YAML 子集（平铺 flow/block map，无 groups/嵌套），manifests 结构变复杂时再换真解析器
def load_items(name):
    path = MANIFESTS / name
    if not path.exists():
        return []
    items, cur = [], None
    for line in path.read_text(encoding="utf-8").splitlines():
        s = line.strip()
        if not s or s.startswith("#") or s == "items: []":
            continue
        m = re.match(r"-\s+(.*)$", s)
        if m:
            cur = {}
            items.append(cur)
            s = m.group(1)
        if cur is None or ":" not in s:
            continue
        for part in s.strip("{}").split(","):
            if ":" in part:
                k, v = part.split(":", 1)
                cur[k.strip()] = v.strip().strip("'\"")
    return items


def check_registry(drifts):
    for it in load_items("registry.yaml"):
        want_t = it.get("type", "REG_SZ")
        want_v = it.get("value", "")
        if want_t in ("REG_DWORD", "REG_QWORD"):
            want_v = hex(int(want_v, 0))
        got = None
        r = run_tool("reg", ["query", it["path"], "/v", it["name"]])
        if r.returncode == 0:
            for line in r.stdout.splitlines():
                parts = line.split()
                if len(parts) >= 3 and parts[0] == it["name"]:
                    got = (parts[1], " ".join(parts[2:]))
        if got is None or got[0] != want_t or got[1] != want_v:
            drifts.append(f"registry {it['path']}\\{it['name']}: want {want_t} {want_v}, got {got}")


def check_features(drifts):
    for it in load_items("windows-features.yaml"):
        want = "Enabled" if it.get("state", "enabled") == "enabled" else "Disabled"
        r = run_tool("dism", ["/online", "/get-featureinfo", "/featurename:" + it["feature"]])
        m = re.search(r"State\s*:\s*(\w+)", r.stdout)
        got = m.group(1) if m else None
        if got != want:
            drifts.append(f"feature {it['feature']}: want {want}, got {got}")


drifts = []
check_registry(drifts)
check_features(drifts)
for d in drifts:
    print("DRIFT: " + d)
print("maintenance check: " + ("drift detected" if drifts else "clean"))
sys.exit(10 if drifts else 0)
