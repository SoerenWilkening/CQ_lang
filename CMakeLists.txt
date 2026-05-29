cmake_minimum_required(VERSION 3.20)
project(cq_lang C CXX)

set(CMAKE_C_STANDARD 11)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# Propagate -Wall -Wextra to every sub-build (warnings only, not -Werror,
# so pre-existing diagnostics in subprojects don't break the build today).
add_compile_options(-Wall -Wextra)

# LLVM 19's exported LLVMSupport target references zstd::libzstd_shared as
# an INTERFACE link dependency. On systems with libzstd1 but no libzstd-dev,
# CMake's target lookup fails when find_package(LLVM) is called. Provide a
# stub IMPORTED target so the lookup resolves; LLVMSupport here is built
# with USE_ZSTD=OFF so the runtime never calls into it. See the matching
# block in transpiler/CMakeLists.txt — kept there defensively for standalone
# configure of that subproject.
if(NOT TARGET zstd::libzstd_shared)
    find_library(ZSTD_RUNTIME_LIBRARY NAMES libzstd.so.1 zstd)
    add_library(zstd::libzstd_shared SHARED IMPORTED)
    if(ZSTD_RUNTIME_LIBRARY)
        set_target_properties(zstd::libzstd_shared PROPERTIES
            IMPORTED_LOCATION "${ZSTD_RUNTIME_LIBRARY}")
    else()
        set_target_properties(zstd::libzstd_shared PROPERTIES
            IMPORTED_LOCATION "/lib/x86_64-linux-gnu/libdl.so.2")
    endif()
endif()

# Find LLVM once; subprojects pick this up from the cache. The libtooling
# Clang dependency went away with the transpiler/ archive (see archive/);
# the active build (ir-pass/, runtime/, prototype/) uses only LLVM C++
# headers, so find_package(Clang) is no longer required.
find_package(LLVM CONFIG REQUIRED)
if(NOT LLVM_VERSION_MAJOR EQUAL 19)
    message(FATAL_ERROR "LLVM 19 required; found ${LLVM_VERSION_MAJOR}")
endif()
message(STATUS "cq_lang: using LLVM ${LLVM_PACKAGE_VERSION} from ${LLVM_DIR}")

enable_testing()

# Conditional add_subdirectory: only the bits with a CMakeLists.txt are
# wired in. The transpiler/ subdirectory was archived (see archive/transpiler/)
# under the taint-driven design — users write cq_* primitives directly,
# so the libtooling AST rewriter and the tools/cqc driver that orchestrated
# it are no longer part of the active build. The old tools/cqc-driven
# tests/e2e/ harness was archived alongside it (see archive/tests/e2e/); the
# taint-driven replacement (plain C + cq_* primitives → clang -O1 → opt
# cq-lowering → link → run) is wired in below at tests/e2e/.
if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/runtime/CMakeLists.txt")
    add_subdirectory(runtime)
endif()

# ir-pass: prefer the parent CMakeLists when issue -rum lands it; fall back
# to the existing test harness so ir-pass-shell/-lit are wired in today.
if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/ir-pass/CMakeLists.txt")
    add_subdirectory(ir-pass)
elseif(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/ir-pass/test/CMakeLists.txt")
    add_subdirectory(ir-pass/test)
endif()

# tests/frontend: LIT harness for the intrinsic-surface (clang) fixtures.
if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/tests/frontend/CMakeLists.txt")
    add_subdirectory(tests/frontend)
endif()

# tests/e2e: the taint-driven vertical slice (clang -O1 → opt cq-lowering →
# link → run, byte-diff vs golden). Placed AFTER the runtime and ir-pass
# blocks so the cq_runtime / cq_templates / CQPass targets exist when the
# $<TARGET_FILE:...> generator expressions resolve.
if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/tests/e2e/CMakeLists.txt")
    add_subdirectory(tests/e2e)
endif()
