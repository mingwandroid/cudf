# Copyright (c) 2018-2019, NVIDIA CORPORATION.

# This assumes the script is executed from the root of the repo directory

# show environment
printenv
# Cleanup local git
git clean -xdf
mkdir -p thirdparty/libcudacxx/libcxx/include || true
cp thirdparty/libcudacxx/include/simt/type_traits thirdparty/libcudacxx/libcxx/include/type_traits
# build libnvstrings with verbose output
./build.sh -v libnvstrings --allgpuarch
