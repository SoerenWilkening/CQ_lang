; spec_reject_dropped_arg_classical_call_arm.ll — DECLINE with the hand-inlined twin's
; verdict and string (bd test_C_libtooling-vsfp; r2A_9bhg F-9C-1 probe `s3d`).
;
; THE DEFECT, on the oracle (`main` aee8f4f8): `if (q > 3) r = K(m);` is a 6.5
; classical-call arm — `K` hoisted, its result route-merged into a fresh `%out` rail
; under the flag of `q > 3` — and `r`'s ONLY reader was the phantom read `h(r, m)` of a
; clone that ignores it (`h(a, k) = k + 1`). ROUND 2 found that site (bd 9paa: `r` is
; classical until the `%out` reseed), so a taint-keyed fix could not have seen it.
; `%out` was left entangled with `q` across `q = cq_theta(q, .7)`: a dephased circuit,
; `opt` exit 0, NO warning, stage 2b STRICT clean.
;
; THE FIX. `dropDeadCallArguments` is STRUCTURAL and runs FIRST, before round 1 — `r`'s
; phi dies with the operand, exactly as `-O1` deletes it in the twin (`int u = m + 1;`,
; `K(m)` kept: its body is in another TU, so its call stays in the arm). What is left is
; the twin's IR, a tainted diamond whose arm holds a classical call and whose merge has
; NO phi, and it declines as the twin does — measured, the twin's `opt` prints this very
; string. RED on the oracle (exit 0 there, so `not` fails).
;
; Caller TU (clang -O1 -include CQ.h):
;   #include <stdlib.h>
;   int K(int x); int h(int a, int k);
;   int main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m, .5); int r = 5; if (q > 3) r = K(m); int u = h(r, m); q = cq_theta(q, .7); return u + cq_measure(q); }
; Library TU (plain C, no CQ.h):
;   __attribute__((const)) int K(int x) { return x * 3 + 1; }
;   int h(int a, int k) { return k + 1; }
;
; Regenerate (the tests/e2e/run_slice_multi.sh recipe, clang/llvm-link 19):
;   clang -O1 -emit-llvm -S -I<repo>/include -include CQ.h caller.c -o caller.ll
;   clang -O1 -emit-llvm -S lib.c -o lib.ll      (plain C, no CQ.h)
;   llvm-link -S caller.ll lib.ll -o <this file's body>
;
; RUN: env CQ_DEADARG_DBG=1 not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s
; CHECK: CQ_DEADARG_DBG: drop arg 0 of @h in @main (inst)
; CHECK: error{{.*}}cq controlled lowering: control flow under quantum control

; ModuleID = 'llvm-link'
source_filename = "llvm-link"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main(i32 noundef %0, ptr nocapture noundef readonly %1) local_unnamed_addr #0 {
  %3 = getelementptr inbounds i8, ptr %1, i64 8
  %4 = load ptr, ptr %3, align 8, !tbaa !6
  %5 = tail call i32 @atoi(ptr nocapture noundef %4)
  %6 = tail call i32 @cq_theta_si32(i32 noundef %5, double noundef 5.000000e-01) #4
  %7 = icmp sgt i32 %6, 3
  br i1 %7, label %8, label %10

8:                                                ; preds = %2
  %9 = tail call i32 @K(i32 noundef %5) #4
  br label %10

10:                                               ; preds = %8, %2
  %11 = phi i32 [ %9, %8 ], [ 5, %2 ]
  %12 = tail call i32 @h(i32 noundef %11, i32 noundef %5) #4
  %13 = tail call i32 @cq_theta_si32(i32 noundef %6, double noundef 0x3FE6666666666666) #4
  %14 = tail call i32 @cq_measure_si32(i32 noundef %13) #4
  %15 = add nsw i32 %14, %12
  ret i32 %15
}

; Function Attrs: mustprogress nofree nounwind willreturn memory(read)
declare i32 @atoi(ptr nocapture noundef) local_unnamed_addr #1

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable
define range(i32 -2147483647, -2147483648) i32 @K(i32 noundef %0) local_unnamed_addr #3 {
  %2 = mul nsw i32 %0, 3
  %3 = add nsw i32 %2, 1
  ret i32 %3
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable
define range(i32 -2147483647, -2147483648) i32 @h(i32 noundef %0, i32 noundef %1) local_unnamed_addr #3 {
  %3 = add nsw i32 %1, 1
  ret i32 %3
}

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nofree nounwind willreturn memory(read) "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { nounwind }

!llvm.ident = !{!0, !0}
!llvm.module.flags = !{!1, !2, !3, !4, !5}

!0 = !{!"Homebrew clang version 19.1.7"}
!1 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!2 = !{i32 1, !"wchar_size", i32 4}
!3 = !{i32 8, !"PIC Level", i32 2}
!4 = !{i32 7, !"uwtable", i32 2}
!5 = !{i32 7, !"frame-pointer", i32 2}
!6 = !{!7, !7, i64 0}
!7 = !{!"any pointer", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
