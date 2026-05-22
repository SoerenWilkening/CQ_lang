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
