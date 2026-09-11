; control_inplace_ry_stateprep_bool_seed_int_cond.ll — ACCEPT, and THE OWNER'S
; SHAPE at the one width it is reachable at today.
;
; `probes/M2.c`, verbatim, through `clang -O1`:
;
;     int  q  = cq_theta(0, 0.5);
;     bool b1 = 0;
;     if (q > 5) b1 = cq_theta(b1, 0.5);
;     return cq_measure(q) + cq_measure(b1);
;
; OWNER RULING 2026-09-11, verbatim: *"WE DO NOT WANT TO WRITE `int b1`. also
; WE DO NOT WANT ANOTHER cq function. it should just be an application of gates
; … I dont see the need for the over-decline."* (bd `drbq.14`; F2's `CondWire`
; narrowing — a pinned value on the CONDITION'S OWN BACKWARD WIRE is no longer a
; collider.)
;
; ⚠ THIS IS THE FIXTURE THE RULING WAS WRITTEN FOR. Before it, this program
; declined `state prep seed is proven equal to the condition register`, and the
; only workaround was to widen `b1` to `int` — *"WE DO NOT WANT TO WRITE `int
; b1`"*. It compiles now, to gates and nothing else (no new `cq_*` function, no
; new runtime symbol):
;
;     cqrt_alloc_i1(false)                       <- the bool rail, prepared
;     cqrt_ry_i1_controlled(f, h1, 0.5)          <- the arm, under the flag
;
; WHY IT COLLIDED. There is no `i1` special case anywhere in F2 — the collision
; is a CONSEQUENCE of the candidate list. The branch's own condition `%2` is a
; tainted `i1` that dominates the branch, and LVI pins it to `{true}` on one
; edge and `{false}` on the other, so **every** `i1` seed matches one of the two
; edges. That is the whole of the retired "THE `i1` STATE-PREP WIDTH IS OUT"
; (bd `drbq.14`). The narrowing removes it because `%2` IS `Region.Condition`,
; the first element of `CondWire`.
;
; ⚠ SAY THE RESIDUAL, because the ruling is *"`i1` is no longer CATEGORICALLY
; out"*, NOT *"`i1` is in"*: an `i1` seed still collides with a tainted `i1`
; that is NOT on this branch's wire — a second, independent compare's result.
; `control_inplace_ry_reject_stateprep_second_flag_i1.ll` pins that, and it
; declines (SCOPE H-7).
;
; ⚠ AND THIS IS NOT THE OWNER'S `grover_oracle_uncompute.c`. That file's
; condition is a BARE RAIL (`br i1 %b0`, no compare), which declines at
; `bare i1 register condition` — bd `l4x4`, wall 2 of 3 — one stage before F2 is
; ever asked; and its own shape carries TWO merge phis, which declines `control
; flow` (bd `b6ap`, wall 1). MEASURED 2026-09-11 on the narrowed binary:
; `probes/V0.c` ⇒ `control flow`, `probes/C2.c` and `probes/M1.c` ⇒ `bare i1
; register condition`. F2 was wall 3, and only wall 3 moved.
; `control_inplace_ry_reject_stateprep_rail_i1_seed_l4x4.ll` is that fact as a
; fixture.
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
define i32 @main() local_unnamed_addr #0 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01) #2
  %2 = icmp sgt i32 %1, 5
  br i1 %2, label %3, label %5

3:                                                ; preds = %0
  %4 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %2, double noundef 5.000000e-01) #2
  br label %5

5:                                                ; preds = %3, %0
  %6 = phi i1 [ %4, %3 ], [ false, %0 ]
  %7 = tail call i32 @cq_measure_si32(i32 noundef %1) #2
  %8 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %6) #2
  %9 = zext i1 %8 to i32
  %10 = add nsw i32 %7, %9
  ret i32 %10
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

; CHECK:      %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: %[[H_CMP:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[H]], i32 5)
; CHECK-NEXT: %[[H1:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_ry_i1_controlled(i32 %[[H_CMP]], i32 %[[H1]], double 5.000000e-01)
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[H_CMP]], i32 %[[H]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[H_CMP]])
; CHECK-NEXT: %[[M:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[H]])
; CHECK-NEXT: %[[M2:[a-zA-Z0-9_.]+]] = call i1 @cqrt_measure_i1(i32 %[[H1]])

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
; NOROUTE-NOT: call void @cqrt_ry_i1(i32 %h1, double 5.000000e-01)

; ACNT-COUNT-2: call i32 @cqrt_alloc_
; ACNT-NOT:     call i32 @cqrt_alloc_
; FCNT-COUNT-1: call void @cqrt_free(
; FCNT-NOT:     call void @cqrt_free(
; XCNT-NOT:     call void @cqrt_x(
; RYCNT-COUNT-2: call void @cqrt_ry_
; RYCNT-NOT:     call void @cqrt_ry_
; CCNT-COUNT-1: call void @cqrt_ry_i1_controlled(
; CCNT-NOT:     call void @cqrt_ry_i1_controlled(

