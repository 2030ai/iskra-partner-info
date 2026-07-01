#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
cd "$REPO_ROOT"

OUTPUT="temp/iskra-partner-info-update/live-landings.md"
TIMEOUT=20

usage() {
  printf 'usage: %s [--output PATH] [--timeout SECONDS]\n' "${0##*/}"
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --output)
      [ "$#" -ge 2 ] || { usage >&2; exit 2; }
      OUTPUT=$2
      shift 2
      ;;
    --output=*)
      OUTPUT=${1#--output=}
      shift
      ;;
    --timeout)
      [ "$#" -ge 2 ] || { usage >&2; exit 2; }
      TIMEOUT=$2
      shift 2
      ;;
    --timeout=*)
      TIMEOUT=${1#--timeout=}
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      printf 'unknown argument: %s\n' "$1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

SKILL_FILE=".agents/skills/iskra-partner-info-update/SKILL.md"

DEFAULT_URLS=(
  "https://iskrabot.ru/sitemap.xml"
  "https://iskrabot.ru/"
  "https://iskrabot.ru/dlya-biznesa/"
  "https://iskrabot.ru/enterprise/"
  "https://iskrabot.ru/baza-znaniy/"
  "https://iskrabot.ru/partner/"
  "https://cloud.iskrabot.ru/lp/b2b"
  "https://cloud.iskrabot.ru/lp/demo"
  "https://cloud.iskrabot.ru/lp/tryiskra"
  "https://cloud.iskrabot.ru/lp/health"
  "https://platform.iskrabot.ru/"
)

DEFAULT_PATTERNS=(
  "152-ФЗ"
  "ФСТЭК"
  "реестр российского ПО"
  "не передаются третьим лицам"
  "не покидают"
  "без внешних LLM"
  "полностью локально"
  "данные в России"
  "on-premise"
)

ALWAYS_PATTERNS=(
  "партнёрская программа"
  "партнерская программа"
  "вознагражд"
  "рефераль"
  "реферал"
  "промо-код"
  "промокод"
)

RISK_REGEX_LABELS=(
  "partner economics / reward claim"
)

RISK_REGEXES=(
  "(получайте|зарабатывайте)[[:space:]]+[0-9]+[[:space:]]*%|[0-9]+[[:space:]]*%[^[:cntrl:]]{0,120}(платеж|оплат|привед(е|ё)н|клиент|партн(е|ё)р|комисс|вознагражд)|партн(е|ё)рск[^[:cntrl:]]{0,120}(процент|выплат|комисс|вознагражд|доход|заработ)"
)

URLS=()
PATTERNS=()

if [ -f "$SKILL_FILE" ]; then
  skill_output="$(
    perl -ne '
      BEGIN { $section = ""; $in_sensitive = 0; }
      chomp;
      if (/^##\s+(.*)/) {
        $section = lc($1);
        $in_sensitive = 0;
        next;
      }
      if (/^###\s+(.*)/) {
        $section = lc($1);
        $in_sensitive = 0;
        next;
      }
      if ($section eq "classification") {
        my $normalized = lc($_);
        $normalized =~ s/^\s+|\s+$//g;
        $normalized =~ s/:$//;
        if ($normalized =~ /^(safe update|discrepancy|sensitive blocker|no-op)$/) {
          $in_sensitive = ($normalized eq "sensitive blocker");
          next;
        }
      }
      next unless /^-\s+(.*)/;
      my $item = $1;
      if ($section eq "marketing and live site sources") {
        while ($item =~ m{https?://[^\s`>\]\)}"\x27]+}g) {
          my $url = $&;
          $url =~ s/[.,);\]\}"]+$//;
          print "URL\t$url\n";
        }
      } elsif ($section eq "public wording rules") {
        while ($item =~ /`([^`]+)`/g) {
          my $pattern = $1;
          $pattern =~ s/^\s+|\s+$//g;
          print "PATTERN\t$pattern\n" if length $pattern;
        }
      } elsif ($section eq "classification" && $in_sensitive) {
        my $pattern = $item;
        $pattern =~ s/^`|`$//g;
        $pattern =~ s/^\s+|\s+$//g;
        print "PATTERN\t$pattern\n" if length $pattern;
      }
    ' "$SKILL_FILE" 2>/dev/null || true
  )"

  while IFS=$'\t' read -r kind value; do
    case "$kind" in
      URL)
        URLS+=("$value")
        ;;
      PATTERN)
        PATTERNS+=("$value")
        ;;
    esac
  done <<< "$skill_output"
fi

if [ "${#URLS[@]}" -eq 0 ]; then
  URLS=("${DEFAULT_URLS[@]}")
fi
if [ "${#PATTERNS[@]}" -eq 0 ]; then
  PATTERNS=("${DEFAULT_PATTERNS[@]}")
else
  PATTERNS=("${DEFAULT_PATTERNS[@]}" "${PATTERNS[@]}")
fi
PATTERNS+=("${ALWAYS_PATTERNS[@]}")

mkdir -p temp/iskra-partner-info-update
TMPDIR="$(mktemp -d "temp/iskra-partner-info-update/.collect-live-landings.XXXXXX")"
trap 'rm -rf "$TMPDIR"' EXIT

normalize_text() {
  python3 -c 'import html, re, sys; text = html.unescape(sys.stdin.read()); sys.stdout.write(re.sub(r"\s+", " ", text).strip())' <<< "${1-}"
}

extract_field() {
  local body_file=$1
  local field=$2
  python3 - "$field" "$body_file" <<'PY'
import html
import re
import sys

field = sys.argv[1]
path = sys.argv[2]
with open(path, "r", encoding="utf-8", errors="replace") as handle:
    body = handle.read()


def clean(text: str) -> str:
    text = re.sub(r"<[^>]+>", " ", text or "")
    text = html.unescape(text)
    return re.sub(r"\s+", " ", text).strip()


def attr_value(attrs: str, name: str) -> str:
    pattern = r"""\b{}\s*=\s*(['"])(.*?)\1""".format(re.escape(name))
    match = re.search(pattern, attrs, flags=re.IGNORECASE | re.DOTALL)
    return match.group(2) if match else ""


if field == "title":
    match = re.search(r"<title[^>]*>(.*?)</title>", body, flags=re.IGNORECASE | re.DOTALL)
    if match:
        print(clean(match.group(1)), end="")
elif field == "description":
    for match in re.finditer(r"<meta\b([^>]*)>", body, flags=re.IGNORECASE | re.DOTALL):
        attrs = match.group(1)
        if attr_value(attrs, "name").lower() == "description":
            print(clean(attr_value(attrs, "content")), end="")
            break
elif field == "canonical":
    for match in re.finditer(r"<link\b([^>]*)>", body, flags=re.IGNORECASE | re.DOTALL):
        attrs = match.group(1)
        if attr_value(attrs, "rel").lower() == "canonical":
            print(clean(attr_value(attrs, "href")), end="")
            break
elif field == "h1":
    values = []
    for match in re.finditer(r"<h1\b[^>]*>(.*?)</h1>", body, flags=re.IGNORECASE | re.DOTALL):
        value = clean(match.group(1))
        if value:
            values.append(value)
        if len(values) >= 3:
            break
    print("\n".join(values), end="")
PY
}

join_lines() {
  awk 'NF { if (out != "") out = out ", "; out = out $0 } END { print out }'
}

collect_hits() {
  local combined_file=$1
  local pattern
  local index label regex
  local hits=""
  for pattern in "${PATTERNS[@]}"; do
    [ -n "$pattern" ] || continue
    if grep -Fqi -- "$pattern" "$combined_file"; then
      case "
$hits
" in
        *"
$pattern
"*) ;;
        *)
          if [ -n "$hits" ]; then
            hits="$hits"$'\n'"$pattern"
          else
            hits="$pattern"
          fi
          ;;
      esac
    fi
  done
  for index in "${!RISK_REGEXES[@]}"; do
    regex="${RISK_REGEXES[$index]}"
    label="${RISK_REGEX_LABELS[$index]}"
    if grep -Eiq -- "$regex" "$combined_file"; then
      case "
$hits
" in
        *"
$label
"*) ;;
        *)
          if [ -n "$hits" ]; then
            hits="$hits"$'\n'"$label"
          else
            hits="$label"
          fi
          ;;
      esac
    fi
  done
  printf '%s\n' "$hits"
}

fetch_page() {
  local url=$1
  local timeout=$2
  local slug body_file meta_file curl_meta code final_url content_type title description canonical h1_list h1_display combined_file hits_display

  slug="$(printf '%s' "$url" | sed 's#^[a-zA-Z][a-zA-Z0-9+.-]*://##; s#[^A-Za-z0-9]#_#g; s/^_//; s/_$//')"
  body_file="$TMPDIR/${slug}.body"
  meta_file="$TMPDIR/${slug}.meta"

  if curl_meta="$(
    curl \
      --silent \
      --show-error \
      --location \
      --max-time "$timeout" \
      --user-agent "iskra-partner-info-update/1.0" \
      --header "Accept: text/html,application/xhtml+xml,application/xml,text/plain;q=0.8,*/*;q=0.5" \
      --output "$body_file" \
      --write-out '%{http_code}\n%{url_effective}\n%{content_type}\n' \
      "$url"
  )"; then
    :
  fi

  printf '%s\n' "$curl_meta" > "$meta_file"

  code="$(sed -n '1p' "$meta_file" | tr -d '\r')"
  final_url="$(sed -n '2p' "$meta_file" | tr -d '\r')"
  content_type="$(sed -n '3p' "$meta_file" | tr -d '\r')"

  [ -n "$code" ] || code=0
  [ "$code" = "000" ] && code=0
  [ -n "$final_url" ] || final_url="$url"

  if [ -s "$body_file" ] && (grep -qi '<html' "$body_file" || grep -qi '<title' "$body_file"); then
    title="$(extract_field "$body_file" title)"
    description="$(extract_field "$body_file" description)"
    canonical="$(extract_field "$body_file" canonical)"
    h1_list="$(extract_field "$body_file" h1)"
  else
    title=""
    description=""
    canonical=""
    h1_list=""
  fi

  h1_display="$(printf '%s\n' "$h1_list" | join_lines)"

  combined_file="$TMPDIR/${slug}.combined"
  {
    printf '%s\n' "$title"
    printf '%s\n' "$description"
    printf '%s\n' "$h1_list"
    if [ -s "$body_file" ]; then
      head -c 5000 "$body_file"
      printf '\n'
    fi
  } > "$combined_file"

  hits_display="$(collect_hits "$combined_file" | join_lines)"

  printf '%s\037%s\037%s\037%s\037%s\037%s\037%s\037%s\n' \
    "$code" \
    "$final_url" \
    "$content_type" \
    "$title" \
    "$description" \
    "$canonical" \
    "$h1_display" \
    "${hits_display:-none}"
}

{
  printf '# Live Iskra Landing Observations\n\n'
  printf 'Collected at: `%s`\n\n' "$(date -u +%Y-%m-%dT%H:%M:%S%z)"
  printf 'This is an observation artifact for the update automation. It is not a source of truth by itself.\n\n'

  for url in "${URLS[@]}"; do
    result="$(fetch_page "$url" "$TIMEOUT")"
    IFS=$'\037' read -r status final_url content_type title description canonical h1_display hits_display <<< "$result"

    printf '## %s\n\n' "$url"
    printf -- '- Status: `%s`\n' "$status"
    printf -- '- Final URL: `%s`\n' "$final_url"
    printf -- '- Content-Type: `%s`\n' "$(normalize_text "$content_type")"
    printf -- '- Title: %s\n' "${title:-(none)}"
    printf -- '- Description: %s\n' "${description:-(none)}"
    printf -- '- Canonical: %s\n' "${canonical:-(none)}"
    printf -- '- H1: %s\n' "${h1_display:-(none)}"
    printf -- '- Risk terms observed: %s\n\n' "${hits_display:-none}"
  done
} > "$OUTPUT"

printf '%s\n' "$OUTPUT"
