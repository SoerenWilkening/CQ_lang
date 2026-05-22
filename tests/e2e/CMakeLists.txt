# tests/e2e/CMakeLists.txt — Phase 1 end-to-end harness.
#
# Registers a single ctest named `e2e` that drives run_e2e.sh over every
# fixture directory under fixtures/. The runner skips (PASS) when the cqc
# shell driver is not yet built, so this test can land before tools/cqc
# (bd issue -rm8) and still satisfy M0's "may fail, just must run" gate.
#
# Spec: phases/phase1/PLAN.md §4.7.

add_test(
    NAME e2e
    COMMAND bash ${CMAKE_CURRENT_SOURCE_DIR}/run_e2e.sh
            ${CMAKE_SOURCE_DIR}/tools/cqc
            ${CMAKE_CURRENT_SOURCE_DIR}/fixtures
)
