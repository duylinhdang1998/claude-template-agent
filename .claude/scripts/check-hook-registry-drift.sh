#!/usr/bin/env bash
##############################################################################
# check-hook-registry-drift.sh
#
# The framework ships TWO copies of itself:
#   .claude/                        → runtime when working inside this repo
#   plugins/vfm-agent-company/      → runtime when installed via marketplace
#
# Every hook must be registered in BOTH, or a rule written into an agent file
# is enforced on one side and decorative on the other. That has happened
# before (74ba59f shipped subagent-verify-go.sh to the plugin registry only,
# while all 11 agent files carried the "/go evidence is MANDATORY" rule).
#
# This script compares the two hook registries and the presence of every
# script they reference. Exit 1 on drift.
#
# Run it after ANY hook change, and in CI.
##############################################################################
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
exec python3 - "$ROOT" <<'PY'
import json, os, re, sys

root = sys.argv[1]
A = os.path.join(root, ".claude", "settings.json")
B = os.path.join(root, "plugins", "vfm-agent-company", "hooks", "hooks.json")

# Scripts that are equivalent across the two registries but named differently.
# .claude hooks take the payload on stdin; the plugin registry uses
# ${tool_input.file_path} templating — hence the wrapper on the .claude side.
ALIASES = {"validate-schema.sh": "validate-schema.py"}

def registry(path, key):
    with open(path, encoding="utf-8") as f:
        hooks = json.load(f)[key] if key else json.load(f)["hooks"]
    out = {}
    for event, groups in hooks.items():
        entries = set()
        for g in groups:
            # normalise: "Write|Edit" and "Edit|Write" are the same matcher,
            # and the two registries group entries differently
            matcher = "|".join(sorted(g.get("matcher", "*").split("|")))
            for h in g.get("hooks", []):
                blob = h.get("command", "") + " " + " ".join(h.get("args", []))
                found = re.findall(r"([\w.-]+\.(?:sh|py|js))", blob)
                name = found[-1] if found else blob.strip()
                entries.add((ALIASES.get(name, name), matcher))
        out[event] = entries
    return out

a = registry(A, None)
b = registry(B, None)

problems = []
for event in sorted(set(a) | set(b)):
    only_plugin = b.get(event, set()) - a.get(event, set())
    only_claude = a.get(event, set()) - b.get(event, set())
    for name, m in sorted(only_plugin):
        problems.append(f"{event} [{m}]: {name} — registered in PLUGIN only, missing from .claude/settings.json")
    for name, m in sorted(only_claude):
        problems.append(f"{event} [{m}]: {name} — registered in .claude only, missing from plugin hooks.json")

# every referenced script must exist on its own side
def exists_on(side_root, name):
    for dirpath, _, files in os.walk(side_root):
        if "node_modules" in dirpath or "/.git" in dirpath:
            continue
        if name in files:
            return True
    return False

inv = {v: k for k, v in ALIASES.items()}
for name, _ in {e for s in a.values() for e in s}:
    if not exists_on(os.path.join(root, ".claude"), inv.get(name, name)):
        problems.append(f"MISSING FILE: .claude/**/{inv.get(name, name)} is registered but does not exist")
for name, _ in {e for s in b.values() for e in s}:
    if not exists_on(os.path.join(root, "plugins", "vfm-agent-company"), name):
        problems.append(f"MISSING FILE: plugins/**/{name} is registered but does not exist")

if problems:
    print("🔴 HOOK REGISTRY DRIFT — the two runtimes do not enforce the same rules:\n")
    for p in problems:
        print(f"  - {p}")
    print("\nFix: mirror the hook to BOTH sides, then re-run this script.")
    sys.exit(1)

total = sum(len(s) for s in a.values())
print(f"✅ Hook registries match — {total} hook registrations across {len(a)} events, all scripts present on both sides.")
PY
