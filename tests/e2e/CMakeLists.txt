# tests/e2e/CMakeLists.txt — Phase 2 end-to-end vertical slice.
#
# The only test layer that LINKS — it proves every symbol the pass emits
# resolves and is signature-correct against the runtime + template libs.
# Tools come from LLVM_TOOLS_BINARY_DIR (set by the root find_package(LLVM));
# the plugin and libs are resolved via generator expressions so the test
# tracks the just-built artifacts.
set(_E2E_CLANG "${LLVM_TOOLS_BINARY_DIR}/clang")
set(_E2E_OPT   "${LLVM_TOOLS_BINARY_DIR}/opt")

# Phase 2 canonical slice: theta -> add_hl -> measure.
add_test(NAME e2e-slice-theta-add-measure
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_theta_add_measure.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_theta_add_measure.expected.log")

# Phase 3 (WP6): Q+Q and Q+C arithmetic across the HH/HL/LH operand shapes,
# pinning the post-O1 opcode stream (mul HH, add_hl, sub_lh, shl_lh).
add_test(NAME e2e-slice-qq-hl-arith
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_qq_hl_arith.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_qq_hl_arith.expected.log")

# Phase 3 (WP6): data-position icmp/fcmp measured through the zext flag-handle
# bridge (compare -> zext_i1_to_i32 -> cqrt_measure_i32).
add_test(NAME e2e-slice-compare-measure
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_compare_measure.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_compare_measure.expected.log")

# Phase 4.1 (WI-4): RSSA swap-routed PHASE-arm diamond. The only layer that
# LINKS — it proves every symbol the swap-route emitter mints (the icmp flag
# template + its `_hl_inv` strip, cqrt_cswap, the |0> rail alloc/free, the
# verbatim arm rz) resolves and signature-matches against the runtime. Tainted
# `if (q>5) { rz(q,a); rz(q,b); }` lowers to the pinned routed stream (§5a):
# flag mint -> rail alloc -> cswap in -> verbatim rz -> cswap back -> rail free
# -> icmp_inv flag-strip -> flag free; ZERO controlled gates, exactly two frees.
add_test(NAME e2e-slice-control-phase-diamond
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_phase_diamond.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_phase_diamond.expected.log")

# Phase 4.1 follow-on (test_C_libtooling-9hh): two-arm PHASE if/else routing a
# DERIVED base (a pre-region cq_phi result). Links the dual-rail §5b stream —
# both rails, the cqrt_x ¬flag bracket, and the pre-region cqrt_rz that must
# precede the flag mint — against the runtime. The arms are asymmetric (2 vs 1
# gates) deliberately: symmetric one-gate arms canonicalize at -O1 into the
# 4.4-deferred tainted ANGLE SELECT, which declines (Rule 9).
add_test(NAME e2e-slice-control-phase-ifelse-derived
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_phase_ifelse_derived.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_phase_ifelse_derived.expected.log")

# Phase 4.2 (WI-6, test_C_libtooling-paj.6): RSSA swap-routed VALUE-arm diamond
# (method-B). The only layer that LINKS — and 4.2 adds a NEW runtime symbol, so
# this golden is the ONLY proof cqrt_copy_i32 resolves + signature-matches
# against libcq_runtime (Rule 2/16). The 6-op linear chain `if (q>5) { p=p+3;
# p=p*5; p=p^9; p=p+1; p=p*7; p=p^2; }` SURVIVES -O1 as a clean br-diamond (a
# short arm folds to a tainted SELECT — 4.4-deferred, PRD §8.4); clang
# reassociates the constants, so the golden pins the POST-reassociation method-B
# stream (§5d): flag mint -> |0> rail -> cswap in -> chain verbatim -> cswap
# back -> cqrt_copy_i32 (sole basis copy) -> R-dagger (route-back-dagger,
# reversed _inv chain, route-in-dagger) -> rail free -> icmp_inv strip -> flag
# free. EXACTLY TWO frees (rail + flag); out and the restored source p are never
# freed; ZERO controlled gates, no surviving `phi i32`.
add_test(NAME e2e-slice-control-value-diamond
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_value_diamond.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_value_diamond.expected.log")

# test_C_libtooling-5j5: the ONE-REGISTER classical-mux lift. The natural
# `if (classical_c) q = cq_phi(q, a);` survives -O1 as a merge phi over two
# SSA names of one register; the lift RAUWs it away and the CLASSICAL branch
# stays byte-untouched, so the rz fires iff the condition held this shot.
# Goldens BOTH polarities in one run (argc>0 true / argc>100 false): the
# taken diamond's rz appears, the not-taken diamond's does not.
add_test(NAME e2e-slice-classical-if-gate
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_classical_if_gate.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_classical_if_gate.expected.log")

# NOTE: the Phase-4 controlled-form e2e slices (control-gate / control-merge /
# control-mux-mixed / control-mux-handles) were removed with the old
# controlled-op lowering on the `swap-route-control` branch. The RSSA swap-route
# control emitter re-adds e2e coverage for tainted control flow when it lands.

# Convenience target: build the prerequisites, then run every e2e slice.
add_custom_target(check-e2e
  COMMAND ${CMAKE_CTEST_COMMAND} -R "^e2e-" --output-on-failure
  DEPENDS CQPass cq_runtime cq_templates
  USES_TERMINAL
  COMMENT "Running e2e vertical slices")
