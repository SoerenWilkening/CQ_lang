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
  src/AbortParkEmit.cpp
  src/AngleSelectEmit.cpp
  src/ArithLowering.cpp
  src/ArmClassify.cpp
  src/ArmHomogeneity.cpp
  src/BennettWrap.cpp
  src/BreakReversePlay.cpp
  src/ByRefInline.cpp
  src/CastLowering.cpp
  src/ChainWalk.cpp
  src/ClassicalCallArmEmit.cpp
  src/CompareLowering.cpp
  src/CondLiteral.cpp
  src/CondTreeEmit.cpp
  src/CondTreeStrip.cpp
  src/ControlDetect.cpp
  src/ControlledSymbols.cpp
  src/CtlzIdiomPrepass.cpp
  src/DagTraversal.cpp
  src/GuardedStoreArmEmit.cpp
  # bd xdu2.8: the arm-guarded classical runtime-VLA read (PredMux E4 (1d)).
  src/GuardedClassicalRead.cpp
  src/CQLoweringPass.cpp
  src/EmitInverse.cpp
  src/EqFoldArm.cpp
  src/Fp80Union.cpp
  src/FreePoint.cpp
  src/IntrinsicLowering.cpp
  src/IOSinkLowering.cpp
  src/LiteralIntegrity.cpp
  src/LoopLowering.cpp
  src/LoopUnrollPrepass.cpp
  src/MeasureLowering.cpp
  src/MergePhiPeel.cpp
  src/PoisonFacts.cpp
  src/OpcodeLowering.cpp
  src/OpcodeSupport.cpp
  src/Plugin.cpp
  src/PredMuxFlatten.cpp
  src/QramLowering.cpp
  # bd xdu2 / L-1a: the rail-bank per-activation promoter (clause C5).
  src/RailBankPromote.cpp
  src/RegionFlatten.cpp
  src/RegionTreeDetect.cpp
  src/RotationLowering.cpp
  src/SelectClassify.cpp
  src/SelectMergeEmit.cpp
  src/Specialization.cpp
  src/SpecializeClone.cpp
  src/SpecializeDetect.cpp
  src/SpecializeReject.cpp
  src/SpecializeSeed.cpp
  src/SwapRouteEmit.cpp
  src/SwitchArmProve.cpp
  src/SwitchClassify.cpp
  src/SwitchDataMuxEmit.cpp
  src/SwitchRouteEmit.cpp
  src/SwitchValueEmit.cpp
  src/TaintPropagation.cpp
  src/TemplateName.cpp
  src/Uncomputation.cpp
  src/WidthDispatch.cpp
  src/WireWalk.cpp
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

# ---------------------------------------------------------------------------
# cq-opt — purpose-built driver for the ONE pipeline this project ever runs.
#
# MEASURED: every `opt` invocation in the tree (1087 in ir-pass-lit + 2 per e2e
# slice) runs the identical `-passes=cq-lowering`, and the pass itself takes
# ~5ms. Generic `opt` costs 0.238s of FIXED per-spawn cost (dyld-binding the
# 140MB libLLVM.dylib plus static initializers for every LLVM component and
# target backend it links). That is ~50x the useful work, ~1330 times a run.
#
# Linking ONLY the components the pass needs, statically, halves it: cq-opt's
# fixed cost is 0.124s. Same pass code, same LLVM, one process per invocation —
# so lit's isolation model, per-fixture diagnostics and `not` exit-code
# inversion are all unchanged. This is NOT a compile server; nothing is shared
# between invocations.
#
# EQUIVALENCE IS GATED, NOT ASSUMED: tools/cq_opt_equivalence.py replays all
# 1069 fixtures through both binaries and compares stdout, stderr AND exit code
# (0 mismatches at introduction). It is wired as the `cq-opt-equivalence` ctest
# entry so a future pass change cannot silently make the two diverge — which
# matters because 579 negative fixtures FileCheck the diagnostic TEXT, not just
# the exit status.
#
# Sources come from the CQPass target so the two can never drift apart.
# Plugin.cpp comes along harmlessly: llvmGetPassPluginInfo is simply unused
# here, since the pass is linked in rather than dlopen'd.
get_target_property(_CQ_PASS_SOURCES CQPass SOURCES)
add_executable(cq-opt tools/cq_opt_main.cpp ${_CQ_PASS_SOURCES})
target_include_directories(cq-opt PRIVATE
  "${CMAKE_CURRENT_SOURCE_DIR}/include" ${LLVM_INCLUDE_DIRS})
target_compile_features(cq-opt PRIVATE cxx_std_17)
target_compile_definitions(cq-opt PRIVATE ${LLVM_DEFINITIONS})
llvm_map_components_to_libnames(_CQ_OPT_LLVM_LIBS
  core irreader passes analysis transformutils bitwriter support)
target_link_libraries(cq-opt PRIVATE ${_CQ_OPT_LLVM_LIBS})

# cq-opt-debugalloc (bd test_C_libtooling-8e5r / -um24): cq-opt's OWN object
# files re-linked with tools/cq_debug_alloc.cpp, the TEST-ONLY allocator
# (`CQ_OPT_DEBUG_ALLOC=lifo|nofree`) that makes a dangling-key alias — or a
# stale-key dereference — DETERMINISTIC instead of a lottery. A SEPARATE binary
# on purpose: replacing the global operator new/delete costs ~5 ms of launch CPU
# even with the variable unset (measured, dyld/static-init), and `%cq-opt` runs
# ~3000 times a lit run, so the harness's default driver stays exactly as it
# was. Same objects, so the pass code under test is the pass code `%cq-opt`
# runs; lit spells it `%debugalloc-cq-opt`. Not a CQPass source: the plugin
# every user loads never contains it. Costs one extra link, no recompile.
add_executable(cq-opt-debugalloc tools/cq_debug_alloc.cpp $<TARGET_OBJECTS:cq-opt>)
add_dependencies(cq-opt-debugalloc cq-opt)
target_compile_features(cq-opt-debugalloc PRIVATE cxx_std_17)
target_link_libraries(cq-opt-debugalloc PRIVATE ${_CQ_OPT_LLVM_LIBS})

# cq-scrub-selftest (bd test_C_libtooling-8e5r / -um24 / -j8sk): the deterministic
# per-member pin of `include/ScrubOnDelete.h` over every pointer-keyed member of
# `cq::TaintSet` — header-only subject, one TU, LLVM core+support. Run twice:
# under `lifo` (address reuse REQUIRED, so the aliasing branch is never vacuous)
# and under the system allocator (the shipped allocation path).
add_executable(cq-scrub-selftest tools/scrub_selftest.cpp tools/cq_debug_alloc.cpp)
target_include_directories(cq-scrub-selftest PRIVATE
  "${CMAKE_CURRENT_SOURCE_DIR}/include" ${LLVM_INCLUDE_DIRS})
target_compile_features(cq-scrub-selftest PRIVATE cxx_std_17)
target_compile_definitions(cq-scrub-selftest PRIVATE ${LLVM_DEFINITIONS})
llvm_map_components_to_libnames(_CQ_SELFTEST_LLVM_LIBS core support)
target_link_libraries(cq-scrub-selftest PRIVATE ${_CQ_SELFTEST_LLVM_LIBS})
add_test(NAME ir-pass-scrub-on-delete-selftest-lifo COMMAND cq-scrub-selftest)
set_tests_properties(ir-pass-scrub-on-delete-selftest-lifo
  PROPERTIES ENVIRONMENT "CQ_OPT_DEBUG_ALLOC=lifo")
add_test(NAME ir-pass-scrub-on-delete-selftest-sysalloc COMMAND cq-scrub-selftest)
set_tests_properties(ir-pass-scrub-on-delete-selftest-sysalloc
  PROPERTIES ENVIRONMENT "CQ_OPT_DEBUG_ALLOC=")
# The STRUCTURAL half: no raw pointer-bearing member may be (re)added to
# `cq::TaintSet`, and every self-cleaning one must be exercised by the selftest
# above. A pure-Python record gate; `--selftest` is its own mutant validation.
find_program(CQ_SCRUB_GUARD_PYTHON NAMES python3 python)
if(CQ_SCRUB_GUARD_PYTHON)
  add_test(NAME taintset-scrub-guard
    COMMAND "${CQ_SCRUB_GUARD_PYTHON}" "${CMAKE_CURRENT_SOURCE_DIR}/../tools/taintset_scrub_guard.py")
  add_test(NAME taintset-scrub-guard-selftest
    COMMAND "${CQ_SCRUB_GUARD_PYTHON}" "${CMAKE_CURRENT_SOURCE_DIR}/../tools/taintset_scrub_guard.py" --selftest)
endif()

# LIT/FileCheck harness for the pass. Lives in test/ alongside the *.ll
# fixtures from issue -345; gated on the CQPass target existing (which it
# now does), so the harness will switch from shell fallback to real LIT
# when llvm-lit + FileCheck are present.
if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/test/CMakeLists.txt")
  add_subdirectory(test)
endif()
