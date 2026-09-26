cmake_minimum_required(VERSION 3.20)
project(cq_lang C CXX)

include(GNUInstallDirs)
include(CMakePackageConfigHelpers)

set(CMAKE_C_STANDARD 11)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# bd test_C_libtooling-a66j (Rule-13 r2 F-R2-2): `taintset-scrub-guard` parses
# `TaintPropagation.h` with a REAL build compile command read from this file (the
# CQPass one: its compiler, defines incl. `-DNDEBUG`, include paths, `-std`) — a
# guard that parsed with other flags missed a raw member inside `#ifdef NDEBUG`.
# ⚠ ONE configuration only: cq-opt compiles the same file without
# `-DCQPass_EXPORTS` (a known gap, bd test_C_libtooling-7gri).
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

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
# the active build (ir-pass/, runtime/) uses only LLVM C++
# headers, so find_package(Clang) is no longer required.
find_package(LLVM CONFIG REQUIRED)
if(NOT LLVM_VERSION_MAJOR EQUAL 19)
    message(FATAL_ERROR "LLVM 19 required; found ${LLVM_VERSION_MAJOR}")
endif()
message(STATUS "cq_lang: using LLVM ${LLVM_PACKAGE_VERSION} from ${LLVM_DIR}")

enable_testing()

# Keep the function-location index synchronized with source edits. The map is
# generated from maintained files, so this catches moved or added functions
# before an agent can hand off a stale navigation guide.
find_program(CQ_MAP_PYTHON NAMES python3 python REQUIRED)
add_test(
    NAME code_map_drift
    COMMAND ${CQ_MAP_PYTHON} ${CMAKE_SOURCE_DIR}/tools/update_code_map.py --check
)
add_test(
    NAME install_cq_unit
    COMMAND ${CQ_MAP_PYTHON} ${CMAKE_SOURCE_DIR}/tools/install_cq_test.py
)

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

# ---------------------------------------------------------------------------
# Installable compiler + backend contract.
#
# CQ's own runtime is deliberately the trace implementation.  A real backend
# supplies the same emitted C ABI and replaces cq_trace_backend at application
# link time.  tools/backend_contract.py fingerprints that ABI and verifies that
# a candidate archive defines the complete emit-capable symbol set.
# ---------------------------------------------------------------------------
set(_CQ_BACKEND_DESCRIPTOR
    "${CMAKE_CURRENT_BINARY_DIR}/cq-backend-contract.json")
execute_process(
    COMMAND "${CQ_MAP_PYTHON}" "${CMAKE_CURRENT_SOURCE_DIR}/tools/backend_contract.py"
            --root "${CMAKE_CURRENT_SOURCE_DIR}" describe
            --output "${_CQ_BACKEND_DESCRIPTOR}"
    RESULT_VARIABLE _CQ_BACKEND_DESCRIPTOR_RV
    ERROR_VARIABLE _CQ_BACKEND_DESCRIPTOR_ERR)
if(NOT _CQ_BACKEND_DESCRIPTOR_RV EQUAL 0)
    message(FATAL_ERROR
        "Could not generate the CQ backend ABI descriptor: "
        "${_CQ_BACKEND_DESCRIPTOR_ERR}")
endif()

if(TARGET cq_runtime AND TARGET cq_templates)
    set_target_properties(cq_runtime PROPERTIES EXPORT_NAME trace_runtime)
    set_target_properties(cq_templates PROPERTIES EXPORT_NAME trace_templates)
    set_target_properties(cq_trace_backend PROPERTIES EXPORT_NAME trace_backend)
    install(TARGETS cq_runtime cq_templates cq_trace_backend
            EXPORT CQTargets
            ARCHIVE DESTINATION "${CMAKE_INSTALL_LIBDIR}")

    add_test(
        NAME backend_contract_trace
        COMMAND "${CQ_MAP_PYTHON}"
                "${CMAKE_CURRENT_SOURCE_DIR}/tools/backend_contract.py"
                --root "${CMAKE_CURRENT_SOURCE_DIR}" check
                --archive "$<TARGET_FILE:cq_templates>"
                --archive "$<TARGET_FILE:cq_runtime>")
    add_test(
        NAME backend_contract_reject_incomplete
        COMMAND "${CQ_MAP_PYTHON}"
                "${CMAKE_CURRENT_SOURCE_DIR}/tools/backend_contract.py"
                --root "${CMAKE_CURRENT_SOURCE_DIR}" check
                --archive "$<TARGET_FILE:cq_runtime>")
    set_tests_properties(backend_contract_reject_incomplete PROPERTIES
        WILL_FAIL TRUE)
endif()

if(TARGET CQPass)
    set_target_properties(CQPass PROPERTIES EXPORT_NAME lowering_pass)
    install(TARGETS CQPass EXPORT CQTargets
            LIBRARY DESTINATION "${CMAKE_INSTALL_LIBDIR}/cq")
endif()

if(TARGET cq-opt)
    install(TARGETS cq-opt RUNTIME DESTINATION "${CMAKE_INSTALL_BINDIR}")
endif()

install(FILES "${CMAKE_CURRENT_SOURCE_DIR}/include/CQ.h"
        DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}")
install(FILES
        "${CMAKE_CURRENT_SOURCE_DIR}/runtime/cq_runtime.h"
        "${CMAKE_CURRENT_SOURCE_DIR}/runtime/cq_templates.h"
        "${CMAKE_CURRENT_SOURCE_DIR}/runtime/cq_intrinsic_templates.h"
        "${CMAKE_CURRENT_SOURCE_DIR}/runtime/cq_libm_templates.h"
        DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}/cq/backend")
install(FILES
        "${CMAKE_CURRENT_SOURCE_DIR}/tools/opcode_table.yaml"
        "${CMAKE_CURRENT_SOURCE_DIR}/tools/intrinsic_table.yaml"
        "${CMAKE_CURRENT_SOURCE_DIR}/tools/libm_table.yaml"
        "${_CQ_BACKEND_DESCRIPTOR}"
        DESTINATION "${CMAKE_INSTALL_DATADIR}/cq/abi")
install(PROGRAMS
        "${CMAKE_CURRENT_SOURCE_DIR}/tools/backend_contract.py"
        DESTINATION "${CMAKE_INSTALL_BINDIR}"
        RENAME cq-backend-contract)
install(PROGRAMS
        "${CMAKE_CURRENT_SOURCE_DIR}/tools/cqc"
        DESTINATION "${CMAKE_INSTALL_BINDIR}")
install(FILES "${CMAKE_CURRENT_SOURCE_DIR}/docs/backend-provider.md"
        DESTINATION "${CMAKE_INSTALL_DATADIR}/doc/cq")

configure_package_config_file(
    "${CMAKE_CURRENT_SOURCE_DIR}/cmake/CQConfig.cmake.in"
    "${CMAKE_CURRENT_BINARY_DIR}/CQConfig.cmake"
    INSTALL_DESTINATION "${CMAKE_INSTALL_LIBDIR}/cmake/CQ")
write_basic_package_version_file(
    "${CMAKE_CURRENT_BINARY_DIR}/CQConfigVersion.cmake"
    VERSION 0.1.0
    COMPATIBILITY SameMajorVersion)
install(FILES
        "${CMAKE_CURRENT_BINARY_DIR}/CQConfig.cmake"
        "${CMAKE_CURRENT_BINARY_DIR}/CQConfigVersion.cmake"
        DESTINATION "${CMAKE_INSTALL_LIBDIR}/cmake/CQ")
install(EXPORT CQTargets
        FILE CQTargets.cmake
        NAMESPACE CQ::
        DESTINATION "${CMAKE_INSTALL_LIBDIR}/cmake/CQ")

add_test(
    NAME package_install_trace
    COMMAND "${CMAKE_COMMAND}"
            -Dcq_source_dir=${CMAKE_CURRENT_SOURCE_DIR}
            -Dcq_build_dir=${CMAKE_CURRENT_BINARY_DIR}
            -Dcq_install_libdir=${CMAKE_INSTALL_LIBDIR}
            -Dcq_config=$<CONFIG>
            -P ${CMAKE_CURRENT_SOURCE_DIR}/tests/package-consumer/run_test.cmake)
