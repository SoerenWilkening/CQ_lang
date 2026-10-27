; ModuleID = 'memset_array.c'
source_filename = "memset_array.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @memset_over_quantum(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3) local_unnamed_addr #0 {
  %5 = alloca [4 x i32], align 16    ; C: int a[4];
  %6 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #4    ; C: cq_theta(&x, th);
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %5) #5    ; C: (a comes into scope)
  br label %19    ; C: for (int i = 0; i < 4; i++)

7:                                                ; preds = %19
  %8 = and i32 %3, 3    ; C: k & 3
  %9 = zext nneg i32 %8 to i64    ; C: k & 3  (as an index)
  %10 = getelementptr inbounds [4 x i32], ptr %5, i64 0, i64 %9    ; C: &a[k & 3]
  %11 = load i32, ptr %10, align 4, !tbaa !6    ; C: int before = a[k & 3];
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 16 dereferenceable(16) %5, i8 0, i64 16, i1 false)    ; C: memset(a, 0, sizeof a);
  %12 = and i32 %6, 3    ; C: x & 3
  %13 = zext nneg i32 %12 to i64    ; C: x & 3  (as an index)
  %14 = getelementptr inbounds [4 x i32], ptr %5, i64 0, i64 %13    ; C: &a[x & 3]
  store i32 %2, ptr %14, align 4, !tbaa !6    ; C: a[x & 3] = c;
  %15 = getelementptr inbounds i8, ptr %5, i64 4    ; C: &a[1]
  %16 = load i32, ptr %15, align 4, !tbaa !6    ; C: a[1]
  %17 = add nsw i32 %16, %11    ; C: before + a[1]
  %18 = tail call i32 @cq_measure_si32(i32 noundef %17) #5    ; C: cq_measure(before + a[1])
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %5) #5    ; C: (a goes out of scope)
  ret i32 %18    ; C: return

19:                                               ; preds = %4, %19
  %20 = phi i64 [ 0, %4 ], [ %24, %19 ]    ; C: i
  %21 = trunc nuw nsw i64 %20 to i32    ; C: i  (as int)
  %22 = add i32 %6, %21    ; C: x + i
  %23 = getelementptr inbounds [4 x i32], ptr %5, i64 0, i64 %20    ; C: &a[i]
  store i32 %22, ptr %23, align 4, !tbaa !6    ; C: a[i] = x + i;
  %24 = add nuw nsw i64 %20, 1    ; C: i++
  %25 = icmp eq i64 %24, 4    ; C: i < 4
  br i1 %25, label %7, label %19, !llvm.loop !10    ; C: for (int i = 0; i < 4; i++)
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare i32 @cq_theta_ui32(i32 noundef, double noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: mustprogress nocallback nofree nounwind willreturn memory(argmem: write)
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg) #3

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

; Function Attrs: nounwind ssp uwtable
define i32 @memset_quantum_byte(i32 noundef %0, i32 noundef %1, double noundef %2, double noundef %3) local_unnamed_addr #0 {
  %5 = alloca [4 x i8], align 1    ; C: unsigned char b[4];
  %6 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %2) #4    ; C: cq_theta(&x, tx);
  %7 = tail call i32 @cq_theta_ui32(i32 noundef %1, double noundef %3) #4    ; C: cq_theta(&y, ty);
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %5) #5    ; C: (b comes into scope)
  %8 = trunc i32 %6 to i8    ; C: (int)x  (memset takes its fill as a byte)
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 1 dereferenceable(4) %5, i8 %8, i64 4, i1 false)    ; C: memset(b, (int)x, sizeof b);
  %9 = and i32 %7, 3    ; C: y & 3
  %10 = zext nneg i32 %9 to i64    ; C: y & 3  (as an index)
  %11 = getelementptr inbounds [4 x i8], ptr %5, i64 0, i64 %10    ; C: &b[y & 3]
  store i8 7, ptr %11, align 1, !tbaa !13    ; C: b[y & 3] = 7;
  %12 = load i8, ptr %5, align 1, !tbaa !13    ; C: b[0]
  %13 = zext i8 %12 to i32    ; C: b[0]  (promoted to int)
  %14 = getelementptr inbounds i8, ptr %5, i64 3    ; C: &b[3]
  %15 = load i8, ptr %14, align 1, !tbaa !13    ; C: b[3]
  %16 = zext i8 %15 to i32    ; C: b[3]  (promoted to int)
  %17 = add nuw nsw i32 %16, %13    ; C: b[0] + b[3]
  %18 = tail call i32 @cq_measure_si32(i32 noundef %17) #5    ; C: cq_measure(b[0] + b[3])
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %5) #5    ; C: (b goes out of scope)
  ret i32 %18    ; C: return
}

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
!13 = !{!8, !8, i64 0}
