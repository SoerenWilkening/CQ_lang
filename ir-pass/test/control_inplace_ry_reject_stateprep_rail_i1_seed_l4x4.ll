; control_inplace_ry_reject_stateprep_rail_i1_seed_l4x4.ll — DECLINE, AND NOT
; AT F2. The string this file pins is `bare i1 register condition`, not
; `state prep seed is proven equal to the condition register`.
;
; It exists so that the 2026-09-11 ruling cannot be misread as *"the owner's
; `grover_oracle_uncompute.c` compiles now"*. It does not. F2 was **wall 3 of
; 3**, and this file is wall 2 standing in the same program.
;
; OWNER RULING 2026-09-11, verbatim: *"WE DO NOT WANT TO WRITE `int b1`. also
; WE DO NOT WANT ANOTHER cq function. it should just be an application of gates
; … I dont see the need for the over-decline."* (bd `drbq.14`; F2's `CondWire`
; narrowing — a pinned value on the CONDITION'S OWN BACKWARD WIRE is no longer a
; collider.)
;
; `probes/M1.c`, verbatim, through `clang -O1`:
;
;     bool b0 = cq_theta(0, 0.5);    // a BARE RAIL condition: `br i1 %1`
;     bool b1 = 0;
;     if (b0) b1 = cq_theta(b1, 0.5);
;
; With NO compare in front of it, `classifyArms` declines the rail leaf on the
; in-place-Ry / state-prep arm path (bd `l4x4`, Inc 1b-C, OPEN) before F2 is
; ever asked. Its `int`-compare twin —
; `control_inplace_ry_stateprep_bool_seed_int_cond.ll`, one token away —
; ACCEPTS.
;
; ⚠ MEASURED 2026-09-11 ON THE NARROWED BINARY, so this is a statement about the
; shipped tree and not a prediction: `probes/V0.c` (the owner's file, verbatim)
; ⇒ `control flow` (TWO merge phis, bd `b6ap`, wall 1); `probes/C2.c` (V0 minus
; one `cq_measure`, so ONE phi) ⇒ `bare i1 register condition` (wall 2); this
; module ⇒ the same. The narrowing moved exactly one of the three walls.
;
; RETIREMENT: when `l4x4` lands, this file's string changes and it becomes an
; ACCEPT whose emitted stream is `cqrt_alloc_i1(false)` +
; `cqrt_ry_i1_controlled(h_b0, h_new, 0.5)` — with the register `h_b0` ITSELF as
; the control, no mint, no strip, no free. Re-derive it then; do not delete
; it.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; ⚠ THE IR-TEXT `CHECK-NOT`s BELOW ARE VACUOUS BY CONSTRUCTION and are
; kept only as documentation: a `DS_Error` decline writes ZERO bytes to
; stdout, so `2>&1 | FileCheck` sees the diagnostic and nothing else.
; The property they describe — no gate is emitted — is pinned by the
; `not` inversion on the RUN line above, which is what actually fails
; if this module ever lowers.
; CHECK: error: {{.*}}cq controlled lowering: bare i1 register condition under quantum control
; CHECK-NOT: cqrt_ry_i1_controlled


target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define range(i32 0, 3) i32 @main() local_unnamed_addr #0 {
  %1 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01) #2
  br i1 %1, label %2, label %4

2:                                                ; preds = %0
  %3 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01) #2
  br label %4

4:                                                ; preds = %2, %0
  %5 = phi i1 [ %3, %2 ], [ false, %0 ]
  %6 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %1) #2
  %7 = zext i1 %6 to i32
  %8 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %5) #2
  %9 = zext i1 %8 to i32
  %10 = add nuw nsw i32 %9, %7
  ret i32 %10
}

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #1

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

