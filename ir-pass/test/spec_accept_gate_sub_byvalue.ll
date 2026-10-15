; spec_accept_gate_sub_byvalue.ll — ACCEPT (bd test_C_libtooling-p3kd.21). A
; non-inlined GATE SUBROUTINE taking its register BY VALUE and returning it as a
; `_Bool` (i1, a non-i32 quantum return), called on two registers (the first two
; calls of CQ_FINDINGS F6's ~/Desktop/alg_test/dicke/t10.c):
;
;   __attribute__((noinline)) static bool cry_eq(int c, int v, bool t, double th) {
;       if (c == v) cq_theta(&t, th);
;       return t;
;   }
;   c += q0;  q1 = cry_eq(c, 1, q1, 0.4);  q2 = cry_eq(c, 1, q2, 0.1);
;
; Before: `callee contains a quantum primitive (cq_*); only classical functions are
; lifted`. Now the gate subroutine is compiled at each call site
; (SpecializeGateInline.h): each call becomes the caller's own `if (c == 1)` over
; the caller's register, which main lowers as an in-place controlled Ry on `q0`'s
; rail, the shape `clang -O1` produces when `noinline` is absent. No
; Bennett-lifted clone exists (a rotation is never reverse-played, no `-0.4`), and
; the local helper is gone. (The full t10, whose later calls test `c == 1` and
; `c == 2` for `c = q0 + q1`, reaches the `xor`/`and` condition fence:
; spec_reject_gate_sub_xor_condition.ll.) `clang -O1 -include CQ.h` output verbatim.
;
; RETIREMENT TRIGGER: if gate subroutines are ever lifted as clones instead, the
; `CLONE-NOT` lines are the ones to revisit, together with the stale-reader and
; caller-control arguments in SpecializeGateInline.h.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
; RUN: %filecheck %s --check-prefix=CLONE < %t.ll
; CHECK-LABEL: define {{.*}}i32 @main(
; CHECK: [[Q0:%[0-9a-z.]+]] = call i32 @cqrt_alloc_i1(
; CHECK: [[Q1:%[0-9a-z.]+]] = call i32 @cqrt_alloc_i1(
; CHECK: call void @cqrt_ry_i1_controlled(i32 [[Q0]], i32 [[Q1]], double 4.000000e-01)
; CHECK: [[Q2:%[0-9a-z.]+]] = call i32 @cqrt_alloc_i1(
; CHECK: call void @cqrt_ry_i1_controlled(i32 [[Q0]], i32 [[Q2]], double 1.000000e-01)
; CHECK-NOT: double -
; CHECK: ret i32 0
; CLONE-NOT: @cry_eq
; CLONE-NOT: @__cq_q_

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@.str = private unnamed_addr constant [10 x i8] c"%d %d %d\0A\00", align 1

; Function Attrs: nounwind ssp uwtable
define noundef i32 @main() local_unnamed_addr #0 {
  %1 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 1.000000e+00) #4
  %2 = zext i1 %1 to i32
  %3 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 3.000000e-01) #4
  %4 = tail call fastcc zeroext i1 @cry_eq(i32 noundef %2, i1 noundef zeroext %3, double noundef 4.000000e-01)
  %5 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 1.000000e-01) #4
  %6 = tail call fastcc zeroext i1 @cry_eq(i32 noundef %2, i1 noundef zeroext %5, double noundef 1.000000e-01)
  %7 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %1) #5
  %8 = zext i1 %7 to i32
  %9 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %4) #5
  %10 = zext i1 %9 to i32
  %11 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %6) #5
  %12 = zext i1 %11 to i32
  %13 = tail call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str, i32 noundef %8, i32 noundef %10, i32 noundef %12)
  ret i32 0
}

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #1

; Function Attrs: noinline nounwind ssp uwtable
define internal fastcc zeroext i1 @cry_eq(i32 noundef %0, i1 noundef zeroext %1, double noundef %2) unnamed_addr #2 {
  %4 = icmp eq i32 %0, 1
  br i1 %4, label %5, label %7

5:                                                ; preds = %3
  %6 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %1, double noundef %2) #4
  br label %7

7:                                                ; preds = %5, %3
  %8 = phi i1 [ %6, %5 ], [ %1, %3 ]
  ret i1 %8
}

; Function Attrs: nofree nounwind
declare noundef i32 @printf(ptr nocapture noundef readonly, ...) local_unnamed_addr #3

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #1

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
