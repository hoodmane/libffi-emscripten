#!/usr/bin/env bash
emcc_exists="$(command -v emcc)"
if [ ! "${emcc_exists}" ]; then
  echo "Emscripten not on path"
  exit 1
fi

set -e

cd "$1"
export CFLAGS="-fPIC -O2 -I../../target/include $EXTRA_CFLAGS"
export CXXFLAGS="-fPIC -I../../target/include -sNO_DISABLE_EXCEPTION_CATCHING -g3 $EXTRA_CFLAGS"
export LDFLAGS=" \
    -sEXPORT_ALL \
    -sMODULARIZE \
    -sMAIN_MODULE \
    -L../../target/lib/ -lffi \
    -sEXPORTED_RUNTIME_METHODS='getTempRet0' \
    -sSTRICT_JS \
    -sNO_DISABLE_EXCEPTION_CATCHING \
    -g3 \
    $EXTRA_LD_FLAGS \
"

# This needs to test false if there exists an environment variable called
# WASM_BIGINT whose contents are empty. Don't use +x.
if [ -n "${WASM_BIGINT}" ]; then
  export LDFLAGS+=" -sWASM_BIGINT"
fi

# Rename main functions to test__filename so we can link them together
find . -name './*c' | sed 's!\(.*\)\.c!sed -i "s/main/test__\1/g" \0!g' | bash

# Compile
find . -name './*.c' | sed 's/\(.*\)\.c/emcc $CFLAGS -c \1.c -o \1.o /g' | bash
find . -name './*.cc' | sed 's/\(.*\)\.cc/em++ $CXXFLAGS -c \1.cc -o \1.o /g' | bash

# Link
em++ $LDFLAGS ./*.o -o test.js
cp ../emscripten/test.html .
