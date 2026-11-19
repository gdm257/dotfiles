"""Drive the registry:set receiver via the fixture alias taskfile; exit code passthrough."""
import json
import subprocess
import sys

item, faillog, root = sys.argv[1:4]
with open(item, encoding="utf-8") as f:
    it = json.load(f)
tf = root + "\\fixtures\\maintenance\\receivers-taskfile.yaml"
rc = subprocess.run(
    ["task", "--taskfile", tf, "registry-set", "ITEM_JSON=" + json.dumps(it), "FAIL_LOG=" + faillog],
    cwd=root,
).returncode
sys.exit(rc)
