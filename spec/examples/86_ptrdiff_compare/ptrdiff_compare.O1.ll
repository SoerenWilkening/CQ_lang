; ModuleID = 'ptrdiff_compare.c'
source_filename = "ptrdiff_compare.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i64 @ptrdiff_q(i32 noundef %0, double noundef %1, ptr nocapture noundef readnone %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #4    ; C: cq_theta(&x, th);
  %5 = shl i32 %4, 2    ; C: x & 3, as a byte offset: the folded p
  %6 = and i32 %5, 12    ; C: (p's byte offset)
  %7 = zext nneg i32 %6 to i64    ; C: (p's byte offset, i64)
  %8 = and i32 %4, 12    ; C: (x >> 2) & 3 as a byte offset: the folded q
  %9 = zext nneg i32 %8 to i64    ; C: (q's byte offset, i64)
  %10 = sub nsw i64 %9, %7    ; C: q - p  (byte difference)
  %11 = ashr exact i64 %10, 2    ; C: q - p  (in elements)
  %12 = tail call i64 @cq_measure_sl(i64 noundef %11) #5    ; C: cq_measure(q - p)
  ret i64 %12    ; C: return
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare i32 @cq_theta_ui32(i32 noundef, double noundef) local_unnamed_addr #2

declare i64 @cq_measure_sl(i64 noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: nounwind ssp uwtable
define i32 @ptr_less(i32 noundef %0, double noundef %1, ptr noundef readnone %2, ptr noundef readnone %3) local_unnamed_addr #0 {
  %5 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #4    ; C: cq_theta(&x, th);
  %6 = and i32 %5, 1    ; C: x & 1
  %7 = icmp eq i32 %6, 0    ; C: (x & 1) ? a : b
  %8 = select i1 %7, ptr %3, ptr %2    ; C: (x & 1) ? a : b
  %9 = lshr i32 %5, 1    ; C: x >> 1
  %10 = and i32 %9, 3    ; C: (x >> 1) & 3
  %11 = zext nneg i32 %10 to i64    ; C: (index)
  %12 = getelementptr inbounds i32, ptr %8, i64 %11    ; C: int *p = ... + ((x >> 1) & 3);
  %13 = lshr i32 %5, 3    ; C: x >> 3
  %14 = and i32 %13, 3    ; C: (x >> 3) & 3
  %15 = zext nneg i32 %14 to i64    ; C: (index)
  %16 = getelementptr inbounds i32, ptr %2, i64 %15    ; C: int *q = a + ((x >> 3) & 3);
  %17 = icmp ult ptr %12, %16    ; C: p < q
  %18 = zext i1 %17 to i32    ; C: (int)(p < q)
  %19 = tail call i32 @cq_measure_si32(i32 noundef %18) #5    ; C: cq_measure(p < q)
  ret i32 %19    ; C: return
}

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

; Function Attrs: nounwind ssp uwtable
define i32 @ptr_eq_two_objects(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = alloca [4 x i32], align 16    ; C: int a[4]
  %4 = alloca [4 x i32], align 16    ; C: int b[4]
  %5 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #4    ; C: cq_theta(&x, th);
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %3) #5    ; C: (a comes into scope)
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 16 dereferenceable(16) %3, i8 0, i64 16, i1 false)    ; C: a = {0, 0, 0, 0}
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %4) #5    ; C: (b comes into scope)
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 16 dereferenceable(16) %4, i8 0, i64 16, i1 false)    ; C: b = {0, 0, 0, 0}
  %6 = and i32 %5, 1    ; C: x & 1
  %7 = icmp eq i32 %6, 0    ; C: (x & 1) ? a : b
  %8 = select i1 %7, ptr %4, ptr %3    ; C: (x & 1) ? a : b
  %9 = lshr i32 %5, 1    ; C: x >> 1
  %10 = and i32 %9, 3    ; C: (x >> 1) & 3
  %11 = zext nneg i32 %10 to i64    ; C: (index)
  %12 = getelementptr inbounds i32, ptr %8, i64 %11    ; C: int *p = ... + ((x >> 1) & 3);
  %13 = lshr i32 %5, 3    ; C: x >> 3
  %14 = and i32 %13, 3    ; C: (x >> 3) & 3
  %15 = zext nneg i32 %14 to i64    ; C: (index)
  %16 = getelementptr inbounds i32, ptr %3, i64 %15    ; C: int *q = a + ((x >> 3) & 3);
  %17 = icmp eq ptr %12, %16    ; C: p == q
  %18 = zext i1 %17 to i32    ; C: (int)(p == q)
  %19 = call i32 @cq_measure_si32(i32 noundef %18) #5    ; C: cq_measure(p == q)
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %4) #5    ; C: (b goes out of scope)
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %3) #5    ; C: (a goes out of scope)
  ret i32 %19    ; C: return
}

; Function Attrs: mustprogress nocallback nofree nounwind willreturn memory(argmem: write)
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg) #3

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
