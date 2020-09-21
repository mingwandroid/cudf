mkdir "%SRC_DIR%"\cpp\build
pushd "%SRC_DIR%"\cpp\build

cmake -G "Ninja" ^
      -DCMAKE_INSTALL_PREFIX="%LIBRARY_PREFIX%" ^
      -DARROW_DEPENDENCY_SOURCE=SYSTEM ^
      -DARROW_PACKAGE_PREFIX="%LIBRARY_PREFIX%" ^
      -DLLVM_TOOLS_BINARY_DIR="%LIBRARY_BIN%" ^
      -DPYTHON_EXECUTABLE="%PYTHON%" ^
      -DARROW_BOOST_USE_SHARED:BOOL=ON ^
      -DARROW_BUILD_TESTS:BOOL=OFF ^
      -DARROW_BUILD_UTILITIES:BOOL=OFF ^
      -DARROW_BUILD_STATIC:BOOL=OFF ^
      -DCMAKE_BUILD_TYPE=release ^
      -DARROW_SSE42:BOOL=OFF ^
      -DARROW_PYTHON:BOOL=ON ^
      -DARROW_FLIGHT:BOOL=ON ^
      -DARROW_PARQUET:BOOL=ON ^
      -DARROW_GANDIVA:BOOL=ON ^
      -DARROW_ORC:BOOL=ON ^
      -DARROW_WITH_BZ2:BOOL=ON ^
      -DBoost_NO_BOOST_CMAKE=ON ^
      ..

cmake --build . --target install --config Release

popd
