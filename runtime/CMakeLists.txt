# runtime/CMakeLists.txt — Phase 1 trace-only runtime.
#
# Builds libcq_runtime as a static library (PRD §6: trace-only stubs,
# e2e tests link the host binary against this). C11, propagates -Wall
# -Wextra from the top-level CMakeLists.txt.
#
# Spec: phases/phase1/PLAN.md §4.3.

add_library(cq_runtime STATIC
    cq_runtime.c
)

target_include_directories(cq_runtime PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}
)

add_library(cq_templates STATIC
    cq_templates.c
)

target_include_directories(cq_templates PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}
)

target_link_libraries(cq_templates PUBLIC cq_runtime)

# M2 acceptance gate (bd issue -oln). test_trace drives the API and the
# ctest target diffs its stdout against the golden trace, pinning the
# format before the IR pass or e2e fixtures begin to consume it.
add_executable(runtime_trace_test test_trace.c)
target_link_libraries(runtime_trace_test PRIVATE cq_templates cq_runtime)

add_test(
    NAME runtime_trace_test
    COMMAND bash -c "$<TARGET_FILE:runtime_trace_test> | diff -u - ${CMAKE_CURRENT_SOURCE_DIR}/test_trace.expected.log"
)

# Phase 3 M3 acceptance gate (bd issue -84m). The generated cq_templates.h
# carries 680 extern decls but only 14 have bodies today (Phase 2's hand-
# written stubs); the rest land with M4. To verify the header itself parses
# clean under the strict warning set without forcing a link step, we build
# test_header_compile.c into an OBJECT library — compilation is exercised,
# linking is not. The ctest entry drives `cmake --build` against that
# object library, so the test passes iff the header compiles warning-free
# under -Wall -Wextra -Wpedantic -Werror. The strict flags live only on
# this target (root CMakeLists ships -Wall -Wextra without -Werror, per
# its comment on line 9-11).
#
# Spec: phases/phase3/PLAN.md §4.3.
add_library(runtime_header_compile_obj OBJECT test_header_compile.c)
target_include_directories(runtime_header_compile_obj PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}
)
target_compile_options(runtime_header_compile_obj PRIVATE
    -Wall -Wextra -Wpedantic -Werror
)

# Aggregate convenience target so callers can `cmake --build . --target
# runtime_header_compile` to force a rebuild before running ctest.
add_custom_target(runtime_header_compile
    DEPENDS runtime_header_compile_obj
)

add_test(
    NAME runtime_header_compile
    COMMAND ${CMAKE_COMMAND} --build ${CMAKE_BINARY_DIR}
            --target runtime_header_compile_obj
)
