; lowering_stale_speccall_reject_inloop_invariant.ll — DECLINE (bd
; test_C_libtooling-r2j3.6): a stale lifted call that the placement MOVES and the
; stale verdict, taken at the new slot, still finds stale.
;
;   __attribute__((noinline)) int f(int x) { return x * 3 + 1; }
;   int main(int argc, char **argv) {
;     int q = 0; cq_theta(&q, .5);
;     int s = 0;
;     for (int i = 0; i < argc; ++i) {
;       int q2 = q; cq_theta(&q2, .3);   // rotates q's register EVERY trip
;       s += (int)cq_measure(f(q));      // q is loop-invariant: the pre-loop record
;     }
;     return s;
;   }
;
; In the body, `%10 = cq_theta(%3)` precedes `%11 = f(%3)`, so the placement candidate
; is the slot before `%10`. But `%3` is defined before the loop: at trip 2 the gate's
; previous instance has already rotated the register, and placing the call before the
; gate does not change that (the back edge reaches the call without re-executing
; `%3`'s definition). The stale verdict is taken where the call now stands, finds
; the gate still staling it, and the fence declines with its own string. (The
; `cq_theta` reader of `%3` is stale across the back edge too; the late 3d8q
; backstop would name it with `rotation/measure operand predates ...`, which this
; CHECK does not match: the lifted-call fence speaks first, at the early slot.)
; Pins: a placement treated as proof of freshness (no verdict at the new slot)
; would accept the call here and the module would die at the 3d8q backstop with the
; other string. (Mutation note, bd r2j3.6: an "undo the move when still stale" step
; was an EQUIVALENT mutant under `opt` — the verdict declines either way — and was
; removed.)
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s
; CHECK: in function main i32 (i32, ptr): cq opcode lowering: operand predates a non-diagonal gate

define i32 @f(i32 noundef %0) local_unnamed_addr #0 {
  %2 = mul nsw i32 %0, 3
  %3 = add nsw i32 %2, 1
  ret i32 %3
}

define i32 @main(i32 noundef %0, ptr nocapture noundef readnone %1) local_unnamed_addr #1 {
  %3 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01) #2
  %4 = icmp sgt i32 %0, 0
  br i1 %4, label %7, label %5

5:                                                ; preds = %7, %2
  %6 = phi i32 [ 0, %2 ], [ %13, %7 ]
  ret i32 %6

7:                                                ; preds = %2, %7
  %8 = phi i32 [ %14, %7 ], [ 0, %2 ]
  %9 = phi i32 [ %13, %7 ], [ 0, %2 ]
  %10 = tail call i32 @cq_theta_si32(i32 noundef %3, double noundef 3.000000e-01) #2
  %11 = tail call i32 @f(i32 noundef %3)
  %12 = tail call i32 @cq_measure_si32(i32 noundef %11) #3
  %13 = add nsw i32 %12, %9
  %14 = add nuw nsw i32 %8, 1
  %15 = icmp eq i32 %14, %0
  br i1 %15, label %5, label %7
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr

attributes #0 = { mustprogress nofree noinline norecurse nosync nounwind willreturn memory(none) }
attributes #1 = { nounwind }
attributes #2 = { nomerge nounwind }
attributes #3 = { nounwind }
