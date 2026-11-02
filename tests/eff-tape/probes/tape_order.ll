; cq-t8oo / cq-64lv (owner ruling 2026-11-02): a classical host effect after a tape entry or a
; quantum-predicated abort is a tape entry with no predicate (tape_order.c).
; ModuleID = 'tape_order.c'
source_filename = "tape_order.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@.str = private unnamed_addr constant [6 x i8] c"a %d\0A\00", align 1
@.str.1 = private unnamed_addr constant [6 x i8] c"b %d\0A\00", align 1
@.str.2 = private unnamed_addr constant [10 x i8] c"after %d\0A\00", align 1
@.str.3 = private unnamed_addr constant [10 x i8] c"first %d\0A\00", align 1
@.str.4 = private unnamed_addr constant [5 x i8] c"done\00", align 1

; Function Attrs: nounwind ssp uwtable
define noundef i32 @ord_after_entry(i32 noundef %0) local_unnamed_addr #0 {
  %2 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 1.000000e+00) #4
  %3 = tail call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str, i32 noundef %2)
  %4 = tail call i32 @cq_measure_si32(i32 noundef %2) #5
  %5 = tail call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str.1, i32 noundef %4)
  ret i32 %4
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

; Function Attrs: nofree nounwind
declare noundef i32 @printf(ptr nocapture noundef readonly, ...) local_unnamed_addr #2

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define noundef i32 @ord_after_abort(i32 noundef %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 1.000000e+00) #4
  %4 = icmp eq i32 %3, %1
  br i1 %4, label %5, label %6

5:                                                ; preds = %2
  tail call void @abort() #6
  unreachable

6:                                                ; preds = %2
  %7 = tail call i32 @cq_measure_si32(i32 noundef %3) #5
  %8 = tail call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str.2, i32 noundef %7)
  ret i32 %7
}

; Function Attrs: cold noreturn nounwind
declare void @abort() local_unnamed_addr #3

; Function Attrs: nounwind ssp uwtable
define i32 @ord_puts(i32 noundef %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str.3, i32 noundef %1)
  %4 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 1.000000e+00) #4
  %5 = icmp eq i32 %4, %1
  br i1 %5, label %6, label %7

6:                                                ; preds = %2
  tail call void @abort() #6
  unreachable

7:                                                ; preds = %2
  %8 = tail call i32 @cq_measure_si32(i32 noundef %4) #5
  %9 = tail call i32 @puts(ptr noundef nonnull dereferenceable(1) @.str.4)
  %10 = and i32 %8, 7
  %11 = or disjoint i32 %10, 48
  %12 = tail call i32 @putchar(i32 noundef %11)
  ret i32 %8
}

; Function Attrs: nofree nounwind
declare noundef i32 @puts(ptr nocapture noundef readonly) local_unnamed_addr #2

; Function Attrs: nofree nounwind
declare noundef i32 @putchar(i32 noundef) local_unnamed_addr #2

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nofree nounwind "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { cold noreturn nounwind "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { nomerge nounwind }
attributes #5 = { nounwind }
attributes #6 = { cold noreturn nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
; CHECK ord_after_entry: call void @cqrt_tape_fmt(i32 %{{t}}, ptr @.str.1)
; CHECK ord_after_entry: call void @cqrt_tape_write_i32_lit(i32 %{{t}}, i32 %{{r}})
; CHECK-COUNT ord_after_entry: @printf( 0
; CHECK ord_after_abort: call void @cqrt_abort_i1(i32 %{{f}})
; CHECK ord_after_abort: call void @cqrt_tape_fmt(i32 %{{t}}, ptr @.str.2)
; CHECK-COUNT ord_after_abort: @printf( 0
; CHECK-COUNT ord_puts: @printf( 1
; CHECK ord_puts: call void @cqrt_tape_fmt(i32 %{{t}}, ptr @.cqfmt.puts)
; CHECK ord_puts: call void @cqrt_tape_write_str_lit(i32 %{{t}}, ptr @.str.4)
; CHECK ord_puts: call void @cqrt_tape_fmt(i32 %{{t}}, ptr @.cqfmt.putchar)
; CHECK-COUNT ord_puts: @puts( 0
; CHECK-COUNT ord_puts: @putchar( 0
