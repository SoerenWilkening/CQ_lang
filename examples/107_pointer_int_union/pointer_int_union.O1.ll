; ModuleID = 'pointer_int_union.c'
source_filename = "pointer_int_union.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

%union.pv = type { ptr }

; Function Attrs: nounwind ssp uwtable
define i32 @union_ptr_to_int(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = alloca [2 x i32], align 8    ; C: int a[2]
  %5 = alloca [2 x i32], align 8    ; C: int b[2]
  %6 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #4    ; C: cq_theta(&x, th);
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %4) #5    ; C: (a comes into scope)
  store i64 8589934593, ptr %4, align 8    ; C: a = {1, 2}
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %5) #5    ; C: (b comes into scope)
  store i64 17179869187, ptr %5, align 8    ; C: b = {3, 4}
  %7 = and i32 %6, 1    ; C: x & 1
  %8 = icmp eq i32 %7, 0    ; C: (x & 1) ? ... : ...
  %9 = getelementptr inbounds i8, ptr %5, i64 4    ; C: b + 1
  %10 = select i1 %8, ptr %9, ptr %4    ; C: u.p = (x & 1) ? a : b + 1;  (the union is folded into its value by SROA)
  %11 = ptrtoint ptr %10 to i64    ; C: u.v  (the pointer member read as an integer)
  %12 = add i64 %11, 4    ; C: u.v += 4;
  %13 = inttoptr i64 %12 to ptr    ; C: u.p  (the integer member read as a pointer)
  %14 = load i32, ptr %13, align 4, !tbaa !6    ; C: *u.p
  %15 = add nsw i32 %14, %2    ; C: *u.p + w
  %16 = call i32 @cq_measure_si32(i32 noundef %15) #5    ; C: cq_measure(*u.p + w)
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %5) #5    ; C: (b goes out of scope)
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %4) #5    ; C: (a goes out of scope)
  ret i32 %16    ; C: return
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare i32 @cq_theta_ui32(i32 noundef, double noundef) local_unnamed_addr #2

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: nounwind ssp uwtable
define i32 @union_int_to_ptr(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = alloca [4 x i32], align 16    ; C: int a[4]
  %5 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #4    ; C: cq_theta(&x, th);
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %4) #5    ; C: (a comes into scope)
  store i32 %2, ptr %4, align 16, !tbaa !6    ; C: a[0] = w
  %6 = getelementptr inbounds i8, ptr %4, i64 4    ; C: &a[1]
  %7 = add nsw i32 %2, 1    ; C: w + 1
  store i32 %7, ptr %6, align 4, !tbaa !6    ; C: a[1] = w + 1
  %8 = getelementptr inbounds i8, ptr %4, i64 8    ; C: &a[2]
  %9 = add nsw i32 %2, 2    ; C: w + 2
  store i32 %9, ptr %8, align 8, !tbaa !6    ; C: a[2] = w + 2
  %10 = getelementptr inbounds i8, ptr %4, i64 12    ; C: &a[3]
  %11 = add nsw i32 %2, 3    ; C: w + 3
  store i32 %11, ptr %10, align 4, !tbaa !6    ; C: a[3] = w + 3
  %12 = ptrtoint ptr %4 to i64    ; C: (uintptr_t)a
  %13 = shl i32 %5, 2    ; C: 4 * x
  %14 = and i32 %13, 12    ; C: 4 * (x & 3)
  %15 = zext nneg i32 %14 to i64    ; C: (widened)
  %16 = or disjoint i64 %15, %12    ; C: u.v = (uintptr_t)a + 4 * (x & 3);  (the union is folded into its value by SROA)
  %17 = inttoptr i64 %16 to ptr    ; C: u.p  (the integer member read as a pointer)
  %18 = load i32, ptr %17, align 4, !tbaa !6    ; C: *u.p
  %19 = call i32 @cq_measure_si32(i32 noundef %18) #5    ; C: cq_measure(*u.p)
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %4) #5    ; C: (a goes out of scope)
  ret i32 %19    ; C: return
}

; Function Attrs: nounwind ssp uwtable
define i32 @union_slot(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = alloca [2 x i32], align 8    ; C: int a[2]
  %5 = alloca [2 x i32], align 8    ; C: int b[2]
  %6 = alloca %union.pv, align 8    ; C: union pv u;  (the slot survives: its address escapes to bump)
  %7 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #4    ; C: cq_theta(&x, th);
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %4) #5    ; C: (a comes into scope)
  store i64 8589934593, ptr %4, align 8    ; C: a = {1, 2}
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %5) #5    ; C: (b comes into scope)
  store i64 17179869187, ptr %5, align 8    ; C: b = {3, 4}
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %6) #5    ; C: (u comes into scope)
  %8 = and i32 %7, 1    ; C: x & 1
  %9 = icmp eq i32 %8, 0    ; C: (x & 1) ? a : b
  %10 = select i1 %9, ptr %5, ptr %4    ; C: (x & 1) ? a : b
  store ptr %10, ptr %6, align 8, !tbaa !10    ; C: u.p = ...;  (store the pointer member)
  call fastcc void @bump(ptr noundef nonnull %6)    ; C: bump(&u);
  %11 = load ptr, ptr %6, align 8, !tbaa !10    ; C: u.p  (load the pointer member)
  %12 = load i32, ptr %11, align 4, !tbaa !6    ; C: *u.p
  %13 = add nsw i32 %12, %2    ; C: *u.p + w
  %14 = call i32 @cq_measure_si32(i32 noundef %13) #5    ; C: cq_measure(*u.p + w)
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %6) #5    ; C: (u goes out of scope)
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %5) #5    ; C: (b goes out of scope)
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %4) #5    ; C: (a goes out of scope)
  ret i32 %14    ; C: return
}

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(argmem: readwrite) uwtable
define internal fastcc void @bump(ptr nocapture noundef %0) unnamed_addr #3 {
  %2 = load i64, ptr %0, align 8, !tbaa !10    ; C: u->v  (the integer member read from the slot)
  %3 = add i64 %2, 4    ; C: u->v + 4
  store i64 %3, ptr %0, align 8, !tbaa !10    ; C: u->v += 4;  (the integer member stored into the slot)
  ret void    ; C: return
}

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(argmem: readwrite) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
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
!10 = !{!8, !8, i64 0}
