"""PATH stub brain: missing-<name> reads as not installed, failing-<name> fails actions."""
import os
import sys

manager, args = sys.argv[1], sys.argv[2:]
sub, rest = (args[0], args[1:]) if args else ("", [])


def value(*flags):
    for flag in flags:
        if flag in rest:
            return rest[rest.index(flag) + 1]
    return next((arg for arg in rest if not arg.startswith("-")), "")


name = {"winget": value("--id"), "scoop": value(), "choco": value("--exact")}[manager]
if sub == "list":
    if manager == "scoop":  # real scoop list exits 0 even with no match
        print("Installed apps matching '%s':" % name)
        if not name.startswith("missing"):
            print("%s 1.0.0 main" % name.split("/")[-1])
        sys.exit(0)
    sys.exit(1 if name.startswith("missing") else 0)
if os.environ.get("STUB_LOG"):
    with open(os.environ["STUB_LOG"], "a", encoding="utf-8") as log:
        log.write(manager + " " + " ".join(args) + "\n")
sys.exit(1 if name.startswith("failing") else 0)
