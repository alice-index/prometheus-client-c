#!/bin/bash

set -e

# 获取当前项目根目录
PROJECT_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
BUILD_DIR="${PROJECT_ROOT}/build"
INCLUDE_DIR="${BUILD_DIR}/include"
LIB_DIR="${BUILD_DIR}/lib"
META_FILE="${PROJECT_ROOT}/lib_meta.json"

# 定义一个极短的临时打包目录 (解决路径过长问题)
SHORT_TEMP_DIR="/tmp/pcc_build"

echo "=== 开始处理 prometheus-client-c ==="

# ---------------------------------------------------------
# 1. 归档文件 (逻辑保持不变)
# ---------------------------------------------------------

# 清理并创建目录
rm -rf "${BUILD_DIR}"
mkdir -p "${INCLUDE_DIR}"
mkdir -p "${LIB_DIR}"

echo "复制库文件..."
# 依然保留你的 cp 逻辑 (复制实体文件没问题)
if [ -f "${PROJECT_ROOT}/prom/build/libprom.so" ]; then
    cp "${PROJECT_ROOT}/prom/build/libprom.so" "${LIB_DIR}/"
else
    echo "错误: 未找到 libprom.so"
    exit 1
fi

if [ -f "${PROJECT_ROOT}/promhttp/build/libpromhttp.so" ]; then
    cp "${PROJECT_ROOT}/promhttp/build/libpromhttp.so" "${LIB_DIR}/"
else
    echo "错误: 未找到 libpromhttp.so"
    exit 1
fi

echo "复制头文件..."
cp "${PROJECT_ROOT}"/prom/include/*.h "${INCLUDE_DIR}/"
cp "${PROJECT_ROOT}"/promhttp/include/*.h "${INCLUDE_DIR}/"

# ---------------------------------------------------------
# 2. 读取配置并打包 (核心修复)
# ---------------------------------------------------------

if [ ! -f "$META_FILE" ]; then
    echo "错误: 未找到 lib_meta.json"
    exit 1
fi

# 提取版本号
VERSION=$(grep '"version":' "$META_FILE" | head -n 1 | sed -E 's/.*"version": "([^"]+)".*/\1/' | sed 's/,//g')

if [ -z "$VERSION" ]; then
    echo "错误: 版本号提取失败"
    exit 1
fi

echo "读取版本号: ${VERSION}"

# === [关键修改] ===
# 将 build 目录的内容复制到 /tmp/pcc_build
# 这样打包工具看到的路径就是 /tmp/pcc_build/include/... (非常短)
# 从而规避 write too long 错误

echo "准备打包环境 (移动到临时目录)..."
rm -rf "${SHORT_TEMP_DIR}"
cp -r "${BUILD_DIR}" "${SHORT_TEMP_DIR}"

echo "开始打包..."
# 必须回到项目根目录执行，因为工具要读取当前目录下的 lib_meta.json
cd "${PROJECT_ROOT}"

# 指向临时目录打包
lib-pkg-mgr package -f "${SHORT_TEMP_DIR}" -v "${VERSION}"

PACK_RESULT=$?

# 清理临时目录
rm -rf "${SHORT_TEMP_DIR}"

if [ $PACK_RESULT -eq 0 ]; then
    echo "打包成功: ${PROJECT_ROOT}/build/prometheus-client-c_${VERSION}.tar.gz"
else
    echo "打包失败"
    exit 1
fi