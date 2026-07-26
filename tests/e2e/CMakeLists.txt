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

# Issue a8c0: the idiomatic conditional phase `if (q != 0) q = cq_phi(q, a)` whose
# else edge `clang -O1` const-folds to `0` (the merge is `phi [phase(q), 0]`).
# Pre-a8c0 the classifier over-declined it (the `Base == Routed` gate saw the
# folded `0`, not the qubit). The straight-through const-fold re-anchor proves
# `q == 0` on that edge and re-anchors the routed handle to `q`, so it lowers as a
# clean phase arm (¬flag cqrt_x brackets — the arm fires on the `q != 0` FALSE
# edge — the Rz on the rail, strip with icmp_eq_inv, merge RAUW'd to q). LINK-proves
# the a8c0 stream resolves against the runtime; the golden is the trace contract.
add_test(NAME e2e-slice-control-phase-ifne
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_phase_ifne.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_phase_ifne.expected.log")

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

# 3c6m.14 L6 / bd 20xt.5 (d): PredMux tolerates `unreachable` switch-defaults.
# The only layer that LINKS — proves the (d)-flattened nest (a tainted special-
# case branch over an EXHAUSTIVE `switch (q&3)` whose dead default clang lowers
# to a shared `unreachable` block, the minimized atan2l quadrant shape) lowers to
# the 4.4 select-merge substrate and its whole symbol set resolves + signature-
# matches against the runtime (Rule 2/16; (d) adds NO new runtime ABI). LLVM's
# PostDominatorTree treats `unreachable` as a 2nd exit, so the standard merge
# lookup bails (virtual-root ipdom) and the nest would decline `nested control
# flow`; (d) recomputes the merge ignoring the unreachable exit so it flattens.
# The `unreachable` arm contributes NO predicate and NO merge incoming; case 3 is
# the sound chain fallback. Deterministic straight-line trace (every gate fires
# unconditionally); flags/out-rails follow the standard 4.4 bookkeeping.
add_test(NAME e2e-slice-predmux-unreachable-switch
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_predmux_unreachable_switch.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_predmux_unreachable_switch.expected.log")

# bd 20xt.5.1 blocker (e): PredMux post-flatten residual-select fold. A tainted
# nest whose classical fp80-const special-case guard (x==1.0, x=0.5L) collapses
# to `false` under cq-lowering's fp80-union promotion, leaving a partial-constant
# `and i1 false,%hi` residue that ConstantFold cannot finish. Without the residue
# fold the residual select declines "control flow under quantum control"; with it
# the dead special-case collapses to EXACTLY the residue-free lowering (verified
# byte-identical). Deterministic straight-line trace, 1 ry + 1 measure (Rule 5).
add_test(NAME e2e-slice-predmux-selectchain-foldresidue
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_predmux_selectchain_foldresidue.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_predmux_selectchain_foldresidue.expected.log")

# bd vyqi (W5): the sole-phi fp diamond — the volatile-single-accumulator
# "***CAUTION***" idiom (log10l `z`, distilled) end-to-end. volatile stores
# defeat clang if-conversion, so the diamond reaches the pass as a real branch;
# promoteVolatileScalarLocals mints the sole 2-incoming fp merge phi, the W5
# claim witness flattens it, and the kjd1 controlled-copy merge lowers it (no
# new runtime ABI — this re-proves the kjd1 fp copy symbols resolve for the
# PredMux-flattened diamond).
add_test(NAME e2e-slice-predmux-fp-diamond-volatile
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_predmux_fp_diamond_volatile.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_predmux_fp_diamond_volatile.expected.log")

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

# fp-DATA select un-staging (fp-data-select-PRD §8, issue kjd1): the branchless
# fp ternary `(q > 0.5) ? q+1.0 : 0.25` -> `select` over an fcmp-ogt condition,
# the FIRST fcmp-minted merge (cq_template_fcmp_ogt_f64_hl / _inv, not icmp).
# The only layer that LINKS the new frozen-designate cqrt_copy_f64_controlled.
# The golden ALSO asserts the §6 uncompute shape: the copied theta-derived fadd
# chain is deliberately LEAKED (its _controlled user marks the DAG NotClosed) —
# NO `_unc` line, EXACTLY ONE cqrt_free (the flag); out / q / t / the
# materialized 0.25 scratch stay allocated (Rules 6/8).
add_test(NAME e2e-slice-control-select-fp
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_select_fp.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_select_fp.expected.log")

# bd 9ymx (owner decision 2026-07-03): the tainted fp ternary INSIDE a classical
# bounded loop -- the -O1-natural shape (LICM-hoisted compare in the guard
# block, select in the body). Pins the per-iteration contract: 3 iterations,
# each minting a fresh flag from the unchanged q, fresh |0> out rail + fresh
# materialized (double)i scratch, strip, and EXACTLY ONE free (the flag); q is
# never freed. The gate-2c cross-block relaxation is what admits this shape.
add_test(NAME e2e-slice-control-select-loop
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_select_loop.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_select_loop.expected.log")

# bd 3c6m.5: cross-domain int<->long-double casts. Two direction slices — the
# LINK-proof that the 18 new int<->f80 cast symbols resolve + signature-match the
# runtime. A non-integer f80 factor (1.5L) keeps clang -O1 from folding the cast
# away (a ×2.0 round-trip collapses to `shl`, Rule 9).
add_test(NAME e2e-slice-cast-int-to-f80
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_cast_int_to_f80.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_cast_int_to_f80.expected.log")

add_test(NAME e2e-slice-cast-f80-to-int
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_cast_f80_to_int.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_cast_f80_to_int.expected.log")

# bd p119.7: the fp<->int `bitcast` REINTERPRET round-trip (EXTRACT_WORDS /
# INSERT_WORDS — the idiom that opens nearly every injected openlibm body). The
# ONLY layer that LINK-proves cq_template_bitcast_f64_to_i64 + _i64_to_f64 resolve
# + signature-match the runtime; the golden pins the reversible relabel chain
# (theta -> ry -> bitcast f64->i64 -> xor -> bitcast i64->f64 -> measure).
add_test(NAME e2e-slice-bitcast-words
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_bitcast_words.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_bitcast_words.expected.log")

# bd 3c6m.7 / p119: the FIRST transcendental compiled by SOURCE INJECTION (Rule 18) —
# a BRANCHLESS soft-exp (select range reduction, no tables/control/scratch) inlined to
# stock reversible opcodes. Load-bearing on BOTH p119 unlocks: p119.6
# (cq_template_fptosi_f64_to_i32 on the kjd1 fp-select merge) AND p119.7
# (cq_template_bitcast_i64_to_f64 for the 2^n INSERT_WORDS scale). The golden pins the
# whole branchless-exp reversible-opcode stream end-to-end.
add_test(NAME e2e-slice-branchless-exp
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_exp.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_exp.expected.log")

# bd 3c6m.10 / L1: the SECOND source-injected transcendental — a BRANCHLESS soft-log
# (musl's core algorithm, special-case branches removed). Range reduction is the
# canonical boundary-shift bit trick: pure i64 add/ashr/and on the punned bit pattern
# (ZERO selects, zero control flow), round-tripping BOTH p119.7 bitcast directions
# (f64->i64 EXTRACT_WORDS and i64->f64 INSERT_WORDS), then musl's minimax R(z) on
# s=f/(2+f) as straight-line fp arithmetic (fdiv QQ + fmuladd keep-set contraction).
# The golden pins the whole branchless-log reversible-opcode stream end-to-end.
add_test(NAME e2e-slice-branchless-log
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_log.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_log.expected.log")

# bd 3c6m.10 / L1 (batch cbrt/log1p/expm1): three more source-injected
# transcendentals landed by the branchless-authored body spine. Corpus twins in
# tools/library_coverage/branchless/{cbrt,log1p,expm1}.c — each body kept in sync.

# cbrt: FreeBSD/openlibm's s_cbrt.c, special-case branches removed. ZERO selects —
# the rough seed "divides the exponent by 3" as an integer udiv on the punned high
# word (hx/3 + Kahan B1), the sign rides a bit, the 23-bit round is add+mask on the
# pattern; clang folds the sign-clear to the hardware-kept @llvm.fabs
# (cq_template_fabs_f64). Both p119.7 bitcast directions, twice. <=1 ulp vs host libm.
add_test(NAME e2e-slice-branchless-cbrt
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_cbrt.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_cbrt.expected.log")

# log1p: openlibm's near-0 range-reduction branch thicket dissolved by an EXACT
# Knuth 2Sum (1+x == u+c) + the branchless soft-log of u + the c/u correction —
# ZERO selects, zero control flow. <=2 ulp vs host libm incl. the near-0 region.
add_test(NAME e2e-slice-branchless-log1p
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_log1p.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_log1p.expected.log")

# expm1: openlibm's per-k reconstruction thicket replaced by the single
# cancellation-free identity 2^n*(1+expm1(r)) - 1 = scale*Pr + (scale-1), keeping
# openlibm's accurate Q1..Q5 primary. The ONLY control is exp's round-bias fp
# select (the kjd1 controlled-copy merge). <=2 ulp vs host libm incl. near 0.
add_test(NAME e2e-slice-branchless-expm1
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_expm1.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_expm1.expected.log")

# bd 3c6m.21 / L1: atan by SOURCE INJECTION. openlibm's 5-segment |x| branch
# ladder (the L6-nested-ctrl blocker) replaced by Cephes's 3-segment reduction
# rendered branchless: the reduced arg xr = N/D is ONE unconditional division
# with N,D from CONSTANT-operand selects (so clang keeps them selects, not
# branches — a division on a bare select arm would SimplifyCFG-branch-ify into
# tainted control flow), then Cephes's degree-4/5 rational R(z) as straight-line
# fmuladd + fdiv, with the sign on a copysign keep-set leaf. 5 fp-select merges.
# <=1.15 ulp vs host libm (dense breakpoint + tail sweeps).
add_test(NAME e2e-slice-branchless-atan
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_atan.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_atan.expected.log")

# bd 3c6m.47 / L1: tanh by SOURCE INJECTION. openlibm's 4-range |x| branch (the
# L6-nested-ctrl blocker) replaced by its OWN |x|<1 kernel made valid for all x:
# tanh(|x|) = -t/(t+2), t = expm1(-2|x|). expm1 is inlined (the branchless kernel,
# == branchless/expm1.c). Saturation is branchless via fmin(|x|,20) — which ALSO
# keeps expm1's arg in-domain (load-bearing for correctness, not just speed). The
# only control is expm1's round-bias fp select. <=3.1 ulp vs host libm (worst
# ~3.05 near |x|=0.125, inherited from the branchless expm1 kernel).
add_test(NAME e2e-slice-branchless-tanh
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_tanh.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_tanh.expected.log")

# bd 3c6m.37 / 3c6m.35 / L1: log2 and log10 by SOURCE INJECTION. openlibm's
# e_log2.c/e_log10.c are ALREADY branchless in their core — the ONLY control flow
# is the leading special-case ladder (x subnormal / x<=0 / inf / NaN / x==1 —
# src/e_log{2,10}.c:50, the L6-nested-ctrl census blocker). These bodies remove
# exactly those data-dependent branches: the {k,1+f} decomposition is the
# canonical full-64-bit boundary-shift bit trick (== branchless/log.c, ZERO
# selects), then openlibm's VERBATIM extra-precision combining — log(m)=hi+lo
# (SET_LOW_WORD via a bitcast+and+bitcast round-trip) scaled by 1/ln2 resp.
# 1/ln10 and k (resp. k*log10(2)) added by a Dekker two-sum. All straight-line
# fp + both p119.7 bitcast directions, zero control flow. ~1 ulp on finite
# normal x>0; log2 is exact at powers of two (k integer-exact, m==1 => log2 m==0).
add_test(NAME e2e-slice-branchless-log2
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_log2.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_log2.expected.log")

add_test(NAME e2e-slice-branchless-log10
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_log10.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_log10.expected.log")

# bd 3c6m.23/.18/.20/.22/.45/.26 / L2-closure: the L2-CLOSURE batch — six compound
# transcendentals by SOURCE INJECTION, each a branchless body that CALLS an L1 leaf
# (atanh/acosh/asinh -> log1p; atan2 -> atan; sinh/cosh -> expm1) resolved by the
# census closure-link and inlined (mirrors tanh->expm1). Each slice inlines a static
# twin of BOTH the compound body AND the leaf, kept in sync with the corpus twins in
# tools/library_coverage/branchless/. All overflow-safe + cancellation-free renderings
# (see per-file headers); <=2.33 ulp vs host libm across their finite domains.
add_test(NAME e2e-slice-branchless-atanh
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_atanh.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_atanh.expected.log")

add_test(NAME e2e-slice-branchless-acosh
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_acosh.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_acosh.expected.log")

add_test(NAME e2e-slice-branchless-asinh
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_asinh.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_asinh.expected.log")

add_test(NAME e2e-slice-branchless-atan2
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_atan2.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_atan2.expected.log")

# bd 3c6m.48: the OTHER two taint masks of atan2. The census now certifies a
# multi-arg fn's COMPILES only if EVERY tainted-double combination lowers (each mask
# is a distinct unitary), so each accepted combination gets its own linked golden.
# slice_branchless_atan2.c pins (q,c) [y tainted, x const]; these pin (c,q) [y const,
# x tainted — exercises the fdiv_lh literal/handle division + an x-tainted quadrant
# merge] and (q,q) [both tainted, two qubits — handle/handle fdiv + a NESTED
# tainted-condition quadrant select, inner (y<0)?±PI merge feeding the outer (x<0)?
# merge as a copy source]. Both are pure value-embeddings (0 controlled rotations,
# balanced flag frees; the quadrant/off DATA rails left allocated, never dirty-freed).
add_test(NAME e2e-slice-branchless-atan2-cq
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_atan2_cq.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_atan2_cq.expected.log")

add_test(NAME e2e-slice-branchless-atan2-qq
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_atan2_qq.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_atan2_qq.expected.log")

add_test(NAME e2e-slice-branchless-sinh
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_sinh.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_sinh.expected.log")

add_test(NAME e2e-slice-branchless-cosh
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_cosh.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_cosh.expected.log")

# bd 3c6m.27/.28 / L2-closure: erf + erfc — the deepest branchy libm body
# (openlibm s_erf.c: FIVE |x| segments + an exp-based asymptotic). Rendered
# branchless via the atan pattern: CONSTANT-operand fp selects producing 0/1
# regime weights that feed an UNCONDITIONAL weighted sum (so clang -O1 cannot
# branch-ify the expensive exp regime onto one arm), over openlibm's own minimax
# coefficients. The exp asymptotic uses the L2-closure spine — exp(y) via the
# branchless expm1 leaf (exp(y)=2^n*(expm1(r)+1), r near 0). Each slice inlines a
# static twin of BOTH the body AND the leaf, kept in sync with the corpus twins
# tools/library_coverage/branchless/{erf,erfc,expm1}.c. Faithful branchless erf/erfc
# over openlibm's coefficients (spot-checked to a few ulp; runtime is trace-only).
# The ONLY layer that LINKS the whole erf/erfc opcode stream.
add_test(NAME e2e-slice-branchless-erf
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_erf.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_erf.expected.log")

add_test(NAME e2e-slice-branchless-erfc
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_erfc.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_erfc.expected.log")

# bd 3c6m.44/.25 / L1: sin + cos by SOURCE INJECTION. openlibm's sin/cos reduce
# with Payne–Hanek, storing the split product into a multi-word scratch double[]
# (e_rem_pio2.c:174 — the L5-shadow `tainted value stored to memory` blocker).
# Replaced by a REGISTER-ONLY, BRANCHLESS Cody–Waite reduction (fn=rint(x·2/π),
# 2-term ≈66-bit π/2) + fdlibm k_sin/k_cos kernels, with the quadrant (fn mod 4)
# derived ENTIRELY in fp (floor keep-set, no fptosi) and blended by CONSTANT-
# operand fp selects into an UNCONDITIONAL weighted sum (the atan/erf pattern, the
# kjd1 fp-DATA select controlled-copy merge). cos = sin(x+π/2) reuses the sin
# weights on (fn+1). fmin/fmax clamp the reduced arg so the body is FINITE for
# every double (no in-domain NaN/Inf). Corpus twins:
# tools/library_coverage/branchless/{sin,cos}.c — keep textually in sync.
add_test(NAME e2e-slice-branchless-sin
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_sin.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_sin.expected.log")

add_test(NAME e2e-slice-branchless-cos
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_cos.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_cos.expected.log")

# bd 20xt.8 Inc 1: the ld80 (x86_fp80) branchless-leaf twins of {sin,cos} — the
# Bennett-parity path for the lgammal hybrid slice. Same 2-term Cody–Waite
# reduction + fp-const-select quadrant blend as the f64 bodies, retyped to
# `long double` with the ld80 rem_pio2l constants (39-bit pio2_1 kept `double`,
# NEGATIVE tail) and the grown ld80 k_sinl (S1..S8) / k_cosl (C1..C7) kernels.
# PURE-REGISTER: the rintl/floorl/fminl/fmaxl keep-set leaves lower to
# cq_template_*_f80 (curated intrinsic bodies) and the fp selects to
# cqrt_copy_f80_controlled (kjd1) — no Shadow/i80/memcpy. A DISJOINT
# hybrid/authored-leaf provenance, never quoted with the real-openlibm goldens.
# Corpus twins: tools/library_coverage/branchless/{sinl,cosl}.c — keep in sync.
add_test(NAME e2e-slice-branchless-sinl
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_sinl.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_sinl.expected.log")

add_test(NAME e2e-slice-branchless-cosl
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_cosl.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_cosl.expected.log")

# bd 20xt.9: the ld80 (x86_fp80) branchless-leaf tan twin — the missing trio leaf
# beside sinl/cosl. Reuses the SAME rem_pio2l reduction + k_sinl/k_cosl kernels;
# tan is π-periodic so only fn mod 2 matters — reconstructed as the RATIO S/C (even)
# or -C/S (odd), NOT openlibm's branchy ld80/k_tanl.c polynomial. The tanl-specific
# op is ONE unconditional QQ division num/den -> cq_template_fdiv_f80; the parity
# blend is a kjd1 const-operand fp select -> cqrt_copy_f80_controlled. PURE-REGISTER,
# DISJOINT hybrid/authored-leaf provenance (census tanl.f80 stays declined, no delta),
# never quoted with the real-openlibm goldens. Corpus twin:
# tools/library_coverage/branchless/tanl.c — keep in sync.
add_test(NAME e2e-slice-branchless-tanl
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_tanl.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_tanl.expected.log")

# bd 20xt.8 Inc 2: the ld80 (x86_fp80) branchless-leaf natural-log twin — the
# third Bennett-parity leaf for the lgammal hybrid slice. e_logl.c's small-exponent
# path log(1+f)=f−½f²+f³P(f)/Q(f) taken UNCONDITIONALLY (faithful over the whole
# centered mantissa for every exponent — the f64 branchless/log.c single-path move),
# with the ld80 P[7]/Q[6]/C1/C2 coefficients. PURE-REGISTER: the frexp mantissa/
# exponent split is a `union IEEEl2bits` bit-cast that SROA promotes to reversible
# cq_template_{bitcast,lshr,shl,and,or,trunc,zext}_i80/i64/i32 surgery on the f80
# (NO Shadow/qram/alloca — a 10-byte fp80 memcpy is deliberately avoided), the √2/2
# centering is ONE constant-operand fp select → cqrt_copy_f80_controlled (kjd1), and
# k is carried to fp with sitofp i32→f80. A DISJOINT hybrid/authored-leaf provenance,
# never quoted with the real-openlibm goldens. Corpus twin:
# tools/library_coverage/branchless/logl.c — keep in sync.
add_test(NAME e2e-slice-branchless-logl
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_logl.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_logl.expected.log")

# bd 20xt.8 Inc 4: the ld80 (x86_fp80) HYBRID lgammal slice — promotes the census
# cell lgammal.f80 COMPILES→VERIFIED. The REAL openlibm ld80/e_lgammal_r.c outer
# ladder (sin_pi reflection helper + the [1.5,2.5] rational / x≥8 asymptotic /
# negative-x reflection branch ladder + every poly coefficient, VERBATIM; the only
# mechanical edits are the GET_LDOUBLE_WORDS union word-read shim, u_int32_t, the
# olm_ entry renames, and the inner sinl/cosl/logl→bsinl/bcosl/blogl +
# floorl/fabsl→__builtin_* renames) wrapped around the THREE AUTHORED branchless
# leaves bsinl/bcosl/blogl (textually identical to slice_branchless_{sinl,cosl,logl}.c;
# always_inline so clang -O1 inlines them into the tainted seed — never spec-cloned,
# the inline-not-cloned lesson). A DISJOINT hybrid/authored-leaf provenance —
# NEVER quoted alongside the real-openlibm goldens; the census cell STAYS declined
# (the ld80 census injects real openlibm sinl/cosl (Payne–Hanek) + logl, none of
# which lowers), so NO census delta. Lowers PURE-REGISTER: opt exit 0, verify-clean,
# 0 qram/Shadow/alloca, 0 spec-clones, 1 ry + 1 measure, deterministic. Corpus twins
# tools/library_coverage/branchless/{sinl,cosl,logl}.c — keep in sync.
add_test(NAME e2e-slice-hybrid-lgammal
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_hybrid_lgammal.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_hybrid_lgammal.expected.log")

# bd 3c6m.46/.30/.19/.17: tan + exp2 + asin + acos by SOURCE INJECTION, all
# single-arg. tan (L1) REUSES the sin/cos Cody–Waite reduction and reconstructs
# tan as a RATIO of the SAME k_sin/k_cos kernels — tan is π-periodic so only the
# PARITY of fn matters (fn even → S/C, fn odd → −C/S), built by ONE constant-operand
# fp select feeding two UNCONDITIONAL weighted sums + ONE division (no k_tan table,
# no Payne–Hanek scratch → sidesteps the L5-shadow blocker). exp2/asin/acos are
# L2-closures: exp2(x)=exp(x·ln2) (dissolves the s_exp2 table, L5-qrom), asin(x)=
# atan(x/√(fmax(1−x²,TINY))) (the fmax clamp kills the |x|→1 NaN — dissolves the
# e_asin nested-if ladder, L6-nested-ctrl), acos(x)=π/2−asin(x). Each slice inlines
# static twins of its leaf(s); corpus twins tools/library_coverage/branchless/
# {tan,exp2,exp,asin,acos,atan}.c — keep textually in sync. All four lower to PURE
# value-embedding traces (0 controlled rotations, balanced flag frees, one measure).
add_test(NAME e2e-slice-branchless-tan
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_tan.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_tan.expected.log")

add_test(NAME e2e-slice-branchless-exp2
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_exp2.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_exp2.expected.log")

add_test(NAME e2e-slice-branchless-asin
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_asin.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_asin.expected.log")

add_test(NAME e2e-slice-branchless-acos
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_acos.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_acos.expected.log")

# bd 3c6m Batch A (.38/.16/.43/.42/.32/.41/.33): the EASY branchless injection
# decliners flipped decline→COMPILES (injection scoreboard 23→30). Each is a keep-set
# identity that dissolves openlibm's special-case control flow with ZERO selects:
#   logb  = (double)(((bits>>52)&0x7FF)-1023)         [field extract]
#   fdim  = fmax(x-y, 0)                               [keep-set fmax]
#   scalbn/scalbln = x * bitcast((n+1023)<<52)         [INSERT_WORDS scale, n classical]
#   fmod  = x - trunc(x/y)*y                           [keep-set trunc]
#   remainder = x - rint(x/y)*y                        [keep-set rint]
#   hypot = fmax(|x|,|y|)*sqrt(1+(fmin/fmax)^2)         [overflow-safe, keep-set fmax/fmin/sqrt]
# The four 2-arg fns (fdim/fmod/remainder/hypot) get a golden PER accepted taint mask
# (qc/cq/qq — 3c6m.48: each mask is a distinct unitary). All traces are PURE
# value-embeddings (0 selects → 0 controlled rotations, 0 flags, single measure).
# Corpus twins tools/library_coverage/branchless/{logb,fdim,scalbn,scalbln,fmod,
# remainder,hypot}.c — keep textually in sync.
add_test(NAME e2e-slice-branchless-logb
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_logb.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_logb.expected.log")

add_test(NAME e2e-slice-libm-real-scalbn
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_scalbn.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_scalbn.expected.log")

# bd 3c6m.51 Inc 1 — the FIRST long-double libm slice: the real openlibm fdiml
# over x86_fp80, exercising the promoteFp80Union peephole (union bit-pattern
# memory -> bitcast x86_fp80 -> i80 + lshr/trunc/zext, padding modelled as 0) and
# the i80 extraction template surface (bitcast/lshr/trunc/and/icmp i80).
add_test(NAME e2e-slice-libm-real-fdiml
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_fdiml.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_fdiml.expected.log")

# bd 3c6m.51 Inc 3 — the long-double RMW slices: the real openlibm scalbnl (+
# its ldexpl strong-reference alias + the scalblnl clamp wrapper) over x86_fp80,
# exercising the MULTI-BLOCK promoteFp80Union (canonicalize + PromoteMemToReg:
# fp80 re-seed in the subnormal arm, two offset-8 field-insert PACK arms, the
# copysignl twin unions, the 5-way f80 return merge), the §4.1 per-bit
# padding-taint walk (the store-backs KEEP diverged straddle bits that land only
# in the dropped >= 80 padding), the i80 field-insert write surface
# (zext/shl/or i80 + and-clear + bitcast i80->f80), and the PredMux + kjd1
# cqrt_copy_f80_controlled merge downstream. The three traces are byte-identical
# by construction (alias + const-folded clamp) — kept as separate goldens so
# each census cell is independently pinned. cbrtl (below, bd etiq) additionally
# exercises the volatile-const-LOCAL fold (its vd2/vd1 rounding constants), the
# TWO-union promotion (u and v), and the tainted exponent-class + k%3 switches.
add_test(NAME e2e-slice-libm-real-scalbnl
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_scalbnl.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_scalbnl.expected.log")

add_test(NAME e2e-slice-libm-real-ldexpl
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_ldexpl.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_ldexpl.expected.log")

add_test(NAME e2e-slice-libm-real-scalblnl
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_scalblnl.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_scalblnl.expected.log")

add_test(NAME e2e-slice-libm-real-cbrtl
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_cbrtl.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_cbrtl.expected.log")

# bd adia (3c6m.55 Lever C) — the FIRST ld80 TRANSCENDENTAL golden: the real
# openlibm coshl closure (e_coshl + e_expl + s_expm1l + s_floorl + __polevll +
# __isnanl + scalbnl-as-ldexpl) at plain -O1. The Lever A+B+C composition of
# record: every union promotes (incl. seeds crossing the OUTLINED pure floorl
# call), both polevll Horner loops force-unroll, the coshl exponent ladder's
# select-form short-circuit conditions and floorl's Q+Q word compares flatten
# and mint, and the outlined expl specializes under tainted control (PredMux
# speculates the proven-pure body; the Phase-6 clone Bennett-wraps it with the
# fp80-ABI copy-out and lowerCloneControl flattens its internal branch web).
# 21k+ trace lines, deterministic; exactly ONE ry + ONE measure (Rule 5).
add_test(NAME e2e-slice-libm-real-coshl
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_coshl.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_coshl.expected.log")

# bd 3c6m.53 (20xt data-symbol closure) — the ld80 census cell atanl.f80
# COMPILES->VERIFIED at plain -O1: the real openlibm atanl closure
# (ld80/s_atanl.c + ld80/invtrig.c atanhi/atanlo/aT tables + invtrig.h
# T_even/T_odd + amd64_fpmath.h union). The proof the 20xt data closure
# unblocked: with the coefficient tables LINKED+INITIALIZED the two
# data-indexed reads atanhi[id]/atanlo[id] classify as cqrt_qram_* QROM reads
# (n=4 each) instead of fake-declining on an uninitialized [0 x x86_fp80]; the
# constant-index reads const-fold. 619-line deterministic trace; exactly ONE
# ry + ONE measure (Rule 5); 0 double-frees, all freed handles minted (Rule 6/8).
add_test(NAME e2e-slice-libm-real-atanl
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_atanl.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_atanl.expected.log")

# bd 20xt.6 — the ld80 census cell atan2l.f80 COMPILES(spec-clone)->VERIFIED at
# the plain -O1 ship floor: the real openlibm atan2l closure (src/e_atan2l.c: the
# special-case/quadrant control ladder + m=2*sign(x)+sign(y) route wrapping the
# inner olm_atanl(fabsl(y/x)) call; over the SAME vendored inner-atanl body as
# slice_libm_real_atanl.c — ld80/s_atanl.c + ld80/invtrig.c atanhi[4]/atanlo[4]/
# aT[13]/pi_lo + invtrig.h T_even/T_odd + amd64_fpmath.h union). This is the
# LINK-layer proof (Rule 2) that the 20xt.3/.4/.5.2 inner-atanl clone-control
# machinery emits+resolves end-to-end: at plain -O1 the inner atanl stays
# OUTLINED and lowers to a Phase-6 spec clone @__cq_q_olm_atanl_1 whose internal
# tainted argument-reduction cascade flattens (lowerCloneControl) and whose two
# data-indexed atanhi[id]/atanlo[id] QROM reads coherently escape via the 20xt.5.2
# Bennett-clone bypass (the range-id is the NeedsMask 4294967295-sentinel phi, not
# the deferred fcmp-select). 1712-line deterministic trace; exactly ONE ry + ONE
# measure (Rule 5); 2 cqrt_qram_alloc_f80(4) tables each read+reversed (4 loads);
# 0 double-frees, all 398 freed handles minted (Rule 6/8). Faithfulness-audited:
# both bodies verbatim-equal to the vendored source modulo the declared renames
# (entry rename, __i386__ guard-out, atanl->olm_atanl, fabsl->__builtin_fabsl).
# See bd libm-real-slice-recipe, clone-control-qram-coherent-escape-20xt52.
add_test(NAME e2e-slice-libm-real-atan2l
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_atan2l.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_atan2l.expected.log")

# bd 20xt — the ld80 census cell exp2l.f80 COMPILES->VERIFIED at the plain -O1
# ship floor: the real openlibm exp2l closure (ld80/s_exp2l.c — the self-
# contained degree-6 minimax table tbl[TBLSIZE*2]=128 hi/lo pairs + P1..P6 +
# redux + the volatile twom10000 + amd64_fpmath.h union; NO inner libm calls,
# the __i386__ exp2() fallback is #ifdef-guarded out). The tainted-index reads
# tbl[i0]/tbl[i0+1] (i0 from x+redux via u.bits.manl) classify as cqrt_qram_*
# QROM reads over cqrt_qram_alloc_f64(256); the fp80 union promotion drives the
# u.xbits/u.bits/v.xbits field extract/insert family. 493-line deterministic
# trace (matches the census hand-verify); exactly ONE ry + ONE measure (Rule 5);
# 0 double-frees, all 100 freed handles minted (Rule 6/8); tables+body
# faithfulness-audited (tbl 130 lines + P1..P6 byte-identical to the vendored
# source; body verbatim modulo the entry rename). See bd libm-real-slice-recipe.
add_test(NAME e2e-slice-libm-real-exp2l
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_exp2l.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_exp2l.expected.log")

# bd 20xt.1 — the general constant-amount funnel shift fshl(a,b,n), a!=b, both
# data operands quantum handles (the (ix<<16)|(i0>>16) word-extract idiom that
# unblocks erfl/erfcl). This e2e is the LINK-layer proof (Rule 2/Rule 16) that
# the new frozen symbols cq_template_fshl_i32_qql[_unc] RESOLVE + signature-match:
# a measured forward funnel + a dead phase-armed funnel reverse-played through the
# void _unc (recompute-and-XOR from live sources). 19-line deterministic trace;
# 0 double-frees; every rail freed only at |0>. Flagged by the Rule-13 review as
# the missing regression baseline for the funnel symbols.
add_test(NAME e2e-slice-funnel-fshl-qq
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_funnel_fshl_qq.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_funnel_fshl_qq.expected.log")

# bd 20xt.2 — the ld80 census cells erfl.f80 / erfcl.f80 COMPILE->VERIFIED at the
# plain -O1 ship floor, post the 20xt.1 general funnel-shift axis that unblocked
# them: the real openlibm erf-family closure (ld80/s_erfl.c pp/qq/pa/qa/ra/sa/rb/
# sb/rc/sc tables + the inner ld80/e_expl.c expl, called TWICE in the asymptotic
# arm, over its own closure __isnanl / __polevll / ldexpl==scalbnl / floorl+fabsl
# keep-intrinsics). The 20xt.1 payoff is direct: the `ix=(ix<<16)|(i0>>16)` word
# extract fuses to @llvm.fshl.i32 -> cq_template_fshl_i32_qql; every |x| range-band
# select flattens under PredMux + the kjd1 fp-select controlled-copy family; the
# ieee_extended_shape_type GET/SET_LDOUBLE_WORDS fp80 union RMW (the SET_LDOUBLE_
# WORDS low-word truncation is the multi-block 3c6m.51 Shadow store) promotes; the
# const-index coefficient reads all const-fold (NO QROM); and both expl inlines
# force-unroll their __polevll Horner loops + pack their ldexpl exponent-RMW union.
# Deterministic (erfl 2518 / erfcl 2724 trace lines); exactly ONE ry + ONE measure
# (Rule 5); 0 double-frees, no free of a never-minted or measured handle (Rule 6/8);
# bodies faithfulness-audited normalized-identical to source modulo the declared
# entry/keep-intrinsic renames. See bd libm-real-slice-recipe, ld80-fshl-funnel-erfl-erfcl.
add_test(NAME e2e-slice-libm-real-erfl
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_erfl.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_erfl.expected.log")

add_test(NAME e2e-slice-libm-real-erfcl
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_erfcl.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_erfcl.expected.log")

# bd szpr (3c6m.51 Inc-3 critic Gap 1) — the i80 field-insert WRITE-surface
# `_unc` adjoints trace-verified: a dead promoted-union RMW on a dedicated rail
# (result-dropped cq_phi keep-alive, the slice_f80.c case-B discipline) makes
# the whole-DAG LIFO uncompute play cq_template_{or,shl,zext,and}_i80*_unc +
# both i80<->f80 bitcast adjoints, each rail freed at proven-|0>. The analytic
# audit of record lives in the slice header.
add_test(NAME e2e-slice-fp80-union-unc
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_fp80_union_unc.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_fp80_union_unc.expected.log")

# bd vqlq — an fp80-union RMW inside a Phase-6 SPECIALIZED callee: the
# argument-derived OPPORTUNISTIC union seed (promoteFp80Union rewrites the
# untainted callee to register form pre-detect) + the scanBody value-bitcast
# carve (Rule-14 mirror of castInScope) compose so @__cq_q_qpack_1 clones,
# lowers the i80 write surface, and Bennett-reverse-plays its full `_unc`
# family (szpr's route (a)). The trace audit lives in the caller TU header.
add_test(NAME e2e-spec-fp80-union
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice_multi.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "${_E2E_LLVM_LINK}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/spec_fp80_union_caller.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/spec_fp80_union_lib.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/spec_fp80_union_caller.expected.log")

# bd 3c6m.54 — the fp-ABI specialization: a Phase-6 clone with an x86_fp80 quantum
# ARG and RETURN. The i32-only FpAbi gate is lifted so a straight-line fp80 helper
# `lpoly` clones with the fp80 arg/return rewritten to i32 handles (Rule 15), the
# fp80 body lowered to `cq_template_f*_f80` producers, the result copied out via
# `cqrt_copy_f80`, and the `_f80_unc` family Bennett-reverse-played. The only layer
# that LINKS: proves the fp-ABI symbols resolve + signature-match (Rule 2/16).
add_test(NAME e2e-spec-fp-arg
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice_multi.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "${_E2E_LLVM_LINK}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/spec_fp_arg_caller.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/spec_fp_arg_lib.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/spec_fp_arg_caller.expected.log")

add_test(NAME e2e-slice-libm-real-lround
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_lround.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_lround.expected.log")

# 3c6m.14 L6 Inc 2 — real openlibm log/cbrt/tanh (tanh = the i1-phi-feeding-a-
# select-condition mechanism cell; expm1 doubly inlined).
add_test(NAME e2e-slice-libm-real-log
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_log.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_log.expected.log")

add_test(NAME e2e-slice-libm-real-cbrt
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_cbrt.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_cbrt.expected.log")

add_test(NAME e2e-slice-libm-real-tanh
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_tanh.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_tanh.expected.log")

# 3c6m.14 L6 Inc 3 — real openlibm exp/atan/erf (volatile-const fold + claimable
# QROM reads under control: provable xsb index (exp), pow2-masked phi-of-constants
# index (atan), composition at scale with two exp inlines (erf)).
add_test(NAME e2e-slice-libm-real-exp
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_exp.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_exp.expected.log")

add_test(NAME e2e-slice-libm-real-atan
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_atan.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_atan.expected.log")

add_test(NAME e2e-slice-libm-real-erf
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_erf.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_erf.expected.log")

# 3c6m.53 — real-openlibm width-sibling verification (34 cells promoted from
# injection-covered -> VERIFIED post-L6 PredMux). 23 f32 siblings + 11 additional
# f64 (atan2 cosh erfc exp2 expm1 ldexp llround log10 log2 logb modf scalbln sinh).
# NOTE: the log1p family (log1p{,f}, atanh{,f}) is census-O2 injection-covered but
# DECLINES at the -O1 verified floor (nested control exceeds PredMux accept shape),
# so it stays injection-covered, NOT verified (Rule 2). See bd 3c6m.53.

add_test(NAME e2e-slice-libm-real-atan2
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_atan2.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_atan2.expected.log")

add_test(NAME e2e-slice-libm-real-cosh
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_cosh.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_cosh.expected.log")

add_test(NAME e2e-slice-libm-real-erfc
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_erfc.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_erfc.expected.log")

add_test(NAME e2e-slice-libm-real-exp2
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_exp2.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_exp2.expected.log")

add_test(NAME e2e-slice-libm-real-expm1
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_expm1.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_expm1.expected.log")

add_test(NAME e2e-slice-libm-real-ldexp
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_ldexp.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_ldexp.expected.log")

add_test(NAME e2e-slice-libm-real-llround
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_llround.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_llround.expected.log")

add_test(NAME e2e-slice-libm-real-log10
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_log10.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_log10.expected.log")

add_test(NAME e2e-slice-libm-real-log2
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_log2.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_log2.expected.log")

add_test(NAME e2e-slice-libm-real-logb
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_logb.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_logb.expected.log")

add_test(NAME e2e-slice-libm-real-modf
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_modf.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_modf.expected.log")

add_test(NAME e2e-slice-libm-real-scalbln
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_scalbln.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_scalbln.expected.log")

add_test(NAME e2e-slice-libm-real-sinh
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_sinh.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_sinh.expected.log")

add_test(NAME e2e-slice-libm-real-atan2f
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_atan2f.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_atan2f.expected.log")

add_test(NAME e2e-slice-libm-real-atanf
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_atanf.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_atanf.expected.log")

add_test(NAME e2e-slice-libm-real-cbrtf
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_cbrtf.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_cbrtf.expected.log")

add_test(NAME e2e-slice-libm-real-coshf
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_coshf.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_coshf.expected.log")

add_test(NAME e2e-slice-libm-real-erfcf
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_erfcf.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_erfcf.expected.log")

add_test(NAME e2e-slice-libm-real-erff
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_erff.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_erff.expected.log")

add_test(NAME e2e-slice-libm-real-exp2f
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_exp2f.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_exp2f.expected.log")

add_test(NAME e2e-slice-libm-real-expf
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_expf.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_expf.expected.log")

add_test(NAME e2e-slice-libm-real-expm1f
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_expm1f.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_expm1f.expected.log")

add_test(NAME e2e-slice-libm-real-ldexpf
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_ldexpf.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_ldexpf.expected.log")

add_test(NAME e2e-slice-libm-real-llroundf
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_llroundf.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_llroundf.expected.log")

add_test(NAME e2e-slice-libm-real-log10f
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_log10f.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_log10f.expected.log")

add_test(NAME e2e-slice-libm-real-log2f
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_log2f.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_log2f.expected.log")

add_test(NAME e2e-slice-libm-real-logbf
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_logbf.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_logbf.expected.log")

add_test(NAME e2e-slice-libm-real-logf
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_logf.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_logf.expected.log")

add_test(NAME e2e-slice-libm-real-lroundf
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_lroundf.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_lroundf.expected.log")

add_test(NAME e2e-slice-libm-real-modff
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_modff.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_modff.expected.log")

add_test(NAME e2e-slice-libm-real-scalblnf
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_scalblnf.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_scalblnf.expected.log")

add_test(NAME e2e-slice-libm-real-scalbnf
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_scalbnf.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_scalbnf.expected.log")

add_test(NAME e2e-slice-libm-real-sinhf
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_sinhf.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_sinhf.expected.log")

add_test(NAME e2e-slice-libm-real-tanhf
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_tanhf.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_tanhf.expected.log")

add_test(NAME e2e-slice-branchless-scalbn
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_scalbn.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_scalbn.expected.log")

add_test(NAME e2e-slice-branchless-scalbln
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_scalbln.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_scalbln.expected.log")

add_test(NAME e2e-slice-branchless-fdim
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_fdim.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_fdim.expected.log")

add_test(NAME e2e-slice-branchless-fdim-cq
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_fdim_cq.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_fdim_cq.expected.log")

add_test(NAME e2e-slice-branchless-fdim-qq
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_fdim_qq.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_fdim_qq.expected.log")

add_test(NAME e2e-slice-branchless-fmod
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_fmod.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_fmod.expected.log")

add_test(NAME e2e-slice-branchless-fmod-cq
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_fmod_cq.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_fmod_cq.expected.log")

add_test(NAME e2e-slice-branchless-fmod-qq
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_fmod_qq.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_fmod_qq.expected.log")

add_test(NAME e2e-slice-branchless-remainder
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_remainder.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_remainder.expected.log")

add_test(NAME e2e-slice-branchless-remainder-cq
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_remainder_cq.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_remainder_cq.expected.log")

add_test(NAME e2e-slice-branchless-remainder-qq
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_remainder_qq.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_remainder_qq.expected.log")

add_test(NAME e2e-slice-branchless-hypot
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_hypot.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_hypot.expected.log")

add_test(NAME e2e-slice-branchless-hypot-cq
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_hypot_cq.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_hypot_cq.expected.log")

add_test(NAME e2e-slice-branchless-hypot-qq
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_hypot_qq.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_hypot_qq.expected.log")

# bd 3c6m Batch B (.40): pow by SOURCE INJECTION — the L2-closure pow(x,y) =
# exp2(y·log2(x)) [x>0], dissolving openlibm e_pow.c's sign/parity/overflow ladder +
# table-driven log/exp. BOTH leaves are authored branchless (log2 fully branchless;
# exp2→exp contributes ONE fp round-bias select — the kjd1 accept shape). Golden per
# accepted taint mask (qc/cq/qq — 3c6m.48); each is a PURE value-embedding (0 controlled
# rotations, single balanced flag, one measure). Injection scoreboard 30→31. Corpus twins
# tools/library_coverage/branchless/{pow,log2,exp2,exp}.c — keep textually in sync.
add_test(NAME e2e-slice-branchless-pow
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_pow.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_pow.expected.log")

add_test(NAME e2e-slice-branchless-pow-cq
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_pow_cq.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_pow_cq.expected.log")

add_test(NAME e2e-slice-branchless-pow-qq
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_pow_qq.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_pow_qq.expected.log")

# bd 3c6m Batch C (.39): nextafter by SOURCE INJECTION — the L5-shadow wildcard. openlibm
# s_nextafter.c is a ladder of data-dependent branches (x==y early-out, x==0 subnormal
# seed, over/underflow flag raises). This body renders the one-ULP bit step FULLY
# ARITHMETIC (dir = (y>x)-(y<x); step = dir*(1-2*sign(x)); bitcast(bits(x)+step)) — the
# comparisons are fcmp->zext, the sign is a bit shift, no selects in the source. Golden per
# accepted taint mask (qc/cq/qq — 3c6m.48): qc/qq are fully arithmetic (0 flags); cq (x
# const) is where clang materializes bits(x)+up as an INTEGER const-select over the tainted
# `up` flag — one balanced cqrt_copy_i64_controlled merge (the base-4.4 integer select
# accept shape). Each a PURE value-embedding (0 controlled rotations, single measure).
# Injection scoreboard 31→32 (COMPLETE injection surface). Corpus twin
# tools/library_coverage/branchless/nextafter.c — keep textually in sync.
add_test(NAME e2e-slice-branchless-nextafter
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_nextafter.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_nextafter.expected.log")

add_test(NAME e2e-slice-branchless-nextafter-cq
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_nextafter_cq.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_nextafter_cq.expected.log")

add_test(NAME e2e-slice-branchless-nextafter-qq
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_nextafter_qq.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_nextafter_qq.expected.log")

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

# dugh (Phase 4×6): the SECOND propagation round. A data-mux merge (untainted by
# SSA data-flow) feeds an ONWARD-QUANTUM phase `cq_phi(r, .25)` — an OPAQUE call
# clang -O1 cannot fold into the switch incomings (a stock `r + const` WOULD fold,
# erasing the onward op), so a real onward-quantum op survives to opt.
# `repropagateControlMerges` re-seeds taint from the emitted %out so the onward
# cq_phi lowers IN PLACE to `cqrt_rz_i32(out, .25)` instead of declining. The only
# layer that LINK-proves the re-tainted onward Rz over the control merge.
add_test(NAME e2e-slice-control-cond-onward-phase
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_cond_onward_phase.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_cond_onward_phase.expected.log")

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

# bd 3c6m.4 (FROZEN ABI): the long-double (f80 / x86_fp80) e2e link proof — the
# width behind the 54 `…l` math.h variants. The only layer that LINKS, so the
# only proof that the new frozen f80 symbols (cqrt_alloc/ry/rz/measure_f80,
# cq_template_fadd_f80 + its `_unc` twin, and the intrinsic-backed
# cq_template_sqrt_f80) resolve and signature-match the hand-written core ABI and
# the generated template ABI at the long-double width. (A) a measured sqrtl over
# a Q+Q fadd proves the forward symbols + the headline `…l` intrinsic shape; (B) a
# dead Q+Q fadd kept alive by a cq_phi proves the fadd_f80 `_unc` twin reverses
# once and frees every rail — no cqrt_copy_f80 (an f80 carrier is an angle, never
# data). On this x86-64 host `long double` == x86_fp80, so CQ.h's _Generic seeds
# the f80 suffix (__LDBL_MANT_DIG__ == 64).
add_test(NAME e2e-slice-f80
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_f80.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_f80.expected.log")

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

# Phase 7.1 wd2p: the ternary fma family (FIRST 3-operand template). Proves the
# QQQ forward (contracted a*b+c -> @llvm.fmuladd.f64) + the QLQ forward/`_unc`
# twin (a dead __builtin_fma(d,3.0,e)) all LINK and signature-match at f64.
add_test(NAME e2e-slice-intrinsic-fma
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_intrinsic_fma.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_intrinsic_fma.expected.log")

# p119: e2e-slice-libm REMOVED — the DIRECT-libm family (cbrt/atan2/ilogb/ldexp) is
# a library-function surface, source-injected not name-recognized (Rule 18). The
# cross-width lrint/llrint survivors are still link-covered by the ir-pass
# lowering_libm_cross_width.ll fixture.

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

# p119: e2e-slice-byref REMOVED — by-ref math (frexp/modf/remquo) is a
# library-function family, source-injected not name-recognized (Rule 18). The
# by-ref out-param INLINER (g7ip, ByRefInline) is a distinct capability and its
# e2e-slice-byref-inline below is UNCHANGED.

# bd g7ip — by-ref out-param on a VISIBLE user function: ByRefInline inlines the
# `noinline` helper's pure store-value producer into the caller (Architecture A),
# so the read-back load lowers to a genuine quantum handle (theta -> add_hl ->
# measure). The link-proof that the inlined stream resolves + signature-matches.
add_test(NAME e2e-slice-byref-inline
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_byref_inline.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_byref_inline.expected.log")

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

# Phase 6 / issue 5po2: a tainted `select` (in-body control) INSIDE a specialized
# clone. spec_select_caller.c routes a theta-tainted `b` through the separate-TU
# classical helper `foo` (spec_select_lib.c), whose body `int a=0; if(b<5) a+=b;
# return a` is `select(icmp slt b,5, b, 0)` at -O1. Pre-5po2 the specializer
# loud-declined (`callee contains tainted control flow under quantum lift`); now
# it lifts `foo` into __cq_q_foo_1, emits the select as a 4.4 controlled-XOR copy
# `out = flag ? b : 0`, and Bennett-wraps it. This LINK-proves the clone +
# cqrt_copy_i32_controlled + the compare `_unc` twin resolve and signature-match
# across llvm-link, and the golden's reverse (the SELF-INVERSE controlled copy
# re-applied to zero the out rail, then the compare `_unc` to unmint the flag,
# then BOTH frees AFTER the complete reverse — no dirty free, Rule 6) is the trace
# contract for a lifted in-body-control select (Rules 2, 6, 13, 16).
add_test(NAME e2e-slice-specialize-select
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice_multi.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "${_E2E_LLVM_LINK}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/spec_select_caller.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/spec_select_lib.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/spec_select_caller.expected.log")

# Phase 6 / issue 5po2 I1 (tainted control in a lifted callee — the two-arm
# integer widening beyond increment-1's `select(icmp, param, 0)`). spec_twoarm_lib.c:
# `if(b>5) a=(b<<2)^9; else a=(b+100)*3; return a` -> `clang -O1` if-converts to a
# two-DERIVED-arm `select(icmp sgt b,5, (b<<2)^9, (b+100)*3)`. Handed a tainted arg
# it lifts into __cq_q_helper_1, emitting the full 4.4 two-copy stream (copy_T ·
# ¬flag `cqrt_x` · copy_F · `cqrt_x`) over `cqrt_copy_i32_controlled` + a |0> out
# rail (flag kept LIVE), Bennett-wrapped. LINK-proves @__cq_q_helper_1 +
# cqrt_copy_i32_controlled + the derived-arm producer `_unc` twins resolve and
# signature-match across llvm-link, and the golden's palindromic reverse (both
# `cqrt_x` brackets replay, the flag + every arm producer `_unc`, then ALL frees
# after the complete reverse; the borrowed input `h0`=`b` left allocated, never
# freed dirty) is the trace contract (Rules 2, 6, 13, 16). The same generalized
# `lowerCloneSelect`/`isLiftableSelect` two-arm path also lowers a PredMux-
# flattened value diamond (ir-pass-lit spec_accept_diamond_body.ll — a real
# multi-block merge-phi diamond rarely survives `clang -O1` from C, which
# if-converts it, so the flatten path is pinned by lit, this e2e link-proves the
# shared two-arm emission).
add_test(NAME e2e-slice-specialize-twoarm-select
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice_multi.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "${_E2E_LLVM_LINK}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/spec_twoarm_caller.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/spec_twoarm_lib.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/spec_twoarm_caller.expected.log")

# Phase 6 / issue 5po2 I2 (multi-exit controlled-return in a lifted fp80 clone —
# the openlibm `expl`-family shape). spec_multiexit_lib.c `mini_expl`: two
# classical-SENTINEL early returns (`if(x>MAX) return C; if(x<MIN) return C'`)
# guarding a tainted fp80 fall-through reduction. Handed a tainted x86_fp80 arg it
# lifts into __cq_q_mini_expl_1: `normalizeReturnMerge` + the scoped PredMux flatten
# collapse the diamond to a nested select whose inner condition is the COMPOUND
# `¬(x>MAX) ∧ ¬(x<MIN)` (a `cqrt_toffoli` conjunction of two fp80 fcmp leaf flags);
# `lowerCloneSelect` mints that network FORWARD-ONLY, MATERIALIZES the sentinels
# into leaked |const⟩ `cqrt_alloc_f80` rails, and emits the `cqrt_copy_f80_controlled`
# XOR muxes; the Bennett wrap plays the SINGLE LIFO reverse (copy⁻¹, the self-inverse
# toffoli, the fcmp/fmul/fma `_unc`s) and frees every proven-|0⟩ rail. LINK-proves
# @__cq_q_mini_expl_1 + cqrt_copy_f80_controlled + cqrt_toffoli + the fp80 producer
# `_unc` twins resolve and signature-match across llvm-link (Rules 2, 6, 13, 16).
add_test(NAME e2e-slice-specialize-multiexit-fp80
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice_multi.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "${_E2E_LLVM_LINK}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/spec_multiexit_caller.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/spec_multiexit_lib.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/spec_multiexit_caller.expected.log")

# Phase 6 / issue kmdc (5po2 fp widening): a fabs-shape FP TWO-ARM select in a
# source-injected int->int helper (fp is internal scratch, reduced to i32 via the
# libm producer ilogb). spec_fp_select_lib.c: `double x=(double)n; double a=(x<0)?
# -x:x; return ilogb(a)` -> select(icmp slt n,0, fneg x, x). Lifts into
# __cq_q_mhelper_1 as an fp cqrt_copy_f64_controlled two-arm merge (copy_T, ¬flag
# cqrt_x bracket, copy_F, cqrt_x) + the libm producer, Bennett-wrapped. LINK-proves
# cqrt_copy_f64_controlled / cqrt_alloc_f64 / cq_template_ilogb_f64_to_i32 + all
# their reverses resolve. The golden is the PALINDROMIC trace — the two cqrt_x
# brackets appear in BOTH the forward stream AND the reverse (the SelectXBrackets
# capture; a dropped bracket would dirty-free the fp rail, Rule 6), and all five
# scratch rails free on |0>. First golden to exercise fp-select-merge + libm
# together (Rules 2, 6, 13, 16).
add_test(NAME e2e-slice-specialize-fp-select
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice_multi.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "${_E2E_LLVM_LINK}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/spec_fp_select_caller.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/spec_fp_select_lib.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/spec_fp_select_caller.expected.log")

# bd 20xt.3 (the materialize-classical-arm widening): a CONST/CONST fp80 select in
# a source-injected int->long-double helper lifted to a reversible clone — the
# atan2l -> inner atanl |x|>=2^64 overflow arm `z = (expsign<0) ? -pi/2 : +pi/2`
# (s_atanl.c block %20; both arms ConstantFP). spec_fp_select_const_lib.c returns
# `(n<0) ? -1.5L : 2.5L` directly, so clang -O1 keeps select(icmp, fp80 const, fp80
# const). Lifts into __cq_q_mhelper_1: EACH ConstantFP arm materialized to its own
# `cqrt_alloc_f80(<const>)` |const> rail (LEAKED, Rule 6), two cqrt_copy_f80_controlled
# merge (copy_T, ¬flag cqrt_x, copy_F, cqrt_x), fp80 result copied out
# (`cqrt_copy_f80`, 3c6m.54), Bennett-wrapped. LINK-proves cqrt_alloc_f80 /
# cqrt_copy_f80_controlled / cqrt_copy_f80 / cq_template_icmp_slt_i32_hl(+_unc)
# resolve. The golden: 1 ry + 1 measure (Rule 5), the two |const> rails NEVER freed
# (Rule 6), the out + flag rails freed on |0> (0 double-frees), palindromic
# forward/reverse copies (Rules 2, 6, 13, 16). atan2l itself still declines at the
# NEXT blocker (the atanhi[id]/atanlo[id] table reads); this synthetic slice is the
# Rule-2 link proof for the const-arm clone widening in isolation.
add_test(NAME e2e-slice-specialize-fp-select-const
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice_multi.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "${_E2E_LLVM_LINK}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/spec_fp_select_const_caller.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/spec_fp_select_const_lib.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/spec_fp_select_const_caller.expected.log")

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

# bd 20xt.4 Inc 1 — a const-global tainted-index QROM read (`kTable[id]`) INSIDE a
# Phase-6 specialized callee (the atan2l inner-atanl `atanhi[id]`/`atanlo[id]`
# spec-callee capability, in isolation: straight-line — no control, no index-select).
# The `noinline` callee `lookup` stays outlined at -O1, so a tainted-arg call is a
# clone-on-taint candidate; `scanBody` admits the gep+load SHAPE (`qromReadShapeInScope`,
# the same `matchQramAccess` structure the emitter re-proves), the clone's
# `lowerQramReads` (`cloneTaint`, `inBennettClone` — the top-level coherent-return
# fence is vacuous in a wrapped clone) lowers it to `cqrt_qram_alloc_f64` (array-handle
# birth) + `cqrt_qram_load_f64`, and the Bennett wrap CAPTURES the load: reversed via
# `cqrt_qram_load_f64_unc`, then the value rail is freed clean. Golden = the gate
# trace: exactly 1 `cqrt_ry` + 1 `cqrt_measure` (Rule 5), the array handle `a1` NEVER a
# `cqrt_free` operand (a classical resource token), `h4` (the load rail) reversed
# before free, `h3` (the index) live through the `load_unc`.
add_test(NAME e2e-slice-spec-qram-read
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_spec_qram_read.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_spec_qram_read.expected.log")

# bd 20xt.4 Inc 2 (blocker c): the spec-callee QROM read called UNDER QUANTUM
# CONTROL. The `noinline` callee `lookup` (its only memory access a const-global
# tainted-index read) is called inside a NESTED tainted diamond (`if(q>5){if(q>10)
# r=lookup(q)}`), so PredMux must prove the callee speculatable to flatten the
# diamond + hoist the call. Inc 2 teaches `isSpeculatableDataflow` to admit the
# QROM read (taint-blind `qromReadShapeInScope`, Rule 14) so `isSpeculatablePure
# CalleeBody` passes; the flatten hoists the call unconditional, the Phase-6 clone
# Bennett-wraps it, and the 4.4 controlled-copy merge selects the result. Golden =
# the gate trace: 1 `cqrt_ry` + 1 `cqrt_measure` (Rule 5), 1 `cqrt_qram_alloc_f64`
# (the array handle, NEVER freed), the load rail reversed via `cqrt_qram_load_f64
# _unc` before free, and the flattened diamond's controlled-copy / flag-strip
# stream. The straight-line Inc-1 clone case is slice_spec_qram_read.c above.
add_test(NAME e2e-slice-spec-qram-read-under-control
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_spec_qram_read_under_control.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_spec_qram_read_under_control.expected.log")

# bd 20xt.5.2 (the FINAL atan2l blocker: inner-atanl clone-control): a spec-clone
# with INTERNAL tainted control whose arm reads a const-global table and whose
# merged value ESCAPES to the clone's non-`main` ret with NO measure (the atanl
# `atanhi[id]`->fmuladd->ret shape). The `noinline` callee `reduce` has a tainted
# diamond `if(x>1.0){ base=kTable[id]+x } else { base=x }; return base;`. Pre-fix
# the clone's PredMux ClaimAll flatten LEFT at E4-gep because
# classifyQromReadUnderControl's coherent-escape no-cloning fence blocked the read;
# the inBennettClone bypass (threaded from ClaimAll) makes it claimable and the
# Bennett wrap reverses the whole stream (the read + index) after copying the
# return out. Golden = 1 `cqrt_ry` + 1 `cqrt_measure` (Rule 5), 1
# `cqrt_qram_alloc_f64` (array handle NEVER freed), the load rail reversed via
# `cqrt_qram_load_f64_unc` before free, the fp arm-merge controlled-copy stream.
add_test(NAME e2e-slice-spec-qrom-read-arm-escape
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_spec_qrom_read_arm_escape.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_spec_qrom_read_arm_escape.expected.log")

# p119: e2e-slice-specialize-libm REMOVED — it lifted a DIRECT-libm call (ilogb)
# into a specialized clone, but direct-libm is a library-function surface
# (source-injected, not name-recognized; Rule 18). Specialization-of-a-clone-with-a-
# curated-producer is still covered by e2e-slice-specialize-intrinsic above.

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

# bd yn71 (Phase 4×6, the CONTROL case): a 6.5 classical-call arm builds an UNTAINTED
# merge %out (`int y=5; if (q>5) y=ext_f(7)`) that then feeds an ONWARD TAINTED-CONTROL
# phase arm (`if (y>50) y=cq_phi(y, .25)`). The merge is data-untainted at round-1, so
# `if (y>50)` is a CLASSICAL branch then; dugh's `repropagateControlMerges` re-seeds the
# second propagation from %out, tainting `icmp sgt %out, 50`. PRE-yn71
# `declineReClassifiedControl` declined that new tainted-condition branch; yn71 RE-DETECTS
# it (`detectAndLowerOnwardControl`) and `SwapRouteEmit` emits the routed phase arm ON
# %out (flag=icmp(%out,50), cqrt_cswap route in, VERBATIM cqrt_rz(rail,.25), route back,
# rail free, icmp_inv strip, flag free; measure reads %out). The ONLY layer that
# LINK-proves the re-detected onward controlled cqrt_cswap/cqrt_rz stream over the control
# merge resolves + signature-matches (Rule 2/16). Reuses classical_call_under_control_lib.c
# for the visible pure `ext_f` (=107); the downstream `ext_f(7)`/`y>50` are unfoldable at
# the CQ-TU compile (ext_f only declared), so `if (y>50)` survives -O1 as a real diamond.
# control_classical_call_arm_accept_onward_ctl_phase.ll is the pinned IR contract.
add_test(NAME e2e-slice-control-cond-onward-ctl-phase
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice_multi.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "${_E2E_LLVM_LINK}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/onward_ctl_phase_caller.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/classical_call_under_control_lib.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/onward_ctl_phase_caller.expected.log")

# p119: e2e-slice-control-byref-frexp REMOVED — it exercised the dugh/0vvq by-ref
# UNFREEZE (an onward frexp on a control-merged %out), but by-ref math is a
# library-function family, source-injected not name-recognized (Rule 18). The
# ONWARD-CONTROL capability (yn71) on a merged %out is still covered by the other
# onward control/switch/select e2e slices; only the by-ref re-run was removed.

# bd 0vvq Increment 2 (the spec-clone RE-PLAN, the D2 core): a 6.5 classical-call
# arm builds an UNTAINTED merge %out (i32) that then feeds a Phase-6 SPECIALIZATION
# candidate qpow(q, %out). At `detectSpecializations` (pre-emit) %out is untainted,
# so the candidate is FROZEN mask 0b01; dugh's `repropagateControlMerges` re-taints
# %out in round 2 and `replanReseedSpecialization` recomputes the mask to 0b11
# BEFORE the step-14 driver clones — so @__cq_q_qpow_11 lowers `mul base,base` +
# `add sq,exp` bare-QQ (the merged register h2 read as a HANDLE, cq_template_add_i32
# NOT _hl — the D2 miscompile fix), Bennett-wrapped. The ONLY layer that LINK-proves
# the re-planned clone + its bare-QQ producers + their _unc twins resolve and
# signature-match through llvm-link (Rule 2/16). Reuses classical_call_under_control_lib.c
# for the visible pure `ext_f`. Pinned by control_classical_call_arm_accept_onward_spec_call.ll.
add_test(NAME e2e-slice-control-spec-replan
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice_multi.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "${_E2E_LLVM_LINK}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/spec_replan_qpow_caller.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/classical_call_under_control_lib.c ${CMAKE_CURRENT_SOURCE_DIR}/spec_replan_qpow_lib.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/spec_replan_qpow_caller.expected.log")

# bd 9paa (round-2 spec DETECTION — the detection twin of the 0vvq re-plan): a 6.5
# classical-call arm builds an UNTAINTED merge %out (i32) that feeds a WHOLLY-NEW
# Phase-6 SPECIALIZATION candidate qsq(y) whose SOLE arg is the merge (NO round-1
# theta handle). At `detectSpecializations` (pre-emit) qsq reads NO tainted operand,
# so it never enters `plan6.Pending` and the 0vvq re-plan skips it — dugh/0vvq
# over-declined it `kMsgUnknownCallee`. dugh's `repropagateControlMerges` re-taints
# %out in round 2 and 9paa's round-2 `detectSpecializations` DETECTS qsq(%out), so
# the step-262 driver clones @__cq_q_qsq_1 with `mul v,v` lowering bare-QQ (the merged
# register h2 read as a HANDLE, cq_template_mul_i32 NOT _hl — the D2 miscompile guard),
# Bennett-wrapped. The ONLY layer that LINK-proves the round-2-DETECTED clone + its
# bare-QQ producer + its _unc twin resolve and signature-match through llvm-link (Rule
# 2/16). Reuses classical_call_under_control_lib.c for the visible pure `ext_f`. Pinned
# by control_classical_call_arm_accept_onward_spec_newcand.ll.
add_test(NAME e2e-slice-control-spec-newcand
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice_multi.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "${_E2E_LLVM_LINK}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/spec_newcand_qsq_caller.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/classical_call_under_control_lib.c ${CMAKE_CURRENT_SOURCE_DIR}/spec_newcand_qsq_lib.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/spec_newcand_qsq_caller.expected.log")

# bd afmv (the CHAINED onward-control -> spec re-plan; a CRITICAL yn71-introduced silent
# miscompile discovered by the 9paa Rule-13 workflow). Two chained 6.5 classical-call arms:
# region 1 `if(q>5)` -> %out1; region 2 `if(y>50)` (cond reads %out1) is lowered by yn71's
# detectAndLowerOnwardControl in round 2 -> %out2 (a quantum rail). `gg(w,q)` is a ROUND-1
# Phase-6 Pending candidate (reads the theta handle q, mask frozen 0b10). Pre-afmv the reseed
# set was frozen BEFORE the yn71 fixpoint, so gg's stale mask was never re-widened for the
# %out2 arg and the driver cloned @__cq_q_gg_10 with cq_template_mul_i32_hl(q, %out2) reading
# the superposed rail's HANDLE-TAG as an _hl literal (q*7, verify-clean wrong unitary). The
# afmv fix computes reseed AFTER the control fixpoint so %out2 is in it; replanReseedSpecial-
# ization re-widens gg 0b10 -> 0b11 and the driver clones @__cq_q_gg_11 with a bare-QQ
# cq_template_mul_i32 over TWO quantum handles. The golden's `cq_template_mul_i32(h0, h7)`
# (q * %out2, both HANDLES) + its _unc twin is the miscompile-fix contract; the second
# measure(y) keeps region-1's merge live so clang -O1 materializes both rails. The ONLY layer
# that LINK-proves the re-widened clone resolves. Pinned by
# control_classical_call_arm_accept_onward_ctl_spec_replan.ll.
add_test(NAME e2e-slice-control-spec-chained-ctl
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice_multi.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "${_E2E_LLVM_LINK}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/spec_chained_ctl_caller.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/classical_call_under_control_lib.c ${CMAKE_CURRENT_SOURCE_DIR}/spec_chained_ctl_lib.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/spec_chained_ctl_caller.expected.log")

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

# bd 38t2: the fp-as-bitpattern memory cell. `arr[q] = x` where `x = cq_theta(...)` is
# an fp superposition CARRIER and `q` a tainted index, then `v = arr[p]`; lowers to
# cqrt_qram_alloc_f64 + cqrt_qram_store_f64 (of the carrier) + cqrt_qram_load_f64 +
# cqrt_measure_f64. Storing a coherent fp carrier is faithful reversible QRAM (bd
# [38t2-fp-cell-commits-to-basis-sound]); the width only tags the symbol (all i32
# handles). main-resident, so no reversal is emitted.
add_test(NAME e2e-slice-qram-store-fp
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_qram_store_fp.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_qram_store_fp.expected.log")

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

# bd 38t2 (Rule-13 clearance link-proof): the FP twin of slice-qram-local-uncompute.
# The only layer that LINKS: proves the fp reversal family — the UNCONTROLLED
# cqrt_copy_f64 copy-out (frozen-designate, its live consumer) + cqrt_qram_load_f64_unc
# + cqrt_qram_store_f64_unc — resolves, signature-matches, and traces in faithful
# Bennett LIFO order (store_unc BEFORE the index rails' Ry† + free) through a real
# link. Byte-parallel to the integer golden with width-tagged symbols.
add_test(NAME e2e-slice-qram-local-uncompute-fp
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_qram_local_uncompute_fp.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_qram_local_uncompute_fp.expected.log")

# iw81.7: a tainted-index Shadow STORE UNDER tainted control — the guarded store.
# The GUARDED symbol cqrt_qram_store_i32_controlled reverses via _controlled_unc with
# the flag live, THEN the flag strips (pred-lifetime invariant); the array is never
# freed. Exercises the reversal path (non-main helper).
add_test(NAME e2e-slice-qram-guarded-store
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_qram_guarded_store.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_qram_guarded_store.expected.log")

# g5gi: guarded store on a SWAPPED (FALSE-successor) branch — `if (q != 3) {...}`
# canonicalizes to `icmp eq; br eq, merge, arm`, so the store fires on `¬(q==3)`.
# g5gi mints the flag with the INVERSE predicate (icmp eq -> icmp ne) — a NEGATED
# MINT, NOT a cqrt_x bracket — so the whole-DAG uncompute reverses it via the same
# `_unc` (cq_template_icmp_ne_i32_hl_unc). The only layer that LINKS: re-proves the
# guarded-store symbol set resolves + signature-matches with the negated flag.
add_test(NAME e2e-slice-qram-guarded-store-swapped
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_qram_guarded_store_swapped.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_qram_guarded_store_swapped.expected.log")

# g5gi: TWO separate guarded-store diamonds sharing a block —
# `if(q<3){arr[i]=7;} if(q<5){arr[j]=8;}`. The first diamond's merge is the second's
# Pred. g5gi exempts a GuardedStoreArm's MergeBB from the cross-region pre-flight
# doomed set (the guarded flatten erases only the Arm, never the merge), so both
# diamonds lower. The whole-DAG uncompute reverses both stores + both flag strips in
# strict reverse program order (store2 before store1); the shared array is never
# freed. The only layer that LINKS: the guarded-store set composes across two
# sequential guarded diamonds.
add_test(NAME e2e-slice-qram-guarded-store-multi
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_qram_guarded_store_multi.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_qram_guarded_store_multi.expected.log")

# bd 38t2 (Rule-13 clearance link-proof): the FP twin of slice-qram-guarded-store.
# The only layer that LINKS: proves the GUARDED fp store family —
# cqrt_qram_store_f64_controlled + _controlled_unc (flag STILL LIVE at the reverse,
# THEN the flag strip: the store-reverse-BEFORE-strip pred-lifetime invariant) plus
# the cqrt_copy_f64 copy-out — resolves, signature-matches, and byte-diffs through a
# real link. Byte-parallel to the integer guarded golden with width-tagged symbols.
add_test(NAME e2e-slice-qram-guarded-store-fp
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_qram_guarded_store_fp.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_qram_guarded_store_fp.expected.log")

# Phase 7.3 Increment 1 (test_C_libtooling-799w.1): the rolled-in-place Case A
# phase accumulator. A classically-bounded loop over an in-place persistent rail
# `for (i<n) q = cq_phi(q, 0.1)` lowers ROLLED — the loop CFG is preserved, the
# body emits `cqrt_rz_f64` in place over the loop-invariant handle, the
# loop-carried header phi AND the zero-trip/exit merge phi collapse to the single
# rail. The bound is a RUNTIME param (the A2 shape: zero-trip guard + exit phi)
# passed a fixed 3 so the trace is deterministic; the golden (alloc + ry + 3×rz +
# measure) is BYTE-IDENTICAL to the manually-unrolled 3-iteration form — the PRD
# §4 done-criterion. ZERO measurements inserted, ZERO in-body frees (the rail is
# measured after L); the classical induction + loop CFG survive. 7.3 adds no new
# runtime ABI — this re-proves the existing alloc/ry/rz/measure symbols compose
# over a rolled loop.
add_test(NAME e2e-slice-loop-phase-accum
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_loop_phase_accum.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_loop_phase_accum.expected.log")

# Issue dtzb (the in-place reversible arithmetic strategy): the VALUE twin of the
# phase accumulator above. A classically-bounded loop over an in-place-mutated
# value rail `q = q ^ 9` lowers ROLLED — `cqrt_xorc_i32(h0, 9)` rolled in place,
# the loop-carried + zero-trip/exit rail phis collapse to the one handle, ZERO
# out-of-place templates, ZERO uncompute/frees. The golden (running the rolled
# loop a FIXED 4 times) is byte-identical to the manually-unrolled 4×cqrt_xorc.
add_test(NAME e2e-slice-loop-value-accum
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_loop_value_accum.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_loop_value_accum.expected.log")

# Phase 7.4 Increment 2 (test_C_libtooling-y05j.2): a classically-bounded,
# data-mutating loop with a SINGLE tainted value-arm `break`, measured after.
# Lowers ROLLED: the rail collapses to one in-place handle, the terminator is
# stripped to the classical bound (full trip count), and the break is realized by
# an index-gated copy-not-move capture + whole-loop reverse-play (forward body ×4,
# capture, copy-out, backward body ×4, balanced R/idx frees, ZERO measurements).
add_test(NAME e2e-slice-loop-break
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_loop_break.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_loop_break.expected.log")

# Phase 7.4 coverage lock (test_C_libtooling-x1t1): the Q==Q value-arm break —
# the break condition compares the rail against a SECOND loop-invariant QUBIT
# (`if (q == p) break;`) rather than a CONSTANT (the e2e-slice-loop-break case).
# The only layer that LINKS the bare-QQ `cq_template_icmp_eq_i32(h_rail, h_p)`
# forward + its void `cq_template_icmp_eq_i32_unc(out, h_rail, h_p)` adjoint for
# the BREAK reverse-play path (a DISTINCT code path from the `_hl` form every
# other break slice exercises; slice_compare_qq.c links the QQ grid only for the
# straight-line/uncompute path). The reverse-play clone reads the SAME invariant
# `p` handle, so `fire'` matches `fire` on every branch; `p` is never mutated and
# never freed (left allocated-clean, Rule 6 — the golden shows NO cqrt_free(h0)).
# No new frozen runtime ABI (reuses the bare-QQ compare grid + the break spine).
add_test(NAME e2e-slice-loop-break-qq
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_loop_break_qq.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_loop_break_qq.expected.log")

# Phase 7.4 coverage lock (test_C_libtooling-mvrb): a Q==Q value-arm break whose
# loop-invariant comparand `p` carries a RELATIVE PHASE (an Rz / cq_phi in p's
# lineage). The accept is CLEARED by a 5-lens adversarial Rule-13 sign-off
# (2026-06-30, 0 concrete holes): the break construct emits ONLY basis-permutation
# gates (no Ry/Rz/H inside — the only cqrt_rz is PRE-LOOP, preparing p), so it is a
# fixed permutation and p's phase rides inert; p is consumed only as a QQ-compare
# control (+matched _unc), never copied into out / measured / freed, and is restored
# exactly + left allocated (Rule-6 safe leak). The golden shows the pre-loop
# cqrt_rz_i32(h0, 0.3) and NO cqrt_free(h0). Distinct from the B3 phase fence (which
# declines a phase ESCAPING ANSWER, where copy-out would dephase, Rule 7). No new ABI.
add_test(NAME e2e-slice-loop-break-qq-phase
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_loop_break_qq_phase.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_loop_break_qq_phase.expected.log")

# Phase 7.4 coverage lock (test_C_libtooling-1784): a Q==Q value-arm break whose
# comparand is a DERIVED (non-mint) loop-invariant tainted value — `p = p0 + 5`
# (producer chain p0 -> p, the deriving cq_template_add_i32_hl strictly PRE-LOOP).
# Same Rule-13 clearance: the construct is permutation-only, so the p0 -> p chain (and
# p0's Ry superposition) rides inert. Both p AND p0 are consumed only as QQ-compare
# operands (+matched _unc), never rotated / copied into out / measured / freed;
# isTerminalHandle is false for both and the spine never enqueues them — the deriving
# add is NEVER reversed and NEITHER is freed dirty. The golden shows
# cq_template_add_i32_hl(h0, 5) with NO _unc and NO cqrt_free(h0)/(h1) (two entangled
# rails left allocated, the Rule-6 safe leak). The symmetric-XOR fold `p = p0 ^ 3`
# with an xor rail is a DIFFERENT shape (E8 kMsgBreakUnemittable decline). No new ABI.
add_test(NAME e2e-slice-loop-break-qq-derived
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_loop_break_qq_derived.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_loop_break_qq_derived.expected.log")

# Phase 7.4 coverage smoke (test_C_libtooling-rxx8): the i64-RAIL Q==Q value-arm
# break. The only layer that LINKS the i64 break-path capture symbols (cqrt_alloc_i64,
# cqrt_copy_i64[_controlled], cqrt_xorc_i64, cq_template_icmp_eq_i64 + its _unc) — a
# missing one fails LOUDLY at LINK, invisible to the .ll fixtures. Also exercises the
# MIXED-width capture (i64 rail + i32 idx counter). `p` is loop-invariant and never
# freed (left allocated-clean, Rule 6). No new frozen runtime ABI.
add_test(NAME e2e-slice-loop-break-qq-i64
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_loop_break_qq_i64.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_loop_break_qq_i64.expected.log")

# Phase 7.3 Increment 2 (test_C_libtooling-799w.2): the per-iteration in-body
# uncompute Case B. Each iteration mints a FRESH rail, derives an iteration-local
# temp (xor_hl), keeps it alive with a dead cq_phi, and drops both. The Phase-5
# spine lifts its two backedge guards for the proven iteration-local DAG and
# places the whole-DAG reversal (rz⁻¹ -> xor `_unc` reading the live mint -> free
# t-rail -> ry⁻¹ -> free q-rail) IN-BODY, once per iteration. The golden (n=3)
# shows THREE balanced compute/uncompute pairs over distinct handle pairs (h0/h1,
# h2/h3, h4/h5) with SIX frees — the per-iteration handle progression proves the
# free runs once per trip, never a function-scope free over a K-times-reallocated
# rail (use-after-free + double-free, the Rule-13 hazard). `noinline` is
# load-bearing (uncompute gated off in main). No new frozen runtime ABI (reuses
# the `_unc` spine).
add_test(NAME e2e-slice-loop-iter-local
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_loop_iter_local.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_loop_iter_local.expected.log")

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

# 3c6m.12 (Phase-4.4 L4 widening): compound (`||`/`&&`) conditions on tainted-
# data selects. The fp `||` half exercises the NEW conjunction network — per-
# leaf fcmp flag mints, a cqrt_alloc_i1 ancilla, the input-preserving OR
# (cnot,cnot,toffoli), root-controlled f64 copies, the exact-LIFO inverse
# network + strips (every free provably |0>). The int `&&` half documents the
# -O1 RANGE-FUSE (clang folds `n>5 && n<100` to `add -6; icmp ult 94` — a
# single compare, the pre-existing single-flag path). Links cqrt_cnot /
# cqrt_toffoli / cqrt_alloc_i1 against libcq_runtime — no new frozen ABI (all
# three are hand-written core symbols).
add_test(NAME e2e-slice-control-select-compound
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_select_compound.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_select_compound.expected.log")

# bd 3c6m.56 — the long-double round-family KEEP path (Bennett-gated). With
# builtins on, `clang -O1` folds `rintl`/`nearbyintl`/`truncl` to the in-grid IR
# intrinsics `@llvm.{rint,nearbyint,trunc}.f80`, which cq-lowering recognizes
# (IntrinsicLowering.cpp) and lowers to `cq_template_{rint,nearbyint,trunc}_f80` —
# NO openlibm body injected (the asm-level `callq _<fn>l` is intercepted as the
# intrinsic BEFORE codegen: the floor.f80 precedent). These are legitimate keeps
# because Bennett.jl ships the reversible gate sequence — `soft_round`
# (round-to-nearest-even = rint/nearbyint under the default FP env) and
# `soft_trunc` (`src/softfloat/fround.jl`) — so a real Phase-9 backend has a
# Bennett source. Contrast `fmod`→`frem`: an in-grid OPCODE but with NO Bennett
# frem/fmod primitive, so it is NOT a keep and is deliberately absent here (bd
# fmod-frem-keep-2026-07-24 + the frem-inversion follow-up). Each golden is the
# Rule-2 e2e proof (link + run + deterministic trace) promoting the census cell
# from COMPILES-by-recognition to VERIFIED; the census (probe.py keep-set) already
# skips these bases, so the ld80 scoreboard is unchanged.
add_test(NAME e2e-slice-libm-keep-rintl
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_keep_rintl.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_keep_rintl.expected.log")

add_test(NAME e2e-slice-libm-keep-nearbyintl
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_keep_nearbyintl.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_keep_nearbyintl.expected.log")

add_test(NAME e2e-slice-libm-keep-truncl
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_keep_truncl.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_keep_truncl.expected.log")

# ---------------------------------------------------------------------------
# bd 3c6m.58 — the VERIFY-FIRST sweep: real-openlibm e2e goldens for the 15
# cells that were injection-covered (census full_census_O1.json) but had NO
# committed golden. Each promotes its cell from COMPILES (an UPPER BOUND, measured
# under the census's own default<O1> cleanup) to VERIFIED at the true
# `clang -O1 -> cq-lowering -> link -> run` ship floor (Rule 2, Rule 18 source
# injection). All 15 held; verified 53 -> 68, closing the gap to injection-covered.
# Bodies are vendored from the openlibm corpus @82e90ae per bd
# libm-real-slice-recipe (mechanical edits ONLY — no constant, branch or
# expression changed); each was cleared by an independent adversarial
# faithfulness + trace-soundness audit.
# ---------------------------------------------------------------------------


# fdim.f64 — f64 sibling of the verified fdiml.f80: union IEEEd2bits is SROA-promoted
# by clang -O1 to `bitcast double to i64`, so the isnan OR-of-negations lands on the plain
# integer-extraction surface and both merges are controlled-XOR copies.
add_test(NAME e2e-slice-libm-real-fdim
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_fdim.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_fdim.expected.log")


# fdimf.f32 — f32 sibling; __isnanf's SINGLE 23-bit mantissa test (not the manl/manh pair).
add_test(NAME e2e-slice-libm-real-fdimf
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_fdimf.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_fdimf.expected.log")


# frexp.f64 — BY-REF cell. NOTE the census probe declares the out-param but never READS it, so
# clang -O1 DCEs every *eptr store before cq-lowering runs: this golden verifies the MANTISSA
# half only (zero store/Shadow/QRAM activity). Measured separately: a live-out-param variant
# also compiles clean, so the dead store is a probe-convention artifact, not a capability gap.
add_test(NAME e2e-slice-libm-real-frexp
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_frexp.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_frexp.expected.log")


# frexpf.f32 — f32 by-ref sibling; same dead-out-param scope caveat as frexp.f64.
add_test(NAME e2e-slice-libm-real-frexpf
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_frexpf.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_frexpf.expected.log")


# frexpl.f80 — ld80 by-ref: union IEEEl2bits read AND write-back (u.bits.exp = 0x3ffe field insert)
# under a 3-way switch on the tainted exponent -- the promoteFp80Union RMW (3c6m.51).
add_test(NAME e2e-slice-libm-real-frexpl
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_frexpl.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_frexpl.expected.log")


# modfl.f80 — ld80 sibling of the verified modf.f64/modff.f32: openbsd GET/SET_LDOUBLE_WORDS RMW
# across a 3-band exponent dispatch. Same dead-out-param scope caveat.
add_test(NAME e2e-slice-libm-real-modfl
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_modfl.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_modfl.expected.log")


# lroundl.f80 — ld80 sibling of the verified lround.f64. The INRANGE macro is vendored VERBATIM and
# clang DEMONSTRATES the compile-time-TRUE fold (LONG_MAX + 0.5 is computed in DOUBLE by the
# usual arithmetic conversions and rounds to 2^63, so dtype_max - LONG_MAX == 1.0 != 0.5):
# feraiseexcept is absent from the lowered IR, exactly as in the census bitcode.
add_test(NAME e2e-slice-libm-real-lroundl
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_lroundl.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_lroundl.expected.log")


# llroundl.f80 — long long instantiation of the same s_lround.c template; trace is byte-identical to
# lroundl (long and long long are both i64 on LP64, so the fptosi is the same).
add_test(NAME e2e-slice-libm-real-llroundl
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_llroundl.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_llroundl.expected.log")


# nextafter.f64 — VOLATILE-LOCAL cell: `volatile double t; t = x*x;` is fdlibm's underflow-flag-raise
# idiom -- the bd zco4 Inc 1 promoteVolatileScalarLocals shape. Plus the hi/lo
# borrow-propagating +-1 ulp walk.
add_test(NAME e2e-slice-libm-real-nextafter
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_nextafter.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_nextafter.expected.log")


# nextafterf.f32 — f32 sibling: single-word ulp walk, same volatile underflow-raise idiom.
add_test(NAME e2e-slice-libm-real-nextafterf
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_nextafterf.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_nextafterf.expected.log")


# nextafterl.f80 — the hardest of the family: a THREE-word (esx/hx/lx) borrow-carry chain with the
# explicit-integer-bit `(hx +- 1) | (hx & 0x80000000)` fixups, and block-scoped volatile locals.
add_test(NAME e2e-slice-libm-real-nextafterl
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_nextafterl.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_nextafterl.expected.log")


# nexttoward.f64 — the only MIXED-WIDTH cell (C11 7.12.11 fixes arg 2 at long double): drives BOTH the f64
# memcpy word shim and the ld80 union in one body, plus the hand-aligned f64->fp80 field
# comparison ladder.
add_test(NAME e2e-slice-libm-real-nexttoward
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_nexttoward.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_nexttoward.expected.log")


# expm1l.f80 — ld80 exp kernel in Cephes rational form: Cody-Waite reduction via @llvm.floor.f80,
# a P4/Q4 rational core, and 2^k reassembly through ldexpl==scalbnl -- one of the cells bd
# vuy6's module-asm .set alias resolution unmasked.
add_test(NAME e2e-slice-libm-real-expm1l
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_expm1l.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_expm1l.expected.log")


# tanhl.f80 — four-band |x| dispatch over the inner expm1l; fp80 selects ride the kjd1
# cqrt_copy_f80_controlled family.
add_test(NAME e2e-slice-libm-real-tanhl
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_tanhl.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_tanhl.expected.log")


# sinhl.f80 — four-band dispatch over BOTH inner kernels (expm1l and expl). Census status is
# `exit0-spec:['expl']` (expl stays outlined as a Phase-6 spec clone under the census harness);
# at the plain -O1 ship floor the recipe's force-inline convention collapses the closure to one
# straight-line body instead. Both routes reach opt exit 0; this golden pins the ship-floor one.
add_test(NAME e2e-slice-libm-real-sinhl
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_sinhl.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_sinhl.expected.log")

# --- bd 3c6m.60: the 11 cells unblocked by the census hardware-keep-set harness fix.
# Each vendors the REAL openlibm body and spells its inner keep-set calls `__builtin_<keep>` —
# the SAME `@llvm.<fn>.f<W>` construct plain `clang -O1` emits for the named call at the ship
# floor (Rule 18), which is exactly what the corpus's blanket `-fno-builtin` used to defeat.
# hypotl.f80 is DELIBERATELY ABSENT: it census-COMPILES but DECLINES at the plain -O1 ship floor
# (`nested control flow under quantum control`) — the one census-pipeline-only cell in this
# baseline. Its faithful vendoring is parked at slice_libm_real_hypotl.c.DECLINED as the
# ready-made re-test for bd q2wk; do NOT wire it until that lever lands (bd 3c6m.61).

# acos.f64 — the classification cascade over the tainted exponent word (|x|>=1 / |x|<0.5 /
# x<-0.5 / x>0.5) flattened through PredMux; the pS/qS Horner polynomials; the `pio2_lo`
# volatile-scalar fold. Inner `sqrt` is a Rule-18 hardware KEEP -> cq_template_sqrt_f64.
add_test(NAME e2e-slice-libm-real-acos
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_acos.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_acos.expected.log")

# acosf.f32 — f32 sibling of acos: same cascade over GET_FLOAT_WORD, sqrtf -> cq_template_sqrt_f32.
add_test(NAME e2e-slice-libm-real-acosf
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_acosf.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_acosf.expected.log")

# acosl.f80 — ld80 sibling: the invtrig P/Q Horner tables + union IEEEl2bits mantissa mask as an
# i80 register RMW (no Shadow/QRAM), sqrtl -> cq_template_sqrt_f80.
add_test(NAME e2e-slice-libm-real-acosl
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_acosl.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_acosl.expected.log")

# asin.f64 — the |x|>=1 / |x|<0.5 / else cascade with the SET_LOW_WORD half-precision split;
# fabs + sqrt are keeps.
add_test(NAME e2e-slice-libm-real-asin
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_asin.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_asin.expected.log")

# asinf.f32 — f32 sibling of asin.
add_test(NAME e2e-slice-libm-real-asinf
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_asinf.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_asinf.expected.log")

# asinl.f80 — ld80 sibling of asin over the invtrig tables.
add_test(NAME e2e-slice-libm-real-asinl
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_asinl.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_asinl.expected.log")

# hypot.f64 — the widest of the acos/asin family (1098 trace lines, 145 allocs): the exponent-difference
# ladder, the two SET_HIGH_WORD rescalings, and the sqrt correction step.
add_test(NAME e2e-slice-libm-real-hypot
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_hypot.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_hypot.expected.log")

# pow.f64 — NB the census cell convention pins arg1 to the classical literal 0.5, which is pow's
# `y == 0.5` fast path -- clang -O1 proves the log/exp core UNREACHABLE, so this golden verifies
# pow's tainted classification prologue + the sqrt route, NOT its numeric core (bd 3c6m.62).
add_test(NAME e2e-slice-libm-real-pow
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_pow.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_pow.expected.log")

# powf.f32 — same arg1=0.5f fast-path caveat as pow.f64 (bd 3c6m.62); verifies the classification
# prologue, the nan_mix f80 leg, and the sqrtf/fabsf keep routes.
add_test(NAME e2e-slice-libm-real-powf
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_powf.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_powf.expected.log")

# lgamma.f64 — the largest slice in the suite (14003 trace lines): e_lgamma_r's band ladder + the
# sin_pi reflection over the real __kernel_sin/__kernel_cos and the real e_log body; floor/fabs are
# keeps. Census bucket is COMPILES (spec-clone); this golden pins the plain -O1 force-inlined route
# (sinhl precedent).
add_test(NAME e2e-slice-libm-real-lgamma
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_lgamma.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_lgamma.expected.log")

# lgammaf.f32 — f32 sibling of lgamma over __kernel_sindf/__kernel_cosdf + the real e_logf body.
add_test(NAME e2e-slice-libm-real-lgammaf
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_lgammaf.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_lgammaf.expected.log")

# ── bd q2wk (3c6m.14 L6 increment 5): the 12 cells unblocked by the PredMux E6
# path-predicated-branch widening (an i1 phi as a branch condition + a condition the
# flatten itself taints). All are REAL openlibm bodies at the plain clang -O1 ship
# floor — census-COMPILES is only an upper bound until the golden exists (Rule 2).

# log1p.f64 — THE MECHANISM CELL for bd q2wk (PredMux L6 inc 5). s_log1p.c's
# `if(hx>0||hx<=(int32_t)0xbfd2bec4)` short-circuit survives plain clang -O1 as an i1 PHI over
# CONSTANTS feeding a conditional branch; before inc 5 that tripped E6-classicalbr and the whole
# fdlibm classification chain declined.
add_test(NAME e2e-slice-libm-real-log1p
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_log1p.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_log1p.expected.log")

# log1pf.f32 — float sibling of log1p over the real s_log1pf.c body (same i1-phi branch).
add_test(NAME e2e-slice-libm-real-log1pf
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_log1pf.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_log1pf.expected.log")

# atanh.f64 — e_atanh.c over the real vendored s_log1p.c (log1p is a library fn, injected as
# source per Rule 18); fabs is a hardware keep.
add_test(NAME e2e-slice-libm-real-atanh
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_atanh.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_atanh.expected.log")

# atanhf.f32 — f32 sibling: e_atanhf.c + the real s_log1pf.c body.
add_test(NAME e2e-slice-libm-real-atanhf
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_atanhf.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_atanhf.expected.log")

# acosh.f64 — e_acosh.c over BOTH the real e_log.c and s_log1p.c bodies; sqrt is a hardware keep
# (never openlibm's software e_sqrt.c — that misrepresentation is the bd 3c6m.60 census bug).
add_test(NAME e2e-slice-libm-real-acosh
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_acosh.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_acosh.expected.log")

# acoshf.f32 — f32 sibling: e_acoshf.c + the real e_logf.c and s_log1pf.c bodies.
add_test(NAME e2e-slice-libm-real-acoshf
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_acoshf.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_acoshf.expected.log")

# asinh.f64 — s_asinh.c over the real e_log.c and s_log1p.c bodies; sqrt/fabs are hardware keeps.
add_test(NAME e2e-slice-libm-real-asinh
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_asinh.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_asinh.expected.log")

# asinhf.f32 — f32 sibling: s_asinhf.c + the real e_logf.c and s_log1pf.c bodies.
add_test(NAME e2e-slice-libm-real-asinhf
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_asinhf.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_asinhf.expected.log")

# hypotf.f32 — the E6 SUB-RULE (B) witness: its blocker was `icmp eq i32 %k, 0` over an UNTAINTED
# phi-merged scale accumulator, admitted now by valueWillTaintAfterFlatten. sqrtf/fabsf are keeps.
add_test(NAME e2e-slice-libm-real-hypotf
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_hypotf.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_hypotf.expected.log")

# acoshl.f80 — ld80 cell over the real ld80/e_logl.c + ld80/s_log1pl.c bodies with union IEEEl2bits
# kept verbatim. Pins that the __polevll Horner loops DO fully unroll at the plain -O1 ship floor
# (their standalone log1pl/log2l/logl siblings do NOT, and stay honest E2-cycle declines: bd 8h7d).
add_test(NAME e2e-slice-libm-real-acoshl
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_acoshl.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_acoshl.expected.log")

# asinhl.f80 — ld80 cell: s_asinhl.c over the real ld80/e_logl.c + ld80/s_log1pl.c bodies,
# union IEEEl2bits verbatim (the pass's promoteFp80Union owns it); sqrtl/fabsl are keeps.
add_test(NAME e2e-slice-libm-real-asinhl
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_asinhl.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_asinhl.expected.log")

# atanhl.f80 — ld80 cell: e_atanhl.c over the real ld80/s_log1pl.c body.
add_test(NAME e2e-slice-libm-real-atanhl
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_atanhl.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_atanhl.expected.log")
