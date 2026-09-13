; control_peel_stateprep_bool_seed_int_cond.ll — ACCEPT, and THE bd `rb9x`
; PROGRAM: a `_Bool` state prep under an `int` COMPARE condition in a diamond
; whose merge ALSO carries a peelable `int` mux.
;
; `trackR/probes/b_P2_intcmp_i1seed_peeled.c`, verbatim, through `clang -O1`
; (`-g` stripped; the accept path reads no `!dbg`):
;
;     int  b0 = 0;
;     bool b1 = 0;
;     int  a  = 5;
;     b0 = cq_theta(b0, 0.5);
;     if (b0 == 1) { b1 = cq_theta(b1, 0.5); a = 2; }
;     return cq_measure(b0) + cq_measure(b1) + cq_measure(a);
;
; ⚠ THIS IS THE PEELED TWIN OF `control_inplace_ry_stateprep_bool_seed_int_cond.ll`
; AND IT IS WHY bd `rb9x` EXISTED. Delete the `a = 2;` and the module is that
; fixture's shape and has accepted since 2026-09-11. Add it back and the merge
; carries TWO phis, `peelIndependentMergePhis` (bd `b6ap`) normalises the `a` mux
; into a `select` on a CLONE of the region's own compare — and F2
; (`f2SeedPinnedByLiveRegister`, the drbq Inc-4 state-prep fence) read that clone
; as a live tainted `i1` pinned to the seed on one edge and DECLINED
; `state prep seed is proven equal to the condition register`. Two features that
; are each individually shipped and cleared collided; one `int` assignment in an
; arm was the difference. MEASURED on the ORACLE `fbbe0820ef4b176a`
; (`trackR/probes/README.md`): DECLINE. On this binary: ACCEPT, 20 trace lines,
; STRICT stage 2b `0 violation(s), 0 unproven`.
;
; HOW THE CLONE GOT INTO F2's ANSWER (SCOPE_R.md §1.1, four steps — the
; `MergePhiPeel.cpp` comment that said merge placement kept it out was FALSE):
; F2's BACKWARD half cannot see it (`Cand` filters on `DT->dominates(&In, BI)`
; and the clone is in the merge block), but the FORWARD half walks every tainted
; USER of the condition's pinned operand rail with NO position filter, folds the
; clone to a singleton `i1` through `f2Model`'s `ICmpInst` arm, and matches it
; against the `i1` seed — `true` on one edge, `false` on the other, so BOTH `i1`
; seeds collide (the seed-`true` edge is
; `control_peel_stateprep_bool_seed_true.ll`).
;
; WHY IT IS ADMISSIBLE — THE PREIMAGE ARGUMENT, AND NOT THE "SAME WIRE" ONE
; (bd `rb9x` / R-1). The clone **did not exist in the module `clang` produced**.
; `peelIndependentMergePhis` manufactured it ~90 lines before detection, as
; `S.CondCmp->clone()`, and its only consumer is the peel's own select. F2's
; question is *"the source the author wrote could have been
; `cq_theta(<that register>, θ)`"*; a value the author could not have named is
; not in that question's domain, so there is no rival program to protect
; against. The exclusion is a RECORD (`TaintSet::PeelClones`, written at the
; manufacture site) consulted at F2's equality TEST — never a name test, never a
; shape test, and never a prune of the walk. Read `TaintSet::PeelClones`' header
; for the four retirement triggers.
;
; THE THREE FIXTURES THAT MUST STAY RED, i.e. what this accept does NOT license:
;   * `control_peel_reject_stateprep_handwritten_clone_i1.ll` — the SAME module
;     with the clone+select written BY HAND (so no peel runs and nothing is
;     recorded). Still DECLINES. That is the file that fails if R-1 is ever
;     re-spelled as "an `icmp` that looks like the region's condition".
;   * `control_inplace_ry_reject_stateprep_second_cmp_onwire_{merge,pred}.ll` — a
;     second tainted compare on the condition's wire that the USER wrote. Still
;     DECLINES, in both positions.
;   * `control_peel_reject_fp_stateprep.ll` — the clone is still POPPED and its
;     users are still modelled, so the fp select reachable only through it still
;     fires F2's conservative arm.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=ACNT  < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=FCNT  < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=XCNT  < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=RYCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=CCNT  < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=CPCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=UCNT  < %t.cqd0.ll

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01) #2
  %2 = icmp eq i32 %1, 1
  br i1 %2, label %3, label %5

3:                                                ; preds = %0
  %4 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01) #2
  br label %5

5:                                                ; preds = %3, %0
  %6 = phi i1 [ %4, %3 ], [ false, %0 ]
  %7 = phi i32 [ 2, %3 ], [ 5, %0 ]
  %8 = tail call i32 @cq_measure_si32(i32 noundef %1) #2
  %9 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %6) #2
  %10 = zext i1 %9 to i32
  %11 = add nsw i32 %8, %10
  %12 = tail call i32 @cq_measure_si32(i32 noundef %7) #2
  %13 = add nsw i32 %11, %12
  ret i32 %13
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #1

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}

; THE WHOLE STREAM, IN ORDER. Region 1 (the state prep) fires on the TRUE
; successor, so there is NO `cqrt_x` bracket on its flag; the peeled `a` mux is
; the ordinary 4.4 controlled-copy merge and brings its own X-bracketed pair.
; CHECK:      %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: %[[F1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[H]], i32 1)
; CHECK-NEXT: %[[H1:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_ry_i1_controlled(i32 %[[F1]], i32 %[[H1]], double 5.000000e-01)
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F1]], i32 %[[H]], i32 1)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F1]])
; CHECK-NEXT: %[[F2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[H]], i32 1)
; CHECK-NEXT: %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: %[[S1:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 2)
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[F2]], i32 %[[S1]], i32 %[[OUT]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[F2]])
; CHECK-NEXT: %[[S2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 5)
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[F2]], i32 %[[S2]], i32 %[[OUT]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[F2]])
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F2]], i32 %[[H]], i32 1)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F2]])
; CHECK-NEXT: %[[M0:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[H]])
; CHECK-NEXT: %[[M1:[a-zA-Z0-9_.]+]] = call i1 @cqrt_measure_i1(i32 %[[H1]])

; ------------------------------------------------------------------
; NEGATIVES — WHOLE-FILE AND PURE (no positive directive inside a negative
; prefix: a positive `-COUNT-n` WINDOWS every negative after it, the drbq Inc-4
; round-1 lesson).
; NOROUTE-NOT: cqrt_cswap
; NOROUTE-NOT: _controlled_inv
; NOROUTE-NOT: _controlled_unc
; NOROUTE-NOT: = phi
; NOROUTE-NOT: = select
; NOROUTE-NOT: cq.peel
; NOROUTE-NOT: cq_theta
; NOROUTE-NOT: cq_phi
; NOROUTE-NOT: = icmp
; THE FREEZE (Rule 6): no `cqrt_free` may ever name the PREPPED `i1` rail — a
; controlled `Ry(0.5)|0> != |0>`, so it is LEFT ALLOCATED and measured.
; NOROUTE-NOT: call void @cqrt_free(i32 %h3)
; …and the arm gate must not become UNCONDITIONAL (that would fire the prep on
; both branches — the verify-clean wrong unitary this whole family guards).
; NOROUTE-NOT: call void @cqrt_ry_i1(i32 %h3, double 5.000000e-01)
; …nor may the merge out-rail be freed dirty.
; NOROUTE-NOT: call void @cqrt_free(i32 %out)

; ACNT-COUNT-5: call i32 @cqrt_alloc_
; ACNT-NOT:     call i32 @cqrt_alloc_
; FCNT-COUNT-2: call void @cqrt_free(
; FCNT-NOT:     call void @cqrt_free(
; XCNT-COUNT-2: call void @cqrt_x(
; XCNT-NOT:     call void @cqrt_x(
; RYCNT-COUNT-2: call void @cqrt_ry_
; RYCNT-NOT:     call void @cqrt_ry_
; CCNT-COUNT-1: call void @cqrt_ry_i1_controlled(
; CCNT-NOT:     call void @cqrt_ry_i1_controlled(
; CPCNT-COUNT-2: call void @cqrt_copy_
; CPCNT-NOT:     call void @cqrt_copy_
; UCNT-COUNT-2: call void @cq_template_icmp_eq_i32_hl_unc(
; UCNT-NOT:     call void @cq_template_icmp_eq_i32_hl_unc(
