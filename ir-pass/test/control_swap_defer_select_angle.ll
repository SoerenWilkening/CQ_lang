; control_swap_defer_select_angle.ll — ***THIS FIXTURE NOW ACCEPTS.*** It pinned
; the 4.4 WI-1 angle-select DEFER (`rotation angle under quantum control`) for
; over a year; bd `test_C_libtooling-drbq` Increment 2b implements the lowering,
; so the shape it describes LOWERS. The file keeps its name for git continuity
; and because several documents cite it by name — read the name as historical.
;
; THE SHAPE, unchanged from the original fixture:
;     q = rz(q, 0.9); if (q > 5) { rz(q, a); } else { rz(q, b); }
; `clang -O1` SimplifyCFG folds that to ONE hoisted `cq_phi` whose ANGLE is a
; tainted-condition select (`select i1 %c, double a, double b`) — the branch CFG
; is gone before the pass runs (Rule 9). The original header called this "a
; rotation angle under quantum control, NOT a data mux", and that half is still
; exactly right: it is a rotation angle, the select is never lowered as a data
; merge, and no angle-position taint ever reaches a handle.
;
; WHAT CHANGED IS THE DISPOSITION, NOT THE CLASSIFICATION. The angle select is
; lowered BY DIFFERENCE (control-in-place-PRD §12.3):
;     rz(q, b)                            ; unconditional, the FALSE-arm angle
;     f = icmp_sgt_i32_hl(q, 5)           ; the ordinary flag mint
;     rz_controlled(f, q, a - b)          ; the drbq Inc-2a in-place gate
;     icmp_sgt_i32_hl_unc(f, q, 5)        ; the ordinary strip
;     free(f)
; Exact IN REAL ARITHMETIC by angle additivity on one axis: under
; `Rz = diag(1, e^{i.theta})` the two diagonals multiply entrywise, so
; `Rz(b).Rz(a-b) = Rz(a)` with no global-phase residue. In IEEE double the
; realized true-arm angle is `b + fl(a-b)`, error `|delta| <= 1/2 ulp(a-b)` — AND
; FOR THIS FIXTURE THAT ERROR IS EXACTLY ZERO: the arms are the CONSTANTS 0.25 and
; 0.75, a Sterbenz pair, so `fl(0.25 - 0.75) = -0.5` is exact, and the
; constant-arm fence (S1 clauses 2a/2b/3, round-1 Rule-13 review lens L7-F1)
; applies to this file and passes.
;
; *** ROUND-2 CORRECTION (lens R2 N5 = lens R1 item 4b). *** The round-1 edit put
; the RUNTIME-ARM sentence here — "the arms here are RUNTIME `double` arguments,
; so no compile-time fence is possible and the bound is what stands" — which is
; false of this fixture (its arms are constants, two lines below in the body) and
; contradicted its own next sentence. The runtime-arm caveat then lived on the two
; files that actually had runtime arms, `control_swap_reject_switch_datamux_angle.ll`
; and `control_angle_select_ry_arg_angles.ll`, and stated BOTH halves of the
; residual rather than only "the bound".
;
; *** CLEARANCE CORRECTION (Rule-13 clearance review, finding F-11 / blocker B1;
; *** orchestrator decision: owner option (2)). RUN-TIME ARMS NOW DECLINE — the
; *** accept class is CONSTANT arms only, so this fixture's Sterbenz constants are
; *** no longer merely "fenced and passing", they are the whole admitted class.
; *** The two files named above changed with it: the datamux one was given the
; *** constants 0.9/0.3 and `control_angle_select_ry_arg_angles.ll` was REPLACED by
; *** `control_angle_select_reject_runtime_arms.ll`, which carries the full
; *** argument. Nothing about THIS fixture's stream, arms or assertions moved.
;
; NOTHING QUANTUM ENTERS THE ANGLE SLOT — every angle emitted is a classical
; constant (here `0.75`, `0.9` and the folded difference `-0.5`), which is what
; the f64/angle prohibition (Rule 3) actually forbids.
;
; NOTE the rotated register IS the condition register (`%qd` and `%q` are one
; rail after the RAUW). That is legal for the `cq_phi` stem and ONLY for it —
; PRD §3c: a diagonal gate moves no computational-basis label, so the strip still
; recomputes the predicate the mint read. The `cq_theta` twin of this shape
; declines; see `control_angle_select_rz_cond_register.ll` and
; `control_angle_select_reject_cond_register.ll`, which are that pair stated
; minimally.
;
; ORACLE DISPOSITION: RED on the pre-2b binary (it declines `rotation angle`),
; GREEN here — Rule 12 red-green, and the reason this file is a rewrite rather
; than an edit.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=CNT     < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0) {
entry:
  %q   = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %qd  = call i32 @cq_phi_si32(i32 %q, double 9.000000e-01)
  %c   = icmp sgt i32 %qd, 5
  %ang = select i1 %c, double 2.500000e-01, double 7.500000e-01
  %q2  = call i32 @cq_phi_si32(i32 %qd, double %ang)
  %m   = call i32 @cq_measure_si32(i32 %q2)
  ret i32 %m
}

; ONE rail for the whole function.
; CHECK:      %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[Q]], double 5.000000e-01)
; CHECK-NEXT: call void @cqrt_rz_i32(i32 %[[Q]], double 9.000000e-01)
; the unconditional twin at the FALSE-arm angle
; CHECK-NEXT: call void @cqrt_rz_i32(i32 %[[Q]], double 7.500000e-01)
; CHECK-NEXT: %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[Q]], i32 5)
; the difference 0.25 - 0.75 = -0.5
; CHECK-NEXT: call void @cqrt_rz_i32_controlled(i32 %[[F]], i32 %[[Q]], double -5.000000e-01)
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[F]], i32 %[[Q]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[Q]])
; A ROTATION IN THE [measure, ret] WINDOW WAS INVISIBLE HERE (round-2 Rule-13
; review, lens R2 N2). The round-1 L6-N11 hardening added exactly this trailing
; negative to the 17 `control_angle_select_*` accepts and, separately, to
; `control_swap_reject_switch_datamux_angle.ll`; the two counts were the same
; number 17 for different sets and THIS file fell through the gap. Measured on the
; current binary's real output: both an extra `cqrt_rz_i32(%q, 0.77)` and the
; HALF-REVERSAL adjoint `cqrt_rz_i32(%q, -0.75)` — the undo of the unconditional
; twin, which is what a broken freeze produces, the twin being an ordinary
; rotation the whole-DAG spine knows how to invert — stayed GREEN on all three
; prefixes. The window is narrow ([measure, ret]; the same injection between the
; `cqrt_free` and the `cqrt_measure` is caught by the adjacency chain above), but
; it matters more here than its size suggests: this file is the ONLY lit exercise
; of the flipped 4.4 WI-1 defer shape and of the flat Rz-on-the-condition-register
; stem, and it has NO e2e slice, so it is the whole regression surface for that
; axis.
; CHECK-NOT: call void @cqrt_rz_
; CHECK-NOT: call void @cqrt_ry_

; The select is GONE and was never realized as a data merge — the original
; fixture's real assertion, and it still holds.
; NOROUTE:     define{{.*}}@example
; NOROUTE-NOT: select
; NOROUTE-NOT: call void @cqrt_copy
; NOROUTE-NOT: call void @cqrt_cswap
; NOROUTE-NOT: call void @cqrt_x
; no Ry-flavoured controlled gate: this is the diagonal stem
; NOROUTE-NOT: cqrt_ry_i32_controlled
; and NO HALF-REVERSAL ANYWHERE IN THE BODY — neither the adjoint of the
; unconditional twin nor the adjoint of the user's own leading Rz is a spelling
; this lowering can emit (the rail is measured, so the whole-DAG spine has no
; reversal to play), and the trailing `CHECK-NOT` above only covers [measure, ret].
; NOROUTE-NOT: double -7.500000e-01
; NOROUTE-NOT: double -9.000000e-01

; ONE alloc (the register) and ONE free (the flag).
; CNT-COUNT-1: call i32 @cqrt_alloc_i32(
; CNT-NOT:     call i32 @cqrt_alloc_i32(
; CNT-COUNT-1: call void @cqrt_free(
; CNT-NOT:     call void @cqrt_free(
