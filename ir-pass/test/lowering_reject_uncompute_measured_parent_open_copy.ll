; lowering_reject_uncompute_measured_parent_open_copy.ll — DECLINE (bd
; test_C_libtooling-01po.8; decline twin of
; lowering_uncompute_measured_parent_open_root.ll's @f3). The `clang -O1` IR of
;     int open_copy(int x){ int q = x; cq_theta(&q, .25); int a = q * 3;
;                           int q2 = a & 6; int t = q2 ^ 9; cq_theta(&t, .5);
;                           int u = a ^ 5; cq_theta(&u, .5); cq_theta(&q, .3);
;                           return cq_measure(q2) + cq_measure(q); }
;
; THE OPEN RAIL THE GROWN FRONTIER MUST NOT BORROW. The frontier retry borrows
; the measured `q2` and `q`; u's reduced DAG then owns `a = 3q`, whose consumer
; `a & 6` (q2's producer) lies outside it. Unlike @f3's open ROOT, `a` is a
; COPY: after its last use (`a ^ 5`) its `_unc` could run against the unmoved
; `q`, so the program does not keep it. Borrowing it would leave all of 3q
; allocated across `cq_theta(&q, .3)`, where the program keeps only the two bits
; in `q2` — a different distribution for `measure(q)`. (The reversal's own `_unc`
; reading `a` would also keep the M-B interior partition off it.) The fixpoint
; widens on an open root only, refuses here, and the module keeps its decline
; verbatim. Discharging `a` after the reversal is the faithful schedule; it is
; not built.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @open_copy(i32 %0) {
  %2 = tail call i32 @cq_theta_si32(i32 %0, double 2.500000e-01)
  %3 = mul nsw i32 %2, 3
  %4 = and i32 %3, 6
  %5 = or disjoint i32 %4, 9
  %6 = tail call i32 @cq_theta_si32(i32 %5, double 5.000000e-01)
  %7 = xor i32 %3, 5
  %8 = tail call i32 @cq_theta_si32(i32 %7, double 5.000000e-01)
  %9 = tail call i32 @cq_theta_si32(i32 %2, double 3.000000e-01)
  %10 = tail call i32 @cq_measure_si32(i32 %4)
  %11 = tail call i32 @cq_measure_si32(i32 %9)
  %12 = add nsw i32 %11, %10
  ret i32 %12
}

; CHECK: error{{.*}}cq uncompute: dead chain would free a measured register
