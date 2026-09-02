; control_swap_eqfold_classical_between.ll — ACCEPT, and THE CRASH REGRESSION PIN
; for `ControlRegion::RoutedBase` (round-1 Rule-13 review of bd
; test_C_libtooling-drbq Inc 1, lens L4 §1).
;
;     int q = cq_theta(3, .5);
;     if (q == 5) q = cq_phi(q, .2);   /* region 1: eq-fold phase diamond      */
;     if (cc)     g();                 /* a CLASSICAL branch between them      */
;     if (q == 6) q = cq_phi(q, .3);   /* region 2: eq-fold, base = region 1's */
;     return cq_measure(q);            /*           MERGE φ                    */
;
; THE DEFECT (measured from this exact C at `clang -O1`; a SIGSEGV under
; `DYLD_INSERT_LIBRARIES=/usr/lib/libgmalloc.dylib`, stack
; `emitRoute` → `IRBuilder::CreateCall` → `llvm::CallInst::Create`):
;
; `EqFoldArm` records `Region.RoutedBase` AT DETECTION, and for region 2 that is
; region 1's merge φ. `lowerControlRegions` emits region 1 first, which does
; `MergePhi->replaceAllUsesWith(q); MergePhi->eraseFromParent()`. A raw `Value *`
; is NOT a use, so the RAUW did not update it and the erase left it DANGLING;
; the phase emitter then dereferenced it to read `Q->getType()`.
;
; WHY THE bd hcrg PRE-FLIGHT DOES NOT CATCH IT, which is the lesson: that
; precedence graph reasons about BASIC BLOCK identities (`doomedBlocks`,
; `sequentialChainAlias`), and the classical `if (cc) g();` makes region 2's pred
; a THIRD block rather than region 1's merge block — so it correctly finds no
; block alias, creates no edge, and declines nothing. The dependency it does not
; model is a VALUE one. `RoutedBase` is now a `llvm::WeakTrackingVH`: it FOLLOWS
; the RAUW, so after region 1 collapses its merge φ the field names region 1's
; base — the correct routed handle. (Erased with no replacement is a separate,
; LOUD decline; see `ControlPlan.h`.)
;
; DELETE THE CLASSICAL BRANCH and the same two regions chain through the hcrg
; ordering and always lowered — that pair is the controlled experiment, and it is
; why this fixture keeps the middle block.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=CNT < %t.cqd0.ll

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare void @g()

define i32 @example(i32 %cc) {
entry:
  %q = call i32 @cq_theta_si32(i32 3, double 5.000000e-01)
  %t1 = icmp eq i32 %q, 5
  br i1 %t1, label %arm1, label %merge1
arm1:
  ; `clang -O1` const-folds the arm's `q` to the literal 5 — the eq-fold shape
  ; whose whole point is that the emitter must re-anchor on `RoutedBase`.
  %g1 = call i32 @cq_phi_si32(i32 5, double 2.000000e-01)
  br label %merge1
merge1:
  %m1 = phi i32 [ %g1, %arm1 ], [ %q, %entry ]
  %cz = icmp eq i32 %cc, 0
  br i1 %cz, label %cjoin, label %cbody
cbody:
  call void @g()
  br label %cjoin
cjoin:
  %t2 = icmp eq i32 %m1, 6
  br i1 %t2, label %arm2, label %merge2
arm2:
  %g2 = call i32 @cq_phi_si32(i32 6, double 3.000000e-01)
  br label %merge2
merge2:
  %m2 = phi i32 [ %g2, %arm2 ], [ %m1, %cjoin ]
  %r = call i32 @cq_measure_si32(i32 %m2)
  ret i32 %r
}

; Both regions act on the ONE register %h, in source order, each with its own flag
; mint, controlled arm Rz IN PLACE (drbq Inc 2a — no work rail, no route), strip
; and flag free. The classical call survives between them.
; CHECK:      %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 3)
; CHECK:      %[[F1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[Q]], i32 5)
; CHECK-NEXT: call void @cqrt_rz_i32_controlled(i32 %[[F1]], i32 %[[Q]], double 2.000000e-01)
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F1]], i32 %[[Q]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F1]])
; CHECK:      call void @g()
; the SECOND region names the SAME %h — this is the assertion that the stale
; pointer was replaced by the RAUW target and not by a constant or a corpse
; CHECK:      %[[F2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[Q]], i32 6)
; CHECK-NEXT: call void @cqrt_rz_i32_controlled(i32 %[[F2]], i32 %[[Q]], double 3.000000e-01)
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F2]], i32 %[[Q]], i32 6)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F2]])
; CHECK:      call i32 @cqrt_measure_i32(i32 %[[Q]])

; ONE alloc (the register — the two work rails went with the route at drbq Inc
; 2a), two frees (the two flags), and NO leftover phi.
; CNT-COUNT-1: call i32 @cqrt_alloc_i32(
; CNT-NOT:     call i32 @cqrt_alloc_i32(
