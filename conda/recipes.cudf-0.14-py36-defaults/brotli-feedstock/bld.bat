set CMAKE_CONFIG=Release

mkdir build_shared_%CMAKE_CONFIG%
pushd build_shared_%CMAKE_CONFIG%

cmake -G "NMake Makefiles" ^
      -DCMAKE_PREFIX_PATH="%LIBRARY_PREFIX%" ^
      -DCMAKE_INSTALL_PREFIX="%LIBRARY_PREFIX%" ^
      -DCMAKE_BUILD_TYPE:STRING=%CMAKE_CONFIG% ^
      "%SRC_DIR%"
if errorlevel 1 exit 1
nmake
if errorlevel 1 exit 1
ctest -V
if errorlevel 1 exit 1
cmake --build . --target install
if errorlevel 1 exit 1
