#!/usr/bin/env bash
set -euo pipefail

SBINDIR="/usr/lib/sbin"
SNIPPETS_DIR="/var/lib/vz/snippets"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DRY_RUN="no"

while [ $# -gt 0 ]; do
  case "$1" in
    --sbindir) SBINDIR="$2"; shift 2 ;;
    --snippets-dir) SNIPPETS_DIR="$2"; shift 2 ;;
    --repo-dir) REPO_DIR="$2"; shift 2 ;;
    --dry-run) DRY_RUN="yes"; shift ;;
    -h|--help)
      echo "usage: $0 [--sbindir PATH] [--snippets-dir PATH] [--repo-dir PATH] [--dry-run]"
      exit 0
      ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  case_end:; esac
done

need_root() {
  if [ "$(id -u)" -ne 0 ]; then
    echo "requires root. re-run with sudo." >&2
    exit 1
  fi
}

do_install() {
  local src="$1" dst="$2" mode="$3"
  if [ "$DRY_RUN" = "yes" ]; then
    echo "DRY: install -D -m $mode $src $dst"
  else
    install -D -m "$mode" "$src" "$dst"
  fi
}

echo "repo: $REPO_DIR"
echo "sbindir: $SBINDIR"
echo "snippets: $SNIPPETS_DIR"
[ "$DRY_RUN" = "yes" ] || need_root

SCRIPTS=()
if compgen -G "$REPO_DIR/scripts/*.sh" > /dev/null; then
  while IFS= read -r f; do SCRIPTS+=("$f"); done < <(find "$REPO_DIR/scripts" -maxdepth 1 -type f -name '*.sh' | sort)
fi
if [ -f "$REPO_DIR/bundles/generic-clone-builder/compose_clone.sh" ]; then
  SCRIPTS+=("$REPO_DIR/bundles/generic-clone-builder/compose_clone.sh")
fi
if [ -f "$REPO_DIR/bundles/generic-clone-builder/make_user_data.sh" ]; then
  SCRIPTS+=("$REPO_DIR/bundles/generic-clone-builder/make_user_data.sh")
fi

SNIPPETS=()
if compgen -G "$REPO_DIR/bundles/**/*.yaml" > /dev/null || compgen -G "$REPO_DIR/bundles/*.yaml" > /dev/null; then
  while IFS= read -r y; do SNIPPETS+=("$y"); done < <(find "$REPO_DIR/bundles" -type f -name '*.yaml' | sort)
fi

if [ "${#SCRIPTS[@]}" -eq 0 ] && [ "${#SNIPPETS[@]}" -eq 0 ]; then
  echo "nothing to deploy" >&2
  exit 3
fi

if [ "$DRY_RUN" != "yes" ]; then
  mkdir -p "$SBINDIR" "$SNIPPETS_DIR"
fi

for s in "${SCRIPTS[@]}"; do
  base="$(basename "$s")"
  do_install "$s" "$SBINDIR/$base" 0755
done

for y in "${SNIPPETS[@]}"; do
  base="$(basename "$y")"
  do_install "$y" "$SNIPPETS_DIR/$base" 0644
done

echo "done"
if [ "${#SCRIPTS[@]}" -gt 0 ]; then
  echo "installed scripts:"
  for s in "${SCRIPTS[@]}"; do echo "  $SBINDIR/$(basename "$s")"; done
fi
if [ "${#SNIPPETS[@]}" -gt 0 ]; then
  echo "installed snippets:"
  for y in "${SNIPPETS[@]}"; do echo "  $SNIPPETS_DIR/$(basename "$y")"; done
fi