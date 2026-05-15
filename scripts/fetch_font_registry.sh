#!/usr/bin/env bash
# Downloads the Landfall font registry (architecture_decisions.md §22) and the
# Noto fallback set (pass 1) into the app asset tree.
#
# Registry fonts → apps/display/assets/google_fonts/
#   Named <FamilyNoSpace>-<Variant>.ttf so google_fonts can resolve them when
#   allowRuntimeFetching=false. Also declared under flutter.fonts in pubspec so
#   the engine resolves fontFamily: 'X' from bundled assets at the engine level.
#
# Noto fallback fonts (pass 1) → apps/display/assets/fonts/
#   Covers Latin/Latin-Extended/common symbols so FontFallbackManager does not
#   fetch from fonts.gstatic.com for typical companion content. Pass 2 (CJK +
#   script-specific subsets) is deferred until a live network capture confirms
#   which families are still requested after pass 1 ships.
#
# Architecture pin: themes can specify any font from the registry, but never
# from arbitrary URLs. Fonts ship bundled at build time — no runtime fetches
# from fonts.gstatic.com. Re-run this script when the registry version bumps.
#
# Source: Google Fonts static CDN (used only at build time, not at runtime).
#
# Usage: bash scripts/fetch_font_registry.sh

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEST="${ROOT}/apps/display/assets/google_fonts"
NOTO_DEST="${ROOT}/apps/display/assets/fonts"
mkdir -p "${DEST}" "${NOTO_DEST}"

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

# Noto fallback set — pass 1. File names match what pubspec flutter.fonts declares.
# These go to NOTO_DEST (assets/fonts/) so they are distinct from the theme registry.
# Each line: <Filename>|<weight>|<GoogleCssFamilyName>
noto_fonts=(
  "NotoSans-Regular|400|Noto+Sans"
  "NotoSans-Bold|700|Noto+Sans"
  "NotoSansSymbols-Regular|400|Noto+Sans+Symbols"
  "NotoSansSymbols2-Regular|400|Noto+Sans+Symbols+2"
  "NotoSansMath-Regular|400|Noto+Sans+Math"
)

# Shared helper: query Google Fonts CSS2 API for the font src URL, then fetch the file.
_fetch_font_url() {
  local css_family="$1" weight="$2" target="$3"
  local css_url="https://fonts.googleapis.com/css2?family=${css_family}:wght@${weight}&display=swap"

  local font_url css
  sleep 0.4
  css="$(curl -fsSL --retry 3 --retry-delay 2 \
    -H "User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36" \
    "${css_url}" || true)"
  font_url="$(printf '%s' "${css}" | grep -Eo 'https://[^)]+\.(ttf|woff2)' | head -1)"

  if [[ -z "${font_url}" ]]; then
    echo "  FAIL  ${target##*/} — no font url in css2 response" >&2
    return 1
  fi

  curl -fsSL -H "User-Agent: Mozilla/5.0" "${font_url}" -o "${target}"
  echo "  ok    ${target##*/} ($(wc -c <"${target}") bytes)"
}

# Fetch a theme registry font into DEST.
# google_fonts expects .ttf — woff2 is saved as .ttf; Flutter's FontLoader accepts both.
fetch_one() {
  local family_no_space="$1" weight="$2" variant="$3" css_family="$4"
  local target="${DEST}/${family_no_space}-${variant}.ttf"
  if [[ -f "${target}" ]]; then echo "  ok    ${family_no_space}-${variant}.ttf (cached)"; return 0; fi
  _fetch_font_url "${css_family}" "${weight}" "${target}"
}

# Fetch a Noto fallback font into NOTO_DEST.
fetch_noto() {
  local filename="$1" weight="$2" css_family="$3"
  local target="${NOTO_DEST}/${filename}.ttf"
  if [[ -f "${target}" ]]; then echo "  ok    ${filename}.ttf (cached)"; return 0; fi
  _fetch_font_url "${css_family}" "${weight}" "${target}"
}

echo "Fetching ${#fonts[@]} registry font files → ${DEST}"
for spec in "${fonts[@]}"; do
  IFS='|' read -r family weight variant css_family <<<"${spec}"
  fetch_one "${family}" "${weight}" "${variant}" "${css_family}"
done

echo "Fetching ${#noto_fonts[@]} Noto fallback fonts (pass 1) → ${NOTO_DEST}"
for spec in "${noto_fonts[@]}"; do
  IFS='|' read -r filename weight css_family <<<"${spec}"
  fetch_noto "${filename}" "${weight}" "${css_family}"
done

echo "Done. Run 'flutter pub get' in apps/display, then rebuild."
