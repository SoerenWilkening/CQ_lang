; control_peel_reject_three_pred_merge.ll — DECLINE `control flow` (bd
; test_C_libtooling-b6ap, P1): the merge has THREE predecessors (a classical guard
; on an EXTERNAL global joins it directly, so nothing folds the edge away).
; `hasNPredecessors(2)` refuses, and the region keeps its existing message.
;
; ⚠ THAT ONE CLAUSE CARRIES THREE LOADS, which is why it is pinned on its own:
; (i) it is what `soleMergePhi`'s 2-incoming phi proves for the shapes that HAVE
; one, and this stage has no phi to read it off — the same reason
; `classifyPhaseKickback` and `lowerControlledIOSinks` ask it directly;
; (ii) it makes every phi's incoming-block list exactly {TruePred, FalsePred}, so
; the polarity lookup is total; and
; (iii) it STRUCTURALLY EXCLUDES the depth-2 nest, whose shared merge has three
; predecessors — so the peel can never disturb a `RegionTreeDetect` accept and
; needs no `Claimed`-set bookkeeping of its own.
;
; A SECOND, INDEPENDENT FENCE also refuses this module: P7 requires the compare's
; operands to dominate the MERGE, and with the extra entry edge they do not.;
; bd `test_C_libtooling-b6ap` — THE MULTI-PHI MERGE PEEL (`MergePhiPeel.cpp`), one
; row of its P1-P9 DECLINE PARTITION. The peel is ACCEPT-ONLY and NEVER diagnoses:
; a shape that fails any clause is left BYTE-UNTOUCHED and reaches its existing
; loud owner unchanged. Over-declining is safe (Prime Directive); the peel's job is
; to remove a BOOKKEEPING over-decline, not to widen the accept class.

; ⚠ A `DS_Error` decline writes 0 bytes to stdout, so every IR-text negative a
; decline fixture could carry is VACUOUS; what pins "no silent lowering" here is
; the `not` inversion on the RUN line (exit non-zero) plus the string, mirrored
; character-for-character below.
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

@g = external global i32
define i32 @example() {
entry:
  %k = load volatile i32, ptr @g, align 4
  %kc = icmp eq i32 %k, 9
  br i1 %kc, label %m, label %p
p:
  %b0 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01)
  %c = icmp eq i32 %b0, 1
  br i1 %c, label %m, label %a
a:
  %t = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01)
  br label %m
m:
  %b1 = phi i32 [ %t, %a ], [ 0, %p ], [ 0, %entry ]
  %mux = phi i32 [ 5, %a ], [ 2, %p ], [ 1, %entry ]
  %x1 = tail call i32 @cq_measure_si32(i32 noundef %b1)
  %s = add nsw i32 %x1, %mux
  ret i32 %s
}
declare i32 @cq_theta_si32(i32 noundef, double noundef)
declare i32 @cq_measure_si32(i32 noundef)

; CHECK: <unknown>:0:0: in function example i32 (): cq controlled lowering: control flow under quantum control
