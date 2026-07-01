# Daily Iskra Partner Info Update Implementation Plan

> **For agentic workers:** REQUIRED: Use subagent-driven-development (if subagents are available) or inline execution with checkpoints to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a daily automation that refreshes `iskra-partner-info` from approved Iskra sources, creates local commits for safe Markdown updates, and reports discrepancies or sensitive blockers to the owner.

**Architecture:** Keep the Codex cron thin and move all durable procedure into a project-local skill. Add deterministic helper scripts for live landing collection and public-content safety checks, while leaving judgment-heavy source reconciliation to the agent following the skill. Create the automation through the Codex app automation tool rather than writing automation files directly.

**Tech Stack:** Markdown, Codex project skills, Bash, Python standard library, pinned `npx markdownlint-cli2@0.23.0`, pinned `npx markdown-link-check@3.14.2`, `rg`, Git, Codex app automation tool, `publishbotzvasil`, `telegram-read`.

## Global Constraints

- Automation id: `daily-iskra-partner-info-update`.
- Automation name: `daily iskra partner info update`.
- Schedule: daily at 05:00 local time.
- Working directory: root of `iskra-partner-info`.
- Do not push to GitHub.
- Do not create PRs.
- Do not edit CRM, platform, marketing or Telegram source systems.
- Do not publish partner compensation, referral percentages, agency fees, payouts, promo-code economics, individual partner terms, CRM clients, deals, contacts, raw Telegram messages, bank details, credentials, tokens, SSH or infrastructure secrets.
- Use `Искра` for the company and main product; use `2030ai`, not `2030AI`.
- Public partner information stays Markdown-only.
- The automation may create a local commit only after checks and owner/partner-reader self-review pass.
- Use `$HOME`, relative paths or repo-relative paths in committed files; do not commit machine-specific absolute paths.

---

## File Structure

- `.agents/skills/iskra-partner-info-update/SKILL.md` — the source of truth for the recurring update workflow: sources, safety rules, source priority, run flow, commit/report contract.
- `.agents/skills/iskra-partner-info-update/scripts/collect_live_landings.sh` — canonical collector that fetches approved live landing URLs and writes a Markdown observation report under `temp/iskra-partner-info-update/`.
- `.agents/skills/iskra-partner-info-update/scripts/collect_live_landings.py` — compatibility wrapper that delegates to the shell collector.
- `.agents/skills/iskra-partner-info-update/scripts/check_public_safety.sh` — deterministic public-content verification: markdown lint, link check, hard forbidden text scan, risky wording warnings and `git diff --check`.
- `agent_docs/development-history/2026-06-30-0500-daily-iskra-partner-info-update.md` — records that the repo gained a daily update automation workflow.
- `agent_docs/development-history/README.md` — inspect only; do not edit when its local rules require timestamped filenames without a manual index entry.
- Codex automation config — created through `automation_update`; do not write automation TOML by hand.
- Ecosystem inbox entry — append a one-line agent ecosystem change after the skill and automation are created.

---

### Task 1: Project-Local Skill

**Files:**
- Create: `.agents/skills/iskra-partner-info-update/SKILL.md`
- Test: `npx --yes markdownlint-cli2@0.23.0 .agents/skills/iskra-partner-info-update/SKILL.md`

**Interfaces:**
- Consumes: design spec `agent_docs/plans/2026-06-30-daily-iskra-partner-info-update-design.md`.
- Produces: project-local skill `iskra-partner-info-update` that the cron automation can run in `mode=automation unattended=true`.

- [ ] **Step 1: Create the skill directory**

Run:

```bash
mkdir -p .agents/skills/iskra-partner-info-update/scripts
```

Expected: directory exists.

- [ ] **Step 2: Add the skill body**

Apply this patch:

```diff
*** Begin Patch
*** Add File: .agents/skills/iskra-partner-info-update/SKILL.md
+---
+name: iskra-partner-info-update
+description: "/iskra-partner-info-update — Refresh the public Iskra partner information repository from approved sources, report discrepancies, block sensitive leaks, and create local commits for safe Markdown changes."
+---
+
+# /iskra-partner-info-update
+
+## Contract
+
+Refresh `2030ai/iskra-partner-info` as the public partner-safe Markdown base for Iskra.
+
+The skill maintains a curated public layer. It does not mirror CRM, platform, marketing, the live site, or Telegram. It updates public Markdown only when claims are supported by approved sources and pass safety review.
+
+Run modes:
+
+- `mode=automation unattended=true` — daily scheduled run. May create a local commit after checks pass. May send a Telegram owner report through `publishbotzvasil` when there are changes, discrepancies, blockers or source failures. Must not push.
+- `mode=dry-run` — collect sources, classify findings and report proposed changes. Do not edit files and do not commit.
+- `mode=manual` — same procedure as automation, but include more detail in the final Codex response.
+
+Always read `AGENTS.md`, `CLAUDE.md`, `agent_docs/index.md`, `docs/legal/claims-and-limitations.md`, and this skill before source collection.
+
+## Source Map
+
+### CRM Source Of Truth
+
+Use these commercial and legal sources:
+
+- `$HOME/Developer/2030ai-CRM/01_методология продаж/КП Искра/КП_Искра.md`
+- `$HOME/Developer/2030ai-CRM/01_методология продаж/Коммерческая модель Искры 2026.06.md`
+- `$HOME/Developer/2030ai-CRM/01_методология продаж/КП Искра/Искра_FAQ_коммерческая_модель_и_on-premise_2026.06.09.md`
+- `$HOME/Developer/2030ai-CRM/01_методология продаж/Искра_юридический/Искра_договор/iskra-contract-checklist.md`
+- `$HOME/Developer/2030ai-CRM/01_методология продаж/Искра_юридический/Искра_договор/iskra-license-agreement-final.md`
+
+Do not read broad CRM client folders for this automation unless the user explicitly asks in the current run.
+
+### Platform Source Of Truth
+
+Use these product and technical sources:
+
+- `$HOME/Developer/2030ai-platform/strategy/01_vision.md`
+- `$HOME/Developer/2030ai-platform/strategy/02_product.md`
+- `$HOME/Developer/2030ai-platform/shared/helpdocs/docs/user/`
+- `$HOME/Developer/2030ai-platform/shared/helpdocs/docs/tech/`
+- `$HOME/Developer/2030ai-platform/docs/44fz/platform-description.md`
+- `$HOME/Developer/2030ai-platform/services/billing/init_plans.yaml`
+
+When a changed capability needs confirmation, inspect relevant platform docs or code with `rg` before changing public claims.
+
+### Marketing And Live Site Sources
+
+Use local marketing sources:
+
+- `$HOME/Developer/2030ai-iskra-marketing/iskra-marketing/creatives/`
+- `$HOME/Developer/2030ai-iskra-marketing/iskra-marketing/creatives/DEPLOY.md`
+- `$HOME/Developer/2030ai-iskra-marketing/iskra-marketing/creatives/landings-spec.md`
+- `$HOME/Developer/2030ai-iskra-marketing/iskra-marketing/strategy/`
+- `$HOME/Developer/2030ai-iskra-marketing/iskra-marketing/product/`
+
+Use live public sources:
+
+- `https://iskrabot.ru/sitemap.xml`
+- `https://iskrabot.ru/`
+- `https://iskrabot.ru/dlya-biznesa/`
+- `https://iskrabot.ru/enterprise/`
+- `https://iskrabot.ru/baza-znaniy/`
+- `https://iskrabot.ru/partner/`
+- `https://cloud.iskrabot.ru/lp/b2b`
+- `https://cloud.iskrabot.ru/lp/demo`
+- `https://cloud.iskrabot.ru/lp/tryiskra`
+- `https://cloud.iskrabot.ru/lp/health`
+- `https://platform.iskrabot.ru/`
+
+Live pages are evidence of published claims. They are not automatically safe wording for this repo.
+
+### Telegram Source
+
+Read-only chat title: `Искра: партнёрская`.
+
+Use Telegram only for field signals:
+
+- repeated partner questions;
+- unclear wording;
+- objections;
+- requests for materials;
+- inconsistencies between what partners ask and what public docs explain.
+
+Never publish names, deals, clients, contacts, raw quotes, chat ids, message ids, percentages, rewards, promo-code economics or private arrangements from Telegram.
+
+If telegram-read read tools are not available, use `tool_search` to expose them. If only draft/write operations are available, do not use them and record Telegram as unavailable for this run.
+
+## Source Priority
+
+- Commercial prices, packages and paid terms: CRM commercial model and КП win over site copy and helpdocs.
+- Product capabilities: platform docs/code win over sales drafts and landing copy.
+- Deployment, LLM, data contour and technical claims: platform tech docs/code and legal docs win over landing copy.
+- Legal/compliance claims: contract checklist and final license text win over every marketing source.
+- Telegram `Искра: партнёрская` is evidence of confusion, demand or discrepancy, not a source for public facts.
+
+## Run Flow
+
+1. Read project instructions, legal page, design spec and automation memory.
+2. Check `git status --short`. If the repo is dirty before the run, do not edit. Send a blocker report when notifications are available.
+3. Verify expected source paths exist. Missing sources block only the claims that depend on them.
+4. Run `python3 .agents/skills/iskra-partner-info-update/scripts/collect_live_landings.py`.
+5. Inspect changed source files since the previous run:
+   - use local Git logs/status in CRM, platform, marketing and partner-info repos;
+   - read live landing report from `temp/iskra-partner-info-update/live-landings.md`;
+   - read Telegram signals from `Искра: партнёрская` when read tools are available.
+6. Classify every finding as one of:
+   - safe update;
+   - discrepancy;
+   - sensitive blocker;
+   - no-op.
+7. In `mode=dry-run`, stop before edits and report proposed safe updates, discrepancies and blockers.
+8. For safe updates in automation/manual mode, edit only `README.md`, `CHANGELOG.md` and files under `docs/`.
+9. Do not silently resolve discrepancies. Add them to the owner report.
+10. Run `.agents/skills/iskra-partner-info-update/scripts/check_public_safety.sh`.
+11. Self-review with both lenses:
+    - owner of Iskra;
+    - partner/client reader who may feed this repo to agents.
+12. If checks and self-review pass, create a local commit with message `docs: refresh iskra partner info`.
+13. Send an owner report through `publishbotzvasil` only when there are public changes, discrepancies, blockers or source failures.
+14. Update automation memory with sources checked, commit hash, discrepancies, blockers, notification status and current run time.
+
+## Classification
+
+Safe update:
+
+- public and useful for partners or clients;
+- supported by an approved source;
+- compatible with `docs/legal/claims-and-limitations.md`;
+- improves capabilities, deployment options, pricing, partner process, positioning or limitations.
+
+Discrepancy:
+
+- live landing says more than the safe public repo can say;
+- site copy, CRM, platform and partner-info disagree on status, price, capability, data contour, LLM, registry, 152-ФЗ, on-premise or partner process;
+- Telegram reveals repeated confusion not covered by public docs;
+- local creative source differs materially from live landing.
+
+Sensitive blocker:
+
+- partner compensation, referral percentages, agency fees, payouts, promo-code economics or individual partner terms;
+- CRM clients, deals, contacts, private names, emails, phone numbers, chat ids, raw messages or meeting notes;
+- bank details, tokens, passwords, SSH, demo credentials, API keys, infrastructure secrets or internal endpoints;
+- raw Telegram quotes or identifiable partner/customer context;
+- unconfirmed claims about registry, FSTEK, full 152-ФЗ compliance, fully local processing, no external LLM/gateway, data never leaving a perimeter, or data never transferred to third parties.
+
+No-op:
+
+- source changes are irrelevant to partner/client understanding;
+- source changes are internal implementation details with no public sales or deployment meaning;
+- only sensitive material changed and cannot be summarized safely.
+
+## Public Wording Rules
+
+Hard forbidden unless the legal page and source policy are updated first:
+
+- `2030AI` as company/product spelling;
+- claiming the company is `2030ai`;
+- `данные никогда не передаются`;
+- `данные не передаются третьим лицам`;
+- `данные не покидают периметр`;
+- `полностью соответствует 152-ФЗ`;
+- `сертифицировано ФСТЭК`;
+- `включено в реестр российского ПО` without registry number and verifiable source;
+- `без внешних LLM` or `полностью локально` without the exact approved deployment contour.
+
+Use safer wording:
+
+- contours are configurable and contract-specific;
+- cloud, Russian contour, on-premise, local models, gateway, GPU, infrastructure, SLA and data processing conditions are fixed in the agreement, specification or technical description.
+
+## Telegram Report Contract
+
+Use `publishbotzvasil` with default owner chat unless the current user request says otherwise. Format as Telegram HTML and escape `<`, `>` and `&` outside tags.
+
+When a commit is created, include:
+
+- title: `daily iskra partner info update`;
+- local commit hash;
+- changed files;
+- sources checked;
+- verification status;
+- discrepancy count;
+- sensitive blockers, if any;
+- recommended owner review items.
+
+When only discrepancies or blockers exist:
+
+- no commit;
+- sanitized discrepancy/blocker list;
+- source names;
+- recommended next action.
+
+For no-op runs:
+
+- no Telegram message by default;
+- compact Codex final output with sources checked.
+
+## Verification
+
+Run:
+
+```bash
+.agents/skills/iskra-partner-info-update/scripts/check_public_safety.sh
+```
+
+The script must pass before any local commit.
+
+## Commit Rules
+
+Commit only public Markdown updates and related `CHANGELOG.md` updates.
+
+Allowed generated temp files stay under `temp/iskra-partner-info-update/` and are not committed.
+
+Use:
+
+```bash
+git add README.md CHANGELOG.md docs
+git commit -m "docs: refresh iskra partner info"
+```
+
+If only skill/docs/automation implementation files changed during setup, use a setup commit message such as:
+
+```bash
+git commit -m "chore: add iskra partner info update automation"
+```
*** End Patch
```

- [ ] **Step 3: Lint the skill**

Run:

```bash
npx --yes markdownlint-cli2@0.23.0 .agents/skills/iskra-partner-info-update/SKILL.md
```

Expected: `Summary: 0 error(s)`.

- [ ] **Step 4: Commit Task 1**

Run:

```bash
git add .agents/skills/iskra-partner-info-update/SKILL.md
git commit -m "chore: add iskra partner info update skill"
```

Expected: commit succeeds.

---

### Task 2: Deterministic Helper Scripts

**Files:**
- Create: `.agents/skills/iskra-partner-info-update/scripts/collect_live_landings.sh`
- Create: `.agents/skills/iskra-partner-info-update/scripts/collect_live_landings.py`
- Create: `.agents/skills/iskra-partner-info-update/scripts/check_public_safety.sh`
- Test: run both scripts from repo root.

**Interfaces:**
- Consumes: source URLs and safety rules from Task 1.
- Produces:
  - executable `collect_live_landings.sh` with default output `temp/iskra-partner-info-update/live-landings.md`;
  - thin executable `collect_live_landings.py` wrapper that resolves `bash` through `PATH` and delegates to the shell collector;
  - executable `check_public_safety.sh` that returns non-zero on hard safety or Markdown verification failures.

- [ ] **Step 1: Add the live landing collector**

Create `.agents/skills/iskra-partner-info-update/scripts/collect_live_landings.sh` as the canonical collector and `.agents/skills/iskra-partner-info-update/scripts/collect_live_landings.py` as a compatibility wrapper.

The shell collector must:

- accept `--output` and `--timeout`;
- read live URLs from the skill when possible and otherwise use the built-in URL list;
- always include built-in legal/risk patterns before adding skill-derived patterns;
- include partner-economics regex checks;
- fetch pages with `curl`;
- decode HTML entities with Python stdlib `html.unescape`, not non-core Perl modules;
- scan the full normalized response body for risky claims, truncating only human-readable output if needed;
- write the Markdown report to `temp/iskra-partner-info-update/live-landings.md` by default.

The Python wrapper must:

- locate `collect_live_landings.sh` relative to itself;
- call `os.execvp("bash", ["bash", shell_script, *sys.argv[1:]])` so `bash` is resolved through `PATH`.

- [ ] **Step 2: Add the safety check script**

Create `.agents/skills/iskra-partner-info-update/scripts/check_public_safety.sh` with these constraints:

- build `PUBLIC_MD_FILES` from `README.md`, `CHANGELOG.md`, `LICENSE.md` and `docs/**/*.md`;
- use pinned `markdownlint-cli2@0.23.0` and `markdown-link-check@3.14.2`, with environment-variable overrides for planned upgrades;
- run blocking metadata, secret-like, hard risky-wording and partner-economics scans only over public Markdown files;
- include both `е` and `ё` variants for Russian bank-account wording such as `расч[её]тный сч[её]т` and `корреспондентский сч[её]т`;
- keep `agent_docs` scans informational/non-blocking unless the local policy explicitly says otherwise;
- run a legal warning scan and `git diff --check`;
- exit non-zero when any blocking check fails.

- [ ] **Step 3: Make scripts executable**

Run:

```bash
chmod +x .agents/skills/iskra-partner-info-update/scripts/collect_live_landings.py
chmod +x .agents/skills/iskra-partner-info-update/scripts/collect_live_landings.sh
chmod +x .agents/skills/iskra-partner-info-update/scripts/check_public_safety.sh
```

Expected: all scripts have executable bits.

- [ ] **Step 4: Run the live landing collector**

Run:

```bash
python3 .agents/skills/iskra-partner-info-update/scripts/collect_live_landings.py
sed -n '1,80p' temp/iskra-partner-info-update/live-landings.md
```

Expected:

- first command prints `temp/iskra-partner-info-update/live-landings.md`;
- report includes `https://iskrabot.ru/`, `https://iskrabot.ru/dlya-biznesa/`, `https://iskrabot.ru/enterprise/` and `https://platform.iskrabot.ru/`.

- [ ] **Step 5: Run the safety script**

Run:

```bash
.agents/skills/iskra-partner-info-update/scripts/check_public_safety.sh
```

Expected:

- either `public safety check passed`, or a concrete scan finding that must be fixed before continuing;
- no committed temp files.

- [ ] **Step 6: Lint new skill files**

Run:

```bash
npx --yes markdownlint-cli2@0.23.0 .agents/skills/iskra-partner-info-update/SKILL.md
git diff --check
```

Expected: markdownlint has `0 error(s)` and `git diff --check` has no output.

- [ ] **Step 7: Commit Task 2**

Run:

```bash
git add .agents/skills/iskra-partner-info-update/scripts
git commit -m "chore: add iskra partner info update checks"
```

Expected: commit succeeds. `temp/iskra-partner-info-update/live-landings.md` remains untracked or ignored by existing `temp/` ignore rule.

---

### Task 3: Agent Documentation And History

**Files:**
- Modify: `agent_docs/index.md`
- Create: `agent_docs/development-history/2026-06-30-0500-daily-iskra-partner-info-update.md`
- Inspect only: `agent_docs/development-history/README.md`
- Test: markdownlint on changed docs.

**Interfaces:**
- Consumes: skill and scripts from Tasks 1-2.
- Produces: discoverable internal docs for future agent sessions.

- [ ] **Step 1: Update the agent docs index**

Apply this patch:

```diff
*** Begin Patch
*** Update File: agent_docs/index.md
@@
 - `agent_docs/plans/` — design and implementation plans for agent-maintained workflows.
+- `.agents/skills/iskra-partner-info-update/SKILL.md` — daily automation procedure for refreshing partner-safe Iskra public information.
 - `agent_docs/development-history/README.md` — development history index.
*** End Patch
```

- [ ] **Step 2: Add development history entry**

Apply this patch:

```diff
*** Begin Patch
*** Add File: agent_docs/development-history/2026-06-30-0500-daily-iskra-partner-info-update.md
+# Daily Iskra Partner Info Update Automation
+
+Date: 2026-06-30
+
+## Summary
+
+Added the design and implementation path for a daily Codex automation that keeps `iskra-partner-info` current from approved Iskra sources.
+
+The workflow is intentionally conservative:
+
+- project-local skill owns the procedure;
+- live landings are treated as published-claim observations, not as source-of-truth wording;
+- Telegram chat `Искра: партнёрская` is used only for sanitized field signals;
+- sensitive partner, client, credential, banking and legal-risk material is blocked;
+- successful safe updates create local commits only and do not push.
+
+## Files
+
+- `agent_docs/plans/2026-06-30-daily-iskra-partner-info-update-design.md`
+- `agent_docs/plans/2026-06-30-daily-iskra-partner-info-update-implementation-plan.md`
+- `.agents/skills/iskra-partner-info-update/SKILL.md`
+- `.agents/skills/iskra-partner-info-update/scripts/collect_live_landings.py`
+- `.agents/skills/iskra-partner-info-update/scripts/check_public_safety.sh`
*** End Patch
```

- [ ] **Step 3: Check the history index rules**

First inspect the file:

```bash
sed -n '1,180p' agent_docs/development-history/README.md
```

If the file requires manual index entries, add one using the existing format. If it only defines filename rules, do not edit it.

This repository uses timestamped development-history filenames, so the entry file is `2026-06-30-0500-daily-iskra-partner-info-update.md` and `agent_docs/development-history/README.md` is left unchanged.

- [ ] **Step 4: Lint docs**

Run:

```bash
npx --yes markdownlint-cli2@0.23.0 agent_docs/index.md agent_docs/development-history/2026-06-30-0500-daily-iskra-partner-info-update.md
git diff --check
```

Expected: markdownlint has `0 error(s)` and `git diff --check` has no output.

- [ ] **Step 5: Commit Task 3**

Run:

```bash
git add agent_docs/index.md agent_docs/development-history/2026-06-30-0500-daily-iskra-partner-info-update.md
git commit -m "docs: document iskra partner info automation"
```

Expected: commit succeeds.

---

### Task 4: Automation Creation And End-To-End Dry Run

**Files:**
- No repository files are created by the Codex automation tool.
- External local state: Codex automation registry and ecosystem inbox.

**Interfaces:**
- Consumes: project-local skill from Task 1, scripts from Task 2, docs from Task 3.
- Produces: active daily Codex automation named `daily iskra partner info update`.

- [ ] **Step 1: Check for duplicate automation**

Run:

```bash
find "$HOME/.codex/automations" -maxdepth 2 -name automation.toml -print 2>/dev/null | sort | xargs rg -n "daily-iskra-partner-info-update|daily iskra partner info update" || true
```

Expected: no existing automation with the same id/name. If one exists, update it instead of creating a duplicate.

- [ ] **Step 2: Create the automation through Codex app tooling**

Use the Codex app `automation_update` tool. Do not edit automation files manually.

Create a cron automation with these fields:

- `id`: `daily-iskra-partner-info-update`
- `kind`: `cron`
- `name`: `daily iskra partner info update`
- `status`: `ACTIVE`
- `executionEnvironment`: `local`
- `destination`: `local`
- `cwds`: `$HOME/Developer/iskra-partner-info`
- `model`: `gpt-5.5`
- `reasoningEffort`: `medium`
- schedule: daily at 05:00 local time
- `prompt`:

```text
[$automation-output-style]($HOME/Developer/zvasil-claude-ecosystem/automation-output-style/SKILL.md)
[$publishbotzvasil]($HOME/Developer/zvasil-claude-ecosystem/publishbot/SKILL.md)

mode=automation

Use the project instructions from AGENTS.md / CLAUDE.md first.

Run the project-local skill at `.agents/skills/iskra-partner-info-update/SKILL.md` with `mode=automation unattended=true`.

Treat that skill as the only procedure for source selection, partner-safe updates, discrepancy handling, sensitive-content blocking, local commit creation, Telegram owner reporting, automation memory and final output.

Do not push to GitHub. Do not create PRs. Do not send messages to partner/customer chats.
```

When calling `automation_update`, pass the schedule through the tool schema rather than writing a local automation file.

- [ ] **Step 3: Verify the automation exists**

Use `automation_update` view mode for id `daily-iskra-partner-info-update`.

Expected:

- status is active;
- working directory is `$HOME/Developer/iskra-partner-info`;
- schedule is daily at 05:00 local time;
- prompt delegates to `.agents/skills/iskra-partner-info-update/SKILL.md`;
- prompt says not to push, create PRs or message partner/customer chats.

- [ ] **Step 4: Run manual dry run in the current session**

Manually execute the skill in dry-run mode:

```text
Run `.agents/skills/iskra-partner-info-update/SKILL.md` with `mode=dry-run`.
```

Expected:

- live landing collector runs;
- source availability is reported;
- no public files are edited;
- no commit is created;
- no Telegram message is sent unless a source failure is important enough to report and the user explicitly asks for a notification during the dry run.

- [ ] **Step 5: Record ecosystem inbox item**

Apply this one-line change outside this repo after the automation is created:

```text
- 2026-06-30 | iskra-partner-info | skill/config | added daily-iskra-partner-info-update skill and Codex automation for partner-safe Iskra public info refresh
```

Target file:

```bash
$HOME/Developer/zvasil-claude-ecosystem/inbox/changes.md
```

Use the existing date order in that file.

- [ ] **Step 6: Final verification**

Run:

```bash
git status --short
git log --oneline --decorate --max-count=8
find "$HOME/.codex/automations" -maxdepth 2 -name automation.toml -print 2>/dev/null | sort | xargs rg -n "daily-iskra-partner-info-update|daily iskra partner info update"
```

Expected:

- repo status is clean except allowed local-only files;
- recent commits include Task 1-3 commits;
- automation registry contains exactly one matching automation.

---

## Self-Review Checklist For Implementer

- Every source in the design spec appears in the skill or helper script.
- Telegram `Искра: партнёрская` is read-only and used only for sanitized signals.
- Live landings are treated as observation/discrepancy inputs, not source-of-truth wording.
- The helper safety script blocks hard forbidden claims and secret-like material.
- The cron prompt delegates to the skill instead of duplicating procedure.
- The automation creates local commits only and never pushes.
- No committed file contains machine-specific absolute paths.
- No committed file exposes partner compensation, raw Telegram content, clients, deals, credentials or bank details.
