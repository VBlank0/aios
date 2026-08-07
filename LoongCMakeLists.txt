cmake_minimum_required(VERSION 3.10)

# 1. 强制设定为龙芯交叉编译架构（必须在 project 前）
set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR loongarch64)

# 2. 绑定在 Debian 容器中自动识别的最新版 GCC 交叉编译器
set(CMAKE_C_COMPILER loongarch64-linux-gnu-gcc)
set(CMAKE_CXX_COMPILER loongarch64-linux-gnu-g++)


# 3. 项目名称
project(loongarch64)

# 4. 引入头文件目录和源文件
include_directories(Inc)
set(SOURCES
)

# 5. 生成可执行文件（注意 loongarch64 和 ${SOURCES} 之间必须有空格！）
add_executable(debug ${SOURCES})
