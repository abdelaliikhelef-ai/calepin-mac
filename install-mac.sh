#!/usr/bin/env bash
# Installe (ou met à jour) Calepin sur le Mac depuis la page de téléchargement publique
# (releases du dépôt abdelaliikhelef-ai/calepin-mac). Aucun compte ni outil GitHub n'est nécessaire.
#
# Usage, à coller une fois dans le Terminal :
#   curl -fsSL https://raw.githubusercontent.com/abdelaliikhelef-ai/calepin-mac/main/install-mac.sh | bash
# puis, pour les mises à jour : calepin-install
#
# Un fichier téléchargé en ligne de commande ne porte pas la « quarantaine » de macOS :
# l'app installée ainsi s'ouvre sans avertissement. Les chantiers et réglages ne sont
# jamais touchés : seule l'app est remplacée.
#
# Variables : CALEPIN_VERSION (version x.y.z à installer, la dernière publiée par défaut),
# CALEPIN_NO_ALIAS=1 (pas d'alias), CALEPIN_APPS_DIR (dossier d'installation, /Applications
# par défaut ; sert aux tests).
# Lancé par l'app elle-même (Calepin › Rechercher les mises à jour…), avec CALEPIN_VERSION :
#   CALEPIN_WAIT_PID    numéro du processus de l'app à attendre avant de la remplacer (60 s au plus,
#                       CALEPIN_WAIT_SECONDS pour changer la durée).

# Tout est dans `main`, appelée à la dernière ligne : lancé par « … | bash », le script
# est lu en entier avant de s'exécuter, et aucune commande ne mange la suite sur stdin.
main() {
  set -euo pipefail

  # Dépôt public des versions ; noms des .dmg : contrat partagé avec src/shared/updates.ts
  # (releaseAssetName) et tools/publish-release.sh.
  local repo="abdelaliikhelef-ai/calepin-mac"
  local apps="${CALEPIN_APPS_DIR:-/Applications}"
  local rc="${HOME}/.zshrc"
  local marker_start="# >>> calepin-install >>>"
  local marker_end="# <<< calepin-install <<<"

  # Vrai une fois l'ancienne app quittée : en cas d'échec, on la rouvre telle qu'elle était.
  local reopen_old=0
  # Lancé par l'app : elle se ferme tout de suite, donc en cas d'échec on la rouvre.
  [ -z "${CALEPIN_WAIT_PID:-}" ] || reopen_old=1

  say() { printf '\033[1m%s\033[0m\n' "$*"; }
  fail() {
    printf 'Erreur : %s\n' "$*" >&2
    if [ "$reopen_old" = "1" ] && [ -d "$apps/Calepin.app" ]; then
      printf "L'ancienne version de Calepin est conservée et rouverte.\n" >&2
      open "$apps/Calepin.app" </dev/null >/dev/null 2>&1 || true
    fi
    exit 1
  }

  # 1. Mac Apple Silicon ou Intel.
  local kind="Intel"
  [ "$(uname -m)" = "arm64" ] && kind="AppleSilicon"

  # 2. Version à installer : celle demandée (par l'app) ou la dernière publiée.
  local version
  if [ -n "${CALEPIN_VERSION:-}" ]; then
    version="$CALEPIN_VERSION"
  else
    say "Recherche de la dernière version de Calepin…"
    # github.com/…/releases/latest redirige vers …/releases/tag/vX.Y.Z (sans jq ni jeton).
    local latest
    latest="$(curl -fsS --retry 3 --retry-all-errors -o /dev/null -w '%{redirect_url}' \
      "https://github.com/$repo/releases/latest" </dev/null || true)"
    version="${latest##*/}"
    version="${version#v}"
  fi
  # Exactement x.y.z, des chiffres seulement (la version entre dans une adresse).
  if ! [[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    fail "version introuvable ou invalide : ${version:-aucune}."
  fi

  # 3. Téléchargement dans un dossier temporaire, supprimé à la fin.
  local tmp
  tmp="$(mktemp -d)"
  local mnt="$tmp/mnt"
  # shellcheck disable=SC2064
  trap "hdiutil detach '$mnt' -quiet >/dev/null 2>&1 || true; rm -rf '$tmp'" EXIT
  local asset="Calepin-${version}-${kind}.dmg"
  local dmg="$tmp/$asset"
  say "Téléchargement de Calepin ${version} (${kind})…"
  # Barre de progression de curl dans un Terminal ; silencieux dans le journal (lancé par l'app).
  local progress=(-sS)
  [ -t 2 ] && progress=(--progress-bar)
  curl -fL --retry 4 --retry-all-errors --retry-delay 2 "${progress[@]}" -o "$dmg" \
    "https://github.com/$repo/releases/download/v${version}/${asset}" </dev/null ||
    fail "le téléchargement de Calepin ${version} a échoué."
  [ -s "$dmg" ] || fail "le fichier téléchargé est vide."

# 4. Installation : attendre la fin de l'app, copier à côté, vérifier, puis échanger.
  if [ -n "${CALEPIN_WAIT_PID:-}" ]; then
    # Lancé par l'app : elle se ferme d'elle-même, on attend sa fin (60 s au plus).
    local waited=0 limit="${CALEPIN_WAIT_SECONDS:-60}"
    while kill -0 "$CALEPIN_WAIT_PID" 2>/dev/null && [ "$waited" -lt "$limit" ]; do
      sleep 1
      waited=$((waited + 1))
    done
  else
    osascript -e 'quit app "Calepin"' </dev/null >/dev/null 2>&1 || true
  fi
  reopen_old=1
  mkdir -p "$mnt"
  # 2>/dev/null : macOS récent affiche un avertissement « deprecated » sans conséquence.
  hdiutil attach -nobrowse -readonly -mountpoint "$mnt" "$dmg" </dev/null >/dev/null 2>&1 ||
    fail "impossible d'ouvrir le fichier d'installation."
  [ -d "$mnt/Calepin.app" ] || fail "Calepin.app est absent du fichier d'installation."
  say "Installation dans ${apps}…"
  # La nouvelle app est préparée et vérifiée à côté : l'ancienne n'est touchée qu'à la fin.
  rm -rf "$apps/Calepin.app.new" "$apps/Calepin.app.old"
  if ! ditto "$mnt/Calepin.app" "$apps/Calepin.app.new"; then
    rm -rf "$apps/Calepin.app.new"
    fail "la copie de la nouvelle version a échoué."
  fi
  hdiutil detach "$mnt" -quiet </dev/null >/dev/null 2>&1 || true
  xattr -dr com.apple.quarantine "$apps/Calepin.app.new" 2>/dev/null || true
  if ! codesign --verify --deep --strict "$apps/Calepin.app.new"; then
    rm -rf "$apps/Calepin.app.new"
    fail "la signature de la nouvelle version n'est pas valide."
  fi
  if [ -d "$apps/Calepin.app" ]; then mv "$apps/Calepin.app" "$apps/Calepin.app.old"; fi
  if ! mv "$apps/Calepin.app.new" "$apps/Calepin.app"; then
    if [ -d "$apps/Calepin.app.old" ]; then mv "$apps/Calepin.app.old" "$apps/Calepin.app"; fi
    rm -rf "$apps/Calepin.app.new"
    fail "le remplacement de l'app a échoué."
  fi
  rm -rf "$apps/Calepin.app.old"
  reopen_old=0 # le `open` final rouvre la nouvelle app

  local version
  version="$(plutil -extract CFBundleShortVersionString raw "$apps/Calepin.app/Contents/Info.plist" 2>/dev/null || echo '?')"
  say "Calepin $version est installé."

  # 5. Raccourci « calepin-install » pour les mises à jour (une seule fois).
  if [ "${CALEPIN_NO_ALIAS:-}" != "1" ] && ! grep -qF "$marker_start" "$rc" 2>/dev/null; then
    {
      printf '\n%s\n' "$marker_start"
      printf "alias calepin-install='curl -fsSL https://raw.githubusercontent.com/%s/main/install-mac.sh | bash'\n" "$repo"
      printf '%s\n' "$marker_end"
    } >>"$rc"
    say "Pour les prochaines mises à jour, ouvre un nouveau Terminal et tape : calepin-install"
  fi

  open "$apps/Calepin.app" </dev/null || true
}

main "$@"
