; /* tests/spine probe (CR rule 20, §1.3): a load and store per type: f64, f80, i8, i64, a pointer. */
; double fd = 1.5; long double fl = 2.5L; char cc = 3; long long ll = 4; double out1; long double out2; char out3; long long out4;
; int float_widths(double x0, double tx) {
;   double x = x0;
;   cq_theta(&x, tx);
;   out1 = fd + x;
;   out2 = fl * x;
;   out3 = cc + (x > 0);
;   out4 = ll + (x > 1);
;   return cq_measure(out3);
; }
; ModuleID = 'bus_float_widths.c'
source_filename = "bus_float_widths.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@fd = local_unnamed_addr global double 1.500000e+00, align 8
@fl = local_unnamed_addr global x86_fp80 0xK4000A000000000000000, align 16
@cc = local_unnamed_addr global i8 3, align 1
@ll = local_unnamed_addr global i64 4, align 8
@out1 = local_unnamed_addr global double 0.000000e+00, align 8
@out2 = local_unnamed_addr global x86_fp80 0xK00000000000000000000, align 16
@out3 = local_unnamed_addr global i8 0, align 1
@out4 = local_unnamed_addr global i64 0, align 8

; Function Attrs: nounwind ssp uwtable
define range(i32 -128, 128) i32 @float_widths(double noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call double @cq_theta_f64(double noundef %0, double noundef %1) #2
  %4 = load double, ptr @fd, align 8, !tbaa !6
  %5 = fadd double %3, %4
  store double %5, ptr @out1, align 8, !tbaa !6
  %6 = load x86_fp80, ptr @fl, align 16, !tbaa !10
  %7 = fpext double %3 to x86_fp80
  %8 = fmul x86_fp80 %6, %7
  store x86_fp80 %8, ptr @out2, align 16, !tbaa !10
  %9 = load i8, ptr @cc, align 1, !tbaa !12
  %10 = fcmp ogt double %3, 0.000000e+00
  %11 = zext i1 %10 to i8
  %12 = add i8 %9, %11
  store i8 %12, ptr @out3, align 1, !tbaa !12
  %13 = load i64, ptr @ll, align 8, !tbaa !13
  %14 = fcmp ogt double %3, 1.000000e+00
  %15 = zext i1 %14 to i64
  %16 = add nsw i64 %13, %15
  store i64 %16, ptr @out4, align 8, !tbaa !13
  %17 = tail call signext i8 @cq_measure_c(i8 noundef signext %12) #3
  %18 = sext i8 %17 to i32
  ret i32 %18
}

declare double @cq_theta_f64(double noundef, double noundef) local_unnamed_addr #1

declare signext i8 @cq_measure_c(i8 noundef signext) local_unnamed_addr #1

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nomerge nounwind }
attributes #3 = { nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
!6 = !{!7, !7, i64 0}
!7 = !{!"double", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
!10 = !{!11, !11, i64 0}
!11 = !{!"long double", !8, i64 0}
!12 = !{!8, !8, i64 0}
!13 = !{!14, !14, i64 0}
!14 = !{!"long long", !8, i64 0}
; USERCHECK float_widths
