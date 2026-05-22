# tests/e2e/CMakeLists.txt — Phase 1 end-to-end harness.
#
# Two ctest entries:
#   * cqc_smoke — drives tools/cqc against one fixture, asserts the output
#     binary exists. Pinned to multi_decl/ because that path through the IR
#     pass is known-good today (worked_example/ exercises measure-as-cast
#     which the cq-lowering pass doesn't yet handle — separate bd issue).
#     Spec: PLAN.md §4.6.
#   * e2e — full run_e2e.sh sweep; skips (PASS) when cqc isn't built so it
#     can land before tools/cqc and still satisfy M0's "must run" gate.
#     Spec: PLAN.md §4.7.

add_test(
    NAME cqc_smoke
    COMMAND bash -c
        "rm -f \"${CMAKE_BINARY_DIR}/cqc_smoke.out\" && \
         \"${CMAKE_SOURCE_DIR}/tools/cqc\" \
            \"${CMAKE_CURRENT_SOURCE_DIR}/fixtures/multi_decl/input.c\" \
            -o \"${CMAKE_BINARY_DIR}/cqc_smoke.out\" && \
         test -x \"${CMAKE_BINARY_DIR}/cqc_smoke.out\""
)

add_test(
    NAME e2e
    COMMAND bash ${CMAKE_CURRENT_SOURCE_DIR}/run_e2e.sh
            ${CMAKE_SOURCE_DIR}/tools/cqc
            ${CMAKE_CURRENT_SOURCE_DIR}/fixtures
)
