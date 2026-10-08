; lowering_stale_speccall_reject_operand_after_gate.ll — DECLINE (bd
; test_C_libtooling-r2j3.6, population 1: the noinline helper).
;
;   __attribute__((noinline)) int f(int x, int k) { return x * 3 + k; }
;   int main(void) {
;     int q = 0; cq_theta(&q, .5);
;     int q2 = q; cq_theta(&q2, .3);
;     int k = (int)cq_measure(q2);     // a POST-gate value ...
;     int r = f(q, k);                 // ... read beside the PRE-gate record
;     return (int)cq_measure(r) + k;
;   }
;
; Before r2j3.6: exit 0, `__cq_q_f_01(h, m)` after `ry(h, .3)` — f ran on the rotated
; register. The call reads the pre-Ry record of `q` and a value that exists only after
; the gate, so it cannot be placed before the gate (57ch (B), the kept pre-rotation
; snapshot, is not built): a loud failure through the ONE stale policy and its
; diagnostic (checkStaleReads), with the call as the emission point.
; RETIREMENT TRIGGER (L7): when 57ch (B) lands this shape lowers with a snapshot and a
; warning; flip this file to an accept in that change.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s
; CHECK: in function main i32 (): cq opcode lowering: operand predates a non-diagonal gate

define i32 @f(i32 noundef %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = mul nsw i32 %0, 3
  %4 = add nsw i32 %3, %1
  ret i32 %4
}

define i32 @main() local_unnamed_addr #1 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01) #2
  %2 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef 3.000000e-01) #2
  %3 = tail call i32 @cq_measure_si32(i32 noundef %2) #3
  %4 = tail call i32 @f(i32 noundef %1, i32 noundef %3)
  %5 = tail call i32 @cq_measure_si32(i32 noundef %4) #3
  %6 = add nsw i32 %5, %3
  ret i32 %6
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr

attributes #0 = { mustprogress nofree noinline norecurse nosync nounwind willreturn memory(none) }
attributes #1 = { nounwind }
attributes #2 = { nomerge nounwind }
attributes #3 = { nounwind }
