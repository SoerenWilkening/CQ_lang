; ModuleID = 'bus_lifetime_reuse.c'
source_filename = "bus_lifetime_reuse.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @bus_scope_reuse(i32 noundef %0, double noundef %1, i32 noundef %2, double noundef %3, i32 noundef %4) local_unnamed_addr #0 {
  %6 = alloca [2 x i32], align 4    ; C: int a[2]  (ONE alloca, outside the loop)
  %7 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #4    ; C: cq_theta(&k, tk);
  %8 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef %3) #4    ; C: cq_theta(&x, tx);
  %9 = icmp sgt i32 %4, 0    ; C: i < n  (trip 0)
  br i1 %9, label %10, label %12    ; C: for (int i = 0; i < n; ...)

10:                                               ; preds = %5
  %11 = getelementptr inbounds i8, ptr %6, i64 4    ; C: &a[1]
  br label %15    ; C: (loop entry)

12:                                               ; preds = %15, %5
  %13 = phi i32 [ 0, %5 ], [ %25, %15 ]    ; C: s  (after the loop)
  %14 = tail call i32 @cq_measure_si32(i32 noundef %13) #5    ; C: cq_measure(s)
  ret i32 %14    ; C: return

15:                                               ; preds = %10, %15
  %16 = phi i32 [ 0, %10 ], [ %26, %15 ]    ; C: i
  %17 = phi i32 [ 0, %10 ], [ %25, %15 ]    ; C: s
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %6) #5    ; C: (a comes into scope: dropped)
  store i32 %16, ptr %6, align 4, !tbaa !6    ; C: a[0] = i
  %18 = lshr i32 %7, %16    ; C: k >> i
  %19 = and i32 %18, 1    ; C: (k >> i) & 1
  %20 = zext nneg i32 %19 to i64    ; C: (index)
  %21 = getelementptr inbounds [2 x i32], ptr %6, i64 0, i64 %20    ; C: &a[(k >> i) & 1]
  store i32 %8, ptr %21, align 4, !tbaa !6    ; C: a[(k >> i) & 1] = x;
  %22 = load i32, ptr %6, align 4, !tbaa !6    ; C: a[0]
  %23 = load i32, ptr %11, align 4, !tbaa !6    ; C: a[1]  (never initialized: what the block holds)
  %24 = add i32 %22, %17    ; C: s + a[0]
  %25 = add i32 %24, %23    ; C: s += a[0] + a[1];
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %6) #5    ; C: (a goes out of scope: dropped)
  %26 = add nuw nsw i32 %16, 1    ; C: i++
  %27 = icmp eq i32 %26, %4    ; C: i < n
  br i1 %27, label %12, label %15, !llvm.loop !10    ; C: for (...; i < n; i++)
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare i32 @cq_theta_ui32(i32 noundef, double noundef) local_unnamed_addr #2

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

; Function Attrs: nounwind ssp uwtable
define i32 @bus_recursion(i32 noundef %0, double noundef %1, i32 noundef %2, double noundef %3, i32 noundef %4) local_unnamed_addr #0 {
  %6 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #4    ; C: cq_theta(&k, tk);
  %7 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef %3) #4    ; C: cq_theta(&x, tx);
  %8 = tail call fastcc i32 @walk(i32 noundef %6, i32 noundef %7, i32 noundef %4)    ; C: walk(k, x, d)
  %9 = tail call i32 @cq_measure_si32(i32 noundef %8) #5    ; C: cq_measure(walk(k, x, d))
  ret i32 %9    ; C: return
}

; Function Attrs: nofree noinline nosync nounwind ssp memory(none) uwtable
define internal fastcc i32 @walk(i32 noundef %0, i32 noundef %1, i32 noundef %2) unnamed_addr #3 {
  %4 = alloca [2 x i32], align 4    ; C: int a[2]
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %4) #5    ; C: (a comes into scope)
  store i32 %2, ptr %4, align 4, !tbaa !6    ; C: a[0] = d
  %5 = getelementptr inbounds i8, ptr %4, i64 4    ; C: &a[1]
  store i32 0, ptr %5, align 4, !tbaa !6    ; C: a[1] = 0
  %6 = and i32 %0, 1    ; C: k & 1
  %7 = zext nneg i32 %6 to i64    ; C: (index)
  %8 = getelementptr inbounds [2 x i32], ptr %4, i64 0, i64 %7    ; C: &a[k & 1]
  store i32 %1, ptr %8, align 4, !tbaa !6    ; C: a[k & 1] = x;
  %9 = icmp eq i32 %2, 0    ; C: d ? ... : 0
  br i1 %9, label %14, label %10    ; C: d ? ... : 0

10:                                               ; preds = %3
  %11 = lshr i32 %0, 1    ; C: k >> 1
  %12 = add nsw i32 %2, -1    ; C: d - 1
  %13 = tail call fastcc i32 @walk(i32 noundef %11, i32 noundef %1, i32 noundef %12)    ; C: walk(k >> 1, x, d - 1)
  br label %14    ; C: (join)

14:                                               ; preds = %3, %10
  %15 = phi i32 [ %13, %10 ], [ 0, %3 ]    ; C: int below = d ? walk(k >> 1, x, d - 1) : 0;
  %16 = load i32, ptr %4, align 4, !tbaa !6    ; C: a[0]
  %17 = add nsw i32 %16, %15    ; C: a[0] + below
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %4) #5    ; C: (a goes out of scope)
  ret i32 %17    ; C: return a[0] + below;
}

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nofree noinline nosync nounwind ssp memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
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
!7 = !{!"int", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
!10 = distinct !{!10, !11, !12}
!11 = !{!"llvm.loop.mustprogress"}
!12 = !{!"llvm.loop.unroll.disable"}
