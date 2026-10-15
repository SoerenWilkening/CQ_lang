; spec_accept_gate_sub_classical_then_quantum.ll — ACCEPT (bd
; test_C_libtooling-p3kd.21). One gate subroutine whose parameter is CLASSICAL at
; one call site and QUANTUM at the other:
;
;   __attribute__((noinline)) static bool rot(bool t) { cq_theta(&t, 0.2); return t; }
;   bool a = rot(0);   // classical argument: the rail is born INSIDE the callee
;   bool b = rot(a);   // quantum argument: the caller's rail is rotated again
;
; Before: `callee contains a quantum primitive (cq_*)`. The first call allocates
; the register in the callee and returns it (a used quantum return, the bd 3jru
; crossing); compiled at its site the allocation is the caller's and nothing is
; freed dirty (R5): the one rail is allocated once, rotated twice in place (Ry is
; never adjointed: no `-2.0e-01`), and measured.
; `clang -O1 -include CQ.h` output verbatim.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
; CHECK-LABEL: define {{.*}}i32 @main(
; CHECK: [[R:%[0-9a-z.]+]] = call i32 @cqrt_alloc_i1(
; CHECK-NOT: cqrt_alloc
; CHECK: call void @cqrt_ry_i1(i32 [[R]], double 2.000000e-01)
; CHECK-NEXT: call void @cqrt_ry_i1(i32 [[R]], double 2.000000e-01)
; CHECK-NOT: double -2.000000e-01
; CHECK-NOT: cqrt_free
; CHECK: call {{.*}}@cqrt_measure_i1(i32 [[R]])
; CHECK-NOT: @rot(

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@.str = private unnamed_addr constant [4 x i8] c"%d\0A\00", align 1

; Function Attrs: nounwind ssp uwtable
define noundef i32 @main() local_unnamed_addr #0 {
  %1 = tail call fastcc zeroext i1 @rot(i1 noundef zeroext false)
  %2 = tail call fastcc zeroext i1 @rot(i1 noundef zeroext %1)
  %3 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %2) #4
  %4 = zext i1 %3 to i32
  %5 = tail call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str, i32 noundef %4)
  ret i32 0
}

; Function Attrs: noinline nounwind ssp uwtable
define internal fastcc zeroext i1 @rot(i1 noundef zeroext %0) unnamed_addr #1 {
  %2 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %0, double noundef 2.000000e-01) #5
  ret i1 %2
}

; Function Attrs: nofree nounwind
declare noundef i32 @printf(ptr nocapture noundef readonly, ...) local_unnamed_addr #2

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #3

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #3

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nofree nounwind "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
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
