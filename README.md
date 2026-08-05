<div align="center">

# 🏢 VFM Agent Company

**An autonomous AI software company, packaged as a Claude Code plugin.**
*One command spins up a full tech org — leadership + FAANG engineers + an SEO division — that ships working code, not just suggestions.*

[![Powered by Claude Code](https://img.shields.io/badge/Powered%20by-Claude%20Code-blue)](https://github.com/anthropics/claude-code)
[![Also runs on Codex CLI](https://img.shields.io/badge/Also%20on-Codex%20CLI-black)](codex/README.md)
[![Version](https://img.shields.io/badge/version-1.8.0-green)](.claude-plugin/plugin.json)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](#-license--giấy-phép)

**🌐 [English](#-english) · [Tiếng Việt](#-tiếng-việt)**

</div>

---

## 🇬🇧 English

### What is this?

**VFM Agent Company** turns Claude Code into a **full software company**. Instead of chatting with one AI, you get an organization: a **leadership team** (CEO / CTO / PM / HR / BA), **17 elite FAANG specialists** (Meta, Google, Apple, Amazon, Netflix, Microsoft), and a dedicated **SEO division** (18 sub-agents) — all coordinated through a **BDD/TDD** workflow so the output is verifiable and actually runs.

| At a glance | |
|---|---|
| 🎯 **5 core roles** | CEO, CTO, PM, HR, BA — leadership that plans & delegates |
| 👷 **34 specialist agents** | 17 FAANG engineers + 18 SEO sub-agents, spawned in parallel |
| 🎓 **99 skills** | On-demand expertise (frontend, backend, cloud, mobile, security, SEO…) |
| 🪝 **Machine-enforced quality** | Hooks enforce commits, code standards & auto-checkpoints — not "AI remembering" |
| 🔌 **8 data extensions** | Ahrefs, DataForSEO, Firecrawl, Bing Webmaster, SE Ranking… |

### Install (Claude Code plugin)

This repo is a Claude Code **plugin marketplace**:

```bash
/plugin marketplace add duylinhdang1998/claude-template-agent
/plugin install vfm-agent-company@vfm-agent-marketplace
```

Then just start working:

```bash
/work "Build an e-commerce platform with Stripe payments"
```

Or open the live dashboard:

```bash
/company start   # real-time panel + integrated terminal in your browser
/company stop    # close it when done
```

### Install (OpenAI Codex CLI)

The company also runs on **Codex CLI**. A single generator (`codex/build.py`) converts the Claude sources into Codex-native skills + an `AGENTS.md` manual — `.claude/` stays the single source of truth.

```bash
# from the repo root:
bash codex/install.sh                 # global  → ~/.codex (every project)
bash codex/install.sh --project .     # project → ./.agents/skills + ./AGENTS.md
# Windows:
powershell -ExecutionPolicy Bypass -File codex\install.ps1
```

> ⚠️ **Codex is single-agent** — no parallel spawning. Each specialist becomes a persona the one agent adopts *sequentially*. Full details in [`codex/README.md`](codex/README.md). Uninstall: `bash codex/install.sh --uninstall`.

### Two-tier architecture

The key design that avoids nested-spawning bottlenecks:

| Tier | Who | How it runs |
|------|-----|-------------|
| **Tier 1 — Core Roles** (`core/`) | 🎯 CEO · 🏗️ CTO · 📋 PM · 👥 HR · 📊 BA | **Not spawned.** The main agent *reads the role file and acts as it* |
| **Tier 2 — Specialists** (`agents/`) | 34 FAANG/SEO engineers | **Spawned** as subagents for parallel execution |

```
🎯 CEO — approve scope, delegate, client comms
🏗️ CTO — tech stack, architecture, File Blueprint, security
📋 PM  — init project, plan sprints, spawn specialists, track
👥 HR  — map requirements → the right specialists (dynamic hiring)
📊 BA  — requirements, SRS, Given/When/Then user stories
```

### Workflow — from idea to delivery

```
User: /work "Build an app"
   │
🎯 CEO   approve scope ──▶ delegate to PM
   │
📋 PM    init ──▶ BA requirements ──▶ CTO tech ──▶ HR builds team
   │
📋 PM    Sprint 0 checkpoints ──▶ user confirms
   │
📋 PM    plan ALL sprints ──▶ user approves roadmap (Gate 1)
   │
📋 PM    4-Batch flow per sprint:
         ├─ Batch 0 · QA writes BDD scenarios ──▶ user approves the CONTRACT
         ├─ Batch 1 · Dev runs the TDD loop ──▶ all tests GREEN
         ├─ Batch 2 · Code Review ──▶ LGTM
         └─ Batch 3 · QA regression + coverage ──▶ APPROVED
   │
🎯 CEO   final sign-off ──▶ delivery
```

**Why it's reliable:** BDD scenarios are a *verifiable contract* the user approves up front, and Dev self-corrects through the TDD loop — so "the AI said it's done but it doesn't run" largely disappears. A bug only escapes when a scenario was never written (mitigated by QA edge cases + user review).

### What's inside

- **🎓 99 skills** (loaded on demand): frontend craft (`ui-ux-pro-max`, `frontend-design`, `shadcn`, `tailwind-patterns`, `figma-implement-design`), backend (`node-backend`, `postgresql`, `redis-expert`, `graphql-architect`, `real-time-systems`, `prisma`), cloud/devops (`aws-expert`, `gcp-expert`, `kubernetes-expert`, `docker-expert`, `observability`), mobile (`ios-architecture`, `swift-expert`, `jetpack-compose`, `kotlin-expert`), security & QA (`security-audit`, `qa-testing`, `chaos-engineering`), plus **~25 SEO skills**.
- **🪝 Hooks (runtime enforcement):** conventional-commit gate, one-component-per-file + ESLint gate, sprint-format validation, schema validation, Git auto-checkpoint on milestones, and **skill lazy-loading** (specialists load only the skills the task needs — the context stays lean).
- **🔌 8 extensions** for real data: `ahrefs`, `dataforseo`, `firecrawl`, `bing-webmaster`, `seranking`, `unlighthouse`, `profound`, `banana`.
- **🧠 Agent memory & templates:** specialists accumulate experience across runs; `helpers/` holds BDD workflow, Clean Code/DRY/SOLID rules, and model-tier (haiku/sonnet/opus) selection.

### Project complexity tiers

| Tier | Team | Duration | Examples |
|------|------|----------|----------|
| Simple | 3–4 | 1–2 weeks | Portfolio, landing page, simple CRUD |
| Standard | 5–6 | 4–6 weeks | Web apps, mobile apps, SaaS tools |
| Complex | 6–8 | 2–4 months | Real-time platforms, streaming, games |
| Enterprise | 8–12 | 4–12 months | Banking, cloud platforms, large systems |

### Quick command reference

```bash
/work "..."       # start a new project (primary entry point)
/work continue    # resume the active project
/work status      # check project status
/company start    # open the management panel (dashboard + terminal)
/company stop     # close the panel
```

<div align="right"><a href="#-vfm-agent-company">↑ back to top</a></div>

---

## 🇻🇳 Tiếng Việt

### Đây là gì?

**VFM Agent Company** biến Claude Code thành một **công ty phần mềm hoàn chỉnh**. Thay vì chat với một AI đơn lẻ, bạn có cả một tổ chức: **ban điều hành** (CEO / CTO / PM / HR / BA), **17 chuyên gia FAANG** (Meta, Google, Apple, Amazon, Netflix, Microsoft) và một **sư đoàn SEO** riêng (18 sub-agent) — tất cả phối hợp theo quy trình **BDD/TDD** để sản phẩm giao ra *kiểm chứng được và chạy thật*.

| Tổng quan nhanh | |
|---|---|
| 🎯 **5 core role** | CEO, CTO, PM, HR, BA — ban lãnh đạo lên kế hoạch & giao việc |
| 👷 **34 specialist agent** | 17 kỹ sư FAANG + 18 sub-agent SEO, chạy song song |
| 🎓 **99 skill** | Kiến thức nạp theo nhu cầu (frontend, backend, cloud, mobile, bảo mật, SEO…) |
| 🪝 **Chất lượng do máy ép buộc** | Hook ép chuẩn commit, chuẩn code & tự checkpoint — không phụ thuộc "AI có nhớ hay không" |
| 🔌 **8 extension dữ liệu** | Ahrefs, DataForSEO, Firecrawl, Bing Webmaster, SE Ranking… |

### Cài đặt (plugin Claude Code)

Repo này là một **plugin marketplace** của Claude Code:

```bash
/plugin marketplace add duylinhdang1998/claude-template-agent
/plugin install vfm-agent-company@vfm-agent-marketplace
```

Sau đó bắt đầu làm việc:

```bash
/work "Xây dựng nền tảng thương mại điện tử tích hợp thanh toán Stripe"
```

Hoặc mở bảng điều khiển trực tiếp:

```bash
/company start   # panel real-time + terminal tích hợp ngay trên trình duyệt
/company stop    # đóng lại khi xong
```

### Cài đặt (OpenAI Codex CLI)

Công ty cũng chạy được trên **Codex CLI**. Một bộ generator (`codex/build.py`) chuyển nguồn Claude thành skill Codex + file `AGENTS.md` — `.claude/` vẫn là nguồn chân lý duy nhất.

```bash
# tại thư mục gốc của repo:
bash codex/install.sh                 # toàn cục → ~/.codex (mọi project)
bash codex/install.sh --project .     # theo project → ./.agents/skills + ./AGENTS.md
# Windows:
powershell -ExecutionPolicy Bypass -File codex\install.ps1
```

> ⚠️ **Codex là single-agent** — không spawn song song. Mỗi specialist trở thành một "persona" mà một agent duy nhất *lần lượt* nhập vai. Chi tiết đầy đủ ở [`codex/README.md`](codex/README.md). Gỡ cài đặt: `bash codex/install.sh --uninstall`.

### Kiến trúc 2 tầng

Đây là thiết kế cốt lõi để tránh nghẽn do "agent gọi agent gọi agent":

| Tầng | Ai | Cách vận hành |
|------|-----|---------------|
| **Tầng 1 — Core Roles** (`core/`) | 🎯 CEO · 🏗️ CTO · 📋 PM · 👥 HR · 📊 BA | **Không spawn.** Agent chính *đọc file vai trò rồi đóng vai* |
| **Tầng 2 — Specialists** (`agents/`) | 34 kỹ sư FAANG/SEO | **Được spawn** thành subagent để chạy song song |

```
🎯 CEO — duyệt scope, giao việc, giao tiếp khách hàng
🏗️ CTO — tech stack, kiến trúc, File Blueprint, bảo mật
📋 PM  — khởi tạo dự án, lập sprint, spawn specialist, theo dõi
👥 HR  — map yêu cầu → chọn đúng specialist (tuyển động)
📊 BA  — yêu cầu, SRS, user story dạng Given/When/Then
```

### Quy trình — từ ý tưởng đến bàn giao

```
User: /work "Xây một ứng dụng"
   │
🎯 CEO   duyệt scope ──▶ giao PM
   │
📋 PM    khởi tạo ──▶ BA lấy yêu cầu ──▶ CTO chốt tech ──▶ HR lập team
   │
📋 PM    Sprint 0 checkpoints ──▶ user xác nhận
   │
📋 PM    plan TOÀN BỘ sprint ──▶ user duyệt roadmap (Gate 1)
   │
📋 PM    Quy trình 4-Batch mỗi sprint:
         ├─ Batch 0 · QA viết BDD scenarios ──▶ user duyệt "HỢP ĐỒNG"
         ├─ Batch 1 · Dev chạy vòng lặp TDD ──▶ tất cả test XANH
         ├─ Batch 2 · Code Review ──▶ LGTM
         └─ Batch 3 · QA regression + coverage ──▶ APPROVED
   │
🎯 CEO   ký duyệt cuối ──▶ bàn giao
```

**Vì sao đáng tin:** BDD scenario là *hợp đồng kiểm chứng được* mà user duyệt ngay từ đầu, còn Dev tự sửa qua vòng lặp TDD — nên tình trạng "AI báo xong nhưng không chạy" gần như biến mất. Lỗi chỉ lọt khi một scenario chưa được viết (giảm thiểu bằng edge case của QA + user review).

### Bên trong có gì

- **🎓 99 skill** (nạp on-demand): frontend (`ui-ux-pro-max`, `frontend-design`, `shadcn`, `tailwind-patterns`, `figma-implement-design`), backend (`node-backend`, `postgresql`, `redis-expert`, `graphql-architect`, `real-time-systems`, `prisma`), cloud/devops (`aws-expert`, `gcp-expert`, `kubernetes-expert`, `docker-expert`, `observability`), mobile (`ios-architecture`, `swift-expert`, `jetpack-compose`, `kotlin-expert`), bảo mật & QA (`security-audit`, `qa-testing`, `chaos-engineering`), cùng **~25 skill SEO**.
- **🪝 Hooks (ép buộc lúc runtime):** chặn commit sai chuẩn, ép 1-component/file + ESLint gate, kiểm tra định dạng sprint, validate schema, tự Git checkpoint tại milestone, và **lazy-load skill** (specialist chỉ nạp skill mà task cần — giữ context gọn nhẹ).
- **🔌 8 extension** lấy dữ liệu thật: `ahrefs`, `dataforseo`, `firecrawl`, `bing-webmaster`, `seranking`, `unlighthouse`, `profound`, `banana`.
- **🧠 Bộ nhớ agent & template:** specialist tích lũy kinh nghiệm giữa các lần chạy; `helpers/` chứa quy trình BDD, quy tắc Clean Code/DRY/SOLID và cách chọn model-tier (haiku/sonnet/opus).

### Phân bậc độ phức tạp dự án

| Bậc | Team | Thời gian | Ví dụ |
|-----|------|-----------|-------|
| Simple | 3–4 | 1–2 tuần | Portfolio, landing page, CRUD đơn giản |
| Standard | 5–6 | 4–6 tuần | Web app, mobile app, công cụ SaaS |
| Complex | 6–8 | 2–4 tháng | Nền tảng real-time, streaming, game |
| Enterprise | 8–12 | 4–12 tháng | Ngân hàng, nền tảng cloud, hệ thống lớn |

### Tham chiếu lệnh nhanh

```bash
/work "..."       # bắt đầu dự án mới (cửa vào chính)
/work continue    # tiếp tục dự án đang chạy
/work status      # kiểm tra trạng thái dự án
/company start    # mở panel quản lý (dashboard + terminal)
/company stop     # đóng panel
```

<div align="right"><a href="#-vfm-agent-company">↑ về đầu trang</a></div>

---

## ⚙️ Technology / Công nghệ

- **Platform:** [Claude Code](https://github.com/anthropics/claude-code) (Anthropic) — also runs on OpenAI Codex CLI
- **Agent system:** Claude Code native Agent tool with specialized subagent types
- **Quality:** BDD (Given/When/Then) + TDD (Red → Green loop) + visual UI check
- **Testing:** Vitest (unit/integration) + Playwright (E2E + visual)
- **Automation:** Bash scripts for project management, gate validation, sprint tracking
- **Hooks:** runtime enforcement (sprint format, wireframe injection, git commits, skill lazy-load)

## 📄 License / Giấy phép

MIT © [Dang Duy Linh](https://github.com/duylinhdang1998) — see [`.claude-plugin/plugin.json`](.claude-plugin/plugin.json).

<div align="center">

**Built with Claude Code** — BDD-driven autonomous AI collaboration for reliable software.
*Xây dựng bằng Claude Code — cộng tác AI tự vận hành theo BDD cho phần mềm đáng tin cậy.*

</div>
