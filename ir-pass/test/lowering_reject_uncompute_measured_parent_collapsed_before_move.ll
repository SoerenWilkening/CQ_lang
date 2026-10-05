; lowering_reject_uncompute_measured_parent_collapsed_before_move.ll — DECLINE
; (bd test_C_libtooling-01po.8 review round 2: a silent miscompile that
; e420a1a9's forcing rule admitted, pinned shut here). The `clang -O1` IR of
;     int slice(int x, int y){ _Bool q = x; cq_theta(&q, .25);
;       _Bool z = y; cq_theta(&z, .3); _Bool r = q ^ z; cq_theta(&r, .5);
;       int m = cq_measure(q); cq_theta(&q, .6); cq_theta(&r, .4);
;       cq_theta(&z, .7); return m + cq_measure(z); }
;
; A ROTATION OF A COLLAPSED PARENT DOES NOT FORCE THE RECORD. The rule leaves a
; dead record allocated only when the program keeps it alive across a move of a
; parent that is still in SUPERPOSITION: then any schedule that resets the
; record must act on the parent and changes its statistics. Here
; `cq_theta(&q, .6)` runs after `measure(q)`: q is |m> in a product state, so
; `r = m ^ z` records `z`, not q, and conjugating by that rotation (undo,
; `xor_i1_unc(r, q, z)`, redo) leaves q's statistics unchanged. e420a1a9 counted
; the rotation anyway, leaked `r`, and kept a full record of `z` across
; `cq_theta(&z, .7)`: the reviewer measured P(z=1) = 0.2298 in the source and
; 0.1347 emitted, behind three live-record warnings. `recordLiveAcrossMove` now
; refuses a move that an observation of the parent's entangled component (a
; measurement or a kept-carrier record of the parent or of any register joined
; to it by a data edge) can precede, and the module keeps main's decline. A loud
; gap (the reversal against the collapsed label is not built), not a physics
; wall (R1).
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
  %11 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %4, double noundef 6.000000e-01)
  %12 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %8, double noundef 4.000000e-01)
  %13 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %6, double noundef 0x3FE6666666666666)
  %14 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %13)
  %15 = zext i1 %14 to i32
  %16 = add nuw nsw i32 %15, %10
  ret i32 %16
}

; CHECK: error{{.*}}cq uncompute: dead chain would free a measured register
