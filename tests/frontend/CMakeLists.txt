# LIT + FileCheck harness for the CQ frontend (intrinsic-surface) tests.
# These fixtures are plain C files that drive clang directly (no pass
# plugin): each RUN line compiles a .c through clang's -emit-llvm and pipes
# the IR through FileCheck. The dependency surface is therefore just
# clang + FileCheck + lit — there is no shell fallback.
#
# Standalone configure must succeed even without the parent build, so this
# CMakeLists.txt can be configured on its own as a smoke check. Two things are
# needed for the STANDALONE form to actually run the suite (both measured
# 2026-09-05, bd test_C_libtooling-3qlq.1):
#   * pass -DLLVM_TOOLS_BINARY_DIR=<llvm>/bin, NOT -DLLVM_DIR=... . The
#     standalone project() below declares no languages, so LLVMConfig.cmake's
#     compiler probes hard-error ("check_source_compiles: CXX: needs to be
#     enabled before use"). LLVM_TOOLS_BINARY_DIR skips find_package entirely.
#   * CQ_INCLUDE_FLAG is derived from this file's location when
#     CMAKE_SOURCE_DIR has no include/ (see below) — standalone it is this
#     directory, and every fixture used to fail with
#     "fatal error: 'CQ.h' file not found".

cmake_minimum_required(VERSION 3.20)

# When configured standalone (no parent project), declare a project so
# enable_testing() / add_test() have somewhere to register against.
if(NOT CMAKE_PROJECT_NAME)
  project(cq_frontend_tests NONE)
endif()

enable_testing()

# LLVM is needed only to locate clang/FileCheck and the bundled lit.py; we
# accept either a pre-set LLVM_DIR or LLVM_TOOLS_BINARY_DIR from the parent.
if(NOT DEFINED LLVM_TOOLS_BINARY_DIR)
  find_package(LLVM CONFIG QUIET)
endif()

# Resolve `clang` (binary names vary across LLVM packaging). Versioned name
# comes first on Debian/Ubuntu installs.
find_program(CQ_CLANG_EXECUTABLE
  NAMES clang-19 clang
  HINTS ${LLVM_TOOLS_BINARY_DIR}
)

# Resolve `FileCheck`. Versioned name comes first on Debian/Ubuntu installs.
find_program(CQ_FILECHECK_EXECUTABLE
  NAMES FileCheck FileCheck-19
  HINTS ${LLVM_TOOLS_BINARY_DIR}
)

# Resolve LIT. Search order: PATH binary, then bundled lit.py inside the
# LLVM install (Debian ships it under build/utils/lit/), then Python module.
find_program(CQ_LIT_EXECUTABLE NAMES llvm-lit lit)

set(CQ_LIT_INVOCATION "")
if(CQ_LIT_EXECUTABLE)
  set(CQ_LIT_INVOCATION "${CQ_LIT_EXECUTABLE}")
else()
  set(_lit_py_candidates "")
  if(LLVM_VERSION_MAJOR)
    list(APPEND _lit_py_candidates
      "/usr/lib/llvm-${LLVM_VERSION_MAJOR}/build/utils/lit/lit.py")
  endif()
  list(APPEND _lit_py_candidates
    "/usr/lib/llvm-19/build/utils/lit/lit.py"
    "/usr/lib/llvm-18/build/utils/lit/lit.py")
  foreach(_cand IN LISTS _lit_py_candidates)
    if(EXISTS "${_cand}")
      set(CQ_LIT_PY_SCRIPT "${_cand}" CACHE FILEPATH "Bundled lit.py")
      break()
    endif()
  endforeach()
  if(CQ_LIT_PY_SCRIPT)
    find_package(Python3 COMPONENTS Interpreter QUIET)
    if(Python3_Interpreter_FOUND)
      set(CQ_LIT_INVOCATION "${Python3_EXECUTABLE};${CQ_LIT_PY_SCRIPT}")
    endif()
  endif()
  if(NOT CQ_LIT_INVOCATION)
    # Last resort: try `python3 -m lit`. May fail; we'll verify below.
    find_package(Python3 COMPONENTS Interpreter QUIET)
    if(Python3_Interpreter_FOUND)
      execute_process(
        COMMAND "${Python3_EXECUTABLE}" -c "import lit"
        RESULT_VARIABLE _lit_module_rv
        OUTPUT_QUIET ERROR_QUIET)
      if(_lit_module_rv EQUAL 0)
        set(CQ_LIT_INVOCATION "${Python3_EXECUTABLE};-m;lit")
      endif()
    endif()
  endif()
endif()

# The frontend harness requires real LIT + FileCheck + clang. Unlike the
# ir-pass harness there is no shell fallback: bail out loudly if any of the
# three is missing rather than silently degrading.
if(NOT CQ_LIT_INVOCATION)
  message(FATAL_ERROR "tests/frontend: could not resolve LIT (no llvm-lit/lit, no bundled lit.py, no `python3 -m lit`)")
endif()
if(NOT CQ_FILECHECK_EXECUTABLE)
  message(FATAL_ERROR "tests/frontend: could not resolve FileCheck")
endif()
if(NOT CQ_CLANG_EXECUTABLE)
  message(FATAL_ERROR "tests/frontend: could not resolve clang")
endif()

message(STATUS "tests/frontend: using LIT (${CQ_LIT_INVOCATION})")

# We invoke lit through a thin Python wrapper (run_lit.py) so an empty suite
# is tolerated. The lit shipped with LLVM 19 has no --allow-empty-suite, and
# --allow-empty-runs only covers the filter-matched-nothing case, not the
# discovered-nothing case — yet this scaffold lands with zero *.c fixtures.
# The wrapper rewrites lit's empty-discovery exit to success and forwards
# every other exit verbatim. A Python interpreter is therefore required; it is
# already present whenever lit is resolved via the bundled lit.py, but resolve
# it explicitly so the llvm-lit-on-PATH branch works too.
find_package(Python3 COMPONENTS Interpreter REQUIRED)
set(CQ_LIT_RUNNER
  "${Python3_EXECUTABLE}"
  "${CMAKE_CURRENT_SOURCE_DIR}/run_lit.py"
  ${CQ_LIT_INVOCATION})

# Generate lit.site.cfg.py from the template. CQ_INCLUDE_FLAG carries the
# absolute -I flag for the CQ header directory so RUN lines using
# `-include CQ.h` resolve without spelling out the path themselves.
#
# Under the PARENT build CMAKE_SOURCE_DIR is the repo root and the first branch
# is taken, byte-for-byte as before. Under a STANDALONE configure it is THIS
# directory, which has no include/ — fall back to this file's own location.
if(EXISTS "${CMAKE_SOURCE_DIR}/include/CQ.h")
  set(CQ_INCLUDE_FLAG "-I${CMAKE_SOURCE_DIR}/include")
else()
  get_filename_component(CQ_REPO_INCLUDE_DIR
    "${CMAKE_CURRENT_SOURCE_DIR}/../../include" ABSOLUTE)
  set(CQ_INCLUDE_FLAG "-I${CQ_REPO_INCLUDE_DIR}")
endif()
set(CQ_TEST_SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}")
set(CQ_TEST_BINARY_DIR "${CMAKE_CURRENT_BINARY_DIR}")
configure_file(
  "${CMAKE_CURRENT_SOURCE_DIR}/lit.site.cfg.py.in"
  "${CMAKE_CURRENT_BINARY_DIR}/lit.site.cfg.py"
  @ONLY)

# Register the LIT suite as a ctest. The wrapper keeps this green while there
# are zero *.c fixtures: lit discovers .c files at run-time, so the same
# registration auto-runs new fixtures with no re-configure needed.
add_test(
  NAME frontend-lit
  COMMAND ${CQ_LIT_RUNNER} -v "${CMAKE_CURRENT_BINARY_DIR}"
)

# Convenience target: `cmake --build <build> --target check-frontend` runs
# the same lit invocation the frontend-lit ctest uses.
add_custom_target(check-frontend
  COMMAND ${CQ_LIT_RUNNER} -v "${CMAKE_CURRENT_BINARY_DIR}"
  WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}"
  COMMENT "Running CQ frontend LIT suite"
  USES_TERMINAL)
