; lowering_reject_uncompute_measured_parent_measured_in_window.ll — DECLINE (bd
; test_C_libtooling-01po.8 review round 1, finding F1: a silent miscompile that
; f6984f85 introduced and this file pins shut). The `clang -O1` IR of
;     int slice(int x, int y){ _Bool q = x; cq_theta(&q, .25);
;       _Bool z = y; cq_theta(&z, .3); _Bool r = q ^ z; cq_theta(&r, .5);
;       int m = cq_measure(q); cq_theta(&r, .4); cq_theta(&z, .7);
;       return m + cq_measure(z); }
;
; A MEASUREMENT IS NOT A MOVE. The borrowed measured `q` is measured inside the
; window of the dead record `r = q ^ z`, and `r` is used after it. f6984f85
; counted that measurement as forcing `r` to stay allocated, and leaked it:
; `r = m ^ z` then stood as a full record of `z` across `cq_theta(&z, .7)`, and
; the reviewer measured P(z=1) = 0.2298 in the source against 0.1347 emitted,
; behind a live-record warning that blamed the user's rotation. But a collapse
; leaves q's computational-basis label unchanged on the realised branch, and
; that label is all an `_unc` reads: the exact reversal exists at r's last use
; (`ry(r,-.4); ry(r,-.5); xor_i1_unc(r, q, z); free(r)`), and the program's
; meaning of a dead `r` is that it is uncomputed before `z` is rotated. So the
; record is NOT forced (`recordLiveAcrossMove` admits only a non-permutation
; in-place gate on the parent), and the module keeps its pre-f6984f85 decline.
; A loud gap, not a physics wall (R1): the measurement-tolerant reversal (an
; `_unc` against the collapsed label, bd yiid territory) is not built.
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
  %9 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %4)
  %10 = zext i1 %9 to i32
  %11 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %8, double noundef 4.000000e-01)
  %12 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %6, double noundef 0x3FE6666666666666)
  %13 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %12)
  %14 = zext i1 %13 to i32
  %15 = add nuw nsw i32 %14, %10
  ret i32 %15
}

; CHECK: error{{.*}}cq uncompute: dead chain would free a measured register
