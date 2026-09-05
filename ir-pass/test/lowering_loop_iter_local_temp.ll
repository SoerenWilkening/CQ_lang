; lowering_loop_iter_local_temp.ll — ACCEPT (Phase 7.3 Inc 2, 799w.2): the Case B
; iteration-local born-and-dies temporary
;     for (int i = 0; i < n; i++) {
;         int q = cq_theta(x, 0.25);   // fresh rail, born in body
;         int t = q ^ 9;               // template producer (born)
;         (void) cq_phi(t, 0.5);       // Rz keep-alive; result dead -> t & q die
;     }
; lowers with a PER-ITERATION IN-BODY uncompute. Verified against real `clang -O1`
; output (Rule 11): a single-block loop body whose ONLY loop phi is the classical
; induction (no tainted header phi, no loop-carried rail), every tainted value
; (the fresh alloc `q`, the `xor` temp `t`, the dead `cq_phi`) BORN AND DEAD within
; one iteration.
;
; THE SPINE SURGERY (PRD §2.5): `lowerLoops` recognizes the iteration-local loop
; and marks its body block; the Phase-5 spine then LIFTS its two backedge guards
; (FreePoint kMsgLoopBackedge + Uncomputation §2.9 InLoop) for the proven
; iteration-local DAG and places the whole-DAG recovery + `cqrt_free` IN-BODY —
; after the temp's last in-iteration use (the keep-alive Rz), before the backedge,
; proven to execute exactly ONCE PER ITERATION (never the function-scope post-
; dominator, which would free the rail K times → use-after-free + double-free, the
; central Rule-13 hazard). The reversal is the standard whole-DAG LIFO: rz(-0.5)
; (undo keep-alive) -> xor `_unc` (reads the live `q`) -> free t-rail -> ry(-0.25)
; (undo mint) -> free q-rail.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
;
; The whole compute+uncompute pair lives INSIDE the loop body, before the backedge:
; CHECK:      loop:
; Forward compute (fresh rail mint, the xor temp, the keep-alive Rz):
; CHECK:        %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %x)
; CHECK:        call void @cqrt_ry_i32(i32 %[[Q]], double 2.500000e-01)
; CHECK:        %[[T:[a-zA-Z0-9_.]+]] = call i32 @cq_template_xor_i32_hl(i32 %[[Q]], i32 9)
; In-body LIFO uncompute (negated keep-alive -> xor `_unc` reading live %[[Q]] ->
; free t-rail -> negated mint -> free q-rail), all before the backedge branch:
; CHECK:   call void @cq_template_xor_i32_hl_unc(i32 %[[T]], i32 %[[Q]], i32 9)
; CHECK-NEXT:   call void @cqrt_free(i32 %[[T]])
; CHECK-NEXT:   call void @cqrt_ry_i32(i32 %[[Q]], double -2.500000e-01)
; CHECK-NEXT:   call void @cqrt_free(i32 %[[Q]])
; CHECK:        br i1 %{{.*}}, label %exit, label %loop
; No fresh-minting `_inv`, no added measurement, no surviving front-end intrinsic:
; CHECK-NOT:  cq_template_xor_i32_hl_inv
; CHECK-NOT:  cqrt_measure
; CHECK-NOT:  cq_theta_si32
; CHECK-NOT:  cq_phi_si32
; 3qlq: migrated from register cq_phi (uncontrolled -> deleted (D2))

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)

define void @slice(i32 %x, i32 %n) {
entry:
  %guard = icmp sgt i32 %n, 0
  br i1 %guard, label %loop, label %exit

loop:                                             ; preds = %entry, %loop
  %i = phi i32 [ 0, %entry ], [ %inext, %loop ]   ; classical induction (NO tainted header phi)
  %q = call i32 @cq_theta_si32(i32 %x, double 2.500000e-01) ; fresh rail, born in body
  %t = xor i32 %q, 9                              ; template producer (born)
  %inext = add nuw nsw i32 %i, 1
  %done = icmp eq i32 %inext, %n                  ; classical exit condition
  br i1 %done, label %exit, label %loop

exit:                                             ; preds = %entry, %loop
  ret void
}
