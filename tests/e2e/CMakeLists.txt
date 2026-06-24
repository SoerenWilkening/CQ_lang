# tests/e2e/CMakeLists.txt — Phase 2 end-to-end vertical slice.
#
# The only test layer that LINKS — it proves every symbol the pass emits
# resolves and is signature-correct against the runtime + template libs.
# Tools come from LLVM_TOOLS_BINARY_DIR (set by the root find_package(LLVM));
# the plugin and libs are resolved via generator expressions so the test
# tracks the just-built artifacts.
set(_E2E_CLANG "${LLVM_TOOLS_BINARY_DIR}/clang")
set(_E2E_OPT   "${LLVM_TOOLS_BINARY_DIR}/opt")
# Phase 6 (DD-6 §7.2): llvm-link for the multi-file harness run_slice_multi.sh,
# mirroring _E2E_CLANG/_E2E_OPT (C19). Resolves to the same LLVM-19 toolchain
# (/usr/local/opt/llvm@19/bin/llvm-link). NOTE: new add_test entries require a
# cmake re-configure — e2e does not auto-discover (unlike the lit .ll fixtures).
set(_E2E_LLVM_LINK "${LLVM_TOOLS_BINARY_DIR}/llvm-link")

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

# Phase 7.1 (8rvn, iw81.4 §4.4): the UNORDERED fcmp predicates lower, link, and
# trace end-to-end. Negated relational compares (`!(x>=k)`->ult, etc.) and
# `__builtin_isunordered`->uno, which Clang -O1 folds straight to the unordered
# twins, now resolve against the regenerated `cq_template_fcmp_<pred>_f32_hl`
# surface (this is the only layer that LINKS).
add_test(NAME e2e-slice-fcmp-unordered
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_fcmp_unordered.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_fcmp_unordered.expected.log")

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

# Phase 7.2 Increment 3 (test_C_libtooling-65wb.3): the controlled abort/exit PARK
# CASCADE (PRD-7.2 §2.8). `if (q > 5) abort();` lowers to flag mint -> graveyard
# cqrt_cswap -> cqrt_tape_write_i1 (the abort marker) -> uncontrolled remainder.
# The ONLY layer that links the park sequence; the golden proves the graveyard +
# flag are KEPT (NO cqrt_free anywhere — the §2-A GraveyardRails do-not-uncompute
# set, subtracted at both spine sites) and the abort call is erased.
add_test(NAME e2e-slice-control-abort
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_abort.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_abort.expected.log")

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

# Phase 7.1 Increment C (test_C_libtooling-sbt1.3): the N-ARY (N>2) one-register
# classical-mux lift. The natural classical N-way `switch` around an in-place
# quantum gate on ONE register survives -O1 as a `switch` with a single merge phi
# whose >2 incomings are distinct SSA names of the one register; the generalized
# lift (the (7a) reachability proof carried against ALL j != i, not just the 2-way
# complement) RAUWs it away and the CLASSICAL switch stays byte-untouched, so each
# case's cqrt_rz fires iff that case ran this shot. DISTINCT per-case gate-chain
# lengths (1/2/1/0) keep clang from merging the cases into one angle-selected
# block, preserving the N>2 phi; the executed case is the 2-gate chain
# (sel=(argc+1)%4=2), goldening the single-block-chain proof (condition (6)) for a
# REAL chain. A second register on the DEFAULT arm goldens the no-case-fires path.
# The only layer that LINKS — it re-proves the lifted N-ary form lowers to the
# phi-less rz-inside-the-case stream the pipeline already accepts (Increment C
# adds NO new symbol).
add_test(NAME e2e-slice-classical-switch-gate
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_classical_switch_gate.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_classical_switch_gate.expected.log")

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

# Phase 5 (WI-7, test_C_libtooling-p2s2.7): the permanent `_unc` LINK-COMPLETENESS
# guard for the shapes slice_uncompute_dead_dag does NOT exercise. WI-6 linked only
# the bare-QQ + `_hl` `_unc` forms; the `_lh`, tainted-cast, and `fneg` `_unc`
# symbols were link-probed ad-hoc during WI-6 but never committed, so a
# generator/emitter name or signature drift in any of those three families would be
# invisible to every test (the .ll fixtures assert IR text and never link — Rule
# 2/16). Three independent dead lineages in a `noinline` helper, each kept alive by
# a `(void) cq_phi`: (A) `100 - a` / `5 << s` -> sub_i32_lh_unc + shl_i32_lh_unc;
# (B) `(long) b` -> sext_i32_to_i64_unc; (C) `-fc` -> fneg_f32_unc. Whole-DAG LIFO
# reversal (chain C, then B, then A): each gate adjointed via its void `_unc` form
# (DD-3 slots: out first, then forward operands in original order), 7 frees (one per
# rail), Rz/Ry undone with negated angles; ZERO `_inv`, ZERO added measure, ZERO
# cqrt_cswap. Together with dead-dag, every `_unc` shape the emitter can mint is now
# permanently link-proven by SOME golden.
add_test(NAME e2e-slice-uncompute-dead-shapes
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_uncompute_dead_shapes.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_uncompute_dead_shapes.expected.log")

# Phase 7.1 Increment A (test_C_libtooling-sbt1.1): the Q+Q (both-operands-
# tainted) DATA-position compare. The only layer that LINKS, so the only proof
# that BOTH the bare-QQ forward `cq_template_icmp_<pred>_i32(i32, i32)` AND its
# void `_unc` twin `cq_template_icmp_<pred>_i32_unc(out, a, b)` resolve and
# signature-match against the generated runtime ABI (Rule 2, Rule 16; the .ll
# fixtures assert IR text and never link). Increment A adds NO new symbol — the
# QQ compare machinery (fwd/_unc, DagTraversal two-parent recovery, WidthDispatch
# QQ resolver) already existed end-to-end; A only feeds it a width recovered from
# `HandleWidth`, so this golden re-proves the bare-QQ compare grid composes. Two
# independent Q+Q lineages in a `noinline` helper (`noinline` is LOAD-BEARING —
# whole-DAG uncompute is gated OFF in `main`): (A) a MEASURED `xi < yi`
# (icmp_slt QQ -> zext bridge -> measure) proves the forward symbol; (B) a DEAD,
# `cq_phi`-kept-alive `pi == qi` (icmp_eq QQ) proves the `_unc` twin — the spine
# reverses it ONCE (zext_unc -> icmp_eq_unc -> ry undos) and frees each rail,
# with NO added measure, NO `_inv`, NO cqrt_cswap.
add_test(NAME e2e-slice-compare-qq
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_compare_qq.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_compare_qq.expected.log")

# Phase 7.1 Increment D (FROZEN ABI): the half-precision (f16) e2e link proof.
# The only layer that LINKS, so the only proof that the new frozen f16 symbols
# (cqrt_alloc/ry/rz/measure_f16, cq_template_fadd_f16 + its `_unc` twin) resolve
# and signature-match the hand-written core ABI and the generated template ABI
# at the `half` width. (A) a measured Q+Q fadd proves the forward symbol; (B) a
# dead Q+Q fadd kept alive by a cq_phi proves the `_unc` twin reverses once and
# frees every rail — no cqrt_copy_f16 (an f16 carrier is an angle, never data).
# i128 is deferred (its C ABI shreds __int128 to {i64,i64}); see the follow-up.
add_test(NAME e2e-slice-f16
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_f16.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_f16.expected.log")

# Phase 7.1 Increment E (FROZEN ABI): curated reversible llvm.* idiom intrinsics.
# The only layer that LINKS, so the only proof the SIBLING symbols
# (cq_template_<op>_<W> + their `_unc`/`_inv` twins in cq_intrinsic_templates,
# in libcq_templates.a) resolve and signature-match. bswap = Class-1 involution;
# ctpop = Class-2 non-injective whose golden proves the R-E source stays live
# through its own `_unc` (recompute-from-live-source).
add_test(NAME e2e-slice-intrinsic-bswap
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_intrinsic_bswap.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_intrinsic_bswap.expected.log")

add_test(NAME e2e-slice-intrinsic-ctpop
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_intrinsic_ctpop.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_intrinsic_ctpop.expected.log")

# Phase 7.1 iw81.4.b (FROZEN ABI): the fp-math intrinsic family. The only layer
# that LINKS, so the only proof the new generated fp symbols resolve and
# signature-match: (A) a measured unary @llvm.floor.f64 proves the forward
# cq_template_floor_f64; (B) a dead binary @llvm.minnum.f64 kept alive by a cq_phi
# proves the binary forward cq_template_fmin_f64 AND its void `_unc` twin
# cq_template_fmin_f64_unc(out, c, d) reverse once from the still-live f64 sources
# and free every rail — no cqrt_copy_f64 (an fp carrier is an angle, never data).
add_test(NAME e2e-slice-intrinsic-fpmath
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_intrinsic_fpmath.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_intrinsic_fpmath.expected.log")

# Phase 7.1 follow-up D5 (test_C_libtooling-m0yi): a non-power-of-2 _BitInt(N)
# INTERMEDIATE round-trips with NO new ABI. clang -O1 rounds the i40 up to i64 and
# emits the i40 wraparound as a stock `and i64 ..., 0xFFFFFFFFFF` (= 2^40-1), so
# the existing cq_template_add_i64 / cq_template_and_i64_hl (+ its _unc) templates
# lower it — the proposed cq_template_mask_<W> frozen family is unnecessary. This
# link-proves the round+mask forward stream AND the and-mask void _unc twin resolve
# and signature-match through the runtime; the golden's lineage (B) (a dead mask
# uncomputed via cq_template_and_i64_hl_unc reading the live source, then freed)
# is the trace contract for the mask's whole-DAG reversal (Rules 2, 16).
add_test(NAME e2e-slice-bitint
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_bitint.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_bitint.expected.log")

# Phase 7.1 follow-up n0ui (Tier-1): a 128-bit INTERMEDIATE round-trips with NO
# new core ABI. slice_i128_mulhi.c squares a quantum unsigned long and observes
# the high 64 bits of the 128-bit product: clang -O1 keeps the source/sink at i64
# and emits the wide work as single clean i128 ops (zext/mul/lshr/trunc) lowered
# to the FROZEN cq_template_*_i128 producers. This LINK-proves the i128 templates
# (incl. the __int128 _hl literal param) resolve and signature-match through the
# runtime, with NO cqrt_alloc_i128/measure_i128/copy_i128 (source/sink stay i64 —
# the __int128 {i64,i64} source/sink shred is Tier-2, deferred). Rules 2, 16.
add_test(NAME e2e-slice-i128-mulhi
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_i128_mulhi.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_i128_mulhi.expected.log")

# Phase 6 (DD-6 §7.1, test_C_libtooling-mvna.3): the ZERO-LIB smoke for the new
# multi-file harness. Drives the EXISTING single-TU theta->add->measure slice
# through run_slice_multi.sh with EMPTY LIBSRCS (the "" 7th positional), so the
# llvm-link is over just cq.ll — an identity on the runtime trace. It byte-diffs
# the SAME golden as e2e-slice-theta-add-measure, which makes it a pure harness
# check of EXACTLY the empty-LIBSRCS branch (Stage 1b never runs) and the
# single-module identity-link, plus -include CQ.h on CQSRC, templates-before-
# runtime link order, and -O1. The lib-isolation invariant (no CQ.h on libs) and
# multi-module llvm-link are NOT exercised here — e2e-slice-multi-2file (below)
# guards those. Spec pins a zero-lib path as a fixture (IMPLEMENTATION_PLAN §7.1).
add_test(NAME e2e-slice-multi-zerolib
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice_multi.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "${_E2E_LLVM_LINK}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_theta_add_measure.c"
    ""
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_theta_add_measure.expected.log")

# Phase 6 (DD-6 §7.1, test_C_libtooling-mvna.3): the NON-EMPTY-LIBSRCS smoke —
# the permanent ctest guard for the C18 lib-isolation invariant + multi-module
# llvm-link, ahead of the specializer's tainted-arg golden (.7). slice_multi_caller.c
# (a CQ TU whose quantum core matches theta-add-measure, additionally calling a
# CLASSICAL helper) + slice_multi_lib.c (the helper, passed as the single LIBSRCS
# word). This exercises Stage 1b (per-lib clang, NO -include CQ.h) and the
# llvm-link of TWO modules. The helper is called with classical data and used
# only post-measure, so no taint escapes (specializer-independent — a pure harness
# test). slice_multi_lib.c carries a baked-in `#ifdef cq_theta / #error` tripwire:
# if the harness ever force-includes CQ.h into a lib TU, this test fails LOUDLY at
# the lib compile, not silently. lib_bias() returns 0 so the trace matches the
# theta-add-measure golden; the dedicated golden keeps the two slices decoupled.
add_test(NAME e2e-slice-multi-2file
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice_multi.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "${_E2E_LLVM_LINK}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_multi_caller.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_multi_lib.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_multi.expected.log")

# Phase 6.1 (WI-1.11, test_C_libtooling-mvna.7): the call-graph-specialization
# golden — the FIRST e2e slice where taint genuinely ESCAPES into a separate-TU
# callee body and the specializer fires. specialize_caller.c (a CQ TU whose
# theta-tainted `x` is passed to `helper`) + specialize_lib.c (the pure i32
# `helper`, the single LIBSRCS word, compiled WITHOUT CQ.h). After llvm-link
# merges them, the ONE cq-lowering pass clones `helper` into the reversible
# `__cq_q_helper_1`, lowers its body to templates, Bennett-wraps it (compute ->
# cqrt_copy_i32 -> reverse-play `_unc` -> cqrt_free), and retargets the call.
# This is the ONLY layer that LINK-proves @__cq_q_helper_1 + cqrt_copy_i32 + the
# `_unc` data-template adjoints (cq_template_mul_i32_unc / add_i32_hl_unc) all
# resolve and signature-match through the multi-module pipeline; the golden's
# LIFO reverse order (mul_unc before add_unc, then both frees) is the trace
# contract for the Bennett core every later Phase-6 increment reuses. The
# borrowed quantum input `x` (h0) is preserved and left allocated (a Rule-6 safe
# leak — no caller-side uncompute fires, the lineage reaches the measure sink).
add_test(NAME e2e-slice-specialize-2file
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice_multi.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "${_E2E_LLVM_LINK}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/specialize_caller.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/specialize_lib.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/specialize_caller.expected.log")

# Phase 7.1-E follow-up (test_C_libtooling-mvjc): a CURATED reversible llvm.* idiom
# intrinsic INSIDE a specialized clone. specialize_intrinsic_caller.c routes a
# theta-tainted `x` through the separate-TU classical helper popcount_helper
# (specialize_intrinsic_lib.c), whose body is `__builtin_popcount(a) + 1` →
# `@llvm.ctpop.i32` + add. Pre-follow-up the specializer loud-declined (the
# intrinsic read as a declaration-only nested call); now it lifts the helper into
# __cq_q_popcount_helper_1, lowers the ctpop to the frozen cq_template_ctpop_i32
# producer, and Bennett-wraps it. This LINK-proves the clone + cq_template_ctpop_i32
# + its void `_unc` twin resolve and signature-match across llvm-link, and the
# golden's LIFO reverse (add_unc before ctpop_unc, the ctpop_unc reading the
# still-live source, then both frees AFTER the complete reverse) is the trace
# contract for a Class-2 intrinsic under quantum specialization (Rules 2, 13, 16).
add_test(NAME e2e-slice-specialize-intrinsic
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice_multi.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "${_E2E_LLVM_LINK}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/specialize_intrinsic_caller.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/specialize_intrinsic_lib.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/specialize_intrinsic_caller.expected.log")

# Phase 6.2 (WI-2.6, test_C_libtooling-mvna.8): signatures / cache / multiplicity.
# specialize_multiarg_caller.c routes ONE theta-tainted `x` through the separate-TU
# helper `combine` (specialize_multiarg_lib.c) at THREE sites with TWO distinct
# taint signatures + one repeat: combine(x,k) [mask 01], combine(k,x) [mask 10],
# combine(x,k) [mask 01 again, CACHE HIT]. The specializer synthesizes exactly two
# DISTINCT clones — __cq_q_combine_01 (arg0 the handle: the reused arg0 lowers the
# second op QQ) and __cq_q_combine_10 (arg1 the handle: the second op lowers HL) —
# and reuses _01 for the third site. This link-proves that BOTH distinct clones and
# the shared one resolve and signature-match through llvm-link; the golden's two
# different gate streams (QQ-mul in _01 vs HL-mul in _10) plus the _01-shaped third
# call are the trace contract for the (callee,mask) cache earning its keep (C7).
add_test(NAME e2e-slice-specialize-multiarg
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice_multi.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "${_E2E_LLVM_LINK}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/specialize_multiarg_caller.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/specialize_multiarg_lib.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/specialize_multiarg_caller.expected.log")

# Phase 6.3 (WI-3.5, test_C_libtooling-mvna.9): the TRANSITIVE worklist. One
# theta-tainted `x` flows through a TWO-LEVEL classical call chain crossing THREE
# TUs — specialize_transitive_caller.c (CQ) calls `outer`
# (specialize_transitive_outer_lib.c), which calls `inner`
# (specialize_transitive_inner_lib.c). Both libs compile WITHOUT CQ.h (C18). After
# llvm-link, the ONE cq-lowering pass lifts `outer` into @__cq_q_outer_1, then
# re-scans that clone, finds the post-seed-tainted inner call, and lifts `inner`
# into @__cq_q_inner_1 + synthesizes the void uncompute twin @__cq_q_inner_1_unc.
# The outer Bennett wrap's reverse CALLS that twin to zero the entangled inner
# rail (the trace's second `cq_template_mul_i32_hl(h0,7)` + `cqrt_copy(h5,h2)`)
# BEFORE freeing it — so the borrowed quantum input h0 is restored to pristine
# (Rule 6/8), never freed dirty. This is the ONLY layer that LINK-proves the
# nested clones + the uncompute twin all resolve and signature-match across the
# three modules through llvm-link; the twin call's executed body in the trace is
# the contract that the transitive reverse is real, not a verify-clean omission.
add_test(NAME e2e-slice-specialize-transitive
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice_multi.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "${_E2E_LLVM_LINK}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/specialize_transitive_caller.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/specialize_transitive_outer_lib.c ${CMAKE_CURRENT_SOURCE_DIR}/specialize_transitive_inner_lib.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/specialize_transitive_caller.expected.log")

# Phase 6.5 (WI-5.7, test_C_libtooling-mvna.11): a PURE CLASSICAL call under
# QUANTUM CONTROL with CLASSICAL inputs (DD-7 / PRD §2.13) — the clone-ORTHOGONAL
# Phase-6 capability (it reuses the cleared swap-route Phase-4 path, NOT clone-on-
# taint). classical_call_under_control_caller.c (a CQ TU whose theta-tainted `q`
# gates `if (q>5) y = ext_f(7);`) + classical_call_under_control_lib.c (the pure
# i32 `ext_f`, the single LIBSRCS word, compiled WITHOUT CQ.h). After llvm-link,
# the ONE cq-lowering pass recognizes the diamond's merge phi [q (tainted),
# ext_f(7) (a direct classical call result)], HOISTS the pure call into the pred
# (inert), and route-merges its i32 result via the 4.4 controlled-XOR copy merge
# over the FLATTENED diamond: flag mint -> |0> out rail -> cqrt_alloc of the call
# result -> cqrt_copy_i32_controlled (the result, on the flag) -> cqrt_x + the
# ¬flag controlled copy of q -> icmp_inv strip -> the ONE cqrt_free (the flag).
# This is the ONLY layer that LINK-proves the hoisted classical call (ext_f, run
# classically — no trace line, its 107 result feeds cqrt_alloc_i32(107)) +
# cqrt_copy_i32_controlled all resolve and signature-match through the multi-file
# pipeline (Rule 2). NO @__cq_q_ clone (clone-orthogonal), NO cqrt_cswap, ZERO
# controlled rotations, no surviving diamond phi, EXACTLY ONE free.
# control_classical_call_arm_accept.ll is the pinned IR contract.
add_test(NAME e2e-slice-classical-call-under-control
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice_multi.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "${_E2E_LLVM_LINK}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/classical_call_under_control_caller.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/classical_call_under_control_lib.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/classical_call_under_control_caller.expected.log")

# Phase 7.6 (test_C_libtooling-9x4z.1): the reversible I/O output tape. The only
# layer that LINKS — and 7.6 adds NEW frozen hand-written core symbols, so this
# golden is the ONLY proof cqrt_tape_alloc + cqrt_tape_write_<W> resolve and
# signature-match against libcq_runtime (Rule 2/16; the .ll fixtures assert IR
# text and never link). A theta-tainted `x` is APPENDED to the output tape twice
# (printf + putchar -> ONE cqrt_tape_alloc t0, TWO cqrt_tape_write_i32 appends
# with distinct out-handles h2/h3); x is then dead + UNMEASURED, so the source
# lineage uncomputes through the Phase-5 spine (ry adjoint + cqrt_free of h1,
# AFTER the tape captured the value — Bennett copy-out). The kept output rails are
# never freed/reversed, and ZERO measurement is emitted (Rule 5). `noinline` is
# load-bearing (uncompute is gated off in `main`, and -O1 would inline `emit`).
add_test(NAME e2e-slice-io
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_io.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_io.expected.log")

# Phase 7.6 Increment 2 (test_C_libtooling-9x4z.2): the CONTROLLED Tier-0
# conditional output `if(q)printf` / `if(q)putchar`. The only layer that LINKS —
# and Increment 2 adds the NEW frozen hand-written symbol
# cqrt_tape_write_<W>_controlled, so this golden is the ONLY proof it resolves and
# signature-matches against libcq_runtime (Rule 2/16). `emit_sgt` is the
# un-negated polarity (gate arm = TRUE successor, write fires on the flag);
# `emit_ne` is the negated polarity (clang -O1 -> icmp eq + swapped successors, so
# the write is ¬flag-bracketed by a self-inverse cqrt_x pair, Rule 9). Each lowers
# to ONE cqrt_tape_write_i32_controlled (entry ALWAYS appended, content gated); q
# stays coherent for the user's measure; ZERO compiler-inserted measurement, ZERO
# controlled rotations / cswap (Rule 5).
add_test(NAME e2e-slice-io-controlled
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_io_controlled.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_io_controlled.expected.log")

# Phase 7.2 Increment 2 (test_C_libtooling-65wb.2): BOTH-ARM controlled I/O
# `if (q > 5) printf("%d", q); else putchar(q);`. clang -O1 keeps a br-diamond
# (distinct unspeculatable sinks) with two single-pred sole-sink arms converging on
# one 2-pred no-phi merge. Both polarities ride the ONE flag minted from the ONE
# compare: the TRUE arm (printf) on `flag`, the FALSE arm (putchar) ¬flag-bracketed
# by a self-inverse cqrt_x pair. Both writes append to the SAME tape (one
# cqrt_tape_alloc); tape length is deterministic (exactly 2 entries, only content
# gated). q stays coherent for the user's measure; ZERO compiler-inserted
# measurement, ZERO controlled rotations / cswap (Rule 5).
add_test(NAME e2e-slice-io-both-arm
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_io_both_arm.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_io_both_arm.expected.log")

# Phase 7.2 Increment 2 (test_C_libtooling-65wb.2): a MIXED value+I/O diamond —
# `if (q > 5) printf("%d", q);` plus a value select `r = (q>5)?q+1:q+2`. clang -O1
# merges both into one br-diamond with a CONSTANT data-mux φ. Both effects ride the
# ONE flag minted from the ONE compare: the I/O → one cqrt_tape_write_i32_controlled
# (TRUE arm, on flag); the value → the 4.4 controlled-XOR copy data-mux (out=|0>;
# const 1 on flag; const 2 on the cqrt_x-bracketed ¬flag) feeding `add q, out` (Q+Q)
# → measure. The constant data-mux is the safe subset (no phase to dephase, Rule 7);
# a computed two-base φ declines (= 65wb.5 exp2). ZERO compiler-inserted measurement,
# ZERO controlled rotations / cswap (Rule 5).
add_test(NAME e2e-slice-mixed-value-io
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_mixed_value_io.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_mixed_value_io.expected.log")

# Phase 7.5 Increment 1: a tainted-index READ of a const-global table (QROM-shaped).
# `tbl[q]` lowers to cqrt_qram_alloc_i32 (array-handle birth) + cqrt_qram_load_i32
# (Toffoli-copy-out); no getelementptr/load survives and NO measurement is inserted
# that the user did not write (Rule 5). The array handle prints `a<N>`.
add_test(NAME e2e-slice-qram-read
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_qram_read.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_qram_read.expected.log")

# Phase 7.5 Increment 2: an alloca-backed tainted-index STORE + LOAD (Shadow-shaped).
# `arr[q]=7; v=arr[p]` lowers to cqrt_qram_alloc_i32 + cqrt_qram_store_i32 (void
# in-place on the array handle) + cqrt_qram_load_i32; the classical store value is
# materialized into a basis-state handle so the (arr,idx,val) trace stays
# all-handles, and NO measurement is inserted that the user did not write (Rule 5).
add_test(NAME e2e-slice-qram-store
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_qram_store.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_qram_store.expected.log")

# Phase 7.5 bug sxuk: a LOCAL alloca array built+loaded in a NON-main helper whose
# loaded value is measured INSIDE the helper. Unlike slice_qram_store (main-resident,
# no reversal), the local scratch MUST uncompute: the loaded value is copied out to a
# kept carrier (cqrt_alloc_i32(0) + cqrt_copy_i32) which is measured, then the
# load+store chain reverses (cqrt_qram_load_i32_unc + cqrt_qram_store_i32_unc) and the
# index rails reverse-play+free; the array handle is left clean |0> (never freed).
# Without the fix the stores leak, entangling the measured value with dirty scratch.
add_test(NAME e2e-slice-qram-local-uncompute
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_qram_local_uncompute.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_qram_local_uncompute.expected.log")

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
