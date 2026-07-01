---
name: iskra-partner-info-update
description: "/iskra-partner-info-update — Refresh the public Iskra partner information repository from approved sources, report discrepancies, block sensitive leaks, and create local commits for safe Markdown changes."
---

# /iskra-partner-info-update

## Contract

Refresh `2030ai/iskra-partner-info` as the public partner-safe Markdown base for Iskra.

The skill maintains a curated public layer. It does not mirror CRM, platform, marketing, the live site, or Telegram. It updates public Markdown only when claims are supported by approved sources and pass safety review.

Run modes:

- `mode=automation unattended=true` — daily scheduled run. May create a local commit after checks pass. May send a Telegram owner report through `publishbotzvasil` when there are changes, discrepancies, blockers or source failures. Must not push.
- `mode=dry-run` — collect sources, classify findings and report proposed changes. Do not edit files and do not commit.
- `mode=manual` — same procedure as automation, but include more detail in the final Codex response.

Always read `AGENTS.md`, `CLAUDE.md`, `agent_docs/index.md`, `docs/legal/claims-and-limitations.md`, and this skill before source collection.

## Source Map

### CRM Source Of Truth

Use these commercial and legal sources:

- `$HOME/Developer/2030ai-CRM/01_методология продаж/КП Искра/КП_Искра.md`
- `$HOME/Developer/2030ai-CRM/01_методология продаж/Коммерческая модель Искры 2026.06.md`
- `$HOME/Developer/2030ai-CRM/01_методология продаж/КП Искра/Искра_FAQ_коммерческая_модель_и_on-premise_2026.06.09.md`
- `$HOME/Developer/2030ai-CRM/01_методология продаж/Искра_юридический/Искра_договор/iskra-contract-checklist.md`
- `$HOME/Developer/2030ai-CRM/01_методология продаж/Искра_юридический/Искра_договор/iskra-license-agreement-final.md`

Do not read broad CRM client folders for this automation unless the user explicitly asks in the current run.

### CRM Sales Deck Source

Use the Iskra product deck as a positioning and use-case signal:

- `$HOME/Developer/2030ai-CRM/01_методология продаж/презентации/iskra/iskra_deck_texts.md`
- `$HOME/Developer/2030ai-CRM/01_методология продаж/презентации/iskra/slides.md`

The deck can support public updates about positioning, buyer pains, examples, pilot flow, adoption metrics, skills, integrations and commercial explanation. It is not a source of truth for legal, registry, compliance, client names, partner economics, data-locality guarantees, or exact deployment promises.

### Platform Source Of Truth

Use these product and technical sources:

- `$HOME/Developer/2030ai-platform/strategy/01_vision.md`
- `$HOME/Developer/2030ai-platform/strategy/02_product.md`
- `$HOME/Developer/2030ai-platform/shared/helpdocs/docs/user/`
- `$HOME/Developer/2030ai-platform/shared/helpdocs/docs/tech/`
- `$HOME/Developer/2030ai-platform/docs/44fz/platform-description.md`
- `$HOME/Developer/2030ai-platform/services/billing/init_plans.yaml`

When a changed capability needs confirmation, inspect relevant platform docs or code with `rg` before changing public claims.

### Marketing And Live Site Sources

Use local marketing sources:

- `$HOME/Developer/2030ai-iskra-marketing/iskra-marketing/creatives/`
- `$HOME/Developer/2030ai-iskra-marketing/iskra-marketing/creatives/DEPLOY.md`
- `$HOME/Developer/2030ai-iskra-marketing/iskra-marketing/creatives/landings-spec.md`
- `$HOME/Developer/2030ai-iskra-marketing/iskra-marketing/strategy/`
- `$HOME/Developer/2030ai-iskra-marketing/iskra-marketing/product/`

Use live public sources:

- `https://iskrabot.ru/sitemap.xml`
- `https://iskrabot.ru/`
- `https://iskrabot.ru/dlya-biznesa/`
- `https://iskrabot.ru/enterprise/`
- `https://iskrabot.ru/baza-znaniy/`
- `https://iskrabot.ru/partner/`
- `https://cloud.iskrabot.ru/lp/b2b`
- `https://cloud.iskrabot.ru/lp/demo`
- `https://cloud.iskrabot.ru/lp/tryiskra`
- `https://cloud.iskrabot.ru/lp/health`
- `https://platform.iskrabot.ru/`

Live pages are evidence of published claims. They are not automatically safe wording for this repo.

### Telegram Source

Read-only chat title: `Искра: партнёрская`.

Use Telegram only for field signals:

- repeated partner questions;
- unclear wording;
- objections;
- requests for materials;
- inconsistencies between what partners ask and what public docs explain.

Never publish names, deals, clients, contacts, raw quotes, chat ids, message ids, percentages, rewards, promo-code economics or private arrangements from Telegram.

If telegram-read read tools are not available, use `tool_search` to expose them. If only draft/write operations are available, do not use them and record Telegram as unavailable for this run.

## Source Priority

- Commercial prices, packages and paid terms: CRM commercial model and КП win over site copy and helpdocs.
- Sales deck wording informs positioning and partner-facing examples only; CRM commercial/legal sources and platform sources win for prices, legal, deployment and data claims.
- Product capabilities: platform docs/code win over sales drafts and landing copy.
- Deployment, LLM, data contour and technical claims: platform tech docs/code and legal docs win over landing copy.
- Legal/compliance claims: contract checklist and final license text win over every marketing source.
- Telegram `Искра: партнёрская` is evidence of confusion, demand or discrepancy, not a source for public facts.

## Run Flow

1. Read project instructions, legal page, design spec and automation memory.
2. Check `git status --short`. If the repo is dirty before the run, do not edit. Send a blocker report when notifications are available.
3. Verify expected source paths exist. Missing sources block only the claims that depend on them.
4. Run `python3 .agents/skills/iskra-partner-info-update/scripts/collect_live_landings.py`.
   - The collector requires `python3`, `bash` and `curl`. A basic `perl` interpreter is used only to parse optional URLs/patterns from this skill; when unavailable, the collector falls back to its built-in URL and risk-term lists.
5. Inspect changed source files since the previous run:
   - use local Git logs/status in CRM, platform, marketing and partner-info repos;
   - read live landing report from `temp/iskra-partner-info-update/live-landings.md`;
   - read Telegram signals from `Искра: партнёрская` when read tools are available.
6. Classify every finding as one of:
   - safe update;
   - discrepancy;
   - sensitive blocker;
   - no-op.
7. In `mode=dry-run`, stop before edits and report proposed safe updates, discrepancies and blockers.
8. For safe updates in automation/manual mode, edit only `README.md`, `CHANGELOG.md` and files under `docs/`.
9. Do not silently resolve discrepancies. Add them to the owner report.
10. Run `.agents/skills/iskra-partner-info-update/scripts/check_public_safety.sh`.
11. Self-review with both lenses:
    - owner of Iskra;
    - partner/client reader who may feed this repo to agents.
12. If checks and self-review pass, create a local commit with message `docs: refresh iskra partner info`.
13. Send an owner report through `publishbotzvasil` only when there are public changes, discrepancies, blockers or source failures.
14. Print the run report in the Codex thread too, in Russian, even when a Telegram owner report was sent.
15. Update automation memory with sources checked, commit hash, discrepancies, blockers, notification status and current run time.

## Classification

Safe update:

- public and useful for partners or clients;
- supported by an approved source;
- compatible with `docs/legal/claims-and-limitations.md`;
- improves capabilities, deployment options, pricing, partner process, positioning or limitations.

Discrepancy:

- live landing says more than the safe public repo can say;
- site copy, CRM, platform and partner-info disagree on status, price, capability, data contour, LLM, registry, 152-ФЗ, on-premise or partner process;
- Telegram reveals repeated confusion not covered by public docs;
- local creative source differs materially from live landing.

Sensitive blocker:

- partner compensation, referral percentages, agency fees, payouts, promo-code economics or individual partner terms;
- CRM clients, deals, contacts, private names, emails, phone numbers, chat ids, raw messages or meeting notes;
- bank details, tokens, passwords, SSH, demo credentials, API keys, infrastructure secrets or internal endpoints;
- raw Telegram quotes or identifiable partner/customer context;
- unconfirmed claims about registry, FSTEK, full 152-ФЗ compliance, fully local processing, no external LLM/gateway, data never leaving a perimeter, or data never transferred to third parties.

No-op:

- source changes are irrelevant to partner/client understanding;
- source changes are internal implementation details with no public sales or deployment meaning;
- only sensitive material changed and cannot be summarized safely.

## Public Wording Rules

Hard forbidden unless the legal page and source policy are updated first:

- `2030AI` as company/product spelling;
- claiming the company is `2030ai`;
- `данные никогда не передаются`;
- `данные не передаются третьим лицам`;
- `данные не покидают периметр`;
- `полностью соответствует 152-ФЗ`;
- `сертифицировано ФСТЭК`;
- `включено в реестр российского ПО` without registry number and verifiable source;
- `без внешних LLM` or `полностью локально` without the exact approved deployment contour.

Use safer wording:

- contours are configurable and contract-specific;
- cloud, Russian contour, on-premise, local models, gateway, GPU, infrastructure, SLA and data processing conditions are fixed in the agreement, specification or technical description.

## Telegram Report Contract

Use `publishbotzvasil` with default owner chat unless the current user request says otherwise. Format as Telegram HTML and escape `<`, `>` and `&` outside tags.

Write Telegram owner reports in Russian. Keep only technical identifiers in their original form: commit hashes, file paths, command names, URLs, message ids, package names and exact source names. Do not use English report labels such as `Status`, `Changed files`, `Verification`, `Next`, `blocked`, `safe updates`, `source issue` or `owner review`; use concise Russian labels instead.

When a commit is created, include:

- title: `обновление iskra partner info`;
- локальный commit hash;
- изменённые файлы;
- проверенные источники;
- статус проверок;
- число расхождений;
- чувствительные блокеры, если есть;
- что владельцу стоит проверить.

When only discrepancies or blockers exist:

- коммита нет;
- обезличенный список расхождений или блокеров;
- названия источников;
- рекомендуемое следующее действие.

For no-op runs:

- no Telegram message by default;
- compact Codex final output with sources checked.

## Codex Thread Report Contract

Always write the final Codex response in Russian.

When a Telegram owner report is sent, duplicate the useful owner-facing report in the Codex thread too. Do not answer only with the Telegram message id. Include:

- статус запуска;
- локальный commit hash, если commit создан;
- изменённые файлы;
- статус проверок;
- число расхождений и обезличенное описание расхождений;
- чувствительные блокеры, если есть;
- статус Telegram-уведомления и message id, если доступны;
- что владельцу стоит проверить.

For no-op runs:

- no Telegram message by default;
- compact Russian Codex final output with sources checked and no-op status.

## Verification

Run:

```bash
.agents/skills/iskra-partner-info-update/scripts/check_public_safety.sh
```

The script must pass before any local commit.

## Commit Rules

Commit only public Markdown updates and related `CHANGELOG.md` updates.

Allowed generated temp files stay under `temp/iskra-partner-info-update/` and are not committed.

Use:

```bash
git add README.md CHANGELOG.md docs
git commit -m "docs: refresh iskra partner info"
```

If only skill/docs/automation implementation files changed during setup, use a setup commit message such as:

```bash
git commit -m "chore: add iskra partner info update automation"
```
