; cq-wskg (rule 16; gate 2a taint-h2 p22_die): a call of a DEFINED noreturn function under a quantum
; predicate. A callee that aborts on every path with nothing before (die: abort; die2 -> die_code: exit or
; abort) is abort_i1(pred), never the original call. Source: tests/eff-tape/probes/noreturn_defined.c.
; CHECK p22: call void @cqrt_abort_i1(
; CHECK-COUNT p22: @die( 0
; CHECK p22b: call void @cqrt_abort_i1(
; CHECK-COUNT p22b: @die2( 0
; ModuleID = 'noreturn_defined.c'
source_filename = "noreturn_defined.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @p22(i32 noundef %0) local_unnamed_addr #0 {
  %2 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 1.000000e+00) #5
  %3 = icmp sgt i32 %2, 0
  br i1 %3, label %4, label %5

4:                                                ; preds = %1
  tail call fastcc void @die()
  unreachable

5:                                                ; preds = %1
  %6 = tail call i32 @cq_measure_si32(i32 noundef %2) #6
  ret i32 %6
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

; Function Attrs: noinline noreturn nounwind ssp uwtable
define internal fastcc void @die() unnamed_addr #2 {
  tail call void @abort() #7
  unreachable
}

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @p22b(i32 noundef %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 1.000000e+00) #5
  %4 = icmp slt i32 %3, 3
  br i1 %4, label %5, label %6

5:                                                ; preds = %2
  tail call fastcc void @die2(i32 noundef %1)
  unreachable

6:                                                ; preds = %2
  %7 = tail call i32 @cq_measure_si32(i32 noundef %3) #6
  ret i32 %7
}

; Function Attrs: noinline noreturn nounwind ssp uwtable
define internal fastcc void @die2(i32 noundef %0) unnamed_addr #2 {
  %2 = add nsw i32 %0, 1
  tail call fastcc void @die_code(i32 noundef %2)
  unreachable
}

; Function Attrs: cold noreturn nounwind
declare void @abort() local_unnamed_addr #3

; Function Attrs: noinline noreturn nounwind ssp uwtable
define internal fastcc void @die_code(i32 noundef %0) unnamed_addr #2 {
  %2 = icmp eq i32 %0, 0
  br i1 %2, label %4, label %3

3:                                                ; preds = %1
  tail call void @exit(i32 noundef %0) #8
  unreachable

4:                                                ; preds = %1
  tail call void @abort() #7
  unreachable
}

; Function Attrs: noreturn
declare void @exit(i32 noundef) local_unnamed_addr #4

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { noinline noreturn nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { cold noreturn nounwind "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { noreturn "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #5 = { nomerge nounwind }
attributes #6 = { nounwind }
attributes #7 = { cold noreturn nounwind }
attributes #8 = { noreturn nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
