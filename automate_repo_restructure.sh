cat > automate_repo_restructure_no_heredoc.sh <<'BASH'
#!/usr/bin/env bash
set -euo pipefail

echo "==> Verifying Git repo..."
git rev-parse --is-inside-work-tree >/dev/null

BASE_BRANCH=${BASE_BRANCH:-main}
NEW_BRANCH=${NEW_BRANCH:-repo/restructure-and-docs}
if git show-ref --verify --quiet "refs/heads/$NEW_BRANCH"; then
  git checkout "$NEW_BRANCH"
else
  git checkout -b "$NEW_BRANCH" "$BASE_BRANCH"
fi

echo "==> Creating directories..."
mkdir -p docs scripts bundles/portainer_demo templates .github/workflows

mv_if_exists () {
  local src="$1" dst="$2"
  if [[ -e "$src" ]]; then
    mkdir -p "$(dirname "$dst")"
    git mv -k "$src" "$dst" 2>/dev/null || mv "$src" "$dst"
    echo "   moved: $src -> $dst"
  else
    echo "   skip (not found): $src"
  fi
}

echo "==> Moving known files (skips missing files)..."
mv_if_exists prep_deb12_docker_base.sh scripts/prep_deb12_docker_base.sh
mv_if_exists build_deb12_docker_base.sh scripts/build_deb12_docker_base.sh
mv_if_exists clone_from_deb12_docker_base.sh scripts/clone_from_deb12_docker_base.sh
mv_if_exists portainer_demo_bundle/clone_portainer.sh bundles/portainer_demo/clone_portainer.sh
mv_if_exists portainer_demo_bundle/portainer-userdata.yaml bundles/portainer_demo/portainer-userdata.yaml
mv_if_exists Portainer_powershell_demo bundles/portainer_demo/Portainer_powershell_demo
mv_if_exists generic-clone-builder bundles/generic-clone-builder
mv_if_exists docker_template_bundle.tar.gz templates/docker_template_bundle.tar.gz
mv_if_exists docker_template_bundle_full.md docs/docker-template.md
mv_if_exists proxmox_docker_template_manual.md docs/portainer-demo.md

echo "==> Writing small placeholder files (no heredocs)..."
[[ -s README.md ]] || printf '%s\n' \
'# Proxmox Templates & Bundles' \
'' \
'Automation and docs for:' \
'- Debian 12 Docker base image (prepare/build/clone)' \
'- Portainer demo bundle (cloud-init)' \
'' \
'👉 Start here: [docs/README.md](docs/README.md)' \
'' \
'License: GPL-3.0 — see `LICENSE`.' > README.md

mkdir -p docs
[[ -s docs/README.md ]] || printf '%s\n' \
'# Proxmox Templates & Bundles — Overview' \
'' \
'This repository includes:' \
'- **Docker base on Debian 12**: prepare, build, and clone scripts.' \
'- **Portainer demo**: cloud-init snippet + helper script.' \
'' \
'## Quickstart (Debian 12 Docker base)' \
'' \
'```bash' \
'bash scripts/prep_deb12_docker_base.sh' \
'bash scripts/build_deb12_docker_base.sh' \
'bash scripts/clone_from_deb12_docker_base.sh <VMID> <NAME> <PUBKEY_PATH> <compose.yml-path>' \
'```' \
'' \
'More: [docker-template.md](./docker-template.md) • [portainer-demo.md](./portainer-demo.md)' > docs/README.md

[[ -e docs/docker-template.md ]] || printf '%s\n' \
'# Docker Template: Debian 12 + Docker' \
'' \
'Document the base template, assumptions, storage names, and first-boot behavior here.' \
'' \
'## Scripts' \
'- `scripts/prep_deb12_docker_base.sh`' \
'- `scripts/build_deb12_docker_base.sh`' \
'- `scripts/clone_from_deb12_docker_base.sh`' \
'' \
'## Example' \
'```bash' \
'./scripts/clone_from_deb12_docker_base.sh 950 kuma-01 ~/.ssh/id_ed25519.pub /mnt/pve/pve-qnap/apps/kuma/docker-compose.yml' \
'```' > docs/docker-template.md

[[ -e docs/portainer-demo.md ]] || printf '%s\n' \
'# Portainer Demo' \
'' \
'## Requirements' \
'- Proxmox VE with cloud-init enabled template' \
'- Access to `/var/lib/vz/snippets/`' \
'' \
'## Steps' \
'1. Copy `bundles/portainer_demo/portainer-userdata.yaml` to `/var/lib/vz/snippets/`.' \
'2. Run `bundles/portainer_demo/clone_portainer.sh`.' \
'3. Access Portainer after first boot.' > docs/portainer-demo.md

printf '%s\n' \
'root = true' \
'[*]' \
'end_of_line = lf' \
'insert_final_newline = true' \
'charset = utf-8' \
'indent_style = space' \
'indent_size = 2' > .editorconfig

printf '%s\n' \
'*.sh text eol=lf' \
'*.md text eol=lf' \
'*.docx binary' \
'*.tar.gz binary' > .gitattributes

mkdir -p .github/workflows
printf '%s\n' \
'name: shellcheck' \
'on:' \
'  push:' \
'    paths: ["scripts/**/*.sh"]' \
'  pull_request:' \
'    paths: ["scripts/**/*.sh"]' \
'jobs:' \
'  lint:' \
'    runs-on: ubuntu-latest' \
'    steps:' \
'      - uses: actions/checkout@v4' \
'      - uses: ludeeus/action-shellcheck@v2' > .github/workflows/shellcheck.yml

printf '%s\n' \
'{' \
'  "ignorePatterns": [' \
'    { "pattern": "^mailto:" },' \
'    { "pattern": "^#" },' \
'    { "pattern": "^\\.\\./" },' \
'    { "pattern": "^\\./" }' \
'  ],' \
'  "httpHeaders": [' \
'    {' \
'      "urls": ["https://raw.githubusercontent.com"],' \
'      "headers": { "User-Agent": "curl/8.x" }' \
'    }' \
'  ]' \
'}' > .mlc.config.json

printf '%s\n' \
'name: markdown-link-check' \
'on:' \
'  push:' \
'    paths: ["**/*.md"]' \
'  pull_request:' \
'    paths: ["**/*.md"]' \
'jobs:' \
'  check:' \
'    runs-on: ubuntu-latest' \
'    steps:' \
'      - uses: actions/checkout@v4' \
'      - uses: gaurav-nelson/github-action-markdown-link-check@v1' \
'        with:' \
"          use-verbose-mode: 'yes'" \
"          config-file: '.mlc.config.json'" > .github/workflows/markdown-link-check.yml

echo "==> Normalizing line endings..."
find . -type f -name '*.sh' -print0 | xargs -0 -I{} bash -c "sed -i '' -e 's/\r$//' '{}' || true"

echo '==> git add & commit...'
git add -A
if git diff --cached --quiet; then
  echo "No changes to commit."
else
  git commit -m "repo: restructure (docs/scripts/bundles/templates), add CI & placeholders (no heredocs)"
fi

echo "==> Done."
echo "Push with:  git push -u origin $NEW_BRANCH"
BASH

chmod +x automate_repo_restructure_no_heredoc.sh
./automate_repo_restructure_no_heredoc.sh