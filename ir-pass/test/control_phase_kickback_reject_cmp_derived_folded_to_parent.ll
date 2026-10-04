; control_phase_kickback_reject_cmp_derived_folded_to_parent.ll — DECLINE, and
; THE DISCRIMINATOR THAT KEEPS THE F-A1-3 NARROWING ABOUT THE WIRE RATHER THAN
; ABOUT THE SPELLING (Track A.1; bd test_C_libtooling-r903 item (b)). Verbatim
; `clang -O1` from `review_a1_r1_probes/c9.c`:
;
;     int q = 0; cq_theta(&q, 0.5);
;     int t = q + 3;
;     int m = cq_measure(q);
;     if (t > 3) cq_phi(0.3);
;     return m + cq_measure(t);
;
; THE SOURCE reads a derived value, exactly like
; `control_swap_select_cmp_derived_operand_parent_measured.ll` — and the two
; verdicts are OPPOSITE, correctly, because `clang -O1` does not leave the
; derivation in the compare: `(q + 3) > 3` is canonicalized to `icmp sgt i32 %1,
; 0`, so the compare's DIRECT operand IS the measured register and the oracle
; emits `cqrt_measure_i32(%h)` followed by `cq_template_icmp_sgt_i32_hl(%h, 0)`
; — a flag minted from a COLLAPSED register, Rule 6's loud-reject class, at exit
; 0 and verify-clean. ACCEPT on `main` 0c7380c.
;
; Read the two files together: seeding rung (ii) from the compare's direct
; operands is not "trust the source text", it is "ask about the register the
; EMITTED gate reads". The same holds for `long long t = (long long) q;`
; (`review_a1_r1_probes/c2.c`), whose sext `-O1` folds away entirely; the
; reviewer's F-A1-3 table listed both as over-declines and their stage-1 IR says
; otherwise.

; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01) #2
  %2 = tail call i32 @cq_measure_si32(i32 noundef %1) #2
  %3 = icmp sgt i32 %1, 0
  br i1 %3, label %4, label %5

4:                                                ; preds = %0
  tail call void @cq_phi(double noundef 3.000000e-01) #2
  br label %5

5:                                                ; preds = %4, %0
  %6 = add nsw i32 %1, 3
  %7 = tail call i32 @cq_measure_si32(i32 noundef %6) #2
  %8 = add nsw i32 %7, %2
  ret i32 %8
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

declare void @cq_phi(double noundef) local_unnamed_addr #1

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

; CHECK: cq controlled lowering: condition measured before the control route under quantum control
