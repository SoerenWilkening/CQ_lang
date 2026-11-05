; ModuleID = 'bus_plain_and_overtaint.c'
source_filename = "bus_plain_and_overtaint.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @plain_local(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3) local_unnamed_addr #0 {
  %5 = alloca [4 x i32], align 16    ; C: int c[4]
  %6 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #3    ; C: cq_theta(&x, tx);
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %5) #4    ; C: (c comes into scope)
  br label %14    ; C: for (int i = 0; ...

7:                                                ; preds = %14
  %8 = and i32 %3, 3    ; C: j & 3
  %9 = zext nneg i32 %8 to i64    ; C: (index)
  %10 = getelementptr inbounds [4 x i32], ptr %5, i64 0, i64 %9    ; C: &c[j & 3]
  %11 = load i32, ptr %10, align 4, !tbaa !6    ; C: c[j & 3]
  %12 = add nsw i32 %11, %6    ; C: x + c[j & 3]
  %13 = tail call i32 @cq_measure_si32(i32 noundef %12) #4    ; C: cq_measure(x + c[j & 3])
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %5) #4    ; C: (c goes out of scope)
  ret i32 %13    ; C: return

14:                                               ; preds = %4, %14
  %15 = phi i64 [ 0, %4 ], [ %20, %14 ]    ; C: i
  %16 = getelementptr inbounds [4 x i32], ptr %5, i64 0, i64 %15    ; C: &c[i]
  %17 = trunc i64 %15 to i32    ; C: (i as int)
  %18 = mul i32 %17, %2    ; C: n * i
  %19 = add i32 %18, 1    ; C: n * i + 1
  store i32 %19, ptr %16, align 4, !tbaa !6    ; C: c[i] = n * i + 1;
  %20 = add nuw nsw i64 %15, 1    ; C: i++
  %21 = icmp eq i64 %20, 4    ; C: i < 4
  br i1 %21, label %7, label %14, !llvm.loop !10    ; C: for (...; i < 4; i++)
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

; Function Attrs: nounwind ssp uwtable
define i32 @overtaint_kloop(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = alloca [4 x i32], align 16    ; C: int c[4]
  %5 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #3    ; C: cq_theta(&x, tx);
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %4) #4    ; C: (c comes into scope)
  call void @ext_fill(ptr noundef nonnull %4, i32 noundef %2) #4    ; C: ext_fill(c, n);
  %6 = load i32, ptr %4, align 16, !tbaa !6    ; C: c[0]  (the first exit test, the pre-header guard)
  %7 = icmp eq i32 %6, 0    ; C: c[0] != 0
  br i1 %7, label %8, label %11    ; C: for (...; c[i] != 0; ...)

8:                                                ; preds = %11, %3
  %9 = phi i32 [ %5, %3 ], [ %15, %11 ]    ; C: x  (after the loop)
  %10 = call i32 @cq_measure_si32(i32 noundef %9) #4    ; C: cq_measure(x)
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %4) #4    ; C: (c goes out of scope)
  ret i32 %10    ; C: return

11:                                               ; preds = %3, %11
  %12 = phi i64 [ %16, %11 ], [ 0, %3 ]    ; C: i
  %13 = phi i32 [ %18, %11 ], [ %6, %3 ]    ; C: c[i]  (loaded by the test before this trip)
  %14 = phi i32 [ %15, %11 ], [ %5, %3 ]    ; C: x
  %15 = add nsw i32 %13, %14    ; C: x += c[i];
  %16 = add nuw nsw i64 %12, 1    ; C: i++
  %17 = getelementptr inbounds [4 x i32], ptr %4, i64 0, i64 %16    ; C: &c[i]
  %18 = load i32, ptr %17, align 4, !tbaa !6    ; C: c[i]
  %19 = icmp eq i32 %18, 0    ; C: c[i] != 0
  br i1 %19, label %8, label %11, !llvm.loop !13    ; C: for (...; c[i] != 0; i++)
}

declare void @ext_fill(ptr noundef, i32 noundef) local_unnamed_addr #2

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
!10 = distinct !{!10, !11, !12}
!11 = !{!"llvm.loop.mustprogress"}
!12 = !{!"llvm.loop.unroll.disable"}
!13 = distinct !{!13, !11, !12}
