; lowering_reject_lift_stale_reader_measure.ll — DECLINE (bd test_C_libtooling-r2j3.11,
; P1 silent miscompile on main 7b4e6359). `clang -O1` of
;
;     int q = 7; cq_theta(&q, .5);
;     int r = q;
;     if (c) { cq_theta(&q, .125); r = q; cq_theta(&q, .25); }
;     return cq_measure(r) + cq_measure(q);
;
; `c` is classical, so both merge phis are one-register lifts onto `%3`: `%10`
; (`r`) over the arm's FIRST gate, `%9` (`q`) over both. `r` names the record
; between the two arm gates, so on the arm path `cq_measure(r)` reads a name the
; wire has moved past (`Ry(.25)` ran after it), the 3d8q stale-reader rule. Main
; emitted `ry .5; ry .125; ry .25; measure h; measure h` at rc 0 with an empty
; stderr, the stream of the well-formed `cq_measure(q) + cq_measure(q)`. The
; early reader fence could not see it (its seed was the phi), and the post-lift
; re-sweep asked pure ops only. Since bd r2j3.11 the lift records its uses and
; the re-sweep asks a lifted reader too, exempt only from the gates on the
; record IT read: `r`'s record holds `%6`, so `%7` is evidence.
; Twin: lowering_classical_mux_phi_onereg_theta_chain.ll measures the phi over
; BOTH gates and keeps accepting.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq opcode lowering: rotation/measure operand predates a non-diagonal gate

define i32 @f(i32 noundef %0, i32 %1) {
  %3 = tail call i32 @cq_theta_si32(i32 noundef 7, double noundef 5.000000e-01)
  %4 = icmp eq i32 %0, 0
  br i1 %4, label %8, label %5

5:                                                ; preds = %2
  %6 = tail call i32 @cq_theta_si32(i32 noundef %3, double noundef 1.250000e-01)
  %7 = tail call i32 @cq_theta_si32(i32 noundef %6, double noundef 2.500000e-01)
  br label %8

8:                                                ; preds = %5, %2
  %9 = phi i32 [ %7, %5 ], [ %3, %2 ]
  %10 = phi i32 [ %6, %5 ], [ %3, %2 ]
  %11 = tail call i32 @cq_measure_si32(i32 noundef %10)
  %12 = tail call i32 @cq_measure_si32(i32 noundef %9)
  %13 = add nsw i32 %12, %11
  ret i32 %13
}

declare i32 @cq_theta_si32(i32 noundef, double noundef)

declare i32 @cq_measure_si32(i32 noundef)
