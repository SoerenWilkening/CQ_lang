; spec_reject_consume_quantum_select.ll — DECLINE, loud (bd
; test_C_libtooling-r2j3.37.3): the select-root callee with a QUANTUM condition
; (`n` rotated). Each arm is in place in `t`, but the arm is chosen by a quantum
; condition, a control region the consumer does not build: owed and unbuilt ->
; loud. (The inlined twin speculates both arms, so `t` is read twice and stays
; out of place with the old rail kept: a main-side gap, noted in the follow-up.)
;
; Source: s4.c (lane L scratch), clang-19 -O1 -include CQ.h.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error: {{.*}}cq specialization: a lifted call overwrites a dead quantum argument, which is not lowered in place across the call
source_filename = "s4.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable
define noundef zeroext i8 @f(i8 noundef zeroext %0, i8 noundef zeroext %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = icmp sgt i32 %2, 2
  %5 = xor i8 %1, %0
  %6 = add i8 %5, 5
  %7 = sub i8 %0, %1
  %8 = select i1 %4, i8 %6, i8 %7
  ret i8 %8
}

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #1 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 3.000000e-01) #3
  %2 = tail call zeroext i8 @cq_theta_ui8(i8 noundef zeroext 0, double noundef 5.000000e-01) #3
  %3 = tail call zeroext i8 @cq_theta_ui8(i8 noundef zeroext 0, double noundef 4.000000e-01) #3
  %4 = tail call zeroext i8 @f(i8 noundef zeroext %3, i8 noundef zeroext %2, i32 noundef %1)
  %5 = tail call zeroext i8 @cq_measure_ui8(i8 noundef zeroext %4) #4
  %6 = zext i8 %5 to i32
  %7 = tail call zeroext i8 @cq_measure_ui8(i8 noundef zeroext %2) #4
  %8 = zext i8 %7 to i32
  %9 = add nuw nsw i32 %8, %6
  %10 = tail call i32 @cq_measure_si32(i32 noundef %1) #4
  %11 = add nsw i32 %9, %10
  ret i32 %11
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

declare zeroext i8 @cq_theta_ui8(i8 noundef zeroext, double noundef) local_unnamed_addr #2

declare zeroext i8 @cq_measure_ui8(i8 noundef zeroext) local_unnamed_addr #2

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
