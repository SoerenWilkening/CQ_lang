; control_swap_inloop_range_cond.ll — ACCEPT (bd test_C_libtooling-8h7d.5, Rule-13
; ROUND 4, finding OD-A). A TWO-SIDED RANGE oracle — the canonical Grover marking
; predicate — inside a classically-bounded loop:
;
;     for (int i = 0; i < 2; ++i) {
;         if (q > 5 && q < 20) { q = cq_phi(q, PI); }
;         q = cq_theta(q, -0.5);
;     }
;
; WHAT WAS WRONG. `clang -O1` canonicalizes the range test to
; `%t = add %q, -6; icmp ult %t, 14`, and `%t` therefore wears the dtzb IN-PLACE
; SHAPE (`inPlaceValueRailOperand` — `V OP c` with add/xor and a classical
; immediate). Round 2's Rule-8 fan-out guard counted it beside the arm's real
; `cq_phi` and declined `cq loop lowering: loop-carried rail has multiple in-place
; consumers` — on a program whose hand-unrolled twin compiles. `%t` is a
; DERIVED-CONDITION temp inside a loop body: M-C's G5 (`inPlaceFenceHolds`,
; ArithLowering.cpp) refuses OUTRIGHT any site inside a natural loop or a
; `blockCanRepeat` block, and it is neither a chain member nor in
; `taint.InPlaceRailOps`, so `lowerOps` mints it a FRESH rail. It never mutates the
; loop-carried register and was never a second in-place consumer at all.
;
; THE FIX is `railValueConsumerDisposition` (LoopLowering.cpp) — ONE spelling of
; "will this `BinaryOperator` be lowered in place", shared by both rounds' fan-out
; guards, by `collectRailGates`' forward extension and by `markIfRailLocal`'s
; `onRail` (Rule 14). Only the PROVEN-`OutOfPlace` cell is dropped; the `Unproven`
; straight-line cell still counts and still declines (see
; lowering_reject_inloop_control_rail_fanout.ll).
;
; THE SECOND HEAD OF THE SAME FINDING is `markIfRailLocal`, and it is why this
; fixture checks the DISCHARGE and not just the accept. Its `onRail` also peeled
; `%t` by SHAPE, so `%t` counted as "the register", `AnyLocal` stayed false, the
; body was never certified ITERATION-LOCAL, and the uncompute spine's §2.9 acyclic
; backstop leaked the whole condition chain once per trip — the rolled trace then
; differs from its hand-unrolled twin's, with two M-A warnings and nothing else.
; `peelInPlaceStep`'s `AsLowered` parameter is that fix.
;
; WHAT THIS FILE DOES *NOT* PIN, stated because the mutation was run and the
; comfortable claim was false: it is NOT a witness for the round-4 window-lemma
; change in `Uncomputation.cpp`. Restoring the dominance-bundled
; `provablyBeforePerActivation` spelling of (W1)/(W2) leaves this fixture GREEN —
; this body has no LEADING basis-relabelling gate, so every mutation of the
; borrowed parent is placed by the old legs too. The window lemma's own pins are
; lowering_inloop_derived_cond_leading_gate.ll (the rolled leading gate) and
; lowering_live_record_dead_compare_flag_discharged.ll (the `M == At` adjacency).
;
; MUTATION (both directions verified): make the fan-out guard count `OutOfPlace`
; again and this fixture goes red on the accept; make `onRail` peel by shape again
; and it goes red on the missing `cq_template_add_i32_hl_unc` / `cqrt_free`.
;
; e2e twin: slice_control_grover_loop_range_oracle{,_unrolled} (byte-diff gate).
;
; SINCE bd test_C_libtooling-drbq Increment 2a the flat phase arm lowers
; CONTROL-IN-PLACE (§6a): the arm's `Rz` is ONE
; `cqrt_rz_i32_controlled(flag, register, theta)` and the swap route (work-rail
; alloc, both `cqrt_cswap`s, the rail free) is gone. Nothing else moves — the flag
; mint, the strip, the flag free and every downstream gate are unchanged.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll 2> %t.err
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=SILENT --allow-empty < %t.err
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
; 3qlq: migrated from register cq_phi (tainted arm -> void call, merge phi dissolved)
declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @slice() {
  %1 = call i32 @cq_theta_si32(i32 0, double 5.000000e-01)
  br label %4

2:                                                ; preds = %11
  %3 = call i32 @cq_measure_si32(i32 %13)
  ret i32 %3

4:                                                ; preds = %0, %11
  %5 = phi i32 [ 0, %0 ], [ %14, %11 ]
  %6 = phi i32 [ %1, %0 ], [ %13, %11 ]
  %7 = add i32 %6, -6
  %8 = icmp ult i32 %7, 14
  br i1 %8, label %9, label %11

9:                                                ; preds = %4
  call void @cq_phi(double 0x400921FB54442D18)
  br label %11

11:                                               ; preds = %9, %4
  %13 = call i32 @cq_theta_si32(i32 %6, double -5.000000e-01)
  %14 = add nuw nsw i32 %5, 1
  %15 = icmp eq i32 %5, 0
  br i1 %15, label %4, label %2
}

; ONE persistent rail, ROLLED — the range temp does NOT join it.
; CHECK-LABEL: define{{.*}}@slice(
; CHECK: %h = call i32 @cqrt_alloc_i32(i32 0)
; CHECK: call void @cqrt_ry_i32(i32 %h, double 5.000000e-01)
; CHECK: %m = call i32 @cqrt_measure_i32(i32 %h)
;
; The range temp lands OUT of place, on a FRESH rail (`_hl`, not `cqrt_addc_i32`),
; and the compare is the control of the in-place phase arm.
; CHECK: %h_op = call i32 @cq_template_add_i32_hl(i32 %h, i32 -6)
; CHECK-NEXT: %h_cmp = call i32 @cq_template_icmp_ult_i32_hl(i32 %h_op, i32 14)
; CHECK-NEXT: call void @cqrt_rz_i32_controlled(i32 %h_cmp, i32 %h, double 0x400921FB54442D18)
;
; …and BOTH condition rails are reversed LIFO and freed IN THE BODY, before the
; trailing Ry. This is the `markIfRailLocal` half of the finding.
; CHECK-NEXT: call void @cq_template_icmp_ult_i32_hl_unc(i32 %h_cmp, i32 %h_op, i32 14)
; CHECK-NEXT: call void @cq_template_add_i32_hl_unc(i32 %h_op, i32 %h, i32 -6)
; CHECK-NEXT: call void @cqrt_free(i32 %h_op)
; CHECK-NEXT: call void @cqrt_free(i32 %h_cmp)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %h, double -5.000000e-01)
;
; No `cqrt_addc_i32` anywhere — the range temp is never an in-place rail op.
; CHECK-NOT: cqrt_addc_
;
; The SILENT prefix: no decline, and no M-A warning either (nothing stands at the gate).
; SILENT-NOT: warning
; SILENT-NOT: error
; The swap route must not come back for this flat phase shape. NOROUTE carries NO
; positive anchor, so its window is the whole module — not a dead trailing span
; (bd memory [filecheck-check-not-window-trap]):
; NOROUTE-NOT: call void @cqrt_cswap
