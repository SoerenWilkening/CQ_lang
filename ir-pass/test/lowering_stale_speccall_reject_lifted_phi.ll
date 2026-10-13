; lowering_stale_speccall_reject_lifted_phi.ll — DECLINE (bd test_C_libtooling-r2j3.6,
; population 3: the one-register merge-phi lift; batch-043 note, repro `call_stale.c`).
;
;   __attribute__((noinline)) int g(int x) { return x * 3 + 1; }
;   int main(int argc, char **argv) {
;     int c = argc > 1;
;     int q = 7; cq_theta(&q, .5);
;     int r = q;
;     if (c) { cq_theta(&q, .125); r = q; cq_theta(&q, .25); }
;     int t = g(r);                    // r is the PRE-.25 record on the c path
;     return (int)cq_measure(t) + (int)cq_measure(q);
;   }
;
; `%9 = phi [%6, %5], [%4, %2]` (r) and `%10` (q) are both one-register merge phis
; over the wire base `%4`; `declineClassicalMuxes` lifts them onto `%4`, so after the
; lift the lifted call reads the base. Before r2j3.6: exit 0, two live-record warnings,
; `__cq_q_g_1(h)` after `ry(h, .25)` — g ran on a register the c path had rotated past
; r. The lifted call's argument slot is a recorded use of r's lift
; (`TaintSet::LiftedMergePhi::Uses`, bd r2j3.11), so the post-lift re-sweep exempts the
; `.125` gate (on r's record) and nothing else: the `.25` gate stales it. Not placed:
; the gate sits in the arm, the call in the merge block, and the post-lift re-sweep
; never places. Loud, with the one stale-record string.
; RETIREMENT TRIGGER (L7): cross-block placement (57ch (A) beyond one block) or 57ch (B).
; ⚠ BATCH 053: cross-block placement (bd 57ch.1) is built and does NOT retire this
; file: no single program point has `r`'s record current on both paths (after
; `.125` on the arm path, `%4` on the other). OWNER RULING 2026-10-13 (bd 57ch.2;
; bd memory owner-ruling-stale-reads-batch053-2026-10-13 item 1): a CLASSICAL merge
; duplicates the read into each incoming path (here: `g` between the two arm Ry, and
; `g(%4)` on the split edge `%2 -> %8`), a tainted merge places it between the
; controlled gates. NOT BUILT in batch 053 (lane L3): the duplicated reads produce
; two clone results merged by a classical-condition phi over two DISTINCT registers,
; which `declineClassicalMuxes` refuses (bd dm7f.15, lane L5's file), and whose
; path-dependent uncompute no stage owns; and the read is only exposed after the
; one-register lift, by the post-lift re-sweep, which never places. RETIREMENT
; TRIGGER (revised): dm7f.15's handle-variable phi plus a placement at the post-lift
; slot (or 57ch (B)).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s
; CHECK: in function main i32 (i32, ptr): cq opcode lowering: operand predates a non-diagonal gate

define i32 @g(i32 noundef %0) local_unnamed_addr #0 {
  %2 = mul nsw i32 %0, 3
  %3 = add nsw i32 %2, 1
  ret i32 %3
}

define i32 @main(i32 noundef %0, ptr nocapture noundef readnone %1) local_unnamed_addr #1 {
  %3 = icmp sgt i32 %0, 1
  %4 = tail call i32 @cq_theta_si32(i32 noundef 7, double noundef 5.000000e-01) #2
  br i1 %3, label %5, label %8

5:                                                ; preds = %2
  %6 = tail call i32 @cq_theta_si32(i32 noundef %4, double noundef 1.250000e-01) #2
  %7 = tail call i32 @cq_theta_si32(i32 noundef %6, double noundef 2.500000e-01) #2
  br label %8

8:                                                ; preds = %5, %2
  %9 = phi i32 [ %6, %5 ], [ %4, %2 ]
  %10 = phi i32 [ %7, %5 ], [ %4, %2 ]
  %11 = tail call i32 @g(i32 noundef %9)
  %12 = tail call i32 @cq_measure_si32(i32 noundef %11) #3
  %13 = tail call i32 @cq_measure_si32(i32 noundef %10) #3
  %14 = add nsw i32 %13, %12
  ret i32 %14
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr

attributes #0 = { mustprogress nofree noinline norecurse nosync nounwind willreturn memory(none) }
attributes #1 = { nounwind }
attributes #2 = { nomerge nounwind }
attributes #3 = { nounwind }
