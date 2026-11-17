; ModuleID = 'overflow_fshr_variants.c'
source_filename = "overflow_fshr_variants.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @uadd_overflow_qc(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #3    ; C: cq_theta(&x, th);
  %5 = tail call { i32, i1 } @llvm.uadd.with.overflow.i32(i32 %4, i32 %2)    ; C: __builtin_add_overflow(x, c, &r)  (the { sum, overflow } aggregate)
  %6 = extractvalue { i32, i1 } %5, 1    ; C: if (__builtin_add_overflow(...))  (the flag)
  %7 = extractvalue { i32, i1 } %5, 0    ; C: r  (the wrapped sum)
  %8 = select i1 %6, i32 %2, i32 %7    ; C: r = c;  (folded into a select)
  %9 = tail call i32 @cq_measure_ui32(i32 noundef %8) #4    ; C: cq_measure(r)
  ret i32 %9    ; C: return
}

declare i32 @cq_theta_ui32(i32 noundef, double noundef) local_unnamed_addr #1

; Function Attrs: mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare { i32, i1 } @llvm.uadd.with.overflow.i32(i32, i32) #2

declare i32 @cq_measure_ui32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i64 @usub_overflow_qq(i64 noundef %0, i64 noundef %1, double noundef %2, double noundef %3) local_unnamed_addr #0 {
  %5 = tail call i64 @cq_theta_ul(i64 noundef %0, double noundef %2) #3    ; C: cq_theta(&x, tx);
  %6 = tail call i64 @cq_theta_ul(i64 noundef %1, double noundef %3) #3    ; C: cq_theta(&y, ty);
  %7 = tail call { i64, i1 } @llvm.usub.with.overflow.i64(i64 %5, i64 %6)    ; C: __builtin_sub_overflow(x, y, &r)  (the { difference, overflow } aggregate)
  %8 = extractvalue { i64, i1 } %7, 1    ; C: o  (the flag)
  %9 = extractvalue { i64, i1 } %7, 0    ; C: r  (the wrapped difference)
  %10 = zext i1 %8 to i32    ; C: int o = ...  (the flag as an int)
  %11 = tail call i64 @cq_measure_ul(i64 noundef %9) #4    ; C: cq_measure(r)
  %12 = tail call i32 @cq_measure_si32(i32 noundef %10) #4    ; C: cq_measure(o)
  %13 = sext i32 %12 to i64    ; C: (unsigned long)cq_measure(o)
  %14 = add i64 %11, %13    ; C: cq_measure(r) + cq_measure(o)
  ret i64 %14    ; C: return
}

declare i64 @cq_theta_ul(i64 noundef, double noundef) local_unnamed_addr #1

; Function Attrs: mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare { i64, i1 } @llvm.usub.with.overflow.i64(i64, i64) #2

declare i64 @cq_measure_ul(i64 noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @rotr_qc(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #3    ; C: cq_theta(&x, th);
  %5 = tail call i32 @llvm.fshr.i32(i32 %4, i32 %4, i32 %2)    ; C: __builtin_rotateright32(x, k)  (a funnel shift of x with itself by a classical k)
  %6 = tail call i32 @cq_measure_ui32(i32 noundef %5) #4    ; C: cq_measure(...)
  ret i32 %6    ; C: return
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.fshr.i32(i32, i32, i32) #2

; Function Attrs: nounwind ssp uwtable
define i32 @rotr_qq(i32 noundef %0, i32 noundef %1, double noundef %2, double noundef %3) local_unnamed_addr #0 {
  %5 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %2) #3    ; C: cq_theta(&x, tx);
  %6 = tail call i32 @cq_theta_ui32(i32 noundef %1, double noundef %3) #3    ; C: cq_theta(&k, tk);
  %7 = tail call i32 @llvm.fshr.i32(i32 %5, i32 %5, i32 %6)    ; C: (x >> (k & 31)) | (x << ((32 - k) & 31))  (folded into a funnel shift of x with itself by the quantum k)
  %8 = tail call i32 @cq_measure_ui32(i32 noundef %7) #4    ; C: cq_measure(...)
  ret i32 %8    ; C: return
}

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none) }
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
