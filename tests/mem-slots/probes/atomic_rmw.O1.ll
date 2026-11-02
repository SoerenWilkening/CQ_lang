; ModuleID = 'atomic_rmw.c'
source_filename = "atomic_rmw.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @atomic_xchg(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = alloca i32, align 4
  %5 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #3
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %4) #4
  store i32 %5, ptr %4, align 4, !tbaa !6
  %6 = atomicrmw xchg ptr %4, i32 %2 seq_cst, align 4
  %7 = call i32 @cq_measure_si32(i32 noundef %6) #4
  %8 = load i32, ptr %4, align 4, !tbaa !6
  %9 = call i32 @cq_measure_si32(i32 noundef %8) #4
  %10 = add nsw i32 %9, %7
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %4) #4
  ret i32 %10
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: nounwind ssp uwtable
define i32 @atomic_ops(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3) local_unnamed_addr #0 {
  %5 = alloca i32, align 4
  %6 = alloca i32, align 4
  %7 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #3
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %5) #4
  store i32 %7, ptr %5, align 4, !tbaa !6
  %8 = xor i32 %7, %2
  %9 = atomicrmw xchg ptr %5, i32 %8 seq_cst, align 4
  %10 = atomicrmw nand ptr %5, i32 %3 seq_cst, align 4
  %11 = atomicrmw max ptr %5, i32 %3 seq_cst, align 4
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %6) #4
  store i32 %7, ptr %6, align 4, !tbaa !6
  %12 = atomicrmw umin ptr %6, i32 %3 seq_cst, align 4
  %13 = atomicrmw xchg ptr %5, i32 %3 seq_cst, align 4
  %14 = call i32 @cq_measure_si32(i32 noundef %9) #4
  %15 = call i32 @cq_measure_si32(i32 noundef %10) #4
  %16 = add nsw i32 %15, %14
  %17 = call i32 @cq_measure_si32(i32 noundef %11) #4
  %18 = add nsw i32 %16, %17
  %19 = call i32 @cq_measure_ui32(i32 noundef %12) #4
  %20 = add nsw i32 %18, %19
  %21 = call i32 @cq_measure_si32(i32 noundef %13) #4
  %22 = add nsw i32 %20, %21
  %23 = load i32, ptr %5, align 4, !tbaa !6
  %24 = call i32 @cq_measure_si32(i32 noundef %23) #4
  %25 = add nsw i32 %22, %24
  %26 = load i32, ptr %6, align 4, !tbaa !6
  %27 = call i32 @cq_measure_ui32(i32 noundef %26) #4
  %28 = add nsw i32 %25, %27
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %6) #4
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %5) #4
  ret i32 %28
}

declare i32 @cq_measure_ui32(i32 noundef) local_unnamed_addr #2

; Function Attrs: nounwind ssp uwtable
define double @atomic_fp(double noundef %0, double noundef %1, double noundef %2) local_unnamed_addr #0 {
  %4 = alloca double, align 8
  %5 = tail call double @cq_theta_f64(double noundef %0, double noundef %1) #3
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %4) #4
  store double %5, ptr %4, align 8, !tbaa !10
  %6 = atomicrmw fadd ptr %4, double %2 seq_cst, align 8
  %7 = atomicrmw fsub ptr %4, double %5 seq_cst, align 8
  %8 = fadd double %6, %7
  %9 = call double @cq_measure_f64(double noundef %8) #4
  %10 = load double, ptr %4, align 8, !tbaa !10
  %11 = call double @cq_measure_f64(double noundef %10) #4
  %12 = fadd double %9, %11
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %4) #4
  ret double %12
}

declare double @cq_theta_f64(double noundef, double noundef) local_unnamed_addr #2

declare double @cq_measure_f64(double noundef) local_unnamed_addr #2

; Function Attrs: nounwind ssp uwtable
define i32 @atomic_g1(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = alloca i32, align 4
  %5 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #3
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %4) #4
  store i32 %5, ptr %4, align 4, !tbaa !6
  %6 = icmp sgt i32 %5, 3
  br i1 %6, label %7, label %9

7:                                                ; preds = %3
  %8 = atomicrmw add ptr %4, i32 %2 seq_cst, align 4
  br label %9

9:                                                ; preds = %7, %3
  %10 = phi i32 [ %8, %7 ], [ 0, %3 ]
  %11 = call i32 @cq_measure_si32(i32 noundef %10) #4
  %12 = load i32, ptr %4, align 4, !tbaa !6
  %13 = call i32 @cq_measure_si32(i32 noundef %12) #4
  %14 = add nsw i32 %13, %11
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %4) #4
  ret i32 %14
}

; Function Attrs: nounwind ssp uwtable
define i32 @atomic_g2(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = alloca i32, align 4
  %5 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #3
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %4) #4
  store i32 %5, ptr %4, align 4, !tbaa !6
  %6 = icmp slt i32 %5, 9
  br i1 %6, label %7, label %10

7:                                                ; preds = %3
  %8 = cmpxchg ptr %4, i32 %5, i32 %2 seq_cst seq_cst, align 4
  %9 = extractvalue { i32, i1 } %8, 0
  br label %10

10:                                               ; preds = %7, %3
  %11 = phi i32 [ %9, %7 ], [ %5, %3 ]
  %12 = load i32, ptr %4, align 4, !tbaa !6
  %13 = call i32 @cq_measure_si32(i32 noundef %12) #4
  %14 = call i32 @cq_measure_si32(i32 noundef %11) #4
  %15 = add nsw i32 %14, %13
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %4) #4
  ret i32 %15
}

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
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
!6 = !{!7, !7, i64 0}
!7 = !{!"int", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
!10 = !{!11, !11, i64 0}
!11 = !{!"double", !8, i64 0}
; USERCHECK atomic_xchg
; USERCHECK atomic_ops
; USERCHECK atomic_fp
; USERCHECK atomic_g1
; USERCHECK atomic_g2
