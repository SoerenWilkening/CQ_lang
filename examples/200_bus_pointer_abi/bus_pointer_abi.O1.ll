; ModuleID = 'bus_pointer_abi.c'
source_filename = "bus_pointer_abi.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@tab = internal global [4 x i32] zeroinitializer, align 16

; Function Attrs: nounwind ssp uwtable
define i32 @bus_pointer_arg(i32 noundef %0, double noundef %1, i32 noundef %2, double noundef %3) local_unnamed_addr #0 {
  %5 = alloca [4 x i32], align 16    ; C: int a[4]
  %6 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #6    ; C: cq_theta(&k, tk);
  %7 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef %3) #6    ; C: cq_theta(&x, tx);
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %5) #7    ; C: (a comes into scope)
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 16 dereferenceable(16) %5, i8 0, i64 16, i1 false)    ; C: a = {0, 0, 0, 0}
  %8 = and i32 %6, 3    ; C: k & 3
  %9 = zext nneg i32 %8 to i64    ; C: (index)
  %10 = getelementptr inbounds [4 x i32], ptr %5, i64 0, i64 %9    ; C: &a[k & 3]
  call fastcc void @put(ptr noundef nonnull %10, i32 noundef %7)    ; C: put(&a[k & 3], x);
  %11 = getelementptr inbounds i8, ptr %5, i64 8    ; C: &a[2]
  call fastcc void @put(ptr noundef nonnull %11, i32 noundef %7)    ; C: put(&a[2], x);
  %12 = getelementptr inbounds i8, ptr %5, i64 4    ; C: &a[1]
  call fastcc void @put(ptr noundef nonnull %12, i32 noundef 5)    ; C: put(&a[1], 5);
  %13 = load i32, ptr %5, align 16, !tbaa !6    ; C: a[0]
  %14 = load i32, ptr %12, align 4, !tbaa !6    ; C: a[1]
  %15 = add nsw i32 %14, %13    ; C: a[0] + a[1]
  %16 = tail call i32 @cq_measure_si32(i32 noundef %15) #7    ; C: cq_measure(a[0] + a[1])
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %5) #7    ; C: (a goes out of scope)
  ret i32 %16    ; C: return
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare i32 @cq_theta_ui32(i32 noundef, double noundef) local_unnamed_addr #2

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nounwind willreturn memory(argmem: write)
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg) #3

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(argmem: write) uwtable
define internal fastcc void @put(ptr nocapture noundef writeonly %0, i32 noundef %1) unnamed_addr #4 {
  store i32 %1, ptr %0, align 4, !tbaa !6    ; C: *p = v;
  ret void    ; C: (end of put)
}

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: nounwind ssp uwtable
define i32 @bus_pointer_result(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #6    ; C: cq_theta(&k, tk);
  %5 = tail call fastcc ptr @slot(i32 noundef %4)    ; C: slot(k)
  store i32 %2, ptr %5, align 4, !tbaa !6    ; C: *slot(k) = v;
  %6 = load i32, ptr getelementptr inbounds (i8, ptr @tab, i64 4), align 4, !tbaa !6    ; C: tab[1]
  %7 = tail call i32 @cq_measure_si32(i32 noundef %6) #7    ; C: cq_measure(tab[1])
  ret i32 %7    ; C: return
}

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable
define internal fastcc nonnull ptr @slot(i32 noundef %0) unnamed_addr #5 {
  %2 = and i32 %0, 3    ; C: i & 3
  %3 = zext nneg i32 %2 to i64    ; C: (index)
  %4 = getelementptr inbounds [4 x i32], ptr @tab, i64 0, i64 %3    ; C: &tab[i & 3]
  ret ptr %4    ; C: return &tab[i & 3];
}

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nocallback nofree nounwind willreturn memory(argmem: write) }
attributes #4 = { mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(argmem: write) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #5 = { mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #6 = { nomerge nounwind }
attributes #7 = { nounwind }

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
