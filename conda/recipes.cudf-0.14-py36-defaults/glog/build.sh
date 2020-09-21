#!/bin/bash

mkdir build_release
cd build_release

cmake ..  \
    -G "Unix Makefiles" \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_PREFIX_PATH="${PREFIX}" \
    -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
    -DCMAKE_INSTALL_LIBDIR=lib \
    -DINSTALL_HEADERS=1 \
    -DBUILD_SHARED_LIBS=1 \
    -DBUILD_STATIC_LIBS=1 \
    -DBUILD_TESTING=1
make
make test || { cat Testing/Temporary/LastTest.log; exit 1; }
make install

