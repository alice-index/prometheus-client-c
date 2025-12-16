#!/usr/bin/env bash

lib="$(dirname ${BASH_SOURCE[0]})"

source "${lib}/env.sh"
source "${lib}/output.sh"

# build all libraries
autolib_build() {
  local lib=$1
  local build_test=$2

  if [[ ! -d ${lib}/build ]]; then
    mkdir ${lib}/build || {
      autolib_output_error "Failed to create build directory"
      return 1
    }
  fi
  pushd ${lib}/build > /dev/null || return $?
    autolib_output_banner "${lib}: CMake Build Stage"
    # YOU MUST set TEST to 1 in order to build the tests
    # 检测 CMake 版本来决定是否使用 -v 参数
    cmake_version=$(cmake --version | head -n1 | grep -o '[0-9]\+\.[0-9]\+')
    # 简单版本比较：提取主版本号
    cmake_major=$(echo "$cmake_version" | cut -d. -f1)
    cmake_minor=$(echo "$cmake_version" | cut -d. -f2)
    if [[ "$cmake_major" -gt 3 ]] || [[ "$cmake_major" -eq 3 && "$cmake_minor" -ge 15 ]]; then
      # CMake 3.15+ 不支持 -v 参数
      TEST=$build_test cmake .. || {
        autolib_output_error "${lib}: CMake Failure"
        return 1
      }
    else
      # 旧版本 CMake 支持 -v 参数
      TEST=$build_test cmake -v .. || {
        autolib_output_error "${lib}: CMake Failure"
        return 1
      }
    fi
    autolib_output_banner "${lib}: Make Build Stage"
    make || {
      autolib_output_error "${lib} Make Failure"
      return 1
    }
  popd > /dev/null || return $?
}