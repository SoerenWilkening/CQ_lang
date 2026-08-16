# LIT + FileCheck harness for the cq-lowering pass plugin (libCQPass.so).
# Standalone configure must succeed even without the parent build, so this
# CMakeLists.txt can be configured on its own as a smoke check.

cmake_minimum_required(VERSION 3.20)

# When configured standalone (no parent project), declare a project so
# enable_testing() / add_test() have somewhere to register against.
if(NOT CMAKE_PROJECT_NAME)
  project(cq_irpass_tests NONE)
endif()

enable_testing()

# LLVM is needed only to locate FileCheck/opt and the bundled lit.py; we
# accept either a pre-set LLVM_DIR or LLVM_TOOLS_BINARY_DIR from the parent.
if(NOT DEFINED LLVM_TOOLS_BINARY_DIR)
  find_package(LLVM CONFIG QUIET)
endif()

# Resolve `opt` (binary names vary across LLVM packaging). This STOCK opt stays
# the reference for the cq-opt-equivalence gate below and is the fallback when
# the cq-opt target is unavailable; it is no longer what the fixtures run.
find_program(CQ_OPT_STOCK
  NAMES opt opt-19
  HINTS ${LLVM_TOOLS_BINARY_DIR}
)

# What `%cq-opt` in a RUN line actually expands to. Every fixture runs the SAME
# `-passes=cq-lowering` pipeline and the pass takes ~5ms, so stock opt's 0.238s
# of fixed per-spawn cost (dyld-binding 140MB of libLLVM.dylib + static
# initializers for every component and target backend) dominated the layer at
# ~1087 spawns. cq-opt links only what the pass needs and costs 0.124s.
# Fixtures keep passing `-load-pass-plugin %cq-pass`, which cq-opt accepts and
# ignores — so RUN lines are IDENTICAL under either binary and the fallback
# below is a genuine drop-in, not a different test.
if(TARGET cq-opt)
  set(CQ_OPT_EXECUTABLE "$<TARGET_FILE:cq-opt>")
else()
  set(CQ_OPT_EXECUTABLE "${CQ_OPT_STOCK}")
endif()

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

# Decide path: real LIT if (a) LIT resolved, (b) FileCheck present, (c) the
# CQPass target exists, and (d) there is at least one *.ll test file (LIT
# returns non-zero when it discovers nothing, which would break ctest until
# test_C_libtooling-345 lands the test fixtures).
file(GLOB _ll_tests "${CMAKE_CURRENT_SOURCE_DIR}/*.ll")
set(_use_lit FALSE)
if(CQ_LIT_INVOCATION AND CQ_FILECHECK_EXECUTABLE AND TARGET CQPass AND _ll_tests)
  set(_use_lit TRUE)
endif()

if(_use_lit)
  message(STATUS "ir-pass/test: using LIT (${CQ_LIT_INVOCATION})")
  # Generate lit.site.cfg.py from the template. Generator expressions in
  # CQ_PASS_PLUGIN resolve at build-time via file(GENERATE).
  set(CQ_PASS_PLUGIN "$<TARGET_FILE:CQPass>")
  set(CQ_TEST_SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}")
  set(CQ_TEST_BINARY_DIR "${CMAKE_CURRENT_BINARY_DIR}")
  configure_file(
    "${CMAKE_CURRENT_SOURCE_DIR}/lit.site.cfg.py.in"
    "${CMAKE_CURRENT_BINARY_DIR}/lit.site.cfg.py.gen"
    @ONLY)
  file(GENERATE
    OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/lit.site.cfg.py"
    INPUT  "${CMAKE_CURRENT_BINARY_DIR}/lit.site.cfg.py.gen")
  add_test(
    NAME ir-pass-lit
    COMMAND ${CQ_LIT_INVOCATION} -v "${CMAKE_CURRENT_BINARY_DIR}"
  )

  # The equivalence gate for the %cq-opt swap. ir-pass-lit above runs `cq-opt`,
  # not stock `opt`; this replays every fixture through BOTH and compares
  # stdout, stderr and exit code. Without it, a pass change that made the two
  # diverge would leave the suite green while testing a tool that is no longer
  # the tool — and 520 negative fixtures assert on diagnostic TEXT, so "same
  # exit code" is nowhere near sufficient. See tools/cq_opt_equivalence.py.
  # Resolve python independently: Python3_EXECUTABLE above is only set inside
  # the lit-detection branches, so it cannot be relied on here.
  find_program(CQ_EQUIV_PYTHON NAMES python3 python)
  if(CQ_OPT_STOCK AND TARGET cq-opt AND CQ_EQUIV_PYTHON)
    # ROUTINE entry: a strided SAMPLE. The full sweep spawns 2 processes per
    # fixture and costs ~658s of CPU — MORE than the cq-opt swap saves — so
    # paying it on every `ctest` would make the optimisation self-defeating.
    # A stride-8 sample is ~128 fixtures / ~13s and still crosses every fixture
    # family. Note what already backs it up: ir-pass-lit itself runs cq-opt over
    # ALL 1051 fixtures and asserts stdout, stderr and exit code, so a divergence
    # is only invisible if it still satisfies the CHECK patterns. This sample is
    # the cheap tripwire for that narrow residue.
    add_test(
      NAME cq-opt-equivalence
      COMMAND "${CQ_EQUIV_PYTHON}" "${CMAKE_SOURCE_DIR}/tools/cq_opt_equivalence.py"
              --opt "${CQ_OPT_STOCK}"
              --cq-opt "$<TARGET_FILE:cq-opt>"
              --plugin "$<TARGET_FILE:CQPass>"
              --fixtures "${CMAKE_CURRENT_SOURCE_DIR}"
              --stride 8
    )
    # FULL sweep, on demand: `cmake --build build --target cq-opt-equivalence-full`.
    # Run it after ANY change to the pass's diagnostic surface or analysis usage
    # — that is where cq-opt and stock opt could drift apart.
    add_custom_target(cq-opt-equivalence-full
      COMMAND "${CQ_EQUIV_PYTHON}" "${CMAKE_SOURCE_DIR}/tools/cq_opt_equivalence.py"
              --opt "${CQ_OPT_STOCK}"
              --cq-opt "$<TARGET_FILE:cq-opt>"
              --plugin "$<TARGET_FILE:CQPass>"
              --fixtures "${CMAKE_CURRENT_SOURCE_DIR}"
              --stride 1
      DEPENDS cq-opt CQPass
      COMMENT "cq-opt vs stock opt: full 1051-fixture equivalence sweep")
  endif()
else()
  # Fallback: shell-grep loop. Same correctness, less diagnostic polish.
  if(NOT CQ_LIT_INVOCATION)
    message(STATUS "ir-pass/test: LIT not found — using shell fallback")
  elseif(NOT CQ_FILECHECK_EXECUTABLE)
    message(STATUS "ir-pass/test: FileCheck not found — using shell fallback")
  elseif(NOT TARGET CQPass)
    message(STATUS "ir-pass/test: CQPass target not present — using shell fallback")
  elseif(NOT _ll_tests)
    message(STATUS "ir-pass/test: no *.ll fixtures yet — using shell fallback (auto-passes empty)")
  endif()
  if(TARGET CQPass)
    set(_pass_so "$<TARGET_FILE:CQPass>")
  else()
    # Standalone configure: leave the path empty; the script reports skip.
    set(_pass_so "")
  endif()
  if(NOT CQ_OPT_EXECUTABLE)
    set(CQ_OPT_EXECUTABLE "opt-19")
  endif()
  add_test(
    NAME ir-pass-shell
    COMMAND "${CMAKE_CURRENT_SOURCE_DIR}/run_shell_tests.sh"
            "${CMAKE_CURRENT_SOURCE_DIR}"
            "${_pass_so}"
            "${CQ_OPT_EXECUTABLE}"
  )
endif()
