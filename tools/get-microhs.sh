#!/usr/bin/env bash
# Fetch and build MicroHs (https://github.com/augustss/MicroHs, MIT) —
# the compiler that turns hs/NowNext.hs into hs-wasm/now-next.comb for
# the in-browser "Right now λ" panel. Pinned to the commit the vendored
# hs-wasm/mhseval.js evaluator was taken from (comb format v8.4).
#
# Downloads via the Go module proxy, which serves zips of public GitHub
# repos — handy in environments where github.com itself is unreachable.
set -euo pipefail
cd "$(dirname "$0")/.."

PIN='v0.0.0-20260719110154-f3e149958233'
DEST='hs/.microhs'

if [ -x "$DEST/bin/mhs" ]; then echo "mhs already built at $DEST/bin/mhs"; exit 0; fi

mkdir -p "$DEST"
curl -sS --fail -o "$DEST/src.zip" \
  "https://proxy.golang.org/github.com/augustss/!micro!hs/@v/$PIN.zip"
python3 -m zipfile -e "$DEST/src.zip" "$DEST/unzip/"
SRC="$DEST/unzip/github.com/augustss/MicroHs@$PIN"
mkdir -p "$DEST/bin"
cc -O2 -I"$SRC/src/runtime" -I"$SRC/src/runtime/unix" \
  "$SRC/src/runtime/main.c" "$SRC/src/runtime/eval.c" "$SRC/generated/mhs.c" \
  -lm -o "$DEST/bin/mhs"
ln -sfn "unzip/github.com/augustss/MicroHs@$PIN" "$DEST/root"
rm "$DEST/src.zip"
"$DEST/bin/mhs" --version
echo "built $DEST/bin/mhs (MHSDIR=$DEST/root)"
