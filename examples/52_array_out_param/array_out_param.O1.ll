; ModuleID = '52_array_out_param/array_out_param.c'
source_filename = "52_array_out_param/array_out_param.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define double @array_out_param(double noundef %0, double noundef %1, double noundef %2, double noundef %3, i32 noundef %4) local_unnamed_addr #0 {
  %6 = alloca [3 x double], align 16    ; C: double tx[3];
  %7 = alloca [2 x double], align 16    ; C: double y[2];
  %8 = tail call double @cq_theta_f64(double noundef %0, double noundef %1) #5    ; C: cq_theta(&x, th);
  call void @llvm.lifetime.start.p0(i64 24, ptr nonnull %6) #6    ; C: (tx comes into scope)
  store double %8, ptr %6, align 16, !tbaa !6    ; C: tx[0] = x;
  %9 = fmul double %8, %2    ; C: x * a
  %10 = getelementptr inbounds i8, ptr %6, i64 8    ; C: &tx[1]
  store double %9, ptr %10, align 8, !tbaa !6    ; C: tx[1] = x * a;
  %11 = fadd double %8, %2    ; C: x + a
  %12 = getelementptr inbounds i8, ptr %6, i64 16    ; C: &tx[2]
  store double %11, ptr %12, align 16, !tbaa !6    ; C: tx[2] = x + a;
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %7) #6    ; C: (y comes into scope)
  %13 = call fastcc i32 @reduce(ptr noundef nonnull %6, i32 noundef %4, double noundef %3, ptr noundef nonnull %7)    ; C: int m = reduce(tx, n, c, y);
  %14 = and i32 %13, 3    ; C: m & 3
  switch i32 %14, label %20 [    ; C: switch (m & 3)
    i32 0, label %15
    i32 1, label %17
  ]

15:                                               ; preds = %5
  %16 = load double, ptr %7, align 16, !tbaa !6    ; C: r = y[0];  (case 0)
  br label %25    ; C: end of case 0

17:                                               ; preds = %5
  %18 = getelementptr inbounds i8, ptr %7, i64 8    ; C: &y[1]  (case 1)
  %19 = load double, ptr %18, align 8, !tbaa !6    ; C: r = y[1];  (case 1)
  br label %25    ; C: end of case 1

20:                                               ; preds = %5
  %21 = load double, ptr %7, align 16, !tbaa !6    ; C: y[0]  (default)
  %22 = getelementptr inbounds i8, ptr %7, i64 8    ; C: &y[1]  (default)
  %23 = load double, ptr %22, align 8, !tbaa !6    ; C: y[1]  (default)
  %24 = fsub double %21, %23    ; C: r = y[0] - y[1];  (default)
  br label %25    ; C: end of default

25:                                               ; preds = %20, %17, %15
  %26 = phi double [ %24, %20 ], [ %19, %17 ], [ %16, %15 ]    ; C: r
  %27 = tail call double @cq_measure_f64(double noundef %26) #6    ; C: cq_measure(r)
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %7) #6    ; C: (y goes out of scope)
  call void @llvm.lifetime.end.p0(i64 24, ptr nonnull %6) #6    ; C: (tx goes out of scope)
  ret double %27    ; C: return
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare double @cq_theta_f64(double noundef, double noundef) local_unnamed_addr #2

; Function Attrs: nofree noinline norecurse nosync nounwind ssp memory(argmem: readwrite) uwtable
define internal fastcc range(i32 -2147483647, -2147483648) i32 @reduce(ptr nocapture noundef readonly %0, i32 noundef %1, double noundef %2, ptr nocapture noundef writeonly %3) unnamed_addr #3 {
  %5 = icmp sgt i32 %1, 0    ; C: for (i = 0; i < n; ...)  (does the loop run at all)
  br i1 %5, label %6, label %8    ; C: for (i = 0; i < n; ...)

6:                                                ; preds = %4
  %7 = zext nneg i32 %1 to i64    ; C: n as the trip bound
  br label %14    ; C: enter the loop

8:                                                ; preds = %14, %4
  %9 = phi double [ 0.000000e+00, %4 ], [ %19, %14 ]    ; C: s after the loop (0.0 if it never ran)
  store double %9, ptr %3, align 8, !tbaa !6    ; C: out[0] = s;
  %10 = load double, ptr %0, align 8, !tbaa !6    ; C: in[0]
  %11 = fsub double %9, %10    ; C: s - in[0]
  %12 = getelementptr inbounds i8, ptr %3, i64 8    ; C: &out[1]
  store double %11, ptr %12, align 8, !tbaa !6    ; C: out[1] = s - in[0];
  %13 = add nsw i32 %1, 1    ; C: n + 1
  ret i32 %13    ; C: return n + 1;

14:                                               ; preds = %6, %14
  %15 = phi i64 [ 0, %6 ], [ %20, %14 ]    ; C: i
  %16 = phi double [ 0.000000e+00, %6 ], [ %19, %14 ]    ; C: s
  %17 = getelementptr inbounds double, ptr %0, i64 %15    ; C: &in[i]
  %18 = load double, ptr %17, align 8, !tbaa !6    ; C: in[i]
  %19 = tail call double @llvm.fmuladd.f64(double %18, double %2, double %16)    ; C: s = s + in[i] * c;  (fused)
  %20 = add nuw nsw i64 %15, 1    ; C: i++
  %21 = icmp eq i64 %20, %7    ; C: i < n
  br i1 %21, label %8, label %14, !llvm.loop !10    ; C: i < n
}

declare double @cq_measure_f64(double noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.fmuladd.f64(double, double, double) #4

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nofree noinline norecurse nosync nounwind ssp memory(argmem: readwrite) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none) }
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
!7 = !{!"double", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
!10 = distinct !{!10, !11, !12}
!11 = !{!"llvm.loop.mustprogress"}
!12 = !{!"llvm.loop.unroll.disable"}
