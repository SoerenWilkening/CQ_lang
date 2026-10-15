; spec_accept_gate_sub_widths.ll — ACCEPT (bd test_C_libtooling-p3kd.21, bd jx32).
; By-value gate subroutines returning their register at i64 and i8:
;
;   __attribute__((noinline)) static long r64(int c, long t) { if (c == 1) cq_theta(&t, 0.4); return t; }
;   __attribute__((noinline)) static char r8(int c, char t)  { if (c == 1) cq_theta(&t, 0.6); return t; }
;   int c = q0;  w = r64(c, w);  n = r8(c, n);   // c quantum, w and n classical 0
;
; Before: `callee contains a quantum primitive (cq_*)`. Compiled at their sites
; (SpecializeGateInline.h): each becomes a controlled Ry at its own width,
; controlled by a flag computed from `c` (an in-place controlled Ry on a fresh
; register). `clang -O1 -include CQ.h` output verbatim.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
; CHECK-LABEL: define {{.*}}i32 @main(
; CHECK-DAG: call void @cqrt_ry_i64_controlled({{.*}}, double 4.000000e-01)
; CHECK-DAG: call void @cqrt_ry_i8_controlled({{.*}}, double 6.000000e-01)
; CHECK-NOT: @r64(
; CHECK-NOT: @r8(

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@.str = private unnamed_addr constant [11 x i8] c"%ld %d %d\0A\00", align 1

; Function Attrs: nounwind ssp uwtable
define noundef i32 @main() local_unnamed_addr #0 {
  %1 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 1.000000e+00) #4
  %2 = zext i1 %1 to i32
  %3 = tail call fastcc i64 @r64(i32 noundef %2)
  %4 = tail call fastcc signext i8 @r8(i32 noundef %2)
  %5 = tail call i64 @cq_measure_sl(i64 noundef %3) #5
  %6 = tail call signext i8 @cq_measure_c(i8 noundef signext %4) #5
  %7 = sext i8 %6 to i32
  %8 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %1) #5
  %9 = zext i1 %8 to i32
  %10 = tail call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str, i64 noundef %5, i32 noundef %7, i32 noundef %9)
  ret i32 0
}

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #1

; Function Attrs: noinline nounwind ssp uwtable
define internal fastcc i64 @r64(i32 noundef %0) unnamed_addr #2 {
  %2 = icmp eq i32 %0, 1
  br i1 %2, label %3, label %5

3:                                                ; preds = %1
  %4 = tail call i64 @cq_theta_sl(i64 noundef 0, double noundef 4.000000e-01) #4
  br label %5

5:                                                ; preds = %3, %1
  %6 = phi i64 [ %4, %3 ], [ 0, %1 ]
  ret i64 %6
}

; Function Attrs: noinline nounwind ssp uwtable
define internal fastcc signext i8 @r8(i32 noundef %0) unnamed_addr #2 {
  %2 = icmp eq i32 %0, 1
  br i1 %2, label %3, label %5

3:                                                ; preds = %1
  %4 = tail call signext i8 @cq_theta_c(i8 noundef signext 0, double noundef 6.000000e-01) #4
  br label %5

5:                                                ; preds = %3, %1
  %6 = phi i8 [ %4, %3 ], [ 0, %1 ]
  ret i8 %6
}

; Function Attrs: nofree nounwind
declare noundef i32 @printf(ptr nocapture noundef readonly, ...) local_unnamed_addr #3

declare i64 @cq_measure_sl(i64 noundef) local_unnamed_addr #1

declare signext i8 @cq_measure_c(i8 noundef signext) local_unnamed_addr #1

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #1

declare i64 @cq_theta_sl(i64 noundef, double noundef) local_unnamed_addr #1

declare signext i8 @cq_theta_c(i8 noundef signext, double noundef) local_unnamed_addr #1

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nofree nounwind "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
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
