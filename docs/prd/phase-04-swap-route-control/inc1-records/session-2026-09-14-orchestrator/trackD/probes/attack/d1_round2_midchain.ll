; d1 — DELTA-SCOPE ATTACK shape 1 (bd 3d8q, IMPL_D section 9 item 1). The reader
; is `cq_measure(%10)`, whose operand is a THETA RESULT and so is tainted at
; ROUND 1 — it is NOT in the round-2 delta, so the delta-scoped re-ask skips it.
; Its staler `%13` is a CHAINED theta, a FORWARD user of %10, which the ROUND-1
; walk reaches with no taint-gated hop. EXPECTED: DECLINE at round 1.

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
  %8 = icmp ne i32 %6, 0
  %9 = zext i1 %8 to i32
  %10 = tail call i32 @cq_theta_si32(i32 noundef %9, double noundef 2.500000e-01) #3
  %11 = icmp eq i32 %10, 1
  %12 = select i1 %11, i32 2, i32 5
  %13 = tail call i32 @cq_theta_si32(i32 noundef %10, double noundef 9.000000e-01) #3
  %14 = tail call i32 @cq_measure_si32(i32 noundef %10) #3
  %15 = tail call i32 @cq_measure_si32(i32 noundef %13) #3
  %16 = add i32 %14, %7
  %17 = add i32 %16, %15
  ret i32 %17
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

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

; THE SIBLING IS AFTER THE MERGE. One rail (%[[HC]]) carries both rotations, and
; the second one follows the flag's free — which is exactly why it is harmless.
; ⚠ THE OLD ACCEPT'S DIRECTIVE BLOCKS ARE PRESERVED BELOW, NEUTERED TO PROSE, and
; that is deliberate (L8): they are the exact stream this program used to emit
; — `ry(h_cast,.25)`, the whole 4.4 copy merge, the strip, the free, then
; `ry(h_cast,.9)`, with 3 ry / 3 free / 3 measure / 4 x — and they are what a
; future agent must re-derive if the RETIREMENT TRIGGER above ever fires. They
; are NOT live directives: a `DS_Error` writes 0 bytes to stdout, so leaving
; them as live positive directives would make this fixture fail for a reason
; that has nothing to do with its subject. (Writing the directive token in this
; very sentence is how the first attempt failed — FileCheck reads comments.)
;
; (was) [check] %[[HC:[a-zA-Z0-9_.]+]] = call i32 @cq_template_zext_i1_to_i32(
; (was) [check] call void @cqrt_ry_i32(i32 %[[HC]], double 2.500000e-01)
; (was) [check-next] %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[HC]], i32 1)
; (was) [check] call void @cqrt_free(i32 %[[F]])
; (was) [check-next] call void @cqrt_ry_i32(i32 %[[HC]], double 9.000000e-01)

; (was) [ord] call void @cqrt_ry_i32({{.*}}, double 2.500000e-01)
; (was) [ord] call i32 @cq_template_icmp_eq_i32_hl(
; (was) [ord] call void @cqrt_copy_i32_controlled(
; (was) [ord] call void @cqrt_copy_i32_controlled(
; (was) [ord] call void @cq_template_icmp_eq_i32_hl_unc(
; (was) [ord] call void @cqrt_free(
; (was) [ord] call void @cqrt_ry_i32({{.*}}, double 9.000000e-01)

; (was) [noroute-not] cqrt_cswap
; (was) [noroute-not] cqrt_rz
; (was) [noroute-not] call i32 @cq_theta_
; (was) [rycnt-count-3] call void @cqrt_ry_
; (was) [rycnt-not] call void @cqrt_ry_
; (was) [fcnt-count-3] call void @cqrt_free(
; (was) [fcnt-not] call void @cqrt_free(
; (was) [mcnt-count-3] call i32 @cqrt_measure_
; (was) [mcnt-not] call i32 @cqrt_measure_
; (was) [xcnt-count-4] call void @cqrt_x(
; (was) [xcnt-not] call void @cqrt_x(
