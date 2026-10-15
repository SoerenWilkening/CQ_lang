; spec_reject_gate_sub_weak.ll — DECLINE (bd test_C_libtooling-p3kd.21, R11 r1 item
; 6; reviewer probe revS1/p6_weak_g.c). A WEAK gate subroutine:
;
;   __attribute__((noinline, weak)) long rot(long x) { cq_theta(&x, 0.3); return x; }
;   long r = rot(1); return (int)cq_measure(r);
;
; An interposable body may be replaced at link time, so the call is NOT compiled
; at its site (inlining would bake in a body the program may not run): it keeps
; its loud owner, here the non-i32 escape guard on `rot`'s return (it has a use,
; so it is no export). Mirrors the diagnostic character-for-character.
; `clang -O1 -include CQ.h` output verbatim.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error: {{.*}}in function rot i64 (i64): cq taint escape: tainted value returned at non-i32 width

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: noinline nounwind ssp uwtable
define weak i64 @rot(i64 noundef %0) local_unnamed_addr #0 {
  %2 = tail call i64 @cq_theta_sl(i64 noundef %0, double noundef 3.000000e-01) #3
  ret i64 %2
}

declare i64 @cq_theta_sl(i64 noundef, double noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #2 {
  %1 = tail call i64 @rot(i64 noundef 1)
  %2 = tail call i64 @cq_measure_sl(i64 noundef %1) #4
  %3 = trunc i64 %2 to i32
  ret i32 %3
}

declare i64 @cq_measure_sl(i64 noundef) local_unnamed_addr #1

attributes #0 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
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
