; spec_accept_gate_sub_phase_under_control.ll — ACCEPT (bd test_C_libtooling-p3kd.21).
; A gate subroutine holding only a register-free branch phase, called under the
; caller's quantum control:
;
;   __attribute__((noinline)) static void ph(void) { cq_phi(0.9); }
;   cq_theta(&a, 0.5);  if (a) ph();  cq_theta(&a, 0.5);
;
; Before: `cq controlled lowering: control flow under quantum control`. Lowered
; standalone, `ph`'s `cq_phi` is uncontrolled, a global phase, and would be
; DELETED: under the caller's `if (a)` it is the controlled phase P(0.9) on `a`,
; and the second Ry makes it observable. Compiled at its site
; (SpecializeGateInline.h), main's control chain lowers it by kickback onto the
; condition rail (`cqrt_rz_i1` on `a`'s rail); `ph` itself is gone.
; `clang -O1 -include CQ.h` output verbatim.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
; CHECK-LABEL: define {{.*}}i32 @main(
; CHECK: [[A:%[0-9a-z.]+]] = call i32 @cqrt_alloc_i1(
; CHECK: call void @cqrt_ry_i1(i32 [[A]], double 5.000000e-01)
; CHECK: call void @cqrt_rz_i1(i32 [[A]], double 9.000000e-01)
; CHECK: call void @cqrt_ry_i1(i32 [[A]], double 5.000000e-01)
; CHECK-NOT: @ph(
; CHECK-NOT: call void @cq_phi(

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@.str = private unnamed_addr constant [4 x i8] c"%d\0A\00", align 1

; Function Attrs: nounwind ssp uwtable
define noundef i32 @main() local_unnamed_addr #0 {
  %1 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01) #4
  br i1 %1, label %2, label %3

2:                                                ; preds = %0
  tail call fastcc void @ph()
  br label %3

3:                                                ; preds = %2, %0
  %4 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %1, double noundef 5.000000e-01) #4
  %5 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %4) #5
  %6 = zext i1 %5 to i32
  %7 = tail call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str, i32 noundef %6)
  ret i32 0
}

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #1

; Function Attrs: noinline nounwind ssp uwtable
define internal fastcc void @ph() unnamed_addr #2 {
  tail call void @cq_phi(double noundef 9.000000e-01) #5
  ret void
}

; Function Attrs: nofree nounwind
declare noundef i32 @printf(ptr nocapture noundef readonly, ...) local_unnamed_addr #3

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #1

declare void @cq_phi(double noundef) local_unnamed_addr #1

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
