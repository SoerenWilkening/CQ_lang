; lowering_reject_uncompute_measured_parent_moved_dead_record.ll — DECLINE (bd
; test_C_libtooling-01po.8; decline twin of
; lowering_uncompute_measured_parent_open_root.ll's @moved_live_prefix). The
; `clang -O1` IR of
;     int f(int x){ int q = x; cq_theta(&q, .25); int a = q * 3; int b = a & 6;
;                   cq_theta(&q, .3); cq_theta(&b, .5); return cq_measure(q); }
;
; THE LEAK THE GROWN FRONTIER MUST NOT TAKE. The borrowed measured `q` is
; rotated inside the window [mul, b's reversal point], so `a = 3q`'s `_unc` can no
; longer run there. Borrowing `a` (leaving it allocated) and reversing `b` against
; it would be Rule-5 clean, but `a`'s last use (`a & 6`) is BEFORE the rotation:
; the program keeps only `b` (two bits of 3q) across `cq_theta(&q, .3)`, and a
; leaked `a` would keep ALL of q there — a different distribution for
; `measure(q)`, behind a live-record warning that would blame the user.
; `recordLiveAcrossMove` refuses (no use of `a` after a move of q), and the module
; keeps its decline verbatim. (A schedule that discharges `a` before the
; rotation and keeps `b` is the faithful one; it is not built.)
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @moved_dead_record(i32 %0) {
  %2 = tail call i32 @cq_theta_si32(i32 %0, double 2.500000e-01)
  %3 = mul nsw i32 %2, 3
  %4 = and i32 %3, 6
  %5 = tail call i32 @cq_theta_si32(i32 %2, double 3.000000e-01)
  %6 = tail call i32 @cq_theta_si32(i32 %4, double 5.000000e-01)
  %7 = tail call i32 @cq_measure_si32(i32 %5)
  ret i32 %7
}

; CHECK: error{{.*}}cq uncompute: dead chain would free a measured register
