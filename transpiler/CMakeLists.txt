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

# P0 only needs to build and print help, but link the libtooling
# libraries we will rely on in later phases so misconfiguration of the
# dev install shows up here instead of in P2+.
add_executable(quantum_transpiler src/main.cpp)
target_link_libraries(quantum_transpiler
    PRIVATE
        clangTooling
        clangFrontend
        clangAST
        clangBasic
        LLVMSupport
)

enable_testing()

# Smoke test: the help-printing binary exits 0.
add_test(NAME smoke_help COMMAND quantum_transpiler --help)

# `cmake --build <build> --target check-quantum` runs the whole test
# suite (today: smoke_help; later: unit + e2e).
add_custom_target(check-quantum
    COMMAND ${CMAKE_CTEST_COMMAND} --output-on-failure
    WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
    USES_TERMINAL
)
