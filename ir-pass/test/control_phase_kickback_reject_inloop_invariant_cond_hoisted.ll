; control_phase_kickback_reject_inloop_invariant_cond_hoisted.ll — DECLINE.
; Rule-13 round-1 finding F-L5-3 (bd test_C_libtooling-3qlq Inc 1 part A, lens
; L5): the OVER-DECLINE that the shipped P6 accept fixture hid.
;
;     int q = cq_theta(0, 0.5);
;     for (int i = 0; i < 2; ++i) { if (q == 5) cq_phi(PI); }   // q untouched
;     return cq_measure(q);
;
; `clang -O1` output verbatim. With NO gate on `q` in the body the condition
; register is LOOP-INVARIANT, so LICM hoists `%2 = icmp eq i32 %1, 5` into the
; PREHEADER (block `%0` here, NOT the loop header where the shipped accept
; fixture hand-writes it). `condWireDisposition`'s P4 precondition
; `Cond->getParent() != R.Pred` — an unbounded gap across blocks — then returns
; `DeclineNow` before any rotation clause runs.
;
; THIS IS bd `drbq.12`'s OVER-DECLINE ARRIVING AT THE PHASE STEM, where it did
; not previously exist. Under the retired register surface a phase arm always
; gated `q` (`q = cq_phi(q, θ)`), so the register was loop-VARIANT and the
; compare stayed put; the pre-3qlq oracle ACCEPTS this program's register
; spelling. Under kickback a pure-phase body gates nothing, so `if (q == k)
; cq_phi(θ)` alone in a loop is ALWAYS hoisted and ALWAYS declines. The Ry stem's
; identical class has had a fixture since drbq Inc 3
; (`control_inplace_ry_reject_inloop_invariant_cond_hoisted.ll`); the phase stem
; had none, so nothing said the suite does not cover this spelling.
;
; TWO ONE-TOKEN WORKAROUNDS, both MEASURED to accept: gate the register in the
; body (`q = cq_theta(q, -0.5);`, i.e. an actual Grover diffusion — see
; `control_phase_kickback_inloop_body_gate.ll`), or make the threshold opaque
; (`volatile int off;` … `q == 5 + off`), which defeats LICM.
;
; LOUD AND SAFE (Prime Directive), so it ships as a decline rather than as a
; widening — `condWireDisposition`'s P4 clause is a POSITIONAL fence in the
; Rule-13 core and moving it is its own increment with its own adversarial round.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error: {{.*}}cq controlled lowering: condition predates a non-diagonal gate under quantum control
; CHECK-NOT: cqrt_rz

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @slice() local_unnamed_addr #0 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01) #1
  %2 = icmp eq i32 %1, 5
  br label %5

3:                                                ; preds = %8
  %4 = tail call i32 @cq_measure_si32(i32 noundef %1) #1
  ret i32 %4

5:                                                ; preds = %0, %8
  %6 = phi i32 [ 0, %0 ], [ %9, %8 ]
  br i1 %2, label %7, label %8

7:                                                ; preds = %5
  tail call void @cq_phi(double noundef 0x400921FB54442D18) #1
  br label %8

8:                                                ; preds = %5, %7
  %9 = add nuw nsw i32 %6, 1
  %10 = icmp eq i32 %6, 0
  br i1 %10, label %5, label %3
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1
declare void @cq_phi(double noundef) local_unnamed_addr #1
declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

attributes #0 = { nounwind ssp uwtable }
attributes #1 = { nounwind }
