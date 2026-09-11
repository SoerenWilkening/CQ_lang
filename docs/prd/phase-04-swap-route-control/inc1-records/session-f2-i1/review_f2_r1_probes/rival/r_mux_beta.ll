; control_inplace_ry_stateprep_mux_incoming_pinned_accept.ll — ACCEPT.
;
; THE **β** (STRAIGHT-THROUGH-EDGE) HALF OF THE 2026-09-11 RULING, from plain C.
; Built from `probes/bc1.c`:
;
;     int q = cq_theta(u, .5);
;     int r = q;  if (q != 5) r = cq_theta(5, .9);
;
; `-O1` folds the merge phi's **Pred** incoming from `%q` to the literal 5 —
; MEASURED, `%7 = phi i32 [ %5, %4 ], [ %2, %1 ]` — because on the
; straight-through edge `q == 5` is a theorem. So F1 (`state prep merged with a
; quantum register`) sees a `ConstantInt` where the source wrote a quantum-data
; MUX, and F2 used to catch it instead. It no longer does: the pin is `%q`, the
; compare's own operand, hence in `CondWire`.
;
; OWNER RULING 2026-09-11, verbatim: *"WE DO NOT WANT TO WRITE `int b1`. also
; WE DO NOT WANT ANOTHER cq function. it should just be an application of gates
; … I dont see the need for the over-decline."* (bd `drbq.14`; F2's `CondWire`
; narrowing — a pinned value on the CONDITION'S OWN BACKWARD WIRE is no longer a
; collider.)
;
; ---- THE STATE-VECTOR ARGUMENT, because this one is NOT covered by the R4
; ---- theorem that covers the α half (SCOPE H-2).
;
; The rival reading is `r = q` on the straight-through branch — an ALIAS, which
; under Rule 8 is one physical rail under two names. The prep reading is a fresh
; rail prepared to |5>. Those are different circuits; the claim is that on this
; module they are the SAME UNITARY.
;
; 1. The pin is SOUND, not heuristic. `LazyValueInfo::getConstantRangeOnEdge`
;    returns a SUPERSET of the values reachable on that edge, so a SINGLETON
;    means `q == 5` on EVERY execution taking it. (This is the same soundness
;    `clang`'s own IPSCCP relies on to perform the substitution in the first
;    place; if it failed, `-O1` would already be miscompiling.)
;
; 2. Therefore the flag's `f = 0` subspace is spanned by basis states on ALL of
;    which `q`'s rail reads |5>. Within that subspace `q` is the PRODUCT basis
;    state |5> — it carries no superposition, and there is nothing there to
;    clone.
;
; 3. The rival's only reversible realisation is a controlled copy of `q` into a
;    fresh |0> rail (an aliased register cannot change wire-count by branch).
;    On the `f = 0` subspace that copy yields |5>_q ⊗ |5>_r — exactly the state
;    `cqrt_alloc_i32(5)` yields. On the `f = 1` subspace both readings emit the
;    identical fresh prep + controlled Ry, because the ARM's seed is a literal
;    in the source of both. The two readings therefore agree on BOTH subspaces.
;
; 4. What IS given up is not a unitary but a LOUD REFUSAL: the UNFOLDED spelling
;    of the same intent still declines `state prep merged with a quantum
;    register` (MEASURED 2026-09-11 on the narrowed binary: `probes/a_copy.c`,
;    `probes/w2.c`, and the β alternative modules
; `probes/alt/b_coincidence_ne.ll`,
;    `alt/b_a2_alias.ll`, `alt/b_i1_both_edges.ll`). Only the shape `-O1` has
;    already collapsed loses it.
;
; ⚠ AND AN "ARM-EDGE-ONLY" NARROWING WOULD NOT HAVE HELPED THE OWNER: the
; owner's own `grover_oracle_uncompute.c` pin is a β pin (SCOPE §4), so the β
; half had to be taken with the α half or neither.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=ACNT    < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=FCNT    < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=XCNT    < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=RYCNT   < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=CCNT    < %t.cqd0.ll

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice(i32 noundef %0) local_unnamed_addr #0 {
  %2 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 5.000000e-01) #2
  %3 = icmp eq i32 %2, 5
  br i1 %3, label %6, label %4

4:                                                ; preds = %1
  %5 = tail call i32 @cq_theta_si32(i32 noundef 5, double noundef 9.000000e-01) #2
  br label %6

6:                                                ; preds = %4, %1
  %7 = phi i32 [ %5, %4 ], [ %2, %1 ]
  %8 = tail call i32 @cq_measure_si32(i32 noundef %2) #2
  %9 = tail call i32 @cq_measure_si32(i32 noundef %7) #2
  %10 = add nsw i32 %9, %8
  ret i32 %10
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

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

; CHECK:      %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: %[[H_CMP:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[H]], i32 5)
; CHECK-NEXT: call void @cqrt_x(i32 %[[H_CMP]])
; CHECK-NEXT: %[[H1:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 5)
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %[[H_CMP]], i32 %[[H1]], double 9.000000e-01)
; CHECK-NEXT: call void @cqrt_x(i32 %[[H_CMP]])
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[H_CMP]], i32 %[[H]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[H_CMP]])
; CHECK-NEXT: %[[M:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[H]])
; CHECK-NEXT: %[[M2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[H1]])

; ------------------------------------------------------------------
; NEGATIVES — WHOLE-FILE AND PURE (no positive directive inside the
; NOROUTE prefix: a positive `-COUNT-n` WINDOWS every negative after
; it, the drbq Inc-4 round-1 lesson). The counts below are the
; injection matrix's answer: an extra uncontrolled `cqrt_ry` on the
; CONDITION register moves RYCNT, an extra `cqrt_free` moves FCNT, and
; a `_controlled` on the WRONG flag breaks the CHECK capture.
; NOROUTE-NOT: cqrt_cswap
; NOROUTE-NOT: cqrt_copy
; NOROUTE-NOT: _controlled_inv
; NOROUTE-NOT: _controlled_unc
; NOROUTE-NOT: = phi
; NOROUTE-NOT: cq_theta
; NOROUTE-NOT: cq_phi
; THE FREEZE: no `cqrt_free` may ever name the PREPPED rail.
; NOROUTE-NOT: call void @cqrt_free(i32 %h1)
; …and the arm gate must not become UNCONDITIONAL.
; NOROUTE-NOT: call void @cqrt_ry_i32(i32 %h1, double 9.000000e-01)

; ACNT-COUNT-2: call i32 @cqrt_alloc_
; ACNT-NOT:     call i32 @cqrt_alloc_
; FCNT-COUNT-1: call void @cqrt_free(
; FCNT-NOT:     call void @cqrt_free(
; XCNT-COUNT-2: call void @cqrt_x(
; XCNT-NOT:     call void @cqrt_x(
; RYCNT-COUNT-2: call void @cqrt_ry_
; RYCNT-NOT:     call void @cqrt_ry_
; CCNT-COUNT-1: call void @cqrt_ry_i32_controlled(
; CCNT-NOT:     call void @cqrt_ry_i32_controlled(

