# VFM Agent Company — Plugin Upgrade Log

This file is maintained by the `claude-architect` skill. Every time a user reports a skill/agent failure and the architect upgrades the plugin, an entry is appended below. Entries are never edited or deleted — only appended.

**Purpose**:
1. Traceability — every plugin change ties back to an observed failure
2. Pattern detection — if the same skill gets upgraded 3+ times for related reasons, it needs structural rework, not another rule
3. Anti-regression — scores and rationale let a future architect verify rules still make sense

---

## [2026-04-18] claude-architect — Initial skill bootstrap

**Trigger (user report):**
> "Skill clone-website đang ngẫu hứng sáng tạo thêm section. Viết 1 skill architect để kiểm tra và nâng cấp .claude lên mỗi khi có vấn đề. Tuyệt đối không được hardcode."

**Iteration count:** 1st — creation, not a fix

**Root cause:**
Plugin had no self-improvement loop. Every skill failure required manual user intervention to re-edit SKILL.md, and there was no structured way to (a) diagnose whether the fix generalized or hardcoded the specific failure, (b) score the upgrade quality, (c) log the evolution. Without this loop, the same class of failure kept re-surfacing across different sections/projects.

**Upgrade type:** added (new skill)

**Files touched:**
- `plugins/vfm-agent-company/skills/claude-architect/SKILL.md` (new, ~270 lines)
- `plugins/vfm-agent-company/skills/claude-architect/UPGRADES.md` (new, this file)
- `plugins/vfm-agent-company/.claude-plugin/plugin.json` (version bump 1.0.5 → 1.1.0)
- `.claude-plugin/marketplace.json` (version bump)

**General principle added:**
Every plugin upgrade must pass the **Generality Litmus Test**: strip every proper noun (URL, brand, section name, specific value) from the proposed rule; if it still reads coherently and actionably, it's general. Otherwise, it's hardcoded — rewrite. The architect scores each upgrade on 10 criteria and will not commit below 8.0 overall.

**Verification mechanism:**
- Litmus Test applied during Step 3 (Draft)
- 10-criterion rubric in Step 6 (Self-Score) with pass threshold overall ≥ 8.0 and no single score < 6
- Mandatory UPGRADES.md append in Step 7 for audit trail
- Conventional commit message format tying back to root cause in Step 8

**Self-score:**
Not applicable — initial skill creation, not an upgrade of an existing skill. The first real upgrade logged here will be the first scored entry.

**Commit:** _(filled after push)_

---
