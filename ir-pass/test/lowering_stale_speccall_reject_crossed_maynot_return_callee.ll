; lowering_stale_speccall_reject_crossed_maynot_return_callee.ll — ACCEPT since the
; OWNER RULING of 2026-10-13 on bd test_C_libtooling-57ch.4 (bd memory
; owner-ruling-57ch4-maynot-return-2026-10-13). ⚠ VERDICT INVERTED: this file was
; the DECLINE that carried the owner question (batch 053 lane L3); the name is kept
; so citations stay valid.
;
;   int g;
;   __attribute__((noinline)) void h(int i) { g = g * 3 + i; }
;   __attribute__((noinline)) void spin(int n) { for (int i = 0; i < n; i++) h(i); }
;   __attribute__((noinline)) int f(int x) { return x * 3 + 1; }
;   int main(int argc, char **argv) {
;     int q = 0; cq_theta(&q, .5);
;     int q2 = q; cq_theta(&q2, .3);
;     spin(argc);                      // CROSSED: a loop LLVM cannot bound (no willreturn)
;     int r = f(q);                    // stale q
;     return (int)cq_measure(r) + (int)cq_measure(q2) + g;
;   }
;
; `spin` carries no `willreturn` and its body is cyclic, so `callProvablyReturns`
; cannot prove it returns. The ruling: a placed read may cross a call that may not
; return when that call is `nounwind` and the module holds no `returns_twice` call;
; non-return is then `exit` or a hang, and no later measurement exists
; (`callTerminationCrossable`, StaleReadRegion.h). `spin` performs no observable
; ordered event and touches no memory `f` reads, so the clone call moves before
; `cq_theta(&q2, .3)`. Decline twin (the same module plus a `setjmp`):
; lowering_stale_speccall_reject_crossed_maynot_return_setjmp.ll. An opaque I/O call
; (`puts`) is still not crossed (lowering_stale_speccall_reject_call_between.ll).
; The CHECK-NEXT chain is the load-bearing order: the clone call between the two
; Ry, `spin` after them.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll 2> %t.err
; RUN: %filecheck %s < %t.ll
; RUN: %filecheck --check-prefix=WARN --allow-empty %s < %t.err
; WARN-NOT: {{error|warning}}
;
; CHECK-LABEL: define i32 @main(
; CHECK:      %[[H:[a-z0-9]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: %[[R:[0-9]+]] = tail call i32 @__cq_q_f_1(i32 noundef %[[H]])
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 3.000000e-01)
; CHECK-NEXT: tail call void @spin(i32 noundef %0)
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[R]])

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@g = local_unnamed_addr global i32 0, align 4

define void @h(i32 noundef %0) local_unnamed_addr #0 {
  %2 = load i32, ptr @g, align 4
  %3 = mul nsw i32 %2, 3
  %4 = add nsw i32 %3, %0
  store i32 %4, ptr @g, align 4
  ret void
}

define void @spin(i32 noundef %0) local_unnamed_addr #1 {
  %2 = icmp sgt i32 %0, 0
  br i1 %2, label %4, label %3

3:                                                ; preds = %4, %1
  ret void

4:                                                ; preds = %1, %4
  %5 = phi i32 [ %6, %4 ], [ 0, %1 ]
  tail call void @h(i32 noundef %5)
  %6 = add nuw nsw i32 %5, 1
  %7 = icmp eq i32 %6, %0
  br i1 %7, label %3, label %4
}

define range(i32 -2147483647, -2147483648) i32 @f(i32 noundef %0) local_unnamed_addr #2 {
  %2 = mul nsw i32 %0, 3
  %3 = add nsw i32 %2, 1
  ret i32 %3
}

define i32 @main(i32 noundef %0, ptr nocapture noundef readnone %1) local_unnamed_addr #3 {
  %3 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01) #5
  %4 = tail call i32 @cq_theta_si32(i32 noundef %3, double noundef 3.000000e-01) #5
  tail call void @spin(i32 noundef %0)
  %5 = tail call i32 @f(i32 noundef %3)
  %6 = tail call i32 @cq_measure_si32(i32 noundef %5) #6
  %7 = tail call i32 @cq_measure_si32(i32 noundef %4) #6
  %8 = add nsw i32 %7, %6
  %9 = load i32, ptr @g, align 4
  %10 = add nsw i32 %8, %9
  ret i32 %10
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr

attributes #0 = { mustprogress nofree noinline norecurse nosync nounwind willreturn memory(readwrite, argmem: none, inaccessiblemem: none) }
attributes #1 = { nofree noinline norecurse nosync nounwind memory(readwrite, inaccessiblemem: none) }
attributes #2 = { mustprogress nofree noinline norecurse nosync nounwind willreturn memory(none) }
attributes #3 = { nounwind }
attributes #5 = { nomerge nounwind }
attributes #6 = { nounwind }
