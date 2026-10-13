; lowering_stale_speccall_nested_dead_slot_accept.ll — ACCEPT (bd
; test_C_libtooling-57ch.5, batch 053: the PROBE the issue asked for, pinned).
;
; Caller TU (clang -O1 -include CQ.h):
;   #include <stdio.h>
;   int g(int a, int k);               // library TU: ignores `a`
;   __attribute__((noinline)) int f(int x, int y, int n) {
;     int p = x;
;     if (y > 3) p = 100 / n;          // y feeds only a branch whose arm feeds g's dead slot
;     return g(p, x);
;   }
;   int main(int argc, char **argv) {
;     int q = 0; cq_theta(&q, .5);
;     int q2 = q; cq_theta(&q2, .3);
;     puts("x");                       // makes the stale read unplaceable
;     int r = f(argc, q, argc);        // stale q, in f's slot y
;     return (int)cq_measure(r) + (int)cq_measure(q2);
;   }
; Library TU (plain C, no CQ.h):
;   int g(int a, int k) { return k * 3 + 1; }
; Regenerate (the tests/e2e/run_slice_multi.sh recipe, clang/llvm-link 19):
;   clang -O1 -emit-llvm -S -I<repo>/include -include CQ.h caller.c -o caller.ll
;   clang -O1 -emit-llvm -S lib.c -o lib.ll
;   llvm-link -S caller.ll lib.ll -o <this file's body>
;
; 57ch.5 asked whether an argument slot that is dead only after the clone's own
; processing (here: `y` is live in `f` through a branch, and dead once `g`'s
; ignored slot empties that branch's arm) still counts as a stale lifted-call read.
; MEASURED: no. The detection-time dead-argument drop reaches it through its own
; fixpoint (`drop arg 0 of @g in @f`, then `drop arg 1 of @f in @main`), BEFORE the
; early stale sweep, so the stale `q` never reaches the call and `f` is classical.
; This file pins that order; the `puts` keeps the read unplaceable, so a regression
; that let the sweep see the slot would decline loudly here.
;
; RUN: env CQ_DEADARG_DBG=1 %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll 2> %t.err
; RUN: %filecheck %s < %t.ll
; RUN: %filecheck --check-prefix=DROP %s < %t.err
; DROP: CQ_DEADARG_DBG: drop arg 0 of @g in @f (inst)
; DROP: CQ_DEADARG_DBG: drop arg 1 of @f in @main (inst)
; DROP-NOT: {{error|warning}}
;
; CHECK-LABEL: define i32 @main(
; CHECK:      call void @cqrt_ry_i32(i32 %[[H:.*]], double 3.000000e-01)
; CHECK-NEXT: tail call i32 @puts(
; CHECK-NEXT: tail call i32 @f(i32 noundef %0, i32 noundef 0, i32 noundef 0)
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[H]])

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@.str = private unnamed_addr constant [2 x i8] c"x\00", align 1

define i32 @f(i32 noundef %0, i32 noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = icmp sgt i32 %1, 3
  br i1 %4, label %5, label %7

5:                                                ; preds = %3
  %6 = sdiv i32 100, %2
  br label %7

7:                                                ; preds = %5, %3
  %8 = phi i32 [ %6, %5 ], [ %0, %3 ]
  %9 = tail call i32 @g(i32 noundef %8, i32 noundef %0) #5
  ret i32 %9
}

define i32 @main(i32 noundef %0, ptr nocapture noundef readnone %1) local_unnamed_addr #1 {
  %3 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01) #6
  %4 = tail call i32 @cq_theta_si32(i32 noundef %3, double noundef 3.000000e-01) #6
  %5 = tail call i32 @puts(ptr noundef nonnull dereferenceable(1) @.str)
  %6 = tail call i32 @f(i32 noundef %0, i32 noundef %3, i32 noundef %0)
  %7 = tail call i32 @cq_measure_si32(i32 noundef %6) #5
  %8 = tail call i32 @cq_measure_si32(i32 noundef %4) #5
  %9 = add nsw i32 %8, %7
  ret i32 %9
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr

declare noundef i32 @puts(ptr nocapture noundef readonly) local_unnamed_addr #3

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr

define range(i32 -2147483647, -2147483648) i32 @g(i32 noundef %0, i32 noundef %1) local_unnamed_addr #4 {
  %3 = mul nsw i32 %1, 3
  %4 = add nsw i32 %3, 1
  ret i32 %4
}

attributes #0 = { noinline nounwind }
attributes #1 = { nounwind }
attributes #3 = { nofree nounwind }
attributes #4 = { mustprogress nofree norecurse nosync nounwind willreturn memory(none) }
attributes #5 = { nounwind }
attributes #6 = { nomerge nounwind }
