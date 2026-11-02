; ModuleID = 'global_handoff.c'
source_filename = "global_handoff.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@sg = global i32 0, align 4
@sgi = internal global i32 0, align 4

; Function Attrs: nounwind ssp uwtable
define i32 @global_handoff_internal(i32 noundef %0) local_unnamed_addr #0 {
  %2 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 3.000000e-01) #5
  %3 = tail call fastcc i32 @f(i32 noundef %2)
  %4 = tail call i32 @cq_measure_si32(i32 noundef %3) #6
  ret i32 %4
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(write, argmem: none, inaccessiblemem: none) uwtable
define internal fastcc i32 @f(i32 noundef %0) unnamed_addr #2 {
  %2 = tail call fastcc i32 @g(i32 noundef %0, ptr noundef nonnull @sgi)
  %3 = xor i32 %2, 5
  ret i32 %3
}

; Function Attrs: nounwind ssp uwtable
define i32 @global_handoff_extern(i32 noundef %0) local_unnamed_addr #0 {
  %2 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 3.000000e-01) #5
  %3 = tail call fastcc i32 @f2(i32 noundef %2)
  %4 = tail call i32 @cq_measure_si32(i32 noundef %3) #6
  ret i32 %4
}

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(write, argmem: none, inaccessiblemem: none) uwtable
define internal fastcc i32 @f2(i32 noundef %0) unnamed_addr #2 {
  %2 = tail call fastcc i32 @g(i32 noundef %0, ptr noundef nonnull @sg)
  %3 = xor i32 %2, 5
  ret i32 %3
}

; Function Attrs: nounwind ssp uwtable
define i32 @global_handoff_read(i32 noundef %0) local_unnamed_addr #0 {
  %2 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 3.000000e-01) #5
  %3 = tail call fastcc i32 @f(i32 noundef %2)
  %4 = tail call i32 @cq_measure_si32(i32 noundef %3) #6
  %5 = tail call fastcc i32 @rd(i32 noundef %2)
  %6 = tail call i32 @cq_measure_si32(i32 noundef %5) #6
  %7 = add nsw i32 %6, %4
  ret i32 %7
}

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(read, argmem: none, inaccessiblemem: none) uwtable
define internal fastcc i32 @rd(i32 noundef %0) unnamed_addr #3 {
  %2 = load i32, ptr @sgi, align 4, !tbaa !6
  %3 = add nsw i32 %2, %0
  ret i32 %3
}

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(argmem: write) uwtable
define internal fastcc range(i32 -2147483647, -2147483648) i32 @g(i32 noundef %0, ptr nocapture noundef writeonly %1) unnamed_addr #4 {
  %3 = mul nsw i32 %0, 3
  store i32 %3, ptr %1, align 4, !tbaa !6
  %4 = add nsw i32 %0, 1
  ret i32 %4
}

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(write, argmem: none, inaccessiblemem: none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(read, argmem: none, inaccessiblemem: none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(argmem: write) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #5 = { nomerge nounwind }
attributes #6 = { nounwind }

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
; CHECK __cq_slot_init_sgi: call i32 @cqrt_alloc_i32(i32 0)
; CHECK __cq_q_f_1: call void @llvm.memcpy.p0.p0.i64(ptr align 1 %{{s}}, ptr align 1 @sgi, i64 4, i1 false)
; USERCHECK global_handoff_internal
; USERCHECK global_handoff_extern
; USERCHECK global_handoff_read
