"""reg add stub: converges value per key/name in REG_STUB_STATE, mirroring /f overwrite."""
import os
import sys

args = sys.argv[1:]
if args[:1] != ["add"]:
    sys.exit(0)


def flag(name):
    return args[args.index(name) + 1]


entry = args[1] + "|" + flag("/v") + "=" + flag("/d")
state = os.environ["REG_STUB_STATE"]
with open(state, encoding="utf-8") as f:
    keep = [l for l in f.read().splitlines() if not l.startswith(args[1] + "|" + flag("/v") + "=")]
with open(state, "w", encoding="utf-8") as f:
    f.write("\n".join(keep + [entry]) + "\n")
