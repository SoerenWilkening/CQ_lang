; lowering_stale_speccall_reject_crossblock_loop.ll — DECLINE (bd
; test_C_libtooling-57ch.1, batch 053): the cross-block placement refuses a span
; that holds a LOOP.
;
;   int g;
;   __attribute__((noinline)) void h(int i) { g = g * 3 + i; }
;   __attribute__((noinline)) int f(int x) { return x * 3 + 1; }
;   int main(int argc, char **argv) {
;     int q = 0; cq_theta(&q, .5);
;     int q2 = q; cq_theta(&q2, .3);
;     for (int i = 0; i < argc; i++) h(i);   // a loop between the gate and the read
;     int r = f(q);                          // stale q
;     return (int)cq_measure(r) + (int)cq_measure(q2) + g;
;   }
;
; The read post-dominates the gate, but the span between them is cyclic. A read
; moved above a loop runs gate code on every trace that reaches the gate, including
; one where the loop never ends and the source never reaches the read. The owner
; ruled bd 57ch.4 on 2026-10-13 for a CROSSED CALL (`nounwind`, no `returns_twice`
; in the module: crossable; lowering_stale_speccall_reject_crossed_maynot_return_callee.ll
; accepts that shape with the loop inside a callee). A loop in the read's own span
; also needs the exact-execution-count argument of StaleReadRegion.h re-made for a
; cyclic span, which is not built, so the placement refuses and the stale fence
; declines with its one string. Contrast
; lowering_stale_speccall_crossblock_placed_accept.ll (an acyclic span).
; RETIREMENT TRIGGER (L7, revised after the 57ch.4 ruling): a cyclic span admitted
; with an exact execution count (under the ruling's nounwind / no-returns_twice
; condition) flips this file to an accept.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s
; CHECK: in function main i32 (i32, ptr): cq opcode lowering: operand predates a non-diagonal gate

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

define range(i32 -2147483647, -2147483648) i32 @f(i32 noundef %0) local_unnamed_addr #1 {
  %2 = mul nsw i32 %0, 3
  %3 = add nsw i32 %2, 1
  ret i32 %3
}

define i32 @main(i32 noundef %0, ptr nocapture noundef readnone %1) local_unnamed_addr #2 {
  %3 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01) #4
  %4 = tail call i32 @cq_theta_si32(i32 noundef %3, double noundef 3.000000e-01) #4
  %5 = icmp sgt i32 %0, 0
  br i1 %5, label %13, label %6

6:                                                ; preds = %13, %2
  %7 = tail call i32 @f(i32 noundef %3)
  %8 = tail call i32 @cq_measure_si32(i32 noundef %7) #5
  %9 = tail call i32 @cq_measure_si32(i32 noundef %4) #5
  %10 = add nsw i32 %9, %8
  %11 = load i32, ptr @g, align 4
  %12 = add nsw i32 %10, %11
  ret i32 %12

13:                                               ; preds = %2, %13
  %14 = phi i32 [ %15, %13 ], [ 0, %2 ]
  tail call void @h(i32 noundef %14)
  %15 = add nuw nsw i32 %14, 1
  %16 = icmp eq i32 %15, %0
  br i1 %16, label %6, label %13
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr

attributes #0 = { mustprogress nofree noinline norecurse nosync nounwind willreturn memory(readwrite, argmem: none, inaccessiblemem: none) }
attributes #1 = { mustprogress nofree noinline norecurse nosync nounwind willreturn memory(none) }
attributes #2 = { nounwind }
attributes #4 = { nomerge nounwind }
attributes #5 = { nounwind }
