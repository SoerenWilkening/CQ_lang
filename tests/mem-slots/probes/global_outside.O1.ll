; ModuleID = 'global_outside.c'
source_filename = "global_outside.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@gd = internal unnamed_addr global double 1.500000e+00, align 8
@gi = internal unnamed_addr global [3 x i32] [i32 7, i32 8, i32 9], align 4

; Function Attrs: nounwind ssp uwtable
define double @global_outside_put_get(double noundef %0) local_unnamed_addr #0 {
  %2 = tail call double @cq_theta_f64(double noundef %0, double noundef 3.000000e-01) #4
  tail call fastcc void @put(double noundef %2)
  %3 = tail call fastcc double @get(double noundef %2)
  %4 = tail call double @cq_measure_f64(double noundef %3) #5
  ret double %4
}

declare double @cq_theta_f64(double noundef, double noundef) local_unnamed_addr #1

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(write, argmem: none, inaccessiblemem: none) uwtable
define internal fastcc void @put(double noundef %0) unnamed_addr #2 {
  %2 = fmul double %0, 3.000000e+00
  store double %2, ptr @gd, align 8, !tbaa !6
  ret void
}

declare double @cq_measure_f64(double noundef) local_unnamed_addr #1

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(read, argmem: none, inaccessiblemem: none) uwtable
define internal fastcc double @get(double noundef %0) unnamed_addr #3 {
  %2 = load double, ptr @gd, align 8, !tbaa !6
  %3 = fadd double %2, %0
  ret double %3
}

; Function Attrs: nounwind ssp uwtable
define double @global_outside_seed(double noundef %0) local_unnamed_addr #0 {
  %2 = tail call double @cq_theta_f64(double noundef %0, double noundef 3.000000e-01) #4
  %3 = tail call fastcc double @get(double noundef %2)
  %4 = tail call double @cq_measure_f64(double noundef %3) #5
  ret double %4
}

; Function Attrs: nounwind ssp uwtable
define i32 @global_outside_index(i32 noundef %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 3.000000e-01) #4
  %4 = icmp ugt i32 %1, 2
  br i1 %4, label %9, label %5

5:                                                ; preds = %2
  tail call fastcc void @puti(i32 noundef %3, i32 noundef %1)
  %6 = sub nuw nsw i32 2, %1
  %7 = tail call fastcc i32 @geti(i32 noundef %3, i32 noundef %6)
  %8 = tail call i32 @cq_measure_si32(i32 noundef %7) #5
  br label %9

9:                                                ; preds = %2, %5
  %10 = phi i32 [ %8, %5 ], [ 0, %2 ]
  ret i32 %10
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(write, argmem: none, inaccessiblemem: none) uwtable
define internal fastcc void @puti(i32 noundef %0, i32 noundef %1) unnamed_addr #2 {
  %3 = xor i32 %0, 5
  %4 = zext nneg i32 %1 to i64
  %5 = getelementptr inbounds [3 x i32], ptr @gi, i64 0, i64 %4
  store i32 %3, ptr %5, align 4, !tbaa !10
  ret void
}

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(read, argmem: none, inaccessiblemem: none) uwtable
define internal fastcc i32 @geti(i32 noundef %0, i32 noundef %1) unnamed_addr #3 {
  %3 = zext nneg i32 %1 to i64
  %4 = getelementptr inbounds [3 x i32], ptr @gi, i64 0, i64 %3
  %5 = load i32, ptr %4, align 4, !tbaa !10
  %6 = add nsw i32 %5, %0
  ret i32 %6
}

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(write, argmem: none, inaccessiblemem: none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(read, argmem: none, inaccessiblemem: none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
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
!10 = !{!11, !11, i64 0}
!11 = !{!"int", !8, i64 0}
; CHECK global_outside_put_get: call fastcc void @__cq_q_put_1(i32 %{{x}})
; CHECK __cq_slot_init_gd: call i32 @cqrt_alloc_f64(double 1.500000e+00)
; CHECK __cq_slot_init_gi: call i32 @cqrt_alloc_i32(i32 9)
; USERCHECK global_outside_put_get
; USERCHECK global_outside_seed
; USERCHECK global_outside_index
