; lowering_reject_live_record_post_theta_user_rz.ll — DECLINE (owner ruling
; 2026-08-28 on the Rule-13 round's F2 finding, bd test_C_libtooling-6uqc). This
; file was the PENDING-RULING accept pin `..._post_theta_user_rz_accept.ll`; the
; ruling came down for the ENUMERATED data-use list, so it is now the negative.
;
; SOURCE (`clang -O1` emits exactly the SSA below):
;     a = cq_theta(a, 0.5);
;     int c = a + 3;          // ONE record of the wire
;     a = cq_theta(a, 0.7);   // T — chained, in-place Ry
;     c = cq_phi(c, 1.0);     // a USER Rz naming the record AFTER T — and NOTHING observes c
;     return cq_measure(a);
;
; THE RULING: a bare post-gate ROTATION on a record is NOT a clause-3 data use.
; A record exempts only if its lineage reaches an OBSERVING sink after the gate
; (measure / ret / tape / a template read that flows to one). A phase written
; onto a register nothing ever observes is unobservable, so it cannot make `%c`
; "the program's own data"; `%c` is a dead, undischarged, entangled record at `T`
; and the module declines — the SAME verdict the rotation-BEFORE spelling
; (`int c = a+3; c = cq_phi(c,1.0); a = cq_theta(a,0.7);`) always had, for the
; same physics at the gate (`Rz` is diagonal; it disentangles nothing).
;
; WHAT STILL ACCEPTS, so the boundary is not over-read: rotate `c` and then
; MEASURE it (or return/tape it) — the measure is an observing sink, `%c` is live
; user data, and its dephasing of `T` is source semantics
; (lowering_stale_record_add_before_theta.ll is the ruled accept boundary).
;
; The decline message tells the author exactly what to do: measure `c` or drop
; it. Zero shipped programs are affected (both spellings were constructed
; probes); the change is accept-NARROWING, the safe direction.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @main() {
  %q  = call i32 @cq_theta_si32(i32 1, double 5.000000e-01)
  %c  = add nsw i32 %q, 3                                      ; the record
  %q2 = call i32 @cq_theta_si32(i32 %q, double 7.000000e-01)   ; T — chained, in-place Ry
  %cz = call i32 @cq_phi_si32(i32 %c, double 1.000000e+00)     ; USER Rz on the record, AFTER T
  %m  = call i32 @cq_measure_si32(i32 %q2)
  ret i32 %m
}

; CHECK: error{{.*}}cq rotation lowering: non-diagonal gate over a live derived record
