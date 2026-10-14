; control_angle_select_reject_rail_cond_target.ll — DECLINE (bd test_C_libtooling-dm7f.54,
; adversarial probe; dm7f.8 territory): the Ry ANGLE SELECT rotates the bare
; `_Bool` register its own condition reads.
;
;     bool a = 0; cq_theta(&a, 1.0);
;     cq_theta(&a, a ? 0.7 : 0.3);
;
; The copy flag would read `a`, then both controlled Ry would relabel `a`, so
; the un-copy `cnot(a, bf)` would not return `bf` to |0> and its free would be
; a hidden measurement (Rules 5/6). Lowering it needs the dm7f.4 KEPT-flag
; treatment (bd dm7f.8). Until then it is S8's loud decline, on the copy path
; exactly as on the compare path (`..._reject_cond_register.ll`).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq controlled lowering: rotation arm on a condition wire under quantum control

declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)

define i32 @example() {
entry:
  %a0 = call i1 @cq_theta_i1(i1 false, double 1.000000e+00) #0
  %ang = select i1 %a0, double 0x3FE6666666666666, double 3.000000e-01
  %a = call i1 @cq_theta_i1(i1 %a0, double %ang) #0
  %ma = call i1 @cq_measure_i1(i1 %a)
  %za = zext i1 %ma to i32
  ret i32 %za
}

attributes #0 = { nomerge nounwind }
