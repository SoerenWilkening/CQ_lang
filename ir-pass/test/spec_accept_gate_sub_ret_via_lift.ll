; spec_accept_gate_sub_ret_via_lift.ll — ACCEPT (bd test_C_libtooling-p3kd.21, R11 r1
; item 7; reviewer probe revS1/p4_ret_via_lift.c). A gate subroutine returning its
; register THROUGH a lifted classical call:
;
;   __attribute__((noinline)) static int h(int x) { return x * 3 + 1; }
;   __attribute__((noinline)) static int g(int x) { cq_theta(&x, 0.3); return h(x); }
;   int r = g(1); return cq_measure(r);
;
; Trigger (c)'s slice crosses `h(x)`'s result because its tainted operand slices
; back to `g`'s own `cq_theta`; it does so only in the phase after the
; dead-argument drop's slot B, where a call result's taint is no longer the
; prediction slot B can still null (slice_spec_dropped_arg_musttail_return lowers
; byte-identically). Before the fix: the 3jru refusal. `g` is compiled at its site
; and `h` is lifted as an ordinary clone on the caller's register.
; `clang -O1 -include CQ.h` output verbatim.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
; CHECK-LABEL: define i32 @main(
; CHECK-NEXT: [[X:%[0-9a-z.]+]] = call i32 @cqrt_alloc_i32(i32 1)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 [[X]], double 3.000000e-01)
; CHECK-NEXT: [[R:%[0-9a-z.]+]] = tail call fastcc {{.*}}i32 @__cq_q_h_1(i32 noundef [[X]])
; CHECK-NEXT: [[M:%[0-9a-z.]+]] = call i32 @cqrt_measure_i32(i32 [[R]])
; CHECK-NEXT: ret i32 [[M]]
; CHECK-NOT: @g(

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 {
  %1 = tail call fastcc i32 @g()
  %2 = tail call i32 @cq_measure_si32(i32 noundef %1) #4
  ret i32 %2
}

; Function Attrs: noinline nounwind ssp uwtable
define internal fastcc range(i32 -2147483647, -2147483648) i32 @g() unnamed_addr #1 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 1, double noundef 3.000000e-01) #5
  %2 = tail call fastcc i32 @h(i32 noundef %1)
  ret i32 %2
}

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable
define internal fastcc range(i32 -2147483647, -2147483648) i32 @h(i32 noundef %0) unnamed_addr #3 {
  %2 = mul nsw i32 %0, 3
  %3 = add nsw i32 %2, 1
  ret i32 %3
}

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { nounwind }
attributes #5 = { nomerge nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
