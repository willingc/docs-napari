#!/usr/bin/env bash
# .devcontainer/on-create.sh
#
# Runs once when the dev container is first created (onCreateCommand).
#
# What this does:
#   1. Clone napari/napari next to napari/docs so the pixi tasks and
#      `make` targets that reference ../napari work out of the box.
#   2. Run `pixi install` inside napari/docs to resolve & fetch the
#      full conda + PyPI environment defined in the repo's own pixi.toml.
#
# Directory layout after this script:
#   /workspaces/
#     docs/    ← napari/docs  (mounted by VS Code — this repo)
#     napari/  ← napari/napari (cloned here)

set -euo pipefail

DOCS_DIR="/workspaces/docs"
NAPARI_DIR="/workspaces/napari"

echo "════════════════════════════════════════════════"
echo "  napari/docs dev-container setup (pixi)"
echo "════════════════════════════════════════════════"

# ── 1. Clone napari/napari ────────────────────────────────────────────────
if [ -d "${NAPARI_DIR}/.git" ]; then
    echo "✔  ${NAPARI_DIR} already cloned – skipping"
else
    echo "→  Cloning napari/napari into ${NAPARI_DIR} …"
    git clone --depth=1 https://github.com/napari/napari.git "${NAPARI_DIR}"
    echo "✔  Clone complete"
fi

# ── 2. pixi install (resolves the environment from pixi.toml / pixi.lock) ─
echo ""
echo "→  Running 'pixi install' in ${DOCS_DIR} …"
echo "   (this downloads conda + PyPI packages; may take a few minutes)"
cd "${DOCS_DIR}"
pixi install

echo "✔  pixi install complete"

# ── 3. Sanity check ───────────────────────────────────────────────────────
echo ""
echo "→  Verifying environment …"
pixi run python - <<'EOF'
import sys, importlib

checks = ["napari", "sphinx", "myst_parser"]
ok = True
for mod in checks:
    try:
        m = importlib.import_module(mod)
        print(f"  ✔  {mod} {getattr(m, '__version__', '?')}")
    except ImportError:
        print(f"  ✘  {mod} NOT FOUND", file=sys.stderr)
        ok = False

sys.exit(0 if ok else 1)
EOF

# ── 4. Done ───────────────────────────────────────────────────────────────
echo ""
echo "════════════════════════════════════════════════"
echo "  Setup complete!"
echo ""
echo "  Workspace layout:"
echo "    /workspaces/docs   → napari/docs  (this repo)"
echo "    /workspaces/napari → napari/napari"
echo ""
echo "  Common pixi tasks (run from /workspaces/docs):"
echo "    pixi run prep-stubs          # generate API stubs (~10 min)"
echo "    pixi run docs-build          # full doc build"
echo "    pixi run docs-build-noplot   # build without example gallery"
echo "    pixi run docs-serve          # live-preview on http://localhost:8000"
echo ""
echo "  Or use make (also available inside the pixi env):"
echo "    pixi run make html"
echo "    pixi run make slimfast"
echo "    pixi run make slimfast-live"
echo "════════════════════════════════════════════════"
