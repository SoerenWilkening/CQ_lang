; lowering_stale_speccall_reject_sunk_read.ll — DECLINE (bd test_C_libtooling-r2j3.6,
; review round 1 F3: recorded, not built).
;
;   __attribute__((noinline)) int f(int x) { return x * 3 + 1; }
;   int main(int argc, char **argv) {
;     int q = 0; cq_theta(&q, .5);
;     int r = f(q);                    // the user reads FIRST, in the fresh order
;     int q2 = q; cq_theta(&q2, .3);
;     int s = 0;
;     if (argc > 1) s = (int)cq_measure(r);
;     return s + (int)cq_measure(q2);
;   }
;
; -O1 (InstCombine) SINKS the `memory(none) willreturn` call into the `if` arm, after
; the gate, so the module below is BYTE-IDENTICAL to the one for the program that
; writes `f(q)` inside the arm after the gate (review probe p3b_inarm.c). The source
; ordering is erased, and with it whether the read was meant on both paths or on
; one: placed before the gate on BOTH paths it dephases `q` on the path that never
; reads it; placed only on the arm's path it needs a copy of a gate-preceding label
; inside a branch. Main lowered it at exit 0 with f on the rotated register; it now
; fails loudly (the read is in a later block than its gate, and it does not
; post-dominate the gate). A read-first program can therefore still be refused.
; RETIREMENT TRIGGER (L7): the owner ruling on that question (follow-up F7 of
; r2j3.6), then the lowering it rules for.
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
  %4 = tail call i32 @cq_theta_si32(i32 noundef %3, double noundef 3.000000e-01) #2
  %5 = icmp sgt i32 %0, 1
  br i1 %5, label %6, label %9

6:                                                ; preds = %2
  %7 = tail call i32 @f(i32 noundef %3)
  %8 = tail call i32 @cq_measure_si32(i32 noundef %7) #3
  br label %9

9:                                                ; preds = %6, %2
  %10 = phi i32 [ %8, %6 ], [ 0, %2 ]
  %11 = tail call i32 @cq_measure_si32(i32 noundef %4) #3
  %12 = add nsw i32 %11, %10
  ret i32 %12
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr

attributes #0 = { mustprogress nofree noinline norecurse nosync nounwind willreturn memory(none) }
attributes #1 = { nounwind }
attributes #2 = { nomerge nounwind }
attributes #3 = { nounwind }
