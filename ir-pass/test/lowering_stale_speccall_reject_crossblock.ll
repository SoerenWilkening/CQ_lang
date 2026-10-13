; lowering_stale_speccall_reject_crossblock.ll — DECLINE (bd test_C_libtooling-r2j3.6):
; a stale lifted call in a LATER BLOCK than its staling gate.
;
;   #include <stdio.h>
;   __attribute__((noinline)) int f(int x) { return x * 3 + 1; }
;   int main(int argc, char **argv) {
;     int q = 0; cq_theta(&q, .5);
;     int q2 = q; cq_theta(&q2, .3);
;     if (argc > 1) puts("x");         // a classical diamond splits the block
;     int r = f(q);                    // reads the PRE-Ry record
;     return (int)cq_measure(r) + (int)cq_measure(q2);
;   }
;
; Before r2j3.6: exit 0, f ran on the rotated register. The read is movable in
; principle (the gate dominates the call, the call post-dominates the gate, and `f`
; is `memory(none)`), but this increment places a stale read only within the gate's
; own block, so it fails loudly with the one stale-record string. That is an
; OVER-DECLINE (NORTHSTAR goal 1; 57ch (A) says it must compile), kept loud until the
; cross-block placement is built.
; ⚠ BATCH 053 (bd 57ch.1) BUILT THAT CROSS-BLOCK PLACEMENT, AND THIS FILE STILL
; DECLINES, for a reason the original trigger did not name: the span the call would
; cross holds `puts`, an opaque declaration that may touch memory (it may perform an
; observable event, owner ruling 2026-10-08). The 57ch.4 ruling of 2026-10-13 makes
; its possible non-return crossable (`nounwind`, no `returns_twice`), but not its
; possible ordered events: `callCrossable` still refuses it. The cross-block accept
; with a store in the arm instead of `puts` is
; lowering_stale_speccall_crossblock_placed_accept.ll.
; RETIREMENT TRIGGER (L7, revised batch 053): a crossing rule for an opaque I/O call
; (its body's ordered events), or 57ch (B). The sunk-read shape is
; lowering_stale_speccall_reject_sunk_read.ll (bd aabo).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s
; CHECK: in function main i32 (i32, ptr): cq opcode lowering: operand predates a non-diagonal gate

@.str = private unnamed_addr constant [2 x i8] c"x\00", align 1

define i32 @f(i32 noundef %0) local_unnamed_addr #0 {
  %2 = mul nsw i32 %0, 3
  %3 = add nsw i32 %2, 1
  ret i32 %3
}

define i32 @main(i32 noundef %0, ptr nocapture noundef readnone %1) local_unnamed_addr #1 {
  %3 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01) #2
  %4 = tail call i32 @cq_theta_si32(i32 noundef %3, double noundef 3.000000e-01) #2
  %5 = icmp sgt i32 %0, 1
  br i1 %5, label %6, label %8

6:                                                ; preds = %2
  %7 = tail call i32 @puts(ptr noundef nonnull dereferenceable(1) @.str)
  br label %8

8:                                                ; preds = %6, %2
  %9 = tail call i32 @f(i32 noundef %3)
  %10 = tail call i32 @cq_measure_si32(i32 noundef %9) #3
  %11 = tail call i32 @cq_measure_si32(i32 noundef %4) #3
  %12 = add nsw i32 %11, %10
  ret i32 %12
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr

declare noundef i32 @puts(ptr nocapture noundef readonly) local_unnamed_addr #4

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr

attributes #0 = { mustprogress nofree noinline norecurse nosync nounwind willreturn memory(none) }
attributes #1 = { nounwind }
attributes #2 = { nomerge nounwind }
attributes #3 = { nounwind }
attributes #4 = { nofree nounwind }
