; lowering_stale_speccall_reject_qrom_operand_after_gate.ll — DECLINE (bd
; test_C_libtooling-r2j3.6, population 2: a QROM read inside the lifted callee).
;
;   static const int tbl[8] = {3,1,4,1,5,9,2,6};
;   __attribute__((noinline)) int g(int x, int k) { return tbl[(x ^ k) & 7]; }
;   int main(void) {
;     int q = 0; cq_theta(&q, .5);
;     int q2 = q; cq_theta(&q2, .3);
;     int k = (int)cq_measure(q2);     // a POST-gate value ...
;     int r = g(q, k);                 // ... read beside the PRE-gate record
;     return (int)cq_measure(r) + k;
;   }
;
; The lifted call needs the pre-Ry label of `q` AND `k`, which exists only after the
; gate: it cannot be placed before the gate (57ch (B), the kept pre-rotation snapshot,
; is not built). Before r2j3.6 it lowered at exit 0 with the clone's QROM load indexed
; by the ROTATED register. It now fails loudly with the pure-op stale-record string:
; one stale policy, one diagnostic (checkStaleReads), the call as the emission point.
; RETIREMENT TRIGGER (L7): when 57ch (B) lands this shape lowers with a snapshot and a
; warning; flip this file to an accept in that change.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s
; CHECK: in function main i32 (): cq opcode lowering: operand predates a non-diagonal gate

@tbl = internal unnamed_addr constant [8 x i32] [i32 3, i32 1, i32 4, i32 1, i32 5, i32 9, i32 2, i32 6], align 16

define i32 @g(i32 noundef %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = xor i32 %1, %0
  %4 = and i32 %3, 7
  %5 = zext nneg i32 %4 to i64
  %6 = getelementptr inbounds [8 x i32], ptr @tbl, i64 0, i64 %5
  %7 = load i32, ptr %6, align 4
  ret i32 %7
}

define i32 @main() local_unnamed_addr #1 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01) #2
  %2 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef 3.000000e-01) #2
  %3 = tail call i32 @cq_measure_si32(i32 noundef %2) #3
  %4 = tail call i32 @g(i32 noundef %1, i32 noundef %3)
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
