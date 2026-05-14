#!/usr/bin/env bash
# Downloads the Landfall font registry (architecture_decisions.md §22) into
# apps/display/assets/google_fonts/ so the `google_fonts` package can resolve
# every registry font from local bundle (allowRuntimeFetching = false).
#
# Architecture pin: themes can specify any font from the registry, but never
# from arbitrary URLs. Fonts ship bundled at build time — no runtime fetches
# from fonts.gstatic.com. Re-run this script when the registry version bumps.
#
# Source: Google Fonts static CDN (used only at build time, not at runtime).
#
# Usage: bash scripts/fetch_font_registry.sh

set -euo pipefail

DEST="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/apps/display/assets/google_fonts"
mkdir -p "${DEST}"

# Each line: <FamilyNoSpace>|<weight>|<variant>|<GoogleCssFamilyName>
# Weights match what Material's TextTheme typically references (300/400/500/600/700).
# google_fonts package looks up files by "<FamilyNoSpace>-<Variant>" — e.g. DMSans-Regular.
# GoogleCssFamilyName must match Google Fonts' CSS API spelling (spaces become "+").
fonts=(
  "Inter|300|Light|Inter"
  "Inter|400|Regular|Inter"
  "Inter|500|Medium|Inter"
  "Inter|600|SemiBold|Inter"
  "Inter|700|Bold|Inter"
  "DMSans|400|Regular|DM+Sans"
  "DMSans|500|Medium|DM+Sans"
  "DMSans|700|Bold|DM+Sans"
  "Outfit|400|Regular|Outfit"
  "Outfit|500|Medium|Outfit"
  "Outfit|700|Bold|Outfit"
  "SpaceGrotesk|400|Regular|Space+Grotesk"
  "SpaceGrotesk|500|Medium|Space+Grotesk"
  "SpaceGrotesk|700|Bold|Space+Grotesk"
  "Syne|400|Regular|Syne"
  "Syne|700|Bold|Syne"
  "PlayfairDisplay|400|Regular|Playfair+Display"
  "PlayfairDisplay|700|Bold|Playfair+Display"
  "Lora|400|Regular|Lora"
  "Lora|700|Bold|Lora"
  "JetBrainsMono|400|Regular|JetBrains+Mono"
  "JetBrainsMono|700|Bold|JetBrains+Mono"
  "SpaceMono|400|Regular|Space+Mono"
  "SpaceMono|700|Bold|Space+Mono"
  "Orbitron|400|Regular|Orbitron"
  "Orbitron|700|Bold|Orbitron"
  "BebasNeue|400|Regular|Bebas+Neue"
  "Lexend|400|Regular|Lexend"
  "Lexend|500|Medium|Lexend"
  "Lexend|700|Bold|Lexend"
)

# Fetch one font: query Google Fonts CSS for the @font-face src URL, then GET it.
fetch_one() {
  local family_no_space="$1" weight="$2" variant="$3" css_family="$4"
  local css_url="https://fonts.googleapis.com/css2?family=${css_family}:wght@${weight}&display=swap"
  local target="${DEST}/${family_no_space}-${variant}.ttf"

  if [[ -f "${target}" ]]; then
    echo "  ok    ${family_no_space}-${variant}.ttf (cached)"
    return 0
  fi

  local font_url css
  # Brief pause between requests — Google Fonts rate-limits aggressive scraping.
  sleep 0.4
  css="$(curl -fsSL --retry 3 --retry-delay 2 \
    -H "User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36" \
    "${css_url}" || true)"
  font_url="$(printf '%s' "${css}" | grep -Eo 'https://[^)]+\.(ttf|woff2)' | head -1)"

  if [[ -z "${font_url}" ]]; then
    echo "  FAIL  ${family_no_space}-${variant} — no font url in css2 response" >&2
    return 1
  fi

  # google_fonts expects .ttf — if Google only serves .woff2 for this family,
  # we still save it as .ttf because the package uses the FontLoader API which
  # accepts either format from the asset bundle (Flutter web tolerates woff2).
  curl -fsSL -H "User-Agent: Mozilla/5.0" "${font_url}" -o "${target}"
  echo "  ok    ${family_no_space}-${variant}.ttf ($(wc -c <"${target}") bytes)"
}

echo "Fetching ${#fonts[@]} font files → ${DEST}"
for spec in "${fonts[@]}"; do
  IFS='|' read -r family weight variant css_family <<<"${spec}"
  fetch_one "${family}" "${weight}" "${variant}" "${css_family}"
done

echo "Done. Run 'flutter pub get' in apps/display, then rebuild."
