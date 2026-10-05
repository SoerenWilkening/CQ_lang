; lowering_reject_uncompute_measured_parent_copy_measured_before_move.ll —
; DECLINE (bd test_C_libtooling-01po.8 review round 2; neighbour of
; lowering_reject_uncompute_measured_parent_collapsed_before_move.ll). The
; `clang -O1` IR of
;     int slice(int x, int y){ _Bool q = x; cq_theta(&q, .25);
;       _Bool z = y; cq_theta(&z, .3); _Bool r = q ^ z; cq_theta(&r, .5);
;       _Bool c = !q; int m = cq_measure(c); cq_theta(&q, .6);
;       cq_theta(&r, .4); cq_theta(&z, .7);
;       return m + cq_measure(z) + cq_measure(q); }
;
; THE COLLAPSE NEED NOT BE A MEASUREMENT OF THE PARENT ITSELF. `q` is measured
; only at the end, so no measurement of q precedes `cq_theta(&q, .6)`. But
; `measure(c)` with `c = !q` collapses q just the same (a bijection on i1), so at
; the rotation q is in a product state and `r = q ^ z` again records only `z`;
; leaking it would dephase `z` exactly as in the neighbour. The superposition
; test therefore walks q's whole ENTANGLED COMPONENT (every register joined to it
; by a data edge: a producer's operands and result, an in-place gate's operands)
; and refuses when an observation of any member can precede the move. Without
; that walk, a test of q's own measurements alone accepts this module (measured
; on e420a1a9: rc 0, r leaked). The module keeps main's decline.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef)
declare zeroext i1 @cq_measure_i1(i1 noundef zeroext)

define i32 @slice(i32 noundef %0, i32 noundef %1) {
  %3 = icmp ne i32 %0, 0
  %4 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %3, double noundef 2.500000e-01)
  %5 = icmp ne i32 %1, 0
  %6 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %5, double noundef 3.000000e-01)
  %7 = xor i1 %4, %6
  %8 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %7, double noundef 5.000000e-01)
  %9 = xor i1 %4, true
  %10 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %9)
  %11 = zext i1 %10 to i32
  %12 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %4, double noundef 6.000000e-01)
  %13 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %8, double noundef 4.000000e-01)
  %14 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %6, double noundef 0x3FE6666666666666)
  %15 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %14)
  %16 = zext i1 %15 to i32
  %17 = add nuw nsw i32 %16, %11
  %18 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %12)
  %19 = zext i1 %18 to i32
  %20 = add nuw nsw i32 %17, %19
  ret i32 %20
}

; CHECK: error{{.*}}cq uncompute: dead chain would free a measured register
