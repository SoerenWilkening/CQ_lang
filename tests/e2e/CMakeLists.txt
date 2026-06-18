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

# Phase 4.3 (WI-4, test_C_libtooling-s8yf.5): RSSA swap-routed depth-2
# homogeneous-PHASE NEST. The only layer that LINKS — and so the only proof the
# nested emitter's symbol set resolves and signature-matches across BOTH routing
# levels against the runtime (Rule 2, Rule 16; 4.3 adds no new runtime ABI, so
# this re-proves 4.1's symbols compose at depth 2). The §0 accept shape
# `if (q>5) { q=rz(q,.25); if (q<9) { q=rz(q,.75); } }` SURVIVES -O1 as the
# measured one-content-arm-diamond-inside-one-content-arm-diamond reconverging at
# a single 3-incoming merge phi, and lowers to the §5g routed stream: outer mint
# -> rail1 alloc -> outer route-in -> intervening rz on rail1 -> inner mint FROM
# RAIL1 -> rail2 alloc -> inner route-in -> inner rz -> inner route-back -> free
# rail2 -> STRIP f2 (BEFORE the outer route-back, the load-bearing §12.3 order)
# -> free f2 -> outer route-back -> free rail1 -> STRIP f1 -> free f1 -> measure
# q. EXACTLY FOUR frees (rail2, f2, rail1, f1); ZERO controlled gates, no
# cqrt_toffoli, no surviving `phi i32`, no added measure.
add_test(NAME e2e-slice-control-nested-phase
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_nested_phase.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_nested_phase.expected.log")

# ziov WI-1 (test_C_libtooling-ziov.1): the SHARED-CONDITION-FLAG path. A tainted
# control compare `q>5` reused as DATA (`int f = (q>5)`) lowers to ONE shared flag
# — the route AND the data `zext`/`add` read the same icmp handle, the flag is
# NEITHER stripped (no icmp_inv) NOR freed (its data lineage owns it). The only
# layer that LINKS, so it proves the shared flag's data consumers resolve against
# the runtime. EXACTLY ONE free (the rail); contrast slice_control_phase_diamond
# (no data use → strip + flag free, two frees).
add_test(NAME e2e-slice-control-cond-datause
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_cond_datause.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_cond_datause.expected.log")

# Phase 4.4 (WI-4, test_C_libtooling-polz.4): RSSA tainted-`select` controlled-XOR
# copy merge. The only layer that LINKS — and 4.4 adds a NEW runtime symbol, so
# this golden is the ONLY proof cqrt_copy_<W>_controlled (WI-2) resolves +
# signature-matches against libcq_runtime (Rule 2/16). The canonical §15 shape
# `sel = (q>5) ? q : x` SPECULATES at -O1 into a single `select` (no diamond, no
# phi) and lowers to the §5a merge stream: flag mint -> |0> out rail alloc ->
# cqrt_copy_i32_controlled the TRUE operand (q) on the flag -> X-bracket +
# cqrt_copy_i32_controlled the FALSE operand (x, materialized via cqrt_alloc) on
# ¬flag -> icmp_inv strip -> the ONE cqrt_free (the flag). q / out / the
# materialized scratch are LEFT ALLOCATED (freeing an operand entangled with out
# is a hidden measurement, Rule 6/8); ZERO cqrt_cswap, ZERO controlled rotations,
# no surviving `phi i32`, EXACTLY ONE free (contrast the method-B value diamond's
# two). control_swap_select_qc.ll is the pinned IR contract; IMPLEMENTATION-4.4 §5a.
add_test(NAME e2e-slice-control-select
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_select.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_select.expected.log")

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

# Phase 4.5 (WI-6, test_C_libtooling-bkpz.6): the RSSA swap-routed tainted SWITCH,
# one golden per ACCEPT class — the only layer that LINKS, so the only proof every
# symbol the four switch emit paths mint resolves + signature-matches against the
# runtime (Rule 2, Rule 16). PHASE switch (N>=3 cases): per-case eq-flag mint ->
# |0> rail -> cqrt_cswap route -> verbatim cqrt_rz arg-1 -> route back -> rail
# free -> icmp_eq_inv strip + flag free; the N>=3 byte-diff exercises the N-way
# folded-gate scrub + N-way flatten (the §5 const-fold re-anchor BLOCKER's only
# downstream backstop). control_swap_switch_phase.ll is the pinned IR contract.
add_test(NAME e2e-slice-control-switch-phase
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_switch_phase.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_switch_phase.expected.log")

# Phase 4.5 (WI-6): VALUE switch (N-way method-B on a shared routed base p != q):
# per-case route-in -> verbatim add chain -> route back, then ONE cqrt_copy_i32
# copy-out + LIFO reverse-play (route-back† · add `_inv` · route-in†) + rail/flag
# frees. control_swap_switch_value.ll is the pinned IR contract.
add_test(NAME e2e-slice-control-switch-value
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_switch_value.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_switch_value.expected.log")

# Phase 4.5 (WI-6): constant DATA-MUX switch (all-ConstantInt merge): preload
# %out = cqrt_alloc(v_d) + per-case XOR-delta cqrt_alloc(v_i^v_d) +
# cqrt_copy_i32_controlled. Non-contiguous cases + pre-init default keep the real
# `switch` (clang -O1 folds the natural contiguous const-mux to a select chain).
# control_swap_switch_datamux.ll is the pinned IR contract.
add_test(NAME e2e-slice-control-switch-datamux
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_switch_datamux.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_switch_datamux.expected.log")

# Phase 4.5 (WI-6): the equality-folded `br` diamond (`if (q==7) { phase arm }`) —
# the regression FLOOR for emitRegion-reuse via the additive D1-D7 tryEqFoldArm
# clause (§4D detection-only; re-tests the golden 4.1 diamond path end-to-end).
# control_swap_eqfold_diamond.ll is the pinned IR contract.
add_test(NAME e2e-slice-control-switch-eqfold
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_switch_eqfold.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_switch_eqfold.expected.log")

# Phase 5 (WI-6, test_C_libtooling-p2s2.6): the whole-DAG uncompute spine — the
# FIRST end-to-end proof of the void in-place `_unc` family + `cqrt_free`. The
# only layer that LINKS, so the only proof every `_unc` symbol the emitter mints
# (WI-3/WI-4) resolves AND signature-matches against the generated runtime ABI
# (WI-2) — the ir-pass fixtures assert IR text and never link. This slice caught
# the QQ `_unc` name disagreement (generator `..._qq_unc` vs emitter/bare-forward
# `..._unc`), invisible to FileCheck. TWO dead, unmeasured handles in a
# `noinline` helper (`noinline` is load-bearing: Phase-5 uncompute is gated OFF in
# `main`, and `-O1` would otherwise inline `slice` away so the uncompute never
# runs). `cq_phi` keeps the dead arithmetic alive past `-O1` DCE. Reverses the
# whole DAG ONCE in reverse program order: mul_qq `_unc` (bare, DD-3 slots) +
# two `_hl_unc` + Rz keep-alive undo (negated angle); SIX frees, one per rail,
# each after its last reverse-use; ZERO `_inv`, ZERO added measure, ZERO cswap.
add_test(NAME e2e-slice-uncompute-dead-dag
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_uncompute_dead_dag.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_uncompute_dead_dag.expected.log")

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
