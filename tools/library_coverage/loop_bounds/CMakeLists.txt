# STANDALONE build for the loop-bound measurement plugin.
#
# *** DELIBERATELY NOT add_subdirectory()'d FROM THE TOP-LEVEL CMakeLists. ***
# This is measurement tooling, not product. Keeping it out of the main build is
# the whole reason it is safe to have in-tree: it cannot affect
# `cmake --build build`, it cannot affect ctest, and it cannot drift into the
# shipped plugin's dependency graph. If you ever feel like wiring it in, don't —
# file a ticket and argue it first.
#
#   cmake -S . -B build -DLLVM_DIR=$(brew --prefix llvm@19)/lib/cmake/llvm \
#         -DCMAKE_BUILD_TYPE=Release
#   cmake --build build -j8            # -> build/LoopBoundProbe.so
#
# NB `find_package(LLVM 19 ...)` FAILS here: LLVMConfig.cmake declares its
# version as 19.1.7 and rejects a bare "19" as incompatible. Use the unversioned
# form and pass LLVM_DIR, exactly as the top-level build does.
cmake_minimum_required(VERSION 3.20)
project(cq_loop_bound_probe CXX)

find_package(LLVM REQUIRED CONFIG)
list(APPEND CMAKE_MODULE_PATH "${LLVM_CMAKE_DIR}")
include(AddLLVM)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_EXTENSIONS OFF)

add_library(LoopBoundProbe MODULE LoopBoundProbe.cpp)
target_include_directories(LoopBoundProbe PRIVATE ${LLVM_INCLUDE_DIRS})
target_compile_definitions(LoopBoundProbe PRIVATE ${LLVM_DEFINITIONS})
set_target_properties(LoopBoundProbe PROPERTIES PREFIX "" SUFFIX ".so")

# Same discipline as the shipped plugin: a MODULE that does not link LLVM;
# symbols resolve from the host opt at dlopen.
if(APPLE)
  target_link_options(LoopBoundProbe PRIVATE -undefined dynamic_lookup)
endif()
