# ─────────────────────────────────────────────────────────────────────────────
# napari/docs – dev container (pixi edition)
#
# Philosophy: keep the image thin. pixi owns all Python/conda dependencies;
# the image only supplies system-level libraries that conda packages need at
# runtime (Qt/OpenGL/XCB), a virtual display (xvfb), and pixi itself.
#
# Layout inside the container:
#   /workspaces/docs/    ← napari/docs  (mounted by VS Code)
#   /workspaces/napari/  ← napari/napari (cloned in onCreateCommand)
# ─────────────────────────────────────────────────────────────────────────────
FROM mcr.microsoft.com/devcontainers/base:ubuntu-24.04

# ---------------------------------------------------------------------------
# System packages required at runtime by Qt / napari / Xvfb
# (conda bundles Qt itself, but it links against these system .so files)
# ---------------------------------------------------------------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
        # Qt / OpenGL runtime
        libgl1 \
        libglib2.0-0 \
        libdbus-1-3 \
        libfontconfig1 \
        libxcb-icccm4 \
        libxcb-image0 \
        libxcb-keysyms1 \
        libxcb-randr0 \
        libxcb-render-util0 \
        libxcb-shape0 \
        libxcb-xinerama0 \
        libxcb-xkb1 \
        libxkbcommon-x11-0 \
        libxkbcommon0 \
        libegl1 \
        # Virtual framebuffer (for headless Qt / sphinx-gallery)
        xvfb \
        x11-utils \
        # Docs build tooling
        make \
        git \
        curl \
        pandoc \
    && rm -rf /var/lib/apt/lists/*

# ---------------------------------------------------------------------------
# Install pixi (latest) system-wide
# ---------------------------------------------------------------------------
RUN curl -fsSL https://pixi.sh/install.sh | PIXI_HOME=/usr/local bash

# ---------------------------------------------------------------------------
# Environment variables
#   QT_QPA_PLATFORM=offscreen  – napari/Qt won't crash without a real display
#   DISPLAY=:99                – Xvfb virtual display (started in on-create.sh)
#   PIXI_HOME                  – already set above; expose for child processes
# ---------------------------------------------------------------------------
ENV QT_QPA_PLATFORM=offscreen \
    DISPLAY=:99 \
    PIXI_HOME=/usr/local \
    PATH="/usr/local/bin:${PATH}"

# Ensure /workspaces exists so VS Code can mount into it
RUN mkdir -p /workspaces

WORKDIR /workspaces
