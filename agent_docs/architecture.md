# Architecture

This repository is a public Markdown knowledge base for Iskra partners.

## Layers

- Public layer: `README.md`, `CHANGELOG.md`, `LICENSE.md`, and `docs/`.
- Agent documentation layer: `agent_docs/`.
- Agent skill layer: `.agents/skills/` is an explicitly allowed project-local automation layer for executable skills and helper scripts; it is the only committed agent-maintenance layer outside `agent_docs/`.
- CI layer: `.github/workflows/markdownlint.yml` and `.markdownlint.json`.

## Source Of Truth

- Commercial claims come from CRM commercial documents and КП materials.
- Product capability descriptions come from `2030ai-platform` strategy and helpdocs.
- Deployment and technical claims come from `2030ai-platform` tech docs and code.
- Legal and compliance wording comes from CRM contract checklist and final contract text.

## Publication Rule

Local content is reviewed and checked before the GitHub repository is created or pushed publicly.
