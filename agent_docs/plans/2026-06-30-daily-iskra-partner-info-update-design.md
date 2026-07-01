# Дизайн: daily iskra partner info update

Дата: 2026-06-30
Статус: утверждён в чате, ожидает review письменной спеки

## Цель

Автоматизация ежедневно обновляет публичную Markdown-базу `2030ai/iskra-partner-info` для партнёров Искры и клиентов, которые читают репозиторий напрямую или передают его своим агентам.

Автоматизация не является зеркалом CRM, платформы, сайта или Telegram-чата. Её задача — поддерживать curated partner-safe слой: актуальные возможности Искры, коммерческие публичные ориентиры, варианты развёртывания, ограничения и безопасные формулировки.

## Название и расписание

- Automation id: `daily-iskra-partner-info-update`
- Automation name: `daily iskra partner info update`
- Периодичность: ежедневно в 05:00 по локальному времени среды Codex.
- Рабочая директория: корень `iskra-partner-info`.
- Модель: основной ежедневный режим должен использовать модель уровня `gpt-5.5` с reasoning не ниже `medium`, потому что задача сочетает продуктовые, юридические и safety-проверки.

Cron prompt должен быть коротким: прочитать `AGENTS.md` / `CLAUDE.md`, затем запустить project-local skill `.agents/skills/iskra-partner-info-update/SKILL.md` в unattended automation mode. Процедура, источники, фильтры, проверки, Telegram-уведомления и формат финального отчёта должны жить в skill, а не в длинном automation prompt.

## Источники

### Source of Truth

CRM:

- `$HOME/Developer/2030ai-CRM/01_методология продаж/КП Искра/КП_Искра.md`
- `$HOME/Developer/2030ai-CRM/01_методология продаж/Коммерческая модель Искры 2026.06.md`
- `$HOME/Developer/2030ai-CRM/01_методология продаж/КП Искра/Искра_FAQ_коммерческая_модель_и_on-premise_2026.06.09.md`
- `$HOME/Developer/2030ai-CRM/01_методология продаж/Искра_юридический/Искра_договор/iskra-contract-checklist.md`
- `$HOME/Developer/2030ai-CRM/01_методология продаж/Искра_юридический/Искра_договор/iskra-license-agreement-final.md`

Platform:

- `$HOME/Developer/2030ai-platform/strategy/01_vision.md`
- `$HOME/Developer/2030ai-platform/strategy/02_product.md`
- `$HOME/Developer/2030ai-platform/shared/helpdocs/docs/user/`
- `$HOME/Developer/2030ai-platform/shared/helpdocs/docs/tech/`
- `$HOME/Developer/2030ai-platform/docs/44fz/platform-description.md`
- `$HOME/Developer/2030ai-platform/services/billing/init_plans.yaml`
- Relevant platform code/docs found during the run when a changed feature needs confirmation.

Marketing:

- `$HOME/Developer/2030ai-iskra-marketing/iskra-marketing/creatives/`
- `$HOME/Developer/2030ai-iskra-marketing/iskra-marketing/creatives/DEPLOY.md`
- `$HOME/Developer/2030ai-iskra-marketing/iskra-marketing/creatives/landings-spec.md`
- `$HOME/Developer/2030ai-iskra-marketing/iskra-marketing/strategy/`
- `$HOME/Developer/2030ai-iskra-marketing/iskra-marketing/product/`

Public site:

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

Telegram:

- Read-only chat title: `Искра: партнёрская`
- Purpose: field signals only. The chat can reveal frequent partner questions, unclear wording, objections, requests for materials and inconsistencies.
- The chat cannot create public claims by itself.

Current public repo:

- `README.md`
- `CHANGELOG.md`
- `docs/overview.md`
- `docs/capabilities/`
- `docs/sales/`
- `docs/commercial/`
- `docs/legal/claims-and-limitations.md`

## Source Priority

- Commercial prices, packages and paid terms: CRM commercial model and КП win over site copy and helpdocs.
- Product capabilities: platform docs/code win over sales drafts and landing copy.
- Deployment, LLM, data contour and technical claims: platform tech docs/code and legal docs win over landing copy.
- Legal/compliance claims: contract checklist and final license text win over every marketing source.
- Live landings are evidence of currently published claims, not automatically safe wording for `iskra-partner-info`.
- Telegram `Искра: партнёрская` is evidence of confusion, demand or discrepancy, not a source for public facts.

## Run Flow

1. Read `AGENTS.md`, `CLAUDE.md`, `agent_docs/index.md`, `docs/legal/claims-and-limitations.md` and automation memory.
2. Verify target repo Git state. If the worktree is dirty before the run, do not edit; send a blocker report.
3. Identify changes since the previous successful run:
   - local Git history/status in CRM, platform, marketing and partner-info repos;
   - live sitemap and selected landing HTML metadata/content;
   - changed commercial/legal/platform source files;
   - new sanitized signals from `Искра: партнёрская`.
4. Classify findings:
   - safe update for partner-info;
   - discrepancy between sources;
   - sensitive blocker;
   - no-op.
5. For safe updates, edit only public Markdown files and `CHANGELOG.md`.
6. For discrepancies, prepare a report item and do not silently normalize facts.
7. Run verification and self-review.
8. If changes pass, create a local commit. Do not push.
9. Notify through `publishbotzvasil` only when there are public changes, discrepancies, blockers or source failures. No-op runs may stay as compact final output without Telegram noise.

## Classification Rules

Safe update:

- The proposed text is public, useful for partners/clients, and supported by an allowed source.
- Product claims are confirmed by platform docs/code or by platform docs plus a compatible live landing.
- Commercial claims are confirmed by CRM commercial sources.
- Legal/deployment/data wording is compatible with `docs/legal/claims-and-limitations.md`.
- The change improves capabilities, deployment options, pricing, partner process, positioning or limitations.

Discrepancy:

- Live landing says more than the safe public repo can say.
- Site copy, CRM, platform and partner-info disagree on status, price, capability, data contour, LLM, registry, 152-ФЗ, on-premise or partner process.
- Telegram chat reveals repeated confusion not covered by public docs.
- Local creative source differs materially from live landing.

Sensitive blocker:

- Partner compensation, referral percentages, agency fees, payouts, promo-code economics or individual partner terms.
- CRM clients, deals, contacts, private names, emails, phone numbers, chat IDs, raw messages or meeting notes.
- Bank details, tokens, passwords, SSH, demo credentials, API keys, infrastructure secrets or internal endpoints.
- Raw Telegram quotes or identifiable partner/customer context.
- Claims that require confirmation but do not have a source: registry, FSTEK, full 152-ФЗ compliance, fully local processing, no external LLM/gateway, data never leaving a perimeter, data never transferred to third parties.

No-op:

- Source changes are irrelevant to partner/client understanding.
- Changes are internal implementation details with no public sales or deployment meaning.
- Only sensitive material changed and cannot be summarized safely.

## Forbidden And Risky Wording

Hard forbidden in public partner-info unless a later source explicitly changes the policy and legal page is updated first:

- `2030AI` as company/product spelling; use `2030ai` for the brand string where needed.
- Claiming the company is `2030ai`; the company and main product are `Искра`.
- `данные никогда не передаются`
- `данные не передаются третьим лицам`
- `данные не покидают периметр`
- `полностью соответствует 152-ФЗ`
- `сертифицировано ФСТЭК`
- `включено в реестр российского ПО` without registry number and verifiable source.
- `без внешних LLM` or `полностью локально` without the exact approved deployment contour.

Allowed safer pattern:

- Describe contours as configurable and contract-specific.
- Say that cloud, Russian contour, on-premise, local models, gateway, GPU, infrastructure, SLA and data processing conditions are fixed in the agreement, specification or technical description.

## Output Contract

If a local commit is created:

- Commit message: `docs: refresh iskra partner info`
- Telegram report includes:
  - commit hash;
  - changed files;
  - sources checked;
  - verification status;
  - discrepancy count;
  - sensitive blockers, if any;
  - recommended owner review items.

If only discrepancies/blockers exist:

- No commit.
- Telegram report includes sanitized discrepancy/blocker list with source names and recommended next action.

If no meaningful changes:

- No commit.
- No Telegram message by default.
- Compact final automation output states that the run was no-op and lists sources checked.

## Verification

Before committing:

```bash
npx --yes markdownlint-cli2@latest "**/*.md"
for f in README.md docs/**/*.md; do npx --yes markdown-link-check "$f" || exit 1; done
rg -n "2030""AI|/(Users|home|sessions)/|T""BD|T""ODO|PLACE""HOLDER|\\[ответственный\\]" README.md CHANGELOG.md LICENSE.md docs agent_docs
rg -ni "password|token|secret|ssh|private key|DemoPass|api key|bank|iban|бик|расч[её]тный счет|корреспондентский счет" README.md CHANGELOG.md LICENSE.md docs agent_docs
rg -ni "реестр|фстэк|152-фз|сертифиц|соответствует|данные никогда|не уходят наружу|не передаются третьим лицам|не покидают периметр|локальн" docs README.md
git diff --check
```

Legal/risky-wording matches are not automatically failures when they occur in `docs/legal/claims-and-limitations.md`, `docs/commercial/deployment-options.md` or `docs/capabilities/deployment-and-llm.md`, but the automation must explicitly re-check the wording before committing.

## Self-Review Lenses

Owner of Iskra:

- Does the repo describe Iskra accurately and sellably?
- Are company/product names correct: `Искра`, `2030ai`, not `2030AI`?
- Are capabilities neither understated nor overpromised?
- Are commercial terms public-safe and not exposing partner compensation?
- Are legal/data/deployment claims defensible?

Partner/client reader:

- Can a partner understand what can be sold and what needs project confirmation?
- Can a client feed the repo to an agent without leaking internal terms?
- Are capability pages detailed enough to be useful, but not filled with internal implementation noise?
- Are discrepancies clearly surfaced instead of hidden?

## Error Handling

- If a required local source is missing, continue only for unrelated sections; do not update claims that depend on the missing source.
- If live site fetch fails, compare local source repos and report the site failure.
- If Telegram read fails, continue without chat signals and report the source failure only when other changes/discrepancies exist.
- If `publishbotzvasil` fails, keep the local commit when checks passed, and include notification failure in final output.
- If verification fails after edits, do not commit; leave changes for inspection only if they are useful, and report blockers.

## Implementation Units

1. Project-local skill `.agents/skills/iskra-partner-info-update/SKILL.md`.
2. Optional helper scripts under `.agents/skills/iskra-partner-info-update/scripts/` only if repeated extraction/scanning becomes too large for a skill prompt.
3. Automation created through Codex app automation tools with the approved id/name/schedule.
4. Automation memory in the standard Codex automation memory for `daily-iskra-partner-info-update`.

## Out Of Scope

- Pushing to GitHub.
- Creating PRs.
- Editing the source CRM/platform/marketing repos.
- Publishing or sending messages to partner chats.
- Extracting or publishing partner compensation.
- Building a JSON/YAML data feed for partner information.
