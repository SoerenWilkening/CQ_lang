; control_phase_kickback_inloop_body_gate.ll — ACCEPT, ROLLED, and the shape
; `clang -O1` ACTUALLY PRODUCES for a rolled Grover (Rule-13 round-1 finding
; F-L5-3; bd test_C_libtooling-3qlq Inc 1 part A, lens L5).
;
;     int q = 0; cq_theta(&q, 0.5);
;     for (int i = 0; i < 2; ++i) {
;         if (q == PI_INDEX) cq_phi(PI);      // the oracle
;         cq_theta(&q, -0.5);              // the diffusion
;     }
;     return cq_measure(q);
;
; `clang -O1` output verbatim. The BODY'S OWN `cq_theta` is what makes this
; compile, and that is the finding: it makes the condition register LOOP-VARIANT,
; so the compare stays in the loop and `condWireDisposition`'s P4 precondition is
; satisfied. Without it — `for (…) { if (q == k) cq_phi(θ); }` alone — `-O1`
; LICM-hoists the compare into the preheader and the program declines
; `condition predates a non-diagonal gate under quantum control`
; (`control_phase_kickback_reject_inloop_invariant_cond_hoisted.ll`).
;
; WHY THAT NEEDED ITS OWN FIXTURE: the increment's only P6 accept
; (`control_phase_kickback_inloop.ll`) is hand-written IR that puts the compare in
; the loop HEADER on a register the body never gates — a module `-O1` does not
; produce — and its header called that "Grover with a diffusion". A reader of the
; suite would have concluded P6 covers the plain C spelling. It does not; this
; file covers the one it does.
;
; WHAT A KICKBACK NEEDS FROM THE ROUND-2 RAIL COLLAPSE HERE: the ordinary Case-A
; collapse of `q`'s loop-carried header phi, because the body's `cq_theta` DOES
; gate it. The kickback itself contributes nothing to collapse — its only ancilla
; is the flag, minted, stripped and freed inside the iteration, so nothing of the
; region crosses the back edge.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=ACNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=FCNT < %t.cqd0.ll

; ROLLED — one region + one diffusion gate in a body the back edge re-enters.
; CHECK: %[[F:.*]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %h, i32 5)
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[F]], double 0x400921FB54442D18), !cq.branchphase
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F]], i32 %h, i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %h, double -5.000000e-01)

; ONE of each in the rolled body — the IR size is independent of the trip count.
; ACNT-COUNT-1: call void @cqrt_rz_i1(
; ACNT-NOT: call void @cqrt_rz_i1(

; NOROUTE is WHOLE-FILE and PURE-NEGATIVE.
; NOROUTE-NOT: @cqrt_cswap
; NOROUTE-NOT: _controlled
; NOROUTE-NOT: @cq_phi
; NOROUTE-NOT: call void @cqrt_rz_{{(i8|i16|i32|i64|f16|f32|f64|f80)}}(
; NOROUTE-NOT: call void @cqrt_x(
; NOROUTE-NOT: double -0x
; NOROUTE-NOT: fneg


; ── Rule-13 ROUND-2 finding F-R2-1, the assertion repair ────────────────────
; Round 1 repaired three assertion families (the 8-width Rz negative, the
; `cqrt_x` negative, the `cqrt_free` count) in the corpus IT could see, and the
; merge brought in a set that had never been asked the same question. Measured by
; injection at `c4bd888`: `cqrt_rz_f80`/`f16` NOT CAUGHT in 18 accepts, an
; UNPAIRED `cqrt_x` (a wrong-branch phase) NOT CAUGHT in 21, an EXTRA
; `cqrt_free` (a hidden measurement, Rule 6) NOT CAUGHT in 20. Every accept in
; the branch now carries all three, and each is validated by injecting the line
; into this fixture's OWN output.

; The `cqrt_free` census. An EXTRA free is a hidden measurement (Rule 6).
; FCNT-COUNT-1: call void @cqrt_free(
; FCNT-NOT: call void @cqrt_free(


target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @slice() local_unnamed_addr #0 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01) #1
  br label %4

2:                                                ; preds = %9
  %3 = tail call i32 @cq_measure_si32(i32 noundef %10) #1
  ret i32 %3

4:                                                ; preds = %0, %9
  %5 = phi i32 [ 0, %0 ], [ %11, %9 ]
  %6 = phi i32 [ %1, %0 ], [ %10, %9 ]
  %7 = icmp eq i32 %6, 5
  br i1 %7, label %8, label %9

8:                                                ; preds = %4
  tail call void @cq_phi(double noundef 0x400921FB54442D18) #1
  br label %9

9:                                                ; preds = %8, %4
  %10 = tail call i32 @cq_theta_si32(i32 noundef %6, double noundef -5.000000e-01) #1
  %11 = add nuw nsw i32 %5, 1
  %12 = icmp eq i32 %5, 0
  br i1 %12, label %4, label %2
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1
declare void @cq_phi(double noundef) local_unnamed_addr #1
declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

attributes #0 = { nounwind ssp uwtable }
attributes #1 = { nounwind }
