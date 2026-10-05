; lowering_reject_uncompute_measured_parent_moved.ll — DECLINE (bd
; test_C_libtooling-ptue; decline twin of
; lowering_uncompute_measured_parent_rotated_dead_copy.ll). The `clang -O1` IR of
;     int slice(int x){ int q = x; cq_theta(&q, .25); int t = q ^ 9;
;                       cq_theta(&q, .3); cq_theta(&t, .5); return cq_measure(q); }
;
; THE NEIGHBOUR THE MEASURED-RAIL FRONTIER MUST NOT TAKE. The retry borrows the
; measured `q` and would reverse `t` (ry(t,-.5); xor_hl_unc(t, q, 9); free(t)) at
; t's free point, after `ry(t, .5)`. But `ry(q, .3)` runs BETWEEN the xor and
; that point, so the `_unc` would read a MOVED label: with q = Σ_w b_w|w> after
; the second Ry, `xor_hl_unc` XORs w^9 onto a rail holding v^9, leaving
; |v^w> ≠ |0>, and `cqrt_free` would then be a hidden measurement (Rule 5). The
; M-B clause-(d) scan (`borrowedParentsUnmoved`) refuses `ry(q, .3)` inside the
; window, the retry is abandoned, and the module keeps today's decline verbatim.
;
; Not a physics wall: `t` is a live which-path record of `q` across `ry(q, .3)`,
; so leaving it allocated is the faithful answer (bd 01po.8's leak-on-refusal
; sketch). Until that is ruled and built this stays loud, never a guess.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @slice(i32 %x) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %x, double 2.500000e-01)
  %t0 = xor i32 %q, 9
  %q2 = call i32 @cq_theta_si32(i32 %q, double 3.000000e-01)    ; moves q INSIDE the window
  %t  = call i32 @cq_theta_si32(i32 %t0, double 5.000000e-01)   ; t DEAD after this
  %m  = call i32 @cq_measure_si32(i32 %q2)
  ret i32 %m
}

; CHECK: error{{.*}}cq uncompute: dead chain would free a measured register
