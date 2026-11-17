; ModuleID = 'ptrtoint_inttoptr.c'
source_filename = "ptrtoint_inttoptr.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @ptr_roundtrip(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = alloca [2 x i32], align 8    ; C: int a[2]
  %5 = alloca [2 x i32], align 8    ; C: int b[2]
  %6 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #3    ; C: cq_theta(&x, th);
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %4) #4    ; C: (a comes into scope)
  store i64 8589934593, ptr %4, align 8    ; C: a = {1, 2}
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %5) #4    ; C: (b comes into scope)
  store i64 17179869187, ptr %5, align 8    ; C: b = {3, 4}
  %7 = and i32 %6, 1    ; C: x & 1
  %8 = icmp eq i32 %7, 0    ; C: (x & 1) ? a : b
  %9 = select i1 %8, ptr %5, ptr %4    ; C: int *p = (x & 1) ? a : b;
  %10 = ptrtoint ptr %9 to i64    ; C: uintptr_t u = (uintptr_t)p;
  %11 = and i32 %6, 4    ; C: x & 4
  %12 = zext nneg i32 %11 to i64    ; C: (widened)
  %13 = or disjoint i64 %10, %12    ; C: u ^= (x & 4);  (xor of disjoint bits = or)
  %14 = inttoptr i64 %13 to ptr    ; C: int *q = (int *)u;
  %15 = load i32, ptr %14, align 4, !tbaa !6    ; C: *q
  %16 = add nsw i32 %15, %2    ; C: *q + v
  %17 = call i32 @cq_measure_si32(i32 noundef %16) #4    ; C: cq_measure(*q + v)
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %5) #4    ; C: (b goes out of scope)
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %4) #4    ; C: (a goes out of scope)
  ret i32 %17    ; C: return
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
