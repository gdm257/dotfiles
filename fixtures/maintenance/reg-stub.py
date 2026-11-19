"""reg stub: add converges into REG_STUB_STATE; query reads it back as REG_SZ."""
import os
import sys

args = sys.argv[1:]
state = os.environ["REG_STUB_STATE"]


def flag(name):
    return args[args.index(name) + 1]


if args[:1] == ["add"]:
    with open(state, encoding="utf-8") as f:
        keep = [l for l in f.read().splitlines() if l and not l.startswith(args[1] + "|" + flag("/v") + "=")]
    with open(state, "w", encoding="utf-8") as f:
        f.write("\n".join(keep + [args[1] + "|" + flag("/v") + "=" + flag("/d")]) + "\n")
elif args[:1] == ["query"]:
    with open(state, encoding="utf-8") as f:
        for l in f.read().splitlines():
            k, _, v = l.partition("=")
            if k == args[1] + "|" + flag("/v"):
                print(args[1])
                print("    " + flag("/v") + "    REG_SZ    " + v)
                sys.exit(0)
    sys.exit(1)
