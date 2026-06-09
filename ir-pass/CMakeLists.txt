# ir-pass/CMakeLists.txt — productionized CQ lowering pass plugin.
#
# Builds the CQPass shared module (libCQPass.so), an opt-loadable pass
# plugin that registers exactly one pass: `cq-lowering`. The pass itself
# lives in src/CQLoweringPass.cpp; the registration shim lives in
# src/Plugin.cpp; the public header is include/CQLoweringPass.h.

# Standalone-configure support: if invoked without the top-level CMake,
# replicate the LLVM lookup so the directory still configures.
if(NOT CMAKE_PROJECT_NAME)
  cmake_minimum_required(VERSION 3.20)
  project(cq_irpass CXX)
  set(CMAKE_CXX_STANDARD 17)
  set(CMAKE_CXX_STANDARD_REQUIRED ON)
  set(CMAKE_POSITION_INDEPENDENT_CODE ON)
  find_package(LLVM REQUIRED CONFIG)
  if(NOT LLVM_VERSION_MAJOR EQUAL 19)
    message(FATAL_ERROR "LLVM 19 required; found ${LLVM_VERSION_MAJOR}")
  endif()
  message(STATUS "ir-pass (standalone): using LLVM ${LLVM_PACKAGE_VERSION}")
  include_directories(SYSTEM ${LLVM_INCLUDE_DIRS})
  separate_arguments(LLVM_DEFINITIONS_LIST NATIVE_COMMAND ${LLVM_DEFINITIONS})
  add_compile_definitions(${LLVM_DEFINITIONS_LIST})
  if(NOT LLVM_ENABLE_RTTI)
    add_compile_options(-fno-rtti)
  endif()
  enable_testing()
else()
  # Parent configure already ran find_package(LLVM). Pick up its include
  # path and definitions explicitly so this subbuild doesn't depend on a
  # global include_directories() from the parent.
  include_directories(SYSTEM ${LLVM_INCLUDE_DIRS})
  separate_arguments(LLVM_DEFINITIONS_LIST NATIVE_COMMAND ${LLVM_DEFINITIONS})
  add_compile_definitions(${LLVM_DEFINITIONS_LIST})
  if(NOT LLVM_ENABLE_RTTI)
    add_compile_options(-fno-rtti)
  endif()
endif()

# Out-of-tree pass-plugin convention: build as a MODULE library, do NOT
# link against LLVM — opt/clang provide the symbols at dlopen time. Polly,
# Enzyme, and the sanitizers all follow this pattern.
add_library(CQPass MODULE
  src/ArithLowering.cpp
  src/ArmClassify.cpp
  src/CastLowering.cpp
  src/ChainWalk.cpp
  src/CompareLowering.cpp
  src/ControlDetect.cpp
  src/ControlledSymbols.cpp
  src/CQLoweringPass.cpp
  src/EmitInverse.cpp
  src/FreePoint.cpp
  src/MeasureLowering.cpp
  src/OpcodeLowering.cpp
  src/OpcodeSupport.cpp
  src/Plugin.cpp
  src/RotationLowering.cpp
  src/TaintPropagation.cpp
  src/TemplateName.cpp
  src/Uncomputation.cpp
  src/WidthDispatch.cpp
)

target_include_directories(CQPass PUBLIC
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
)
target_compile_features(CQPass PRIVATE cxx_std_17)
set_target_properties(CQPass PROPERTIES POSITION_INDEPENDENT_CODE ON)

# macOS: ld is strict about undefined symbols even for MODULE libraries.
# The pass plugin gets its LLVM symbols from the host process (opt /
# clang) at dlopen time, so allow dynamic lookup. Linux's ld silently
# permits this by default, so no flag needed there. Same idiom as
# Polly, Enzyme, and the LLVM sanitizers.
if(APPLE)
  target_link_options(CQPass PRIVATE "LINKER:-undefined,dynamic_lookup")
endif()

# LIT/FileCheck harness for the pass. Lives in test/ alongside the *.ll
# fixtures from issue -345; gated on the CQPass target existing (which it
# now does), so the harness will switch from shell fallback to real LIT
# when llvm-lit + FileCheck are present.
if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/test/CMakeLists.txt")
  add_subdirectory(test)
endif()
