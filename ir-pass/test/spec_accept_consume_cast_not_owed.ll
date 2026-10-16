; spec_accept_consume_cast_not_owed.ll — ACCEPT, NOT consumed (bd
; test_C_libtooling-r2j3.37.2; R11 r1 rL1B-F3). `r = g(t, a)` with
; `g(signed char t, int a) = t ^ a`, `t` dead, `a` live. The return reads `t`
; only through a widening `sext`, which no in-place gate overwrites, so `t`'s slot
; is not in the chain (`chainReachSlots` stops at a cast) and the call stays the
; out-of-place clone — the inlined `r = (int)t ^ a`'s answer too (its QQ round
; never sees `t` as an operand). WAS (d4b8a340): a misleading `self-dependent`
; reason. Planning ext/trunc chains is a follow-up (bd r2j3.37 children).
;
; Source: q2.c (lane L scratch), clang-19 -O1 -include CQ.h.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
;
; CHECK-LABEL: define {{.*}}i32 @main(
; CHECK:      call i32 @__cq_q_g_11(i32 noundef signext [[T:%[a-z0-9]+]], i32 noundef [[A:%[a-z0-9]+]])
; CHECK-NOT:  _c0
source_filename = "q2.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable
define noundef i32 @g(i8 noundef signext %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = sext i8 %0 to i32
  %4 = xor i32 %3, %1
  ret i32 %4
}

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #1 {
  %1 = tail call signext i8 @cq_theta_si8(i8 noundef signext 0, double noundef 4.000000e-01) #3
  %2 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 3.000000e-01) #3
  %3 = tail call i32 @g(i8 noundef signext %1, i32 noundef %2)
  %4 = tail call i32 @cq_theta_si32(i32 noundef %3, double noundef 0x3FE6666666666666) #3
  %5 = tail call i32 @cq_measure_si32(i32 noundef %4) #4
  %6 = tail call i32 @cq_measure_si32(i32 noundef %2) #4
  %7 = add nsw i32 %6, %5
  ret i32 %7
}

declare signext i8 @cq_theta_si8(i8 noundef signext, double noundef) local_unnamed_addr #2

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

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
