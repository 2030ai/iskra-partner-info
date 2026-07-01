#!/usr/bin/env bash
set -euo pipefail

for required_command in git npx rg; do
  if ! command -v "$required_command" >/dev/null 2>&1; then
    printf 'required command not found: %s\n' "$required_command" >&2
    exit 127
  fi
done

ROOT="${1:-$(git rev-parse --show-toplevel)}"
cd "$ROOT"

fail=0
PUBLIC_MD_FILES=()
CLAIM_SCAN_FILES=()
AGENT_DOC_FILES=()
AGENT_SCRIPT_FILES=()
MARKDOWNLINT_CLI2_VERSION="${MARKDOWNLINT_CLI2_VERSION:-0.23.0}"
MARKDOWN_LINK_CHECK_VERSION="${MARKDOWN_LINK_CHECK_VERSION:-3.14.2}"

section() {
  printf '\n== %s ==\n' "$1"
}

mark_fail() {
  fail=1
}

for top_file in README.md CHANGELOG.md LICENSE.md; do
  if [ -f "$top_file" ]; then
    PUBLIC_MD_FILES+=("$top_file")
  fi
done
if [ -d docs ]; then
  while IFS= read -r -d '' file; do
    PUBLIC_MD_FILES+=("$file")
  done < <(find docs -type f -name '*.md' -print0)
fi
for file in "${PUBLIC_MD_FILES[@]}"; do
  case "$file" in
    docs/legal/claims-and-limitations.md)
      ;;
    *)
      CLAIM_SCAN_FILES+=("$file")
      ;;
  esac
done
if [ -d agent_docs ]; then
  while IFS= read -r -d '' file; do
    AGENT_DOC_FILES+=("$file")
  done < <(find agent_docs -type f -name '*.md' -print0)
fi
if [ -d .agents ]; then
  while IFS= read -r -d '' file; do
    AGENT_DOC_FILES+=("$file")
  done < <(find .agents -type f -name '*.md' -print0)
  while IFS= read -r -d '' file; do
    AGENT_SCRIPT_FILES+=("$file")
  done < <(find .agents -type f \( -name '*.sh' -o -name '*.py' \) -print0)
fi

section "markdownlint"
if [ "${#PUBLIC_MD_FILES[@]}" -gt 0 ]; then
  npx --yes "markdownlint-cli2@${MARKDOWNLINT_CLI2_VERSION}" "${PUBLIC_MD_FILES[@]}" || mark_fail
fi

section "markdown link check"
for file in "${PUBLIC_MD_FILES[@]}"; do
  npx --yes "markdown-link-check@${MARKDOWN_LINK_CHECK_VERSION}" "$file" || mark_fail
done

section "hard public metadata scan"
if [ "${#PUBLIC_MD_FILES[@]}" -gt 0 ]; then
  if rg -n "2030AI|/(Users|home|sessions)/|\bTBD\b|\bTODO\b|PLACEHOLDER|\[ответственный\]" "${PUBLIC_MD_FILES[@]}"; then
    mark_fail
  fi
fi

section "secret-like public scan"
if [ "${#PUBLIC_MD_FILES[@]}" -gt 0 ]; then
  if rg -ni "password|token|secret|ssh|private key|DemoPass|api key|bank|iban|бик|расч[её]тный сч[её]т|корреспондентский сч[её]т" "${PUBLIC_MD_FILES[@]}"; then
    mark_fail
  fi
fi

section "hard risky wording scan"
if [ "${#PUBLIC_MD_FILES[@]}" -gt 0 ]; then
  if rg -ni "данные никогда|не уходят наружу|не передаются третьим лицам|не покидают периметр|полностью соответствует 152-фз|сертифицирован[а-я ]*фстэк" "${PUBLIC_MD_FILES[@]}"; then
    mark_fail
  fi
fi

section "hard unconfirmed public claim scan"
if [ "${#CLAIM_SCAN_FILES[@]}" -gt 0 ]; then
  if rg -ni "без внешних LLM|полностью локально|включ[её]н[аоы]?[[:space:]]+в[[:space:]]+реестр российского ПО|внес[её]н[аоы]?[[:space:]]+в[[:space:]]+реестр российского ПО|в реестре российского ПО" "${CLAIM_SCAN_FILES[@]}"; then
    mark_fail
  fi
fi

section "partner economics public scan"
if [ "${#PUBLIC_MD_FILES[@]}" -gt 0 ]; then
  if rg -ni "вознагражд|рефераль|реферал|партн[её]рск[а-я ]*(процент|выплат|комисс|вознагражд|доход|заработ)|получайте [0-9]+%|зарабатывайте|[0-9]+%.*(платеж|оплат|привед[её]н|клиент|партн[её]р|комисс|вознагражд)|(промо-код|промокод).*(экономик|вознагражд|выплат|комисс|процент|%)" "${PUBLIC_MD_FILES[@]}"; then
    mark_fail
  fi
fi

section "agent hard leak scan"
AGENT_LEAK_FILES=("${AGENT_DOC_FILES[@]}" "${AGENT_SCRIPT_FILES[@]}")
if [ "${#AGENT_DOC_FILES[@]}" -gt 0 ]; then
  if rg -n "\bTBD\b|\bTODO\b|PLACEHOLDER|\[ответственный\]" "${AGENT_DOC_FILES[@]}"; then
    mark_fail
  fi
fi
if [ "${#AGENT_LEAK_FILES[@]}" -gt 0 ]; then
  if rg -n "/(Users|home|sessions)/[A-Za-z0-9._/-]+" "${AGENT_LEAK_FILES[@]}"; then
    mark_fail
  fi
  if rg -ni "BEGIN [A-Z ]*PRIVATE KEY|ssh-rsa [A-Za-z0-9+/=]{40,}|(DemoPass|api[ _-]?key|password|token|secret|iban|бик|расч[её]тный сч[её]т|корреспондентский сч[её]т)\s*[:=]" "${AGENT_LEAK_FILES[@]}"; then
    mark_fail
  fi
fi

section "legal review warning scan"
rg -ni "реестр|фстэк|152-фз|сертифиц|соответствует|локальн|LLM|gateway|on-premise" "${PUBLIC_MD_FILES[@]}" agent_docs || true

section "git diff check"
git diff --check || mark_fail

if [ "$fail" -ne 0 ]; then
  printf '\npublic safety check failed\n' >&2
  exit 1
fi

printf '\npublic safety check passed\n'
