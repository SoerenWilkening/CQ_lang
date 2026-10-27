; ModuleID = 'multi_origin_pointer.c'
source_filename = "multi_origin_pointer.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @ptr_select_store(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = alloca [2 x i32], align 8    ; C: int a[2]
  %5 = alloca [2 x i32], align 8    ; C: int b[2]
  %6 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #3    ; C: cq_theta(&x, th);
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %4) #4    ; C: (a comes into scope)
  store i64 8589934593, ptr %4, align 8    ; C: a = {1, 2}
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %5) #4    ; C: (b comes into scope)
  store i64 17179869187, ptr %5, align 8    ; C: b = {3, 4}
  %7 = icmp ugt i32 %6, 5    ; C: if (x > 5)
  br i1 %7, label %8, label %16    ; C: if (x > 5)

8:                                                ; preds = %3
  %9 = and i32 %6, 1    ; C: x & 1
  %10 = icmp eq i32 %9, 0    ; C: (x & 1) ? a : b
  %11 = select i1 %10, ptr %5, ptr %4    ; C: int *p = (x & 1) ? a : b;  (sunk into the arm by -O1)
  %12 = lshr i32 %6, 1    ; C: x >> 1
  %13 = and i32 %12, 1    ; C: (x >> 1) & 1
  %14 = zext nneg i32 %13 to i64    ; C: (index)
  %15 = getelementptr inbounds i32, ptr %11, i64 %14    ; C: &p[(x >> 1) & 1]
  store i32 %2, ptr %15, align 4, !tbaa !6    ; C: p[(x >> 1) & 1] = v;
  br label %16    ; C: end of if

16:                                               ; preds = %8, %3
  %17 = load i32, ptr %4, align 8, !tbaa !6    ; C: a[0]
  %18 = getelementptr inbounds i8, ptr %5, i64 4    ; C: &b[1]
  %19 = load i32, ptr %18, align 4, !tbaa !6    ; C: b[1]
  %20 = add nsw i32 %19, %17    ; C: a[0] + b[1]
  %21 = tail call i32 @cq_measure_si32(i32 noundef %20) #4    ; C: cq_measure(a[0] + b[1])
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %5) #4    ; C: (b goes out of scope)
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %4) #4    ; C: (a goes out of scope)
  ret i32 %21    ; C: return
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare i32 @cq_theta_ui32(i32 noundef, double noundef) local_unnamed_addr #2

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

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
