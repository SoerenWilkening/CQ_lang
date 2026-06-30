; control_swap_reject_nested_loop_irreducible.ll — DECLINE + BROKEN-MODULE
; REGRESSION GUARD (test_C_libtooling-d8jl, adversarial Rule-13 round 2). The
; depth-2 NEST sibling of control_swap_reject_inloop_diamond_irreducible.ll. A
; `goto` INTO a loop body that contains an `if(q>5){…if(q<9){…}}` phase nest makes
; clang -O1 emit an IRREDUCIBLE cyclic CFG (the cycle has TWO entry edges, so no
; natural-loop header dominates it and `LoopInfo`/`getLoopFor` reports NO loop).
; Real, verifier-clean clang -O1 output of:
;
;     int example(int x, double a, double b, int n, int e) {
;         int acc = 0, i = 0;
;         if (e) goto MID;                  // jump INTO the loop body -> irreducible
;         for (; i < n; i++) {
;             int q = cq_theta(x, 0.5);
;             if (q > 5) { q = cq_phi(q, b); if (q < 9) q = cq_phi(q, a); }
;             acc += cq_measure(q);
;         MID:;
;         }
;         return acc;
;     }
;
; WHY recoverRegionTree's OWN loop guard misses it: that guard is a `DominatorTree`
; "successor dominates source" backedge test scoped to edges out of the region set
; {Pred, Mid, InnerArm, Merge}. Here the backedge runs Merge -> latch -> header
; with the latch OUTSIDE the region, and — because the loop is IRREDUCIBLE —
; neither cycle-entry block dominates the other, so NO edge tests as a backedge.
; The nest was therefore ACCEPTED, `flattenRegionTree` erased the merge (a
; backedge source feeding the latch's re-entry phi), and `opt` aborted
; `PHI node entries do not match predecessors! … Broken module` (SIGABRT). The
; shipped fix declines any nest whose entry is on a CFG cycle via the
; reducibility-independent `regionEntryInLoop` walk in the `RegionShape::Nested`
; dispatch, BEFORE recoverRegionTree, firing the same `nested control flow`
; message it already uses for the reducible in-loop nest
; (control_swap_reject_nested_loop.ll). A regression to a DT/LoopInfo-only test
; would crash `opt` here.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}nested control flow under quantum control
; CHECK-NOT: Broken module
; CHECK-NOT: PHI node entries do not match predecessors
; CHECK-NOT: cqrt_cswap

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %x, double %a, double %b, i32 %n, i32 %e) {
entry:
  %c0 = icmp eq i32 %e, 0
  br i1 %c0, label %head, label %latch        ; TWO cycle entries -> irreducible
head:                                          ; preds = %entry, %latch
  %acc = phi i32 [ 0, %entry ], [ %accn, %latch ]
  %i   = phi i32 [ 0, %entry ], [ %inext, %latch ]
  %lt  = icmp slt i32 %i, %n
  br i1 %lt, label %pred, label %exit
pred:                                          ; preds = %head   (outer diamond)
  %q = call i32 @cq_theta_si32(i32 %x, double 5.000000e-01)
  %c1 = icmp sgt i32 %q, 5                      ; outer TAINTED condition
  br i1 %c1, label %mid, label %merge
mid:                                           ; preds = %pred   (inner diamond)
  %g = call i32 @cq_phi_si32(i32 %q, double %b)
  %c2 = icmp slt i32 %g, 9                      ; inner TAINTED condition
  br i1 %c2, label %inner, label %merge
inner:                                         ; preds = %mid
  %h = call i32 @cq_phi_si32(i32 %g, double %a)
  br label %merge
merge:                                         ; preds = %inner, %mid, %pred
  %qm = phi i32 [ %h, %inner ], [ %g, %mid ], [ %q, %pred ]
  %m = call i32 @cq_measure_si32(i32 %qm)
  %sum = add nsw i32 %m, %acc
  br label %latch
latch:                                         ; preds = %entry, %merge
  %accn  = phi i32 [ 0, %entry ], [ %sum, %merge ]
  %iin   = phi i32 [ 0, %entry ], [ %i, %merge ]
  %inext = add nsw i32 %iin, 1
  br label %head
exit:                                          ; preds = %head
  ret i32 %acc
}
