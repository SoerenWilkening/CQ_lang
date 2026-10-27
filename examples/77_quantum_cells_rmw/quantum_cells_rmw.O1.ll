; ModuleID = 'quantum_cells_rmw.c'
source_filename = "quantum_cells_rmw.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @quantum_cells_rmw(i32 noundef %0, i32 noundef %1, double noundef %2, double noundef %3) local_unnamed_addr #0 {
  %5 = alloca [4 x i32], align 16    ; C: unsigned a[4]
  %6 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %2) #3    ; C: cq_theta(&x, tx);
  %7 = tail call i32 @cq_theta_ui32(i32 noundef %1, double noundef %3) #3    ; C: cq_theta(&y, ty);
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %5) #4    ; C: (a comes into scope)
  store i32 %7, ptr %5, align 16, !tbaa !6    ; C: a[0] = y
  %8 = getelementptr inbounds i8, ptr %5, i64 4    ; C: &a[1]
  %9 = add i32 %7, 1    ; C: y + 1
  store i32 %9, ptr %8, align 4, !tbaa !6    ; C: a[1] = y + 1
  %10 = getelementptr inbounds i8, ptr %5, i64 8    ; C: &a[2]
  %11 = add i32 %7, 2    ; C: y + 2
  store i32 %11, ptr %10, align 8, !tbaa !6    ; C: a[2] = y + 2
  %12 = getelementptr inbounds i8, ptr %5, i64 12    ; C: &a[3]
  %13 = add i32 %7, 3    ; C: y + 3
  store i32 %13, ptr %12, align 4, !tbaa !6    ; C: a[3] = y + 3
  %14 = and i32 %6, 3    ; C: x & 3
  %15 = zext nneg i32 %14 to i64    ; C: x & 3  (index widened)
  %16 = getelementptr inbounds [4 x i32], ptr %5, i64 0, i64 %15    ; C: &a[x & 3]
  %17 = load i32, ptr %16, align 4, !tbaa !6    ; C: a[x & 3]  (read)
  %18 = add i32 %17, %7    ; C: a[x & 3] + y
  store i32 %18, ptr %16, align 4, !tbaa !6    ; C: a[x & 3] += y;  (write back)
  %19 = load i32, ptr %5, align 16, !tbaa !6    ; C: a[0]
  %20 = load i32, ptr %8, align 4, !tbaa !6    ; C: a[1]
  %21 = xor i32 %20, %19    ; C: a[0] ^ a[1]
  %22 = load i32, ptr %10, align 8, !tbaa !6    ; C: a[2]
  %23 = xor i32 %21, %22    ; C: a[0] ^ a[1] ^ a[2]
  %24 = load i32, ptr %12, align 4, !tbaa !6    ; C: a[3]
  %25 = xor i32 %23, %24    ; C: a[0] ^ a[1] ^ a[2] ^ a[3]
  %26 = tail call i32 @cq_measure_ui32(i32 noundef %25) #4    ; C: cq_measure(a[0] ^ a[1] ^ a[2] ^ a[3])
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %5) #4    ; C: (a goes out of scope)
  ret i32 %26    ; C: return
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare i32 @cq_theta_ui32(i32 noundef, double noundef) local_unnamed_addr #2

declare i32 @cq_measure_ui32(i32 noundef) local_unnamed_addr #2

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
