; lowering_stale_speccall_crossblock_placed_accept.ll — ACCEPT (bd
; test_C_libtooling-57ch.1, batch 053; owner ruling bd 57ch (A)): a stale lifted
; call in a LATER BLOCK than its staling gate is placed before the gate.
;
;   int g;
;   __attribute__((noinline)) int f(int x) { return x * 3 + 1; }
;   int main(int argc, char **argv) {
;     int q = 0; cq_theta(&q, .5);
;     int q2 = q; cq_theta(&q2, .3);
;     if (argc > 1) g = argc;          // a classical diamond: no observable event
;     int r = f(q);                    // reads the PRE-Ry record, post-dominates the gate
;     return (int)cq_measure(r) + (int)cq_measure(q2) + g;
;   }
;
; The call's block post-dominates the gate's, the span between them (the arm with
; the store) is acyclic and closed, and nothing in it is an observable ordered
; event or conflicts in memory with `f` (`memory(none)`), so the call moves to just
; before `cq_theta(&q2, .3)` (StaleReadRegion.h). Before batch 053 it declined
; loudly (the read was placed only within its gate's block); before r2j3.6 it ran
; `f` on the rotated register. The CHECK-NEXT chain is the load-bearing order: the
; clone call between the two Ry, the classical diamond after them.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll 2> %t.err
; RUN: %filecheck %s < %t.ll
; RUN: %filecheck --check-prefix=WARN --allow-empty %s < %t.err
; WARN-NOT: {{error|warning}}
;
; CHECK-LABEL: define i32 @main(
; CHECK:      %[[H:.*]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: %[[R:.*]] = tail call i32 @__cq_q_f_1(i32 noundef %[[H]])
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 3.000000e-01)
; CHECK-NEXT: icmp sgt i32 %0, 1
; CHECK:      store i32 %0, ptr @g
; CHECK:      call i32 @cqrt_measure_i32(i32 %[[R]])

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@g = local_unnamed_addr global i32 0, align 4

define range(i32 -2147483647, -2147483648) i32 @f(i32 noundef %0) local_unnamed_addr #0 {
  %2 = mul nsw i32 %0, 3
  %3 = add nsw i32 %2, 1
  ret i32 %3
}

define i32 @main(i32 noundef %0, ptr nocapture noundef readnone %1) local_unnamed_addr #1 {
  %3 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01) #3
  %4 = tail call i32 @cq_theta_si32(i32 noundef %3, double noundef 3.000000e-01) #3
  %5 = icmp sgt i32 %0, 1
  br i1 %5, label %6, label %7

6:                                                ; preds = %2
  store i32 %0, ptr @g, align 4
  br label %7

7:                                                ; preds = %6, %2
  %8 = tail call i32 @f(i32 noundef %3)
  %9 = tail call i32 @cq_measure_si32(i32 noundef %8) #4
  %10 = tail call i32 @cq_measure_si32(i32 noundef %4) #4
  %11 = add nsw i32 %10, %9
  %12 = load i32, ptr @g, align 4
  %13 = add nsw i32 %11, %12
  ret i32 %13
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr

attributes #0 = { mustprogress nofree noinline norecurse nosync nounwind willreturn memory(none) }
attributes #1 = { nounwind }
attributes #3 = { nomerge nounwind }
attributes #4 = { nounwind }
