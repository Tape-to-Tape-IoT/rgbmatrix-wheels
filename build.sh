#!/usr/bin/env bash
# Build hzeller's rpi-rgb-led-matrix Python bindings as a wheel, at one commit.
#
# Runs as root in a debian:trixie arm64 container: the OS every scoreboard Pi runs,
# so the wheel links the same glibc and compiles against the same Pillow headers a
# Pi's own `uv sync --extra hardware` would. One wheel covers every 64-bit Pi —
# the library compiles the Pi 5 (RP1) backends in beside the classic GPIO path and
# picks one at runtime from the device tree.
#
# The build settings mirror nhl-led-scoreboard-v2's pyproject.toml ([tool.uv]
# config-settings-package); keep the two in step.
#
#   docker run --rm -v "$PWD:/work" debian:trixie /work/build.sh <upstream commit sha>
#
# Leaves dist/: the wheel, the exact source it was built from (GPL-2.0-or-later
# asks for that beside a binary), and SHA256SUMS.
set -euo pipefail

REV="${1:?usage: build.sh <upstream commit sha>}"
UPSTREAM=https://github.com/hzeller/rpi-rgb-led-matrix.git
cd "$(dirname "${BASH_SOURCE[0]}")"
OUT="$PWD/dist"
WORK="$(mktemp -d)"
SRC="$WORK/rpi-rgb-led-matrix"

# What setup_pi.sh apt-installs for the same build: the toolchain, Python.h, and
# python3-pil for the Imaging.h the bindings' Pillow shim includes.
echo "==> apt"
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq --no-install-recommends \
  build-essential python3-dev python3-pil git curl ca-certificates >/dev/null

echo "==> uv"
curl -LsSf https://astral.sh/uv/install.sh | env UV_INSTALL_DIR=/usr/local/bin UV_NO_MODIFY_PATH=1 sh

echo "==> source @ $REV"
git clone --quiet --filter=blob:none "$UPSTREAM" "$SRC"
git -C "$SRC" checkout --quiet "$REV"

echo "==> wheel"
rm -rf "$OUT" && mkdir -p "$OUT"
# The one setting the scoreboard passes, and only an include path: every panel
# option is set at runtime from [display], so nothing about the panel is baked in.
uv build --wheel --python /usr/bin/python3 \
  --config-setting 'cmake.define.CMAKE_C_FLAGS=-idirafter /usr/include/python3.13' \
  --out-dir "$OUT" "$SRC"

# The check setup_pi.sh makes: it imports, and has rp1_pio, which only a build
# with the Pi 5 support carries.
echo "==> check"
WHEEL="$(ls "$OUT"/rgbmatrix-*.whl)"
uv venv --quiet --python /usr/bin/python3 "$WORK/check"
uv pip install --quiet --python "$WORK/check/bin/python" "$WHEEL" pillow
"$WORK/check/bin/python" -c "import rgbmatrix; rgbmatrix.RGBMatrixOptions().rp1_pio"

git -C "$SRC" archive --format=tar.gz --prefix="rpi-rgb-led-matrix-$REV/" \
  -o "$OUT/rpi-rgb-led-matrix-$REV-src.tar.gz" "$REV"
(cd "$OUT" && sha256sum -- * > SHA256SUMS)

echo "==> done"
cat "$OUT/SHA256SUMS"
