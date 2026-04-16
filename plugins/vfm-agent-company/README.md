# VFM Agent Company

> Autonomous AI software company plugin for Claude Code — CEO/CTO/PM/HR/BA + 17 FAANG specialists with BDD-driven development.

## Install

```bash
# Add the marketplace
/plugin marketplace add duylinhdang1998/claude-template-agent

# Install the plugin
/plugin install vfm-agent-company@vfm-agent-marketplace
```

## What's Included

- **5 Core Roles** (read-only orchestrators): CEO, CTO, PM, HR, BA
- **17 FAANG Specialists** (spawnable agents): Meta, Google, Apple, Amazon, Netflix, Microsoft engineers
- **49 Skills**: From frontend (React, Next.js) to backend (Node, Java, .NET), DevOps, ML, security, design, and more
- **Hook automation**: Conventional commits, sprint validation, auto-git checkpointing, subagent monitoring
- **MCP servers**: Playwright, Figma, Sequential Thinking, Context7

## Quick Start

After install:

```bash
/work "Build an e-commerce platform with Stripe payments"
```

The company handles everything: requirements (BDD), file blueprint, sprint planning, TDD coding, code review, QA, deployment.

## Project Setup

This plugin expects `.project/` directory in your project for sprints/state/specialists. The `/work` skill auto-creates this on first run.

## Hooks Behavior

- **PreToolUse(Bash)**: Enforces conventional commits on `git commit`
- **PostToolUse(Write|Edit)**: Validates sprint format, auto-commits milestones
- **SubagentStart**: Lazy-loads skills, validates sprint, injects task rules
- **SubagentStop**: Validates output, syncs progress, git checkpoint
- **UserPromptSubmit**: Enforces delegation rules
- **Stop/SessionEnd**: Sync progress, cleanup

## Troubleshooting

If hooks complain about missing `.project/` directory, run `/work` once to bootstrap.

## License

MIT — Dang Duy Linh
