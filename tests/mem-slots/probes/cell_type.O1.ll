; ModuleID = 'cell_type.c'
source_filename = "cell_type.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define double @ct_buf(double noundef %0) local_unnamed_addr #0 {
  %2 = alloca [4 x x86_fp80], align 16
  %3 = tail call double @cq_theta_f64(double noundef %0, double noundef 5.000000e-01) #5
  call void @llvm.lifetime.start.p0(i64 64, ptr nonnull %2) #6
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 16 dereferenceable(64) %2, i8 0, i64 64, i1 false)
  %4 = call fastcc double @fr(double noundef %3, ptr noundef nonnull %2)
  %5 = tail call double @cq_measure_f64(double noundef %4) #6
  call void @llvm.lifetime.end.p0(i64 64, ptr nonnull %2) #6
  ret double %5
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare double @cq_theta_f64(double noundef, double noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nounwind willreturn memory(argmem: write)
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg) #3

declare double @cq_measure_f64(double noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(argmem: write) uwtable
define internal fastcc noundef double @fr(double noundef %0, ptr nocapture noundef writeonly %1) unnamed_addr #4 {
  %3 = fcmp ogt double %0, 1.000000e+00
  %4 = select i1 %3, i32 3, i32 -2
  store i32 %4, ptr %1, align 4, !tbaa !6
  %5 = fmul double %0, 5.000000e-01
  ret double %5
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: nounwind ssp uwtable
define double @ct_buf2(double noundef %0) local_unnamed_addr #0 {
  %2 = alloca [4 x x86_fp80], align 16
  %3 = fadd double %0, 1.000000e+00
  %4 = tail call double @cq_theta_f64(double noundef %3, double noundef 2.500000e-01) #5
  call void @llvm.lifetime.start.p0(i64 64, ptr nonnull %2) #6
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 16 dereferenceable(64) %2, i8 0, i64 64, i1 false)
  %5 = call fastcc double @fr(double noundef %4, ptr noundef nonnull %2)
  %6 = tail call double @cq_measure_f64(double noundef %5) #6
  call void @llvm.lifetime.end.p0(i64 64, ptr nonnull %2) #6
  ret double %6
}

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nocallback nofree nounwind willreturn memory(argmem: write) }
attributes #4 = { mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(argmem: write) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #5 = { nomerge nounwind }
attributes #6 = { nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
!6 = !{!7, !7, i64 0}
!7 = !{!"int", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
; USERCHECK ct_buf
; USERCHECK ct_buf2
