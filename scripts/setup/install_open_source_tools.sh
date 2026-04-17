#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

echo "[setup] Installing open-source toolchain prerequisites"

if command -v apt-get >/dev/null 2>&1; then
  sudo apt-get update
  sudo apt-get install -y \
    build-essential \
    cmake \
    ninja-build \
    python3 \
    python3-pip \
    iverilog \
    verilator \
    gtkwave \
    yosys \
    opensta \
    openroad
else
  echo "[setup] apt-get not detected; skipping OS package installation."
  echo "[setup] Install the following manually: iverilog verilator gtkwave yosys opensta openroad."
fi

python3 -m pip install --upgrade pip
python3 -m pip install -r "$ROOT_DIR/requirements.txt"

echo "[setup] Completed dependency bootstrap."
