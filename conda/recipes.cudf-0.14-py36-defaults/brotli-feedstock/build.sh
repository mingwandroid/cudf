#!/bin/bash

set -e

BROTLI_CFLAGS="-O3"
BROTLI_CXXFLAGS="-O3"

# Build both static and shared libraries
cmake -DCMAKE_INSTALL_PREFIX=$PREFIX \
      -DCMAKE_INSTALL_LIBDIR=$PREFIX/lib \
      -DCMAKE_C_FLAGS=$BROTLI_CFLAGS \
      -DCMAKE_CXX_FLAGS=$BROTLI_CXXFLAGS

make -j${CPU_COUNT}
ctest -V
make install
