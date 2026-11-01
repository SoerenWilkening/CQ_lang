; ModuleID = 'clone_cell_read_fp.c'
source_filename = "clone_cell_read_fp.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define double @clone_cell_read_fp(i64 noundef %0, double noundef %1, i64 noundef %2) local_unnamed_addr #0 {
  %4 = alloca double, align 8
  %5 = tail call i64 @cq_theta_sll(i64 noundef %0, double noundef %1) #4
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %4) #5
  %6 = call fastcc i32 @g(i64 noundef %5, ptr noundef nonnull %4, i64 noundef %2)
  %7 = load double, ptr %4, align 8, !tbaa !6
  %8 = call double @cq_measure_f64(double noundef %7) #5
  %9 = call i32 @cq_measure_si32(i32 noundef %6) #5
  %10 = sitofp i32 %9 to double
  %11 = fadd double %8, %10
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %4) #5
  ret double %11
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare i64 @cq_theta_sll(i64 noundef, double noundef) local_unnamed_addr #2

; Function Attrs: nofree noinline nounwind ssp memory(argmem: readwrite) uwtable
define internal fastcc range(i32 0, 2) i32 @g(i64 noundef %0, ptr noundef %1, i64 noundef %2) unnamed_addr #3 {
  %4 = icmp slt i64 %0, %2
  %5 = and i64 %2, %0
  %6 = add nsw i64 %0, 3
  %7 = select i1 %4, i64 %5, i64 %6
  %8 = zext i1 %4 to i32
  store i64 %7, ptr %1, align 1
  ret i32 %8
}

declare double @cq_measure_f64(double noundef) local_unnamed_addr #2

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

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

; CHECK clone_cell_read_fp: call i32 @cq_template_bitcast_i64_to_f64(i32 %{{h}})
; CHECK clone_cell_read_fp: call double @cqrt_measure_f64(
