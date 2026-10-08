; control_predmux_accept_i80_cmp_purecallee.ll — ACCEPT (bd 3c6m.14.1). This
; file was control_predmux_reject_i80_cmp_purecallee.ll until 3c6m.14.1; it is
; the SAME MODULE, byte for byte, with the verdict flipped. Keeping the input
; identical is the point: the red-green evidence for surface S1 is that this
; exact text declines on the pre-3c6m.14.1 plugin and lowers on this one.
;
; SURFACE S1 — E4's CALL admission in the TOP-LEVEL region walk. `@leaf` is a
; perfect pending-specialization candidate (visible, exact definition, acyclic,
; non-varargs, total, template-width result) except that its only off-grid
; instruction is an `icmp i80` with exactly one ConstantInt operand — the
; provably-`_hl` fp80 bit-pattern compare bd 3c6m.61 admitted at the region-body
; walk and deliberately did NOT admit here. 3c6m.14.1 admits it, because the
; question this proof answers is "is `@leaf` a pure, total, terminating function
; of its arguments?" and an `icmp` is all three at every width.
;
; WHERE THE COMPARE ACTUALLY LOWERS — and why the caller's flatten is not the
; place that owes an obligation for it: nothing splices a callee body into a
; caller AFTER a claim, so ONLY the call moves. (Stated that way deliberately: a
; Rule-13 lens rejected the first wording, "the pass does no inlining".
; `lowerByRefInline` IS a body-splicer, but it runs at CQLoweringPass.cpp step
; ~87, before the PredMux fixpoint at ~178, and its own gate requires a tainted
; actual while this proof rejects any body containing a `cq_*` call — so it can
; never feed the widened proof.) The
; compare stays in `@leaf`, which Phase-6 clones into `@__cq_q_leaf_1`, where it
; is STRAIGHT-LINE and lowers on the frozen §6.0 grid to
; `cq_template_icmp_eq_i80_hl` + its void `_unc` twin. No new symbol, no new
; gate sequence, no YAML edit. The same compare written straight-line at top
; level already lowered before this change (measured on the pinned pre-change
; plugin), so this increment adds no new EMISSION — only a new claim.
;
; THE BOUNDARY, pinned as differential siblings on the same module shape:
;   * control_predmux_reject_i80_cmp_purecallee_qq.ll — the SAME `@leaf` with
;     the compare's constant replaced by a second derived operand. Q+Q, still
;     declines (bd 3c6m.14.1 leaves (C) open).
;   * control_predmux_reject_i80_cmp_purecallee_armdiamond.ll — the SAME
;     compare, moved into a tainted diamond INSIDE `@leaf`. Still declines, at
;     the clone-mode `!ClaimAll` bare-compare fence. That decline is what makes
;     it sound to stop worrying about the callee's interior here.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s  --implicit-check-not='br i1' --implicit-check-not='phi x86_fp80' < %t.cqd0.ll
; RUN: env CQ_PREDMUX_DBG=1 %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering \
; RUN:   -S %s -o /dev/null 2>&1 | %filecheck %s --check-prefix=DBG --allow-empty

target datalayout = "e-m:o-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx"

declare x86_fp80 @cq_theta_f80(x86_fp80, double)
declare x86_fp80 @cq_measure_f80(x86_fp80)

; Pure, acyclic, total. Its ONLY instruction outside the pure-callee grid is the
; i80 `_hl` compare — which the E4 REGION walk admitted from 3c6m.61 and which
; this proof admits from 3c6m.14.1.
define x86_fp80 @leaf(x86_fp80 %v) {
e:
  %bc = bitcast x86_fp80 %v to i80
  %man = and i80 %bc, 18446744073709551615
  %eq = icmp eq i80 %man, 9223372036854775808
  %r = select i1 %eq, x86_fp80 %v, x86_fp80 0xK3FFF8000000000000000
  ret x86_fp80 %r
}

define x86_fp80 @probe(x86_fp80 %u0) {
entry:
  %q = call x86_fp80 @cq_theta_f80(x86_fp80 %u0, double 5.000000e-01)
  %c = fcmp olt x86_fp80 %q, 0xK3FFE8000000000000000
  br i1 %c, label %arm, label %norm

arm:
  %r = call x86_fp80 @leaf(x86_fp80 %q)
  %k1 = fadd x86_fp80 %r, 0xKBFFE8000000000000000
  br label %merge

norm:
  %k2 = fmul x86_fp80 %q, 0xK40008000000000000000
  br label %merge

merge:                                  ; 2 merge phis = the W3 claim witness
  %z = phi x86_fp80 [ %k1, %arm ], [ %k2, %norm ]
  %z2 = phi x86_fp80 [ %r, %arm ], [ %q, %norm ]
  %s = fadd x86_fp80 %z, %z2
  %m = call x86_fp80 @cq_measure_f80(x86_fp80 %s)
  ret x86_fp80 %m
}

; ---------------------------------------------------------------------------
; @probe — the region is claimed: the call is SPECULATED out of the arm (it now
; precedes the flag mint, i.e. it executes on every basis state, which is what
; the purity/totality proof buys) and the diamond is gone. The two
; --implicit-check-not flags on the RUN line carry the flattening assertion.
; ---------------------------------------------------------------------------
; CHECK: %u0.stable = freeze x86_fp80 %u0
; CHECK:      %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_f80(x86_fp80 %u0.stable)
; CHECK:      call void @cqrt_ry_f80(i32 %[[Q]], double 5.000000e-01)

; The ELSE-arm value. It is bound HERE, before the call, because it is the ¬flag
; copy source below and a Rule-13 lens caught the first draft leaving that slot
; an unbound wildcard — under which an arm inversion passed FileCheck green.
; CHECK:      %[[K2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_fmul_f80_hl(i32 %[[Q]], x86_fp80 0xK40008000000000000000)
; CHECK:      %[[R:[a-zA-Z0-9_.]+]] = call i32 @__cq_q_leaf_1(i32 %[[Q]])

; The 4.4/kjd1 merge for %z. BOTH copy sources are named and ordered: flag=1
; takes the arm value %[[K1]] (derived from the call result %[[R]]), ¬flag takes
; the straight-through value %[[K2]] (derived from the rail %[[Q]]). Swapping
; them is an arm inversion — verify-clean and silently wrong — so NEITHER is a
; wildcard, and both are bound to the instruction that produces them.
; CHECK:      %[[K1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_fadd_f80_hl(i32 %[[R]], x86_fp80 0xKBFFE8000000000000000)
; CHECK:      %[[F1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_fcmp_olt_f80_hl(i32 %[[Q]], x86_fp80 0xK3FFE8000000000000000)
; CHECK:      %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_f80(x86_fp80 0xK00000000000000000000)
; CHECK:      call void @cqrt_copy_f80_controlled(i32 %[[F1]], i32 %[[K1]], i32 %[[OUT]])
; CHECK:      call void @cqrt_x(i32 %[[F1]])
; CHECK:      call void @cqrt_copy_f80_controlled(i32 %[[F1]], i32 %[[K2]], i32 %[[OUT]])
; CHECK:      call void @cqrt_x(i32 %[[F1]])
; CHECK:      call void @cq_template_fcmp_olt_f80_hl_unc(i32 %[[F1]], i32 %[[Q]], x86_fp80 0xK3FFE8000000000000000)
; CHECK:      call void @cqrt_free(i32 %[[F1]])

; The second merge phi %z2 muxes the call result against the raw rail.
; CHECK:      %[[F2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_fcmp_olt_f80_hl(i32 %[[Q]], x86_fp80 0xK3FFE8000000000000000)
; CHECK:      %[[OUT2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_f80(x86_fp80 0xK00000000000000000000)
; CHECK:      call void @cqrt_copy_f80_controlled(i32 %[[F2]], i32 %[[R]], i32 %[[OUT2]])
; CHECK:      call void @cqrt_x(i32 %[[F2]])
; CHECK:      call void @cqrt_copy_f80_controlled(i32 %[[F2]], i32 %[[Q]], i32 %[[OUT2]])
; CHECK:      call void @cqrt_x(i32 %[[F2]])
; CHECK:      call void @cq_template_fcmp_olt_f80_hl_unc(i32 %[[F2]], i32 %[[Q]], x86_fp80 0xK3FFE8000000000000000)
; CHECK:      call void @cqrt_free(i32 %[[F2]])
; CHECK:      call i32 @cq_template_fadd_f80(i32 %[[OUT]], i32 %[[OUT2]])

; ---------------------------------------------------------------------------
; @__cq_q_leaf_1 — where the i80 compare actually lands. The mask is
; load-bearing: the compare must read the MASKED word, never the raw bitcast, or
; `manh == LDBL_NBIT && manl == 0` silently becomes a whole-bit-pattern equality.
; ---------------------------------------------------------------------------
; CHECK-LABEL: define internal i32 @__cq_q_leaf_1(i32 %v)
; CHECK:      %[[CAST:[a-zA-Z0-9_.]+]] = call i32 @cq_template_bitcast_f80_to_i80(i32 %v)
; CHECK:      %[[MAN:[a-zA-Z0-9_.]+]] = call i32 @cq_template_and_i80_hl(i32 %[[CAST]], i80 18446744073709551615)
; CHECK:      %[[EQ:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i80_hl(i32 %[[MAN]], i80 9223372036854775808)

; The callee's own fp select, arms named and in order.
; CHECK:      %[[SEL:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_f80(x86_fp80 0xK00000000000000000000)
; CHECK:      call void @cqrt_copy_f80_controlled(i32 %[[EQ]], i32 %v, i32 %[[SEL]])
; CHECK:      call void @cqrt_x(i32 %[[EQ]])
; CHECK:      %[[ONE:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_f80(x86_fp80 0xK3FFF8000000000000000)
; CHECK:      call void @cqrt_copy_f80_controlled(i32 %[[EQ]], i32 %[[ONE]], i32 %[[SEL]])

; Rule 6 — the whole i80 chain is reverse-played by void out-first `_unc` calls,
; each recomputing from the SAME operands as its forward twin (a strip against
; different operands computes a different function and leaves the rail dirty),
; and each NAMES the rail a later `cqrt_free` takes (bd 8txa).
; CHECK:      call void @cq_template_icmp_eq_i80_hl_unc(i32 %[[EQ]], i32 %[[MAN]], i80 9223372036854775808)
; CHECK:      call void @cq_template_and_i80_hl_unc(i32 %[[MAN]], i32 %[[CAST]], i80 18446744073709551615)
; CHECK:      call void @cq_template_bitcast_f80_to_i80_unc(i32 %[[CAST]], i32 %v)
; CHECK:      call void @cqrt_free(i32 %[[CAST]])
; CHECK:      call void @cqrt_free(i32 %[[MAN]])
; CHECK:      call void @cqrt_free(i32 %[[EQ]])

; The DBG assertion is NEGATIVE and it is the sharpest evidence this file
; carries: on the pre-3c6m.14.1 plugin these two lines were PRESENT (that was
; the old fixture's whole assertion), so their absence is a genuine red-green
; split, not a restatement of the CHECKs above.
; DBG-NOT: pure-callee leaf fails
; DBG-NOT: leave @probe
