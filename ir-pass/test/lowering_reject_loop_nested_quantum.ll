; lowering_reject_loop_nested_quantum.ll — DECLINE (Phase 7.3 Inc 2, 799w.2): a
; NESTED quantum loop must NOT be folded into the outer iteration-local set. This
; is the adversarial regression pin for a SILENT MISCOMPILE found during Rule-13
; review of Increment 2 (and confirmed): an outer loop mints a fresh rail `q` in
; its body, an inner DO-WHILE loop rotates it (the inner body has NO zero-trip
; guard, so it DOMINATES the outer recovery point — the `DT.dominates(G, At)`
; divergent-arm backstop does NOT catch it), then `q` is dead.
;
; Without the guard, `tryCaseA` collapses the inner rail (rolled `cqrt_rz(%h, .1)`
; running n times per outer iteration), `markIfIterationLocal` marks the OUTER loop
; (its per-instruction scan skips the subloop block), and the Phase-5 spine reverses
; that rotation ONCE at the outer-body recovery point — freeing `%h` after one
; `cqrt_rz(%h, -.1)` though it was rotated n times: a DIRTY free of an
; (n-1)-rotations-un-reversed rail (a hidden collapse, verify-clean, Rule 6/8).
;
; THE GUARD (LoopLowering::markIfIterationLocal): a loop with a strictly-deeper
; SUBLOOP carrying tainted content is left UNMARKED unless that subloop is
; iteration-local ON ITS OWN (bd 01po.19.34 narrowed the old blanket refusal to
; that, by recursion into the same predicate). Here it is not: the inner loop
; reads `%q`, minted in the OUTER body (a tainted operand defined outside it),
; and carries a tainted header phi. So the outer loop stays unmarked and `q`'s
; terminal keeps FreePoint's `kMsgLoopBackedge` reject (its use is the in-loop
; inner rotation). Lowering it (reverse the inner rotations per outer trip) is a
; capability gap, not a physics decline (R1). The accept side of the narrowing
; is railwindow_dicke_n5k3_nested_accept.ll.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq uncompute: tainted handle live range crosses a loop backedge
; 3qlq: migrated from register cq_phi (uncontrolled -> deleted (D2))

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)

define void @slice(i32 %x, i32 %m, i32 %n) {
entry:
  br label %outer

outer:                                            ; preds = %entry, %odone
  %j = phi i32 [ 0, %entry ], [ %jn, %odone ]
  %q = call i32 @cq_theta_si32(i32 %x, double 2.500000e-01) ; fresh rail in outer body
  br label %inner

inner:                                            ; preds = %outer, %inner  (do-while: >=1 trip)
  %qh = phi i32 [ %q, %outer ], [ %qh, %inner ]
  %ii = phi i32 [ 0, %outer ], [ %iin, %inner ]
  %iin = add i32 %ii, 1
  %idone = icmp slt i32 %iin, %n
  br i1 %idone, label %inner, label %odone

odone:                                            ; preds = %inner
  %jn = add i32 %j, 1
  %jdone = icmp slt i32 %jn, %m
  br i1 %jdone, label %outer, label %exit

exit:                                             ; preds = %odone
  ret void
}
