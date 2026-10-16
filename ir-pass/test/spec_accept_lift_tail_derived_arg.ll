; spec_accept_lift_tail_derived_arg.ll — ACCEPT (bd test_C_libtooling-r2j3.37,
; the interim backstop's over-decline guard): `x = t * 3; r = f(x, a)` with
; `f = t ^ a` and `t` dead. The dead argument `x` is a DERIVED temporary, not a
; user register's value (`userRegisterValue`): the spine returns it to |0> after
; the call (mul_hl_unc + free below), exactly as for the inlined `r = (t*3) ^ a`,
; so the call stays lifted and nothing is loud. A mutant that drops the
; user-register clause from the gate declines here.
;
; Source: g3.c (lane L scratch), clang-19 -O1 -include CQ.h.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
;
; CHECK-LABEL: define {{.*}}i32 @main(
; CHECK:      [[X:%[a-z_0-9]+]] = call i32 @cq_template_mul_i8_hl(i32 [[T:%[a-z0-9]+]], i8 3)
; CHECK-NEXT: [[R:%[0-9]+]] = call i32 @__cq_q_f_11(i32 [[X]], i32 [[A:%[a-z0-9]+]])
; CHECK-NEXT: call void @cq_template_mul_i8_hl_unc(i32 [[X]], i32 [[T]], i8 3)
; CHECK-NEXT: call void @cqrt_free(i32 [[X]])
; CHECK-NEXT: call void @cqrt_ry_i8(i32 [[A]], double 0x3FE6666666666666)
source_filename = "g3.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable
define noundef zeroext i8 @f(i8 noundef zeroext %0, i8 noundef zeroext %1) local_unnamed_addr #0 {
  %3 = xor i8 %1, %0
  ret i8 %3
}

; Function Attrs: nounwind ssp uwtable
define range(i32 0, 511) i32 @main() local_unnamed_addr #1 {
  %1 = tail call zeroext i8 @cq_theta_ui8(i8 noundef zeroext 0, double noundef 5.000000e-01) #3
  %2 = tail call zeroext i8 @cq_theta_ui8(i8 noundef zeroext 0, double noundef 4.000000e-01) #3
  %3 = mul i8 %2, 3
  %4 = tail call zeroext i8 @f(i8 noundef zeroext %3, i8 noundef zeroext %1)
  %5 = tail call zeroext i8 @cq_theta_ui8(i8 noundef zeroext %1, double noundef 0x3FE6666666666666) #3
  %6 = tail call zeroext i8 @cq_measure_ui8(i8 noundef zeroext %5) #4
  %7 = zext i8 %6 to i32
  %8 = tail call zeroext i8 @cq_measure_ui8(i8 noundef zeroext %4) #4
  %9 = zext i8 %8 to i32
  %10 = add nuw nsw i32 %9, %7
  ret i32 %10
}

declare zeroext i8 @cq_theta_ui8(i8 noundef zeroext, double noundef) local_unnamed_addr #2

declare zeroext i8 @cq_measure_ui8(i8 noundef zeroext) local_unnamed_addr #2

attributes #0 = { mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nomerge nounwind }
attributes #4 = { nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
