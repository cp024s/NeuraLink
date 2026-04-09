#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
THIRD_PARTY_DIR="$ROOT_DIR/third_party/repos"
mkdir -p "$THIRD_PARTY_DIR"
LOCAL_REF_REPOS="${LOCAL_REF_REPOS:-/mnt/d/Repositories/ref_repos}"

link_local_or_clone() {
  local local_name="$1"
  local remote_url="$2"
  local target_name="$3"
  local local_src="$LOCAL_REF_REPOS/$local_name"
  local dst="$THIRD_PARTY_DIR/$target_name"

  if [[ "${USE_LOCAL_REF_REPOS:-0}" == "1" && -d "$local_src" ]]; then
    rm -rf "$dst"
    ln -s "$local_src" "$dst"
    echo "Linked local reference: $dst -> $local_src"
  else
    clone_or_update "$remote_url" "$target_name"
  fi
}

clone_or_update() {
  local url="$1"
  local name="$2"
  local dir="$THIRD_PARTY_DIR/$name"
  if [[ -d "$dir/.git" ]]; then
    git -C "$dir" pull --ff-only
  else
    git clone --depth 1 "$url" "$dir"
  fi
}

# Curated by usefulness for this project workflow.
link_local_or_clone "sauria" "https://github.com/bsc-loca/sauria.git" "sauria"
link_local_or_clone "Tiny_LeViT_Hardware_Accelerator" "https://github.com/BoChen-Ye/Tiny_LeViT_Hardware_Accelerator.git" "tiny_levit_hw"
link_local_or_clone "Systolic-array-implementation-in-RTL-for-TPU" "https://github.com/abdelazeem201/Systolic-array-implementation-in-RTL-for-TPU.git" "rtl_tpu_ref"
link_local_or_clone "SystolicArray" "https://github.com/lllibano/SystolicArray.git" "systolic_array_exp"

# Optional heavy industrial clone for phase-2 studies.
if [[ "${INCLUDE_HEAVY:-0}" == "1" ]]; then
  link_local_or_clone "hw" "https://github.com/nvdla/hw.git" "nvdla_hw"
fi

echo "Reference repositories are ready in: $THIRD_PARTY_DIR"
