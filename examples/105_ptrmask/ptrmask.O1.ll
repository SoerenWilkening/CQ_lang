; ModuleID = 'ptrmask.c'
source_filename = "ptrmask.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @ptrmask_q(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = alloca [8 x i32], align 16    ; C: int a[8] (16-aligned)
  %5 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #4    ; C: cq_theta(&x, th);
  call void @llvm.lifetime.start.p0(i64 32, ptr nonnull %4) #5    ; C: (a comes into scope)
  store i32 %2, ptr %4, align 16, !tbaa !6    ; C: a[0] = v
  %6 = getelementptr inbounds i8, ptr %4, i64 4    ; C: &a[1]
  %7 = add nsw i32 %2, 1    ; C: v + 1
  store i32 %7, ptr %6, align 4, !tbaa !6    ; C: a[1] = v + 1
  %8 = getelementptr inbounds i8, ptr %4, i64 8    ; C: &a[2]
  %9 = add nsw i32 %2, 2    ; C: v + 2
  store i32 %9, ptr %8, align 8, !tbaa !6    ; C: a[2] = v + 2
  %10 = getelementptr inbounds i8, ptr %4, i64 12    ; C: &a[3]
  %11 = add nsw i32 %2, 3    ; C: v + 3
  store i32 %11, ptr %10, align 4, !tbaa !6    ; C: a[3] = v + 3
  %12 = getelementptr inbounds i8, ptr %4, i64 16    ; C: &a[4]
  %13 = add nsw i32 %2, 4    ; C: v + 4
  store i32 %13, ptr %12, align 16, !tbaa !6    ; C: a[4] = v + 4
  %14 = getelementptr inbounds i8, ptr %4, i64 20    ; C: &a[5]
  %15 = add nsw i32 %2, 5    ; C: v + 5
  store i32 %15, ptr %14, align 4, !tbaa !6    ; C: a[5] = v + 5
  %16 = getelementptr inbounds i8, ptr %4, i64 24    ; C: &a[6]
  %17 = add nsw i32 %2, 6    ; C: v + 6
  store i32 %17, ptr %16, align 8, !tbaa !6    ; C: a[6] = v + 6
  %18 = getelementptr inbounds i8, ptr %4, i64 28    ; C: &a[7]
  %19 = add nsw i32 %2, 7    ; C: v + 7
  store i32 %19, ptr %18, align 4, !tbaa !6    ; C: a[7] = v + 7
  %20 = and i32 %5, 7    ; C: x & 7
  %21 = zext nneg i32 %20 to i64    ; C: (index)
  %22 = getelementptr inbounds i32, ptr %4, i64 %21    ; C: int *p = a + (x & 7);
  %23 = call align 16 ptr @llvm.ptrmask.p0.i64(ptr nonnull %22, i64 -16)    ; C: int *q = __builtin_align_down(p, 16);
  %24 = getelementptr inbounds i8, ptr %22, i64 12    ; C: p + 15 bytes (clang: + 12, p is 4-aligned)
  %25 = call align 16 ptr @llvm.ptrmask.p0.i64(ptr nonnull %24, i64 -16)    ; C: int *r = __builtin_align_up(p, 16);
  %26 = load i32, ptr %23, align 16, !tbaa !6    ; C: *q
  %27 = load i32, ptr %25, align 16, !tbaa !6    ; C: *r
  %28 = add nsw i32 %27, %26    ; C: *q + *r
  %29 = tail call i32 @cq_measure_si32(i32 noundef %28) #5    ; C: cq_measure(*q + *r)
  call void @llvm.lifetime.end.p0(i64 32, ptr nonnull %4) #5    ; C: (a goes out of scope)
  ret i32 %29    ; C: return
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare i32 @cq_theta_ui32(i32 noundef, double noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare ptr @llvm.ptrmask.p0.i64(ptr, i64) #3

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none) }
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
