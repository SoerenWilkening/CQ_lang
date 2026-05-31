cmake_minimum_required(VERSION 3.13)
project(cq_pass CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

# Configure with:
#   cmake -DLLVM_DIR=/usr/lib/llvm-19/lib/cmake/llvm -B build .
# (LLVM_DIR pins the version; we don't need find_package's version selector.)
find_package(LLVM REQUIRED CONFIG)

if(NOT LLVM_VERSION_MAJOR EQUAL 19)
  message(FATAL_ERROR "Expected LLVM 19, found ${LLVM_VERSION_MAJOR}")
endif()

message(STATUS "Found LLVM ${LLVM_PACKAGE_VERSION}")
message(STATUS "LLVMConfig.cmake: ${LLVM_DIR}")
message(STATUS "Include dirs: ${LLVM_INCLUDE_DIRS}")

include_directories(SYSTEM ${LLVM_INCLUDE_DIRS})

separate_arguments(LLVM_DEFINITIONS_LIST NATIVE_COMMAND ${LLVM_DEFINITIONS})
add_compile_definitions(${LLVM_DEFINITIONS_LIST})

if(NOT LLVM_ENABLE_RTTI)
  add_compile_options(-fno-rtti)
endif()

# Build the pass plugin as a shared module.
# We do NOT link against LLVM libraries: opt/clang already provides them at
# load time. This is the standard out-of-tree pass-plugin pattern (Polly,
# Enzyme, AddressSanitizer all do the same thing).
add_library(cq_pass MODULE cq_pass.cpp)
target_compile_features(cq_pass PRIVATE cxx_std_17)
