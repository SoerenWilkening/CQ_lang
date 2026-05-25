cmake_minimum_required(VERSION 3.20)
project(quantum_transpiler CXX C)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# LLVM 19's exported LLVMSupport target references zstd::libzstd_shared
# as an INTERFACE link dependency. On this environment libzstd1 is
# installed (so the runtime symbol is present) but libzstd-dev is not,
# so CMake can't locate the .so symlink and the import fails. LLVMSupport
# is built with USE_ZSTD=OFF here, so we just need to satisfy CMake's
# target lookup with a stub IMPORTED target whose only effect is to link
# the available libzstd.so.1 if it is ever actually pulled in.
if(NOT TARGET zstd::libzstd_shared)
    find_library(ZSTD_RUNTIME_LIBRARY NAMES libzstd.so.1 zstd)
    add_library(zstd::libzstd_shared SHARED IMPORTED)
    if(ZSTD_RUNTIME_LIBRARY)
        set_target_properties(zstd::libzstd_shared PROPERTIES
            IMPORTED_LOCATION "${ZSTD_RUNTIME_LIBRARY}")
    else()
        # Pretend it's the runtime loader; LLVMSupport won't actually
        # call any symbols from it for our P0 build.
        set_target_properties(zstd::libzstd_shared PROPERTIES
            IMPORTED_LOCATION "/lib/x86_64-linux-gnu/libdl.so.2")
    endif()
endif()

# Locate the LLVM/Clang dev install. Callers can override on the
# command line: -DLLVM_DIR=... -DClang_DIR=...
find_package(LLVM CONFIG REQUIRED)
find_package(Clang CONFIG REQUIRED)

message(STATUS "Found LLVM ${LLVM_PACKAGE_VERSION}")
message(STATUS "  LLVM_INCLUDE_DIRS:  ${LLVM_INCLUDE_DIRS}")
message(STATUS "  CLANG_INCLUDE_DIRS: ${CLANG_INCLUDE_DIRS}")
message(STATUS "  Using LLVMConfig.cmake in: ${LLVM_DIR}")

# LLVM/Clang headers; SYSTEM so their warnings don't pollute our build.
include_directories(SYSTEM ${LLVM_INCLUDE_DIRS} ${CLANG_INCLUDE_DIRS})

# Mirror LLVM's preprocessor flags (e.g. -D__STDC_CONSTANT_MACROS) so
# the headers parse the way they were built.
separate_arguments(LLVM_DEFINITIONS_LIST NATIVE_COMMAND ${LLVM_DEFINITIONS})
add_definitions(${LLVM_DEFINITIONS_LIST})

# Library target — all reusable transpiler logic lives here so it can
# be linked into both the driver executable and the unit-test binary.
add_library(quantum_transpiler_lib STATIC
    src/TypeMap.cpp
    src/QuantumAttr.cpp
    src/SourceText.cpp
    src/OperandClass.cpp
    src/Codegen.cpp
    src/DeclStmtRewrite.cpp
    src/CastRewrite.cpp
    src/Matcher.cpp
)
target_include_directories(quantum_transpiler_lib PUBLIC src)
target_link_libraries(quantum_transpiler_lib
    PUBLIC
        clangTooling
        clangFrontend
        clangAST
        clangASTMatchers
        clangBasic
        clangRewrite
        LLVMSupport
)

# Driver executable: just main, links the library for everything else.
add_executable(quantum_transpiler src/main.cpp)
target_link_libraries(quantum_transpiler PRIVATE quantum_transpiler_lib)

enable_testing()

# Smoke test: invoking the driver with `--help` causes CommonOptionsParser
# to print LLVM's libtooling USAGE banner. The exit code is not portable
# across LLVM versions (some print + exit 0, others exit non-zero), so
# we assert only on the banner text via PASS_REGULAR_EXPRESSION.
add_test(NAME smoke_help COMMAND quantum_transpiler --help)
set_tests_properties(smoke_help PROPERTIES
    PASS_REGULAR_EXPRESSION "USAGE"
)

# Unit tests: GoogleTest binary linking the transpiler library.
find_package(GTest REQUIRED)
add_executable(quantum_transpiler_unit_tests
    tests/unit/test_type_map.cpp
    tests/unit/test_source_text.cpp
    tests/unit/test_operand_class.cpp
    tests/unit/test_codegen.cpp
    tests/unit/test_decl_stmt_rewrite.cpp
    tests/unit/test_cast_rewrite.cpp
    tests/unit/test_cq_mid_compiles.cpp
)
# test_cq_mid_compiles.cpp #include's <cq_mid.h> from the repo-root
# include/ dir (the transpiled-C ABI surface; not normally consumed by
# C++ sources). cqc threads the same dir in via -I at clang time
# (tools/cqc line 101); here we add it explicitly for the test target.
target_include_directories(quantum_transpiler_unit_tests
    PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}/../include
)
target_link_libraries(quantum_transpiler_unit_tests
    PRIVATE
        quantum_transpiler_lib
        GTest::gtest
        GTest::gtest_main
)
add_test(NAME unit_tests COMMAND quantum_transpiler_unit_tests)

# End-to-end fixtures: invoke the transpiler on each input.c under
# tests/e2e/fixtures and diff stdout against the matching expected.c.
add_test(
    NAME e2e_fixtures
    COMMAND ${CMAKE_CURRENT_SOURCE_DIR}/tests/e2e/run_e2e.sh
            $<TARGET_FILE:quantum_transpiler>
            ${CMAKE_CURRENT_SOURCE_DIR}/tests/e2e/fixtures
)

# Note: the legacy v1 `acceptance` ctest target (which ran
# tests/e2e/acceptance.sh against repo-root example_v1.c / qint.h) was
# retired when those inputs were removed in d3f9290. Full-pipeline
# coverage for Phase 1 lives in the top-level tests/e2e/run_e2e.sh
# harness (registered as the `e2e` and `cqc_smoke` ctests).

# `cmake --build <build> --target check-quantum` runs the whole test
# suite (today: smoke_help; later: unit + e2e).
add_custom_target(check-quantum
    COMMAND ${CMAKE_CTEST_COMMAND} --output-on-failure
    WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
    USES_TERMINAL
)
