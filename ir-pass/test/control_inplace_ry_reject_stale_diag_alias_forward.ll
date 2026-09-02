; control_inplace_ry_reject_stale_diag_alias_forward.ll — DECLINE: a DIAGONAL
; ALIAS of the rotated register, minted BEFORE the region, is measured AFTER it
; (control-in-place-PRD §4 R6; bd test_C_libtooling-drbq Inc 1, finding J).
;
;     int q = cq_theta(0,.7); int r = cq_theta(0,.3);
;     int mark = cq_phi(r, .1);            // ONE hop off `r`, SAME physical wire
;     if (q == 5) r = cq_theta(r, .9);
;     return cq_measure(mark) + cq_measure(r) + cq_measure(q);
;
; `cq_phi` is `Rz`, which ALWAYS lowers IN PLACE on its arg-0 handle, so `mark`
; and `r` are two SSA names for ONE physical rail. R6 as first shipped ranged over
; the DIRECT users of the base only, so `mark` — a user, but not a read — hid the
; `cq_measure(mark)` one hop out and the region ACCEPTED. Measured before the fix:
;
;     rz(h1,.1); icmp(h,5)->f; ry_controlled(f,h1,.9); icmp_unc; free(f);
;     measure(h1); measure(h1)
;
; both measurements naming the POST-Ry register while the source names the pre-Ry
; record with the first one — a verify-clean, stage-2b-clean WRONG VALUE.
;
; This is the bd 8h7d.5 F-1/F-3 lesson verbatim (`rail-record-set-is-the-rail-not-
; the-chain`): the fence was written over the CHAIN — one SSA name — when the
; object it protects is the RAIL, every SSA name of one physical wire. R6 now
; ranges over the base's ALIAS CLOSURE, backward AND forward.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}stale rail record read past a controlled Ry under quantum control
; CHECK-NOT: cqrt_ry_i32_controlled

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %u1) {
entry:
  %q    = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r    = call i32 @cq_theta_si32(i32 %u1, double 3.000000e-01)
  %mark = call i32 @cq_phi_si32(i32 %r, double 1.000000e-01)
  %c    = icmp sgt i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %rt = call i32 @cq_theta_si32(i32 %r, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi i32 [ %rt, %arm ], [ %r, %entry ]
  %a  = call i32 @cq_measure_si32(i32 %mark)
  %b  = call i32 @cq_measure_si32(i32 %rm)
  %s  = add i32 %a, %b
  ret i32 %s
}
