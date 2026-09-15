; control_swap_reject_select_rail_round2_plainc_twotu.ll — DECLINE (bd
; test_C_libtooling-r9e5 1b-B.1, Rule-13 ROUND-2 finding F-B1R2-1 — THE PLAIN-C
; REPRODUCER, committed as the `clang -O1` + `llvm-link` STAGE-1 MODULE it
; really is rather than as hand IR, because this is the one that makes the
; finding a CONFIRMED silent miscompile rather than an argument about hand IR).
; The reviewer's probe `multi/e16_{caller,lib}.c`, two TUs through the shipped
; 6.5 recipe (per-TU `-O1` IR -> `llvm-link` -> ONE `cq-lowering`):
;
;   int ext_f(int a);                    /* e16_lib.c: { return a + 100; } */
;   int slice(void) {
;       int q = 3;  q = cq_theta(q, 0.5);
;       int y = 5;
;       if (q > 5) y = ext_f(7);         /* 6.5 classical-call arm -> %out  */
;       int keep = cq_measure(y);        /* keeps %out live as an i32 phi   */
;       bool x  = (y != 0);              /* CLASSICAL at round 1            */
;       bool b  = cq_theta(x, 0.25);
;       bool b3 = cq_theta(x, 0.9);      /* SIBLING on the same wire        */
;       int a = b ? 2 : 5;               /* the rail select reads `b`       */
;       return cq_measure(a) + cq_measure(b3) + keep;
;   }
;
; ⚠ THERE IS NO e2e DECLINE MODE, which is why this lives here and not in
; `tests/e2e`: `run_slice_multi.sh` runs under `set -euo pipefail` and byte-diffs
; a golden, so a program whose `opt` exits non-zero cannot be registered as a
; passing slice at all (MEASURED: no `WILL_FAIL` and no decline runner exists in
; `tests/e2e/CMakeLists.txt`). Committing the linked stage-1 module keeps the
; plain-C provenance of the pin without inventing a harness mode.
;
; RED ON f8d29e8 (the round-1-fix checkpoint): rc=0, 29 trace lines, stage 2b
; `2 verified, 0 violation(s), 0 unproven`, links and runs — with
;   cq_template_icmp_ne_i32_hl(h2, 0) -> h5     <- %x's rail
;   cqrt_ry_i1(h5, 0x1p-2)                      <- b  = θ(x, 0.25)
;   cqrt_ry_i1(h5, 0x1.ccccccccccccdp-1)        <- b3 = θ(x, 0.9)  ** SAME RAIL **
;   cqrt_alloc_i1(0) -> h6
;   cqrt_cnot(h5, h6)                           <- the select's control read
; i.e. the copies controlled on Ry(0.9)Ry(0.25)|x> while the select's condition
; names Ry(0.25)|x>. On `main` b00fdc2 the same program declines
; `bare i1 register condition`, so this increment is what turned a loud decline
; into a wrong unitary for the rail spelling — which is why the fix is B.1's.
; The COMPARE spelling of the same window (`multi/e13`) accepts identically on
; `main` and is a PRE-EXISTING P1 filed as bd `9pum`; it is deliberately NOT
; widened here.
;
; ⚠ A `DS_Error` decline writes 0 bytes to stdout, so every IR-text negative a
; decline fixture could carry is VACUOUS; what pins "no silent lowering" here is
; the `not` inversion on the RUN line (exit non-zero) plus the string, mirrored
; character-for-character below.
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice() local_unnamed_addr #0 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 3, double noundef 5.000000e-01) #3
  %2 = icmp sgt i32 %1, 5
  br i1 %2, label %3, label %5

3:                                                ; preds = %0
  %4 = tail call i32 @ext_f(i32 noundef 7) #3
  br label %5

5:                                                ; preds = %3, %0
  %6 = phi i32 [ %4, %3 ], [ 5, %0 ]
  %7 = tail call i32 @cq_measure_si32(i32 noundef %6) #3
  %8 = icmp ne i32 %7, 0
  %9 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %8, double noundef 2.500000e-01) #3
  %10 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %8, double noundef 9.000000e-01) #3
  %11 = select i1 %9, i32 2, i32 5
  %12 = tail call i32 @cq_measure_si32(i32 noundef %11) #3
  %13 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %10) #3
  %14 = zext i1 %13 to i32
  %15 = add i32 %12, %7
  %16 = add i32 %15, %14
  ret i32 %16
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #1

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define noundef i32 @main() local_unnamed_addr #0 {
  %1 = tail call i32 @slice()
  ret i32 0
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable
define range(i32 -2147483548, -2147483648) i32 @ext_f(i32 noundef %0) local_unnamed_addr #2 {
  %2 = add nsw i32 %0, 100
  ret i32 %2
}

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nounwind }

!llvm.ident = !{!0, !0}
!llvm.module.flags = !{!1, !2, !3, !4, !5}

!0 = !{!"Homebrew clang version 19.1.7"}
!1 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!2 = !{i32 1, !"wchar_size", i32 4}
!3 = !{i32 8, !"PIC Level", i32 2}
!4 = !{i32 7, !"uwtable", i32 2}
!5 = !{i32 7, !"frame-pointer", i32 2}

; CHECK: cq controlled lowering: condition predates a non-diagonal gate under quantum control
