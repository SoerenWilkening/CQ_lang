; control_inplace_ry_crossblock_cse_cond.ll — ACCEPT. bd `test_C_libtooling-drbq.12`
; (2026-09-17), and it is the half of that bead a reader will not predict from its
; title: **the widening moves ACYCLIC programs, and they are HALF the population.**
;
;     int a = cq_theta(0, 0.5);
;     int r = cq_theta(0, 0.3);
;     if (a == 5) { r = cq_theta(r, 0.9); }     // region 1
;     if (a == 5) { r = cq_theta(r, 0.9); }     // region 2
;     return cq_measure(a) + cq_measure(r);
;
; This is the HAND-UNROLLED TWIN of `control_inplace_ry_reject_inloop_invariant_cond_hoisted.ll`
; — the `.unrolled` half of PRD §13.2 row W, where 16 twin-matrix cells declined on
; BOTH sides. There is no loop here at all. `clang -O1` CSEs the two `a == 5`
; compares into ONE `%3` in the ENTRY block, so region 1's `Pred` IS the entry block
; (it always passed P4) while **region 2's `Pred` is region 1's MERGE block `%6`** —
; and `condWireDisposition`'s P4 precondition `Cond->getParent() != R.Pred` refused
; it. The body below is verbatim `clang -O1` output.
;
; ⚠ THE GAP IS NOT EMPTY AND THAT IS THE POINT. Between `%3` and region 2's branch
; sits region 1's whole arm, including `%5 = cq_theta(%2, 0.9)` — a CHAINED,
; NON-DIAGONAL Ry. The wire-BLIND gap scan (`chainedThetaBetweenDefAndBranch`) finds
; it and would decline; `crossBlockCompareMintable` asks whether it names the
; CONDITION's rail, and it does not: the condition's rail closure is `{%3, %1}` and
; the theta's arg-0 is `%2`, a SOURCE theta's own fresh rail. Disjoint rails, so the
; mint at region 2's branch reads exactly the basis the source compare read. This is
; PRD §13.10 Q1's remedy: *"admit a compare that DOMINATES `Pred` when nothing on the
; CONDITION's wire stands between it and `BI`"*.
;
; ⚠ TWO REGIONS, ONE COMPARE, AND THE COMPARE IS STILL ERASED. `RegionFlatten` erases
; a use-empty condition; with two branch users the FIRST flatten leaves it and the
; SECOND erases it. The lowered module below contains no `icmp` at all — that is the
; property the counts pin.
;
; RETIREMENT TRIGGER (L8): if the cross-block prong is narrowed back this file becomes
; a decline expecting
; `cq controlled lowering: condition predates a non-diagonal gate under quantum control`.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s -o %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck --check-prefix=NEG --implicit-check-not="call void @cqrt_x(" --implicit-check-not="call void @cqrt_cswap(" %s < %t.cqd0.ll
; RUN: %filecheck --check-prefix=CNTMINT %s < %t.cqd0.ll
; RUN: %filecheck --check-prefix=CNTSTRIP %s < %t.cqd0.ll
; RUN: %filecheck --check-prefix=CNTFREE %s < %t.cqd0.ll
; RUN: %filecheck --check-prefix=CNTCRY %s < %t.cqd0.ll
; RUN: %filecheck --check-prefix=CNTCMP %s < %t.cqd0.ll
; ---- MUTATION-MATRIX HARDENING (bd `test_C_libtooling-drbq.12`, 2026-09-17) ----
; Rule 12(c): a fixture is validated by MUTATION, not by re-reading its prefixes.
; The first injection-matrix run over this batch reported 21 MISSED over 9 accept
; fixtures — a stray `cqrt_ry` before the `ret`, a duplicated mint, a duplicated
; free, and a `cqrt_x` injected onto the USER REGISTER all slipped through, because
; no whole-file prefix counted those symbols here. The block below is the closure:
; an EXACT count per symbol (a `COUNT-n` followed by its own `-NOT`, which is what
; turns "at least n" into "exactly n"), ONE PREFIX PER SYMBOL because consecutive
; `COUNT`s under a shared prefix scan FORWARD and fall through to the trailing
; `declare` lines, and a pure-negative prefix for the two gates that must never
; appear. Counts are MEASURED off this fixture's own lowered output, never guessed.
; RUN: %filecheck --check-prefix=MXALLOC %s < %t.cqd0.ll
; RUN: %filecheck --check-prefix=MXRY %s < %t.cqd0.ll
; RUN: %filecheck --check-prefix=MXRYC %s < %t.cqd0.ll
; RUN: %filecheck --check-prefix=MXMINT %s < %t.cqd0.ll
; RUN: %filecheck --check-prefix=MXSTRIP %s < %t.cqd0.ll
; RUN: %filecheck --check-prefix=MXFREE %s < %t.cqd0.ll
; RUN: %filecheck --check-prefix=MXMEAS %s < %t.cqd0.ll
; RUN: %filecheck --check-prefix=MXNONE --implicit-check-not="call void @cqrt_x(" --implicit-check-not="call void @cqrt_cswap(" --implicit-check-not="call void @cqrt_cnot(" %s < %t.cqd0.ll

; MXALLOC-COUNT-2: = call i32 @cqrt_alloc_
; MXALLOC-NOT: = call i32 @cqrt_alloc_
; MXRY-COUNT-2: call void @cqrt_ry_i32(
; MXRY-NOT: call void @cqrt_ry_i32(
; MXRYC-COUNT-2: call void @cqrt_ry_i32_controlled(
; MXRYC-NOT: call void @cqrt_ry_i32_controlled(
; MXMINT-COUNT-2: = call i32 @cq_template_icmp_
; MXMINT-NOT: = call i32 @cq_template_icmp_
; MXSTRIP-COUNT-2: call void @cq_template_icmp_
; MXSTRIP-NOT: call void @cq_template_icmp_
; MXFREE-COUNT-2: call void @cqrt_free(
; MXFREE-NOT: call void @cqrt_free(
; MXMEAS-COUNT-2: = call i32 @cqrt_measure_
; MXMEAS-NOT: = call i32 @cqrt_measure_
; MXNONE-NOT: call{{.*}}@cq_theta_
; MXNONE-NOT: call{{.*}}@cq_measure_si32
; MXNONE-NOT: call{{.*}}@cq_phi


; CHECK: %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK: %[[R:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK: call void @cqrt_ry_i32(i32 %[[R]], double 3.000000e-01)
; CHECK: %[[F1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[H]], i32 5)
; CHECK: call void @cqrt_ry_i32_controlled(i32 %[[F1]], i32 %[[R]], double 9.000000e-01)
; CHECK: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F1]], i32 %[[H]], i32 5)
; CHECK: call void @cqrt_free(i32 %[[F1]])
; CHECK: %[[F2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[H]], i32 5)
; CHECK: call void @cqrt_ry_i32_controlled(i32 %[[F2]], i32 %[[R]], double 9.000000e-01)
; CHECK: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F2]], i32 %[[H]], i32 5)
; CHECK: call void @cqrt_free(i32 %[[F2]])
; CHECK: call i32 @cqrt_measure_i32(i32 %[[H]])
; CHECK: call i32 @cqrt_measure_i32(i32 %[[R]])

; The condition register is read only as arg-0 of the mints/strips, as the CONTROL of
; the controlled rotations, and by its measure. Negatives name the CALL, never the
; bare symbol (the module keeps an unused `declare void @cqrt_x(i32)` — bd `qta2`).
; NEG-NOT: call void @cqrt_cnot
; NEG-NOT: call void @cqrt_toffoli
; NEG-NOT: call void @cqrt_rz
; NEG-NOT: call{{.*}}@cq_theta_
; NEG-NOT: call{{.*}}@cq_measure_

; Counts in their own whole-file prefixes (Rule 12(a)). TWO flags, TWO strips, TWO
; frees, TWO controlled rotations, and ZERO surviving `icmp` — the CSE'd compare is
; erased by the SECOND flatten, once its use count reaches zero.
; ⚠ ONE PREFIX PER SYMBOL. Consecutive `COUNT` directives under a SHARED prefix scan
; FORWARD from where the previous one stopped, so four INTERLEAVED symbols cannot be
; counted in one prefix — measured here: the shared-prefix spelling went red on the
; controlled rotations and, at COUNT-1, would instead have matched the trailing
; `declare` line. Every pattern names the CALL and carries its own `-NOT`.
; CNTMINT-COUNT-2: call i32 @cq_template_icmp_eq_i32_hl(
; CNTMINT-NOT: call i32 @cq_template_icmp_eq_i32_hl(
; CNTSTRIP-COUNT-2: call void @cq_template_icmp_eq_i32_hl_unc(
; CNTSTRIP-NOT: call void @cq_template_icmp_eq_i32_hl_unc(
; CNTFREE-COUNT-2: call void @cqrt_free(
; CNTFREE-NOT: call void @cqrt_free(
; CNTCRY-COUNT-2: call void @cqrt_ry_i32_controlled(
; CNTCRY-NOT: call void @cqrt_ry_i32_controlled(
; CNTCMP-NOT: {{ }}icmp{{ }}

declare i32 @cq_theta_si32(i32 noundef, double noundef)
declare i32 @cq_measure_si32(i32 noundef)

define i32 @slice() local_unnamed_addr #0 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01) #2
  %2 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 3.000000e-01) #2
  %3 = icmp eq i32 %1, 5
  br i1 %3, label %4, label %6

4:                                                ; preds = %0
  %5 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef 9.000000e-01) #2
  br label %6

6:                                                ; preds = %4, %0
  %7 = phi i32 [ %5, %4 ], [ %2, %0 ]
  br i1 %3, label %8, label %10

8:                                                ; preds = %6
  %9 = tail call i32 @cq_theta_si32(i32 noundef %7, double noundef 9.000000e-01) #2
  br label %10

10:                                               ; preds = %8, %6
  %11 = phi i32 [ %9, %8 ], [ %7, %6 ]
  %12 = tail call i32 @cq_measure_si32(i32 noundef %1) #2
  %13 = tail call i32 @cq_measure_si32(i32 noundef %11) #2
  %14 = add nsw i32 %13, %12
  ret i32 %14
}

attributes #0 = { nounwind ssp uwtable }
attributes #2 = { nounwind }
