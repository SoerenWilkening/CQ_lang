; ModuleID = 'clone_cell_read_int.c'
source_filename = "clone_cell_read_int.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i64 @clone_cell_read_int(double noundef %0, double noundef %1, i32 noundef %2, i64 noundef %3) local_unnamed_addr #0 {
  %5 = alloca double, align 8
  %6 = tail call double @cq_theta_f64(double noundef %0, double noundef %1) #4
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %5) #5
  %7 = call fastcc double @g(double noundef %6, ptr noundef nonnull %5, i32 noundef %2, i64 noundef %3)
  %8 = load i64, ptr %5, align 8
  %9 = call i64 @cq_measure_sll(i64 noundef %8) #5
  %10 = call double @cq_measure_f64(double noundef %7) #5
  %11 = fptosi double %10 to i64
  %12 = add nsw i64 %9, %11
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %5) #5
  ret i64 %12
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare double @cq_theta_f64(double noundef, double noundef) local_unnamed_addr #2

; Function Attrs: nofree noinline nounwind ssp memory(argmem: readwrite) uwtable
define internal fastcc noundef double @g(double noundef %0, ptr noundef %1, i32 noundef %2, i64 noundef %3) unnamed_addr #3 {
  %5 = bitcast double %0 to i64
  %6 = lshr i64 %5, 52
  %7 = trunc nuw nsw i64 %6 to i32
  %8 = and i32 %7, 2047
  %9 = icmp slt i32 %8, %2
  br i1 %9, label %10, label %12

10:                                               ; preds = %4
  %11 = and i64 %5, %3
  store i64 %11, ptr %1, align 1
  br label %15

12:                                               ; preds = %4
  %13 = fmul double %0, 2.000000e+00
  store double %13, ptr %1, align 8, !tbaa !6
  %14 = fsub double %0, %0
  br label %15

15:                                               ; preds = %12, %10
  %16 = phi double [ %0, %10 ], [ %14, %12 ]
  ret double %16
}

declare i64 @cq_measure_sll(i64 noundef) local_unnamed_addr #2

declare double @cq_measure_f64(double noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nofree noinline nounwind ssp memory(argmem: readwrite) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { nomerge nounwind }
attributes #5 = { nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
!6 = !{!7, !7, i64 0}
!7 = !{!"double", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}

; CHECK clone_cell_read_int: call i32 @cq_template_bitcast_f64_to_i64(i32 %{{h}})
; CHECK clone_cell_read_int: call i64 @cqrt_measure_i64(
