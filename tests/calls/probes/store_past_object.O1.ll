; ModuleID = 'store_past_object.c'
source_filename = "store_past_object.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(argmem: write) uwtable
define void @fill(double noundef %0, ptr nocapture noundef writeonly %1, i32 noundef %2) local_unnamed_addr #0 {
  switch i32 %2, label %10 [
    i32 2, label %4
    i32 1, label %7
  ]

4:                                                ; preds = %3
  %5 = fmul double %0, 4.000000e+00
  %6 = getelementptr inbounds i8, ptr %1, i64 16
  store double %5, ptr %6, align 8, !tbaa !6
  br label %7

7:                                                ; preds = %3, %4
  %8 = fmul double %0, 2.000000e+00
  %9 = getelementptr inbounds i8, ptr %1, i64 8
  store double %8, ptr %9, align 8, !tbaa !6
  br label %10

10:                                               ; preds = %3, %7
  %11 = fadd double %0, 1.000000e+00
  store double %11, ptr %1, align 8, !tbaa !6
  ret void
}

; Function Attrs: nounwind ssp uwtable
define double @sp_one(double noundef %0, double noundef %1) local_unnamed_addr #1 {
  %3 = alloca [1 x double], align 8
  %4 = tail call double @cq_theta_f64(double noundef %0, double noundef %1) #4
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %3) #5
  call void @fill(double noundef %4, ptr noundef nonnull %3, i32 noundef 0)
  %5 = load double, ptr %3, align 8, !tbaa !6
  %6 = tail call double @cq_measure_f64(double noundef %5) #5
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %3) #5
  ret double %6
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #2

declare double @cq_theta_f64(double noundef, double noundef) local_unnamed_addr #3

declare double @cq_measure_f64(double noundef) local_unnamed_addr #3

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #2

attributes #0 = { mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(argmem: write) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #3 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
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
