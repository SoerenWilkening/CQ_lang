; ModuleID = 'bus_kept_and_uncopied.c'
source_filename = "bus_kept_and_uncopied.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@__const.bus_kept_and_uncopied.a = private unnamed_addr constant [4 x i32] [i32 1, i32 2, i32 3, i32 4], align 16

; Function Attrs: nounwind ssp uwtable
define i32 @bus_kept_and_uncopied(i32 noundef %0, double noundef %1, i32 noundef %2, double noundef %3, double noundef %4, double noundef %5) local_unnamed_addr #0 {
  %7 = alloca [4 x i32], align 16    ; C: int a[4]
  %8 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #4    ; C: cq_theta(&k, tk);
  %9 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef %3) #4    ; C: cq_theta(&y, ty);
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %7) #5    ; C: (a comes into scope)
  call void @llvm.memcpy.p0.p0.i64(ptr noundef nonnull align 16 dereferenceable(16) %7, ptr noundef nonnull align 16 dereferenceable(16) @__const.bus_kept_and_uncopied.a, i64 16, i1 false)    ; C: a = {1, 2, 3, 4}
  %10 = and i32 %8, 3    ; C: k & 3
  %11 = zext nneg i32 %10 to i64    ; C: (index)
  %12 = getelementptr inbounds [4 x i32], ptr %7, i64 0, i64 %11    ; C: &a[k & 3]
  %13 = load i32, ptr %12, align 4, !tbaa !6    ; C: a[k & 3]  (load 1)
  %14 = icmp sgt i32 %13, 2    ; C: if (a[k & 3] > 2)
  br i1 %14, label %15, label %16    ; C: if (a[k & 3] > 2)

15:                                               ; preds = %6
  tail call void @cq_phi(double noundef %4) #5    ; C: cq_phi(p1);
  br label %16    ; C: end of if

16:                                               ; preds = %15, %6
  %17 = lshr i32 %8, 2    ; C: k >> 2
  %18 = and i32 %17, 3    ; C: (k >> 2) & 3
  %19 = zext nneg i32 %18 to i64    ; C: (index)
  %20 = getelementptr inbounds [4 x i32], ptr %7, i64 0, i64 %19    ; C: &a[(k >> 2) & 3]
  %21 = load i32, ptr %20, align 4, !tbaa !6    ; C: int t = a[(k >> 2) & 3];  (load 2, before the store)
  store i32 %9, ptr %12, align 4, !tbaa !6    ; C: a[k & 3] = y;  (the address of load 1 again)
  %22 = icmp sgt i32 %21, 2    ; C: if (t > 2)  (the consumer of load 2, after the store)
  br i1 %22, label %23, label %24    ; C: if (t > 2)

23:                                               ; preds = %16
  tail call void @cq_phi(double noundef %5) #5    ; C: cq_phi(p2);
  br label %24    ; C: end of if

24:                                               ; preds = %23, %16
  %25 = load i32, ptr %7, align 16, !tbaa !6    ; C: a[0]  (load 3)
  %26 = tail call i32 @cq_measure_si32(i32 noundef %25) #5    ; C: cq_measure(a[0])
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %7) #5    ; C: (a goes out of scope)
  ret i32 %26    ; C: return
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare i32 @cq_theta_ui32(i32 noundef, double noundef) local_unnamed_addr #2

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nounwind willreturn memory(argmem: readwrite)
declare void @llvm.memcpy.p0.p0.i64(ptr noalias nocapture writeonly, ptr noalias nocapture readonly, i64, i1 immarg) #3

declare void @cq_phi(double noundef) local_unnamed_addr #2

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

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
