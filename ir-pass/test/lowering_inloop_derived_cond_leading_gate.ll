; lowering_inloop_derived_cond_leading_gate.ll — ACCEPT (bd test_C_libtooling-8h7d.5,
; Rule-13 ROUND 4, finding F-4). The rolled loop whose body puts a BASIS-RELABELLING
; GATE BEFORE the tainted region, and whose derived-condition ancilla chain therefore
; used to LEAK once per trip:
;
;     for (int i = 0; i < 2; ++i) {
;         q = cq_theta(q, 0.25);                   /* the LEADING Ry */
;         if ((q & 3) == 1) { q = cq_phi(q, PI); } /* a DERIVED condition */
;         q = cq_theta(q, -0.5);
;     }
;
; WHAT WAS WRONG. The M-B interior partition proves clause (d1) — "the borrowed
; parent holds, at every emitted `_unc`, the value it held when the forward gate
; ran" — over the window `(T_First, T_At)`, and the mutation it must place here is
; the NEXT iteration's leading `cqrt_ry`, which sits textually BEFORE `First` in the
; body. Rounds 1-3 spelt the "M is outside the window" legs with `First` in the
; barrier slot, so the forward walk from `First` reached that Ry around the back edge
; WITHOUT re-entering `First`, the leg failed, and the whole component was abandoned:
; `cq_template_and_i32_hl(%h, 3)` was minted, never `_unc`-reversed and never freed,
; and the trailing `cqrt_ry` then fired over a LIVE, ENTANGLED record of the wire
; (Rule 8 — a dirty entangled rail dephases under later interference).
;
; IT WAS INVISIBLE TO EVERY SHIPPED GATE. `opt` exited 0, `opt -verify` was clean,
; STRICT `free_pairing_check.py` reported 0 violations (it counts `cqrt_alloc` mints,
; and this rail is TEMPLATE-minted), and with no leading `cq_phi` to trip the M-A
; guard the run was SILENT. The only witness is the hand-unrolled twin, which
; discharges the chain — which is why the e2e pair
; slice_control_grover_loop_leading_gate{,_unrolled} ships with a byte-diff twin gate,
; and why tools/loop_twin_matrix.py now runs the whole prefix x region x suffix matrix.
;
; THE FIX is the window lemma at the borrowed-parent scan (Uncomputation.cpp). The
; certificate that places the leading Ry is (W2) — "every path `M` -> `At`
; re-executes `First`" — asked as the BARE barrier walk. Rounds 1-3 asked it through
; `provablyBeforePerActivation`, which bundles a `DT.dominates` conjunct that no step
; of the window proof uses; the leading Ry does not dominate the discharge point, so
; the leg failed on a premise it never needed. `M == At` is also REACHABLE here
; (`At` is `getNextNode()` of the last consumer of an owned rail, which is the
; TRAILING `cqrt_ry`), and (W2) places that one too.
;
; MUTATION (both directions verified): restore the `provablyBeforePerActivation`
; spelling of (W1)/(W2) and this fixture goes red on the missing
; `cq_template_and_i32_hl_unc` / `cqrt_free`.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll 2> %t.err
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=SILENT --allow-empty < %t.err
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @slice() {
  %1 = call i32 @cq_theta_si32(i32 0, double 5.000000e-01)
  br label %4

2:                                                ; preds = %12
  %3 = call i32 @cq_measure_si32(i32 %14)
  ret i32 %3

4:                                                ; preds = %0, %12
  %5 = phi i32 [ 0, %0 ], [ %15, %12 ]
  %6 = phi i32 [ %1, %0 ], [ %14, %12 ]
  %7 = call i32 @cq_theta_si32(i32 %6, double 2.500000e-01)
  %8 = and i32 %7, 3
  %9 = icmp eq i32 %8, 1
  br i1 %9, label %10, label %12

10:                                               ; preds = %4
  %11 = call i32 @cq_phi_si32(i32 %7, double 0x400921FB54442D18)
  br label %12

12:                                               ; preds = %10, %4
  %13 = phi i32 [ %11, %10 ], [ %7, %4 ]
  %14 = call i32 @cq_theta_si32(i32 %13, double -5.000000e-01)
  %15 = add nuw nsw i32 %5, 1
  %16 = icmp eq i32 %5, 0
  br i1 %16, label %4, label %2
}

; ONE persistent rail, the loop stays ROLLED (one body block, one back edge).
; CHECK-LABEL: define{{.*}}@slice(
; CHECK: %h = call i32 @cqrt_alloc_i32(i32 0)
; CHECK: call void @cqrt_ry_i32(i32 %h, double 5.000000e-01)
; The rail is MEASURED, never freed — it is the user's register (Rule 6). `-O1`
; hoists the exit block above the body, so this line precedes the body checks.
; CHECK: %m = call i32 @cqrt_measure_i32(i32 %h)
;
; The body: the LEADING Ry, then the derived chain, then the routed phase arm.
; CHECK: call void @cqrt_ry_i32(i32 %h, double 2.500000e-01)
; CHECK-NEXT: %h_op = call i32 @cq_template_and_i32_hl(i32 %h, i32 3)
; CHECK-NEXT: %h_cmp = call i32 @cq_template_icmp_eq_i32_hl(i32 %h_op, i32 1)
; CHECK: call void @cqrt_cswap(i32 %h_cmp, i32 %h, i32 %rail)
; CHECK: call void @cqrt_rz_i32(i32 %rail, double 0x400921FB54442D18)
; CHECK: call void @cqrt_cswap(i32 %h_cmp, i32 %h, i32 %rail)
; CHECK: call void @cqrt_free(i32 %rail)
;
; THE FINDING, IN THREE LINES. Both records are reversed LIFO and freed, IN THE
; BODY, and — the part that was missing — the `and` record's `_unc` and `cqrt_free`
; land BEFORE the trailing `cqrt_ry`, not after it and not never.
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %h_cmp, i32 %h_op, i32 1)
; CHECK-NEXT: call void @cq_template_and_i32_hl_unc(i32 %h_op, i32 %h, i32 3)
; CHECK-NEXT: call void @cqrt_free(i32 %h_op)
; CHECK-NEXT: call void @cqrt_free(i32 %h_cmp)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %h, double -5.000000e-01)
;
; SILENT — no M-A warning, because nothing is standing at either gate. The pre-fix
; module was silent too on THIS spelling (the leading gate is an Ry, and the M-A
; guard's `preservesBorrowedParent` clause only ever caught the `cq_phi` variant),
; so this prefix is a regression pin, never the finding's witness.
; SILENT-NOT: warning
; SILENT-NOT: error
