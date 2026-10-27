; ModuleID = '55_array_in_quantum_loop/array_in_quantum_loop.c'
source_filename = "55_array_in_quantum_loop/array_in_quantum_loop.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @array_in_quantum_loop(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = alloca [4 x i32], align 16    ; C: int a[4]
  %5 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #4    ; C: cq_theta(&m, th);
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %4) #5    ; C: (a comes into scope)
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 16 dereferenceable(16) %4, i8 0, i64 16, i1 false)    ; C: int a[4] = {0, 0, 0, 0};
  %6 = icmp slt i32 %5, 0    ; C: for (i = 0; i <= m; ...)  (does the loop run at all)
  br i1 %6, label %10, label %7    ; C: for (i = 0; i <= m; ...)

7:                                                ; preds = %3
  %8 = add nuw i32 %5, 1    ; C: m + 1  (trip count)
  %9 = zext i32 %8 to i64    ; C: m + 1 as the trip bound
  br label %16    ; C: enter the loop

10:                                               ; preds = %16, %3
  %11 = add nsw i32 %5, -1    ; C: m - 1
  %12 = sext i32 %11 to i64    ; C: (index)
  %13 = getelementptr inbounds [4 x i32], ptr %4, i64 0, i64 %12    ; C: &a[m - 1]
  %14 = load i32, ptr %13, align 4, !tbaa !6    ; C: a[m - 1]
  %15 = tail call i32 @cq_measure_si32(i32 noundef %14) #5    ; C: cq_measure(a[m - 1])
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %4) #5    ; C: (a goes out of scope)
  ret i32 %15    ; C: return

16:                                               ; preds = %7, %16
  %17 = phi i64 [ 0, %7 ], [ %21, %16 ]    ; C: i
  %18 = getelementptr inbounds [4 x i32], ptr %4, i64 0, i64 %17    ; C: &a[i]
  %19 = trunc i64 %17 to i32    ; C: i as int
  %20 = mul i32 %19, %2    ; C: i * c
  store i32 %20, ptr %18, align 4, !tbaa !6    ; C: a[i] = i * c;
  %21 = add nuw nsw i64 %17, 1    ; C: i++
  %22 = icmp eq i64 %21, %9    ; C: i <= m  (as i + 1 == m + 1)
  br i1 %22, label %10, label %16, !llvm.loop !10    ; C: i <= m
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nounwind willreturn memory(argmem: write)
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg) #3

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nocallback nofree nounwind willreturn memory(argmem: write) }
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
