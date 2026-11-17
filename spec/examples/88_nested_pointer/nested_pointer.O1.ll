; ModuleID = 'nested_pointer.c'
source_filename = "nested_pointer.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

%struct.S = type { i32, i32 }

; Function Attrs: nounwind ssp uwtable
define i32 @nested_pointer(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = alloca [2 x i32], align 8    ; C: int a[2]
  %5 = alloca [2 x i32], align 8    ; C: int b[2]
  %6 = alloca %struct.S, align 8    ; C: struct S s
  %7 = alloca [2 x ptr], align 16    ; C: int *tab[2]
  %8 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #3    ; C: cq_theta(&x, th);
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %4) #4    ; C: (a comes into scope)
  store i64 8589934593, ptr %4, align 8    ; C: a = {1, 2}
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %5) #4    ; C: (b comes into scope)
  store i64 17179869187, ptr %5, align 8    ; C: b = {3, 4}
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %6) #4    ; C: (s comes into scope)
  store i64 25769803781, ptr %6, align 8    ; C: s = {5, 6}
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %7) #4    ; C: (tab comes into scope)
  store ptr %4, ptr %7, align 16, !tbaa !6    ; C: tab[0] = a
  %9 = getelementptr inbounds i8, ptr %7, i64 8    ; C: &tab[1]
  store ptr %5, ptr %9, align 8, !tbaa !6    ; C: tab[1] = b
  %10 = and i32 %8, 1    ; C: x & 1
  %11 = zext nneg i32 %10 to i64    ; C: (index)
  %12 = getelementptr inbounds ptr, ptr %7, i64 %11    ; C: int **pp = tab + (x & 1);
  %13 = load ptr, ptr %12, align 8, !tbaa !6    ; C: int *p = *pp;
  %14 = lshr i32 %8, 1    ; C: x >> 1
  %15 = and i32 %14, 1    ; C: (x >> 1) & 1
  %16 = zext nneg i32 %15 to i64    ; C: (index)
  %17 = getelementptr inbounds i32, ptr %13, i64 %16    ; C: &p[(x >> 1) & 1]
  store i32 %2, ptr %17, align 4, !tbaa !10    ; C: p[(x >> 1) & 1] = v;
  %18 = getelementptr inbounds i8, ptr %6, i64 4    ; C: &s.g
  %19 = lshr i32 %8, 2    ; C: x >> 2
  %20 = and i32 %19, 1    ; C: (x >> 2) & 1
  %21 = zext nneg i32 %20 to i64    ; C: (index)
  %22 = getelementptr inbounds [2 x ptr], ptr %7, i64 0, i64 %21    ; C: &tab[(x >> 2) & 1]
  store ptr %18, ptr %22, align 8, !tbaa !6    ; C: tab[(x >> 2) & 1] = &s.g;
  %23 = load ptr, ptr %9, align 8, !tbaa !6    ; C: int *q = tab[1];
  %24 = load i32, ptr %4, align 8, !tbaa !10    ; C: a[0]
  %25 = getelementptr inbounds i8, ptr %5, i64 4    ; C: &b[1]
  %26 = load i32, ptr %25, align 4, !tbaa !10    ; C: b[1]
  %27 = add nsw i32 %26, %24    ; C: a[0] + b[1]
  %28 = load i32, ptr %23, align 4, !tbaa !10    ; C: *q
  %29 = add nsw i32 %27, %28    ; C: a[0] + b[1] + *q
  %30 = call i32 @cq_measure_si32(i32 noundef %29) #4    ; C: cq_measure(a[0] + b[1] + *q)
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %7) #4    ; C: (tab goes out of scope)
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %6) #4    ; C: (s goes out of scope)
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %5) #4    ; C: (b goes out of scope)
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %4) #4    ; C: (a goes out of scope)
  ret i32 %30    ; C: return
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
!7 = !{!"any pointer", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
!10 = !{!11, !11, i64 0}
!11 = !{!"int", !8, i64 0}
