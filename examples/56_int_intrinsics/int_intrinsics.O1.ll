; ModuleID = 'int_intrinsics.c'
source_filename = "int_intrinsics.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @fshl_qq(i32 noundef %0, i32 noundef %1, double noundef %2, double noundef %3) local_unnamed_addr #0 {
  %5 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %2) #4    ; C: cq_theta(&a, ta);
  %6 = tail call i32 @cq_theta_ui32(i32 noundef %1, double noundef %3) #4    ; C: cq_theta(&b, tb);
  %7 = tail call i32 @llvm.fshl.i32(i32 %5, i32 %6, i32 1)    ; C: (a << 1) | (b >> 31)  (fused into a funnel shift)
  %8 = tail call i32 @cq_measure_ui32(i32 noundef %7) #5    ; C: cq_measure(...)
  ret i32 %8    ; C: return
}

declare i32 @cq_theta_ui32(i32 noundef, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_ui32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @rotl_qc(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #4    ; C: cq_theta(&x, th);
  %5 = shl i32 %4, %2    ; C: x << k
  %6 = sub i32 32, %2    ; C: 32 - k  (classical)
  %7 = lshr i32 %4, %6    ; C: x >> (32 - k)
  %8 = or i32 %5, %7    ; C: (x << k) | (x >> (32 - k))  (not fused: the two shift amounts are separate values)
  %9 = tail call i32 @cq_measure_ui32(i32 noundef %8) #5    ; C: cq_measure(...)
  ret i32 %9    ; C: return
}

; Function Attrs: nounwind ssp uwtable
define i32 @clz_q(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #4    ; C: cq_theta(&x, th);
  %4 = tail call range(i32 0, 33) i32 @llvm.ctlz.i32(i32 %3, i1 true)    ; C: __builtin_clz(x)
  %5 = tail call i32 @cq_measure_si32(i32 noundef %4) #5    ; C: cq_measure(...)
  ret i32 %5    ; C: return
}

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.ctlz.i32(i32, i1 immarg) #2

; Function Attrs: nounwind ssp uwtable
define i32 @popcount_q(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #4    ; C: cq_theta(&x, th);
  %5 = and i32 %4, %2    ; C: x & c
  %6 = tail call range(i32 0, 33) i32 @llvm.ctpop.i32(i32 %5)    ; C: __builtin_popcount(x & c)
  %7 = tail call i32 @cq_measure_si32(i32 noundef %6) #5    ; C: cq_measure(...)
  ret i32 %7    ; C: return
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.ctpop.i32(i32) #2

; Function Attrs: nounwind ssp uwtable
define i32 @smax_qc(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #4    ; C: cq_theta(&x, th);
  %5 = tail call i32 @llvm.smax.i32(i32 %4, i32 %2)    ; C: x > c ? x : c  (folded to smax)
  %6 = tail call i32 @cq_measure_si32(i32 noundef %5) #5    ; C: cq_measure(...)
  ret i32 %6    ; C: return
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @umax_qq(i32 noundef %0, i32 noundef %1, double noundef %2, double noundef %3) local_unnamed_addr #0 {
  %5 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %2) #4    ; C: cq_theta(&x, tx);
  %6 = tail call i32 @cq_theta_ui32(i32 noundef %1, double noundef %3) #4    ; C: cq_theta(&y, ty);
  %7 = tail call i32 @llvm.umax.i32(i32 %5, i32 %6)    ; C: x > y ? x : y  (folded to umax)
  %8 = tail call i32 @cq_measure_ui32(i32 noundef %7) #5    ; C: cq_measure(...)
  ret i32 %8    ; C: return
}

; Function Attrs: nounwind ssp uwtable
define i32 @abs_q(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #4    ; C: cq_theta(&x, th);
  %4 = tail call i32 @llvm.abs.i32(i32 %3, i1 true)    ; C: __builtin_abs(x)
  %5 = tail call i32 @cq_measure_si32(i32 noundef %4) #5    ; C: cq_measure(...)
  ret i32 %5    ; C: return
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.abs.i32(i32, i1 immarg) #2

; Function Attrs: nounwind ssp uwtable
define i32 @fptoui_q(double noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call double @cq_theta_f64(double noundef %0, double noundef %1) #4    ; C: cq_theta(&x, th);
  %4 = fptoui double %3 to i32    ; C: (unsigned)x
  %5 = tail call i32 @cq_measure_ui32(i32 noundef %4) #5    ; C: cq_measure(...)
  ret i32 %5    ; C: return
}

declare double @cq_theta_f64(double noundef, double noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define double @same_operand_twice(double noundef %0, double noundef %1, double noundef %2) local_unnamed_addr #0 {
  %4 = tail call double @cq_theta_f64(double noundef %0, double noundef %1) #4    ; C: cq_theta(&x, th);
  %5 = fpext double %4 to x86_fp80    ; C: (long double)x
  %6 = fpext double %2 to x86_fp80    ; C: (long double)p  (classical)
  %7 = fmul x86_fp80 %6, %5    ; C: (long double)x * p
  %8 = fdiv x86_fp80 %7, %7    ; C: t / t  (the same value in both operands)
  %9 = tail call x86_fp80 @cq_measure_f80(x86_fp80 noundef %8) #5    ; C: cq_measure(...)  (long double)
  %10 = fptrunc x86_fp80 %9 to double    ; C: implicit conversion of the classical outcome to double
  ret double %10    ; C: return
}

declare x86_fp80 @cq_measure_f80(x86_fp80 noundef) local_unnamed_addr #1

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.fshl.i32(i32, i32, i32) #3

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.smax.i32(i32, i32) #3

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.umax.i32(i32, i32) #3

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
