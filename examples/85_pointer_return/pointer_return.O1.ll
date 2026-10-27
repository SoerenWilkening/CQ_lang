; ModuleID = 'pointer_return.c'
source_filename = "pointer_return.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @ptr_return(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = alloca [4 x i32], align 16    ; C: int a[4]
  %5 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #4    ; C: cq_theta(&x, th);
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %4) #5    ; C: (a comes into scope)
  store i32 %2, ptr %4, align 16, !tbaa !6    ; C: a[0] = a0
  %6 = getelementptr inbounds i8, ptr %4, i64 4    ; C: &a[1]
  %7 = add nsw i32 %2, 1    ; C: a0 + 1
  store i32 %7, ptr %6, align 4, !tbaa !6    ; C: a[1] = a0 + 1
  %8 = getelementptr inbounds i8, ptr %4, i64 8    ; C: &a[2]
  %9 = add nsw i32 %2, 2    ; C: a0 + 2
  store i32 %9, ptr %8, align 8, !tbaa !6    ; C: a[2] = a0 + 2
  %10 = getelementptr inbounds i8, ptr %4, i64 12    ; C: &a[3]
  %11 = add nsw i32 %2, 3    ; C: a0 + 3
  store i32 %11, ptr %10, align 4, !tbaa !6    ; C: a[3] = a0 + 3
  %12 = call fastcc ptr @pick(ptr noundef nonnull %4, i32 noundef %5)    ; C: int *p = pick(a, x);
  %13 = icmp eq ptr %12, null    ; C: p ? ... : ...
  br i1 %13, label %16, label %14    ; C: p ? *p : -1

14:                                               ; preds = %3
  %15 = load i32, ptr %12, align 4, !tbaa !6    ; C: *p
  br label %16    ; C: (join)

16:                                               ; preds = %3, %14
  %17 = phi i32 [ %15, %14 ], [ -1, %3 ]    ; C: int r = p ? *p : -1;
  %18 = call i32 @cq_measure_si32(i32 noundef %17) #5    ; C: cq_measure(r)
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %4) #5    ; C: (a goes out of scope)
  ret i32 %18    ; C: return
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare i32 @cq_theta_ui32(i32 noundef, double noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable
define internal fastcc ptr @pick(ptr noundef readnone %0, i32 noundef %1) unnamed_addr #3 {
  %3 = and i32 %1, 1    ; C: k & 1
  %4 = icmp eq i32 %3, 0    ; C: (k & 1) ? ... : NULL
  %5 = lshr i32 %1, 1    ; C: k >> 1
  %6 = and i32 %5, 3    ; C: (k >> 1) & 3
  %7 = zext nneg i32 %6 to i64    ; C: (index)
  %8 = getelementptr inbounds i32, ptr %0, i64 %7    ; C: &a[2]
  %9 = select i1 %4, ptr null, ptr %8    ; C: (k & 1) ? a + ((k >> 1) & 3) : (int *)0
  ret ptr %9    ; C: return
}

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
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
