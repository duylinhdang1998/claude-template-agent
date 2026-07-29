# Single Source of Truth

There are three copies of the agent system. Only ONE is canonical.

| Location | Role | How to update |
|----------|------|---------------|
| **`.claude/`** | ✅ **CANONICAL** — edit here | edit directly |
| `codex/dist/` | GENERATED (Codex CLI) | `python3 codex/build.py` — never hand-edit |
| `plugins/vfm-agent-company/` | DISTRIBUTED plugin | keep in sync from `.claude/` (see below) |

## Rules

1. **Always edit `.claude/`.** Never edit `codex/dist/` (it is overwritten) and
   avoid editing the plugin directly except to reconcile.
2. After changing `.claude/`, run:
   ```bash
   python3 codex/build.py            # regenerate codex/dist (safe, automatic)
   bash .claude/scripts/check-drift.sh   # report what the plugin still lags
   ```
3. **Plugin sync is manual, not a blind copy.** The plugin uses a transformed
   layout (`.claude/hooks/*.sh` → `hooks/scripts/*.sh`, `.claude/automation` →
   `hooks/scripts/automation`, `.claude/monitor/hooks` → `hooks/scripts/monitor`)
   and its hook scripts resolve paths differently (`$CLAUDE_PLUGIN_ROOT` vs
   `$SCRIPT_DIR/../..`). Copying `.sh` files verbatim will break path resolution.
   Port the *logic* by hand, then re-run the drift check.

## Why this matters

Editing the wrong copy is a classic "I fixed it but the agent still does the old
thing" trap — the runtime loaded a different copy. `check-drift.sh` makes divergence
visible so it never silently rots.
