; /* tests/spine probe (CR rules 3, 18, 26; cq-le2c, cq-ejne): a clone returns one rail per field of its result layout, so a
;  * packed small struct whose returns the layout does not split ({short, short, char} as i48 with a constant field) is one
;  * rail, and every byte of it the caller reads is computed from that rail: t.a and t.c are templates on it, never a
;  * classical instruction handed the rail ('a rail handle reaching a classical instruction').
;  * Regenerate packed_result_classical_bytes.ll: clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -include CQ.h packed_result_classical_bytes.c */
; USERCHECK s7
; ModuleID = 'packed_result_classical_bytes.c'
source_filename = "packed_result_classical_bytes.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable
define range(i48 21474836480, 25769803776) i48 @f(i16 noundef signext %0, i16 noundef signext %1) local_unnamed_addr #0 {
  %3 = add i16 %0, 1
  %4 = shl i16 %1, 1
  %5 = zext i16 %4 to i48
  %6 = shl nuw nsw i48 %5, 16
  %7 = zext i16 %3 to i48
  %8 = or disjoint i48 %6, %7
  %9 = or disjoint i48 %8, 21474836480
  ret i48 %9
}

; Function Attrs: nounwind ssp uwtable
define range(i32 -65531, 65540) i32 @s7(i32 noundef %0, i32 noundef %1) local_unnamed_addr #1 {
  %3 = trunc i32 %1 to i16
  %4 = tail call signext i16 @cq_theta_si16(i16 noundef signext %3, double noundef 1.000000e+00) #3
  %5 = trunc i32 %0 to i16
  %6 = tail call i48 @f(i16 noundef signext %5, i16 noundef signext %4)
  %7 = trunc i48 %6 to i32
  %8 = lshr i48 %6, 16
  %9 = trunc i48 %8 to i16
  %10 = shl i32 %7, 16
  %11 = ashr exact i32 %10, 16
  %12 = tail call signext i16 @cq_measure_si16(i16 noundef signext %9) #4
  %13 = sext i16 %12 to i32
  %14 = add nsw i32 %13, 5
  %15 = add nsw i32 %14, %11
  ret i32 %15
}

declare signext i16 @cq_theta_si16(i16 noundef signext, double noundef) local_unnamed_addr #2

declare signext i16 @cq_measure_si16(i16 noundef signext) local_unnamed_addr #2

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
