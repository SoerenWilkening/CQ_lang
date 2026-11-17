; ModuleID = 'memcpy_array.c'
source_filename = "memcpy_array.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @memcpy_classical(i32 noundef %0, double noundef %1, ptr nocapture noundef readonly %2) local_unnamed_addr #0 {
  %4 = alloca [4 x i32], align 16    ; C: int a[4];
  %5 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #4    ; C: cq_theta(&x, th);
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %4) #5    ; C: (a comes into scope)
  call void @llvm.memcpy.p0.p0.i64(ptr noundef nonnull align 16 dereferenceable(16) %4, ptr noundef nonnull align 4 dereferenceable(16) %2, i64 16, i1 false)    ; C: memcpy(a, src, sizeof a);
  %6 = and i32 %5, 3    ; C: x & 3
  %7 = zext nneg i32 %6 to i64    ; C: x & 3  (as an index)
  %8 = getelementptr inbounds [4 x i32], ptr %4, i64 0, i64 %7    ; C: &a[x & 3]
  %9 = load i32, ptr %8, align 4, !tbaa !6    ; C: a[x & 3]  (read of a[x & 3] += 1)
  %10 = add nsw i32 %9, 1    ; C: a[x & 3] + 1
  store i32 %10, ptr %8, align 4, !tbaa !6    ; C: a[x & 3] += 1;
  %11 = load i32, ptr %4, align 16, !tbaa !6    ; C: a[0]
  %12 = getelementptr inbounds i8, ptr %4, i64 12    ; C: &a[3]
  %13 = load i32, ptr %12, align 4, !tbaa !6    ; C: a[3]
  %14 = add nsw i32 %13, %11    ; C: a[0] + a[3]
  %15 = tail call i32 @cq_measure_si32(i32 noundef %14) #5    ; C: cq_measure(a[0] + a[3])
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %4) #5    ; C: (a goes out of scope)
  ret i32 %15    ; C: return
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare i32 @cq_theta_ui32(i32 noundef, double noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nounwind willreturn memory(argmem: readwrite)
declare void @llvm.memcpy.p0.p0.i64(ptr noalias nocapture writeonly, ptr noalias nocapture readonly, i64, i1 immarg) #3

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: nounwind ssp uwtable
define i32 @memcpy_quantum(i32 noundef %0, i32 noundef %1, double noundef %2, double noundef %3, i32 noundef %4) local_unnamed_addr #0 {
  %6 = alloca [4 x i32], align 16    ; C: int a[4];
  %7 = alloca [4 x i32], align 16    ; C: int b[4];
  %8 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %2) #4    ; C: cq_theta(&x, tx);
  %9 = tail call i32 @cq_theta_ui32(i32 noundef %1, double noundef %3) #4    ; C: cq_theta(&y, ty);
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %6) #5    ; C: (a comes into scope)
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %7) #5    ; C: (b comes into scope)
  br label %20    ; C: for (int i = 0; i < 4; i++)

10:                                               ; preds = %20
  call void @llvm.memcpy.p0.p0.i64(ptr noundef nonnull align 16 dereferenceable(16) %7, ptr noundef nonnull align 16 dereferenceable(16) %6, i64 16, i1 false)    ; C: memcpy(b, a, sizeof b);
  %11 = and i32 %9, 3    ; C: y & 3
  %12 = zext nneg i32 %11 to i64    ; C: y & 3  (as an index)
  %13 = getelementptr inbounds [4 x i32], ptr %7, i64 0, i64 %12    ; C: &b[y & 3]
  store i32 %4, ptr %13, align 4, !tbaa !6    ; C: b[y & 3] = c;
  %14 = getelementptr inbounds i8, ptr %6, i64 4    ; C: &a[1]
  %15 = load i32, ptr %14, align 4, !tbaa !6    ; C: a[1]
  %16 = getelementptr inbounds i8, ptr %7, i64 4    ; C: &b[1]
  %17 = load i32, ptr %16, align 4, !tbaa !6    ; C: b[1]
  %18 = add nsw i32 %17, %15    ; C: a[1] + b[1]
  %19 = tail call i32 @cq_measure_si32(i32 noundef %18) #5    ; C: cq_measure(a[1] + b[1])
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %7) #5    ; C: (b goes out of scope)
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %6) #5    ; C: (a goes out of scope)
  ret i32 %19    ; C: return

20:                                               ; preds = %5, %20
  %21 = phi i64 [ 0, %5 ], [ %25, %20 ]    ; C: i
  %22 = trunc nuw nsw i64 %21 to i32    ; C: i  (as int)
  %23 = add i32 %8, %22    ; C: x + i
  %24 = getelementptr inbounds [4 x i32], ptr %6, i64 0, i64 %21    ; C: &a[i]
  store i32 %23, ptr %24, align 4, !tbaa !6    ; C: a[i] = x + i;
  %25 = add nuw nsw i64 %21, 1    ; C: i++
  %26 = icmp eq i64 %25, 4    ; C: i < 4
  br i1 %26, label %10, label %20, !llvm.loop !10    ; C: for (int i = 0; i < 4; i++)
}

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nocallback nofree nounwind willreturn memory(argmem: readwrite) }
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
