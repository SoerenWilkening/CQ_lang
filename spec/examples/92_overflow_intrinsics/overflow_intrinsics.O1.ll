; ModuleID = 'overflow_intrinsics.c'
source_filename = "overflow_intrinsics.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @mul_overflow(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #4    ; C: cq_theta(&x, th);
  %5 = tail call { i32, i1 } @llvm.umul.with.overflow.i32(i32 %4, i32 %2)    ; C: __builtin_mul_overflow(x, c, &r)
  %6 = extractvalue { i32, i1 } %5, 1    ; C: o (the overflow flag)
  %7 = extractvalue { i32, i1 } %5, 0    ; C: r (the wrapped product)
  %8 = zext i1 %6 to i32    ; C: int o = ...
  %9 = tail call i32 @cq_measure_ui32(i32 noundef %7) #5    ; C: cq_measure(r)
  %10 = tail call i32 @cq_measure_si32(i32 noundef %8) #5    ; C: cq_measure(o)
  %11 = add i32 %10, %9    ; C: cq_measure(r) + cq_measure(o)
  ret i32 %11    ; C: return
}

declare i32 @cq_theta_ui32(i32 noundef, double noundef) local_unnamed_addr #1

; Function Attrs: mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare { i32, i1 } @llvm.umul.with.overflow.i32(i32, i32) #2

declare i32 @cq_measure_ui32(i32 noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @add_overflow_qq(i32 noundef %0, i32 noundef %1, double noundef %2, double noundef %3) local_unnamed_addr #0 {
  %5 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %2) #4    ; C: cq_theta(&x, tx);
  %6 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef %3) #4    ; C: cq_theta(&y, ty);
  %7 = tail call { i32, i1 } @llvm.sadd.with.overflow.i32(i32 %5, i32 %6)    ; C: __builtin_add_overflow(x, y, &r)
  %8 = extractvalue { i32, i1 } %7, 1    ; C: (overflow flag)
  %9 = extractvalue { i32, i1 } %7, 0    ; C: r (the wrapped sum)
  %10 = select i1 %8, i32 2147483647, i32 %9    ; C: if (overflow) r = 0x7fffffff;
  %11 = tail call i32 @cq_measure_si32(i32 noundef %10) #5    ; C: cq_measure(r)
  ret i32 %11    ; C: return
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

; Function Attrs: mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare { i32, i1 } @llvm.sadd.with.overflow.i32(i32, i32) #2

; Function Attrs: nounwind ssp uwtable
define i32 @add_sat(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #4    ; C: cq_theta(&x, th);
  %5 = tail call i32 @llvm.uadd.sat.i32(i32 %4, i32 %2)    ; C: s = x + c; if (s < x) s = 0xffffffffu;  (folded to a saturating add)
  %6 = tail call i32 @cq_measure_ui32(i32 noundef %5) #5    ; C: cq_measure(s)
  ret i32 %6    ; C: return
}

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.uadd.sat.i32(i32, i32) #3

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #3 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }
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
