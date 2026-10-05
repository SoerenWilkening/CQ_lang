; lowering_reject_uncompute_measured_parent_read_after_measure.ll — DECLINE (bd
; test_C_libtooling-ptue; second decline twin of
; lowering_uncompute_measured_parent_rotated_dead_copy.ll). The `clang -O1` IR of
;     int slice(int x){ int q = x; cq_theta(&q, .25); int m = cq_measure(q);
;                       int t = q ^ 9; cq_theta(&t, .5); return m; }
;
; THE DEAD CHAIN READS THE MEASURED REGISTER AFTER ITS MEASUREMENT — bd yiid.
; yiid is NOT an open question: it is CLOSED with owner rulings 2026-09-14 ("a
; capability, not a decline" — the measured name is re-usable by re-preparation,
; a fresh allocation seeded from the outcome) and 2026-09-15 E3 (b) BROAD (every
; use positioned after the measurement is fresh/classical). E3 is ruled and NOT
; BUILT: today the forward xor chains on the collapsed rail.
;
; SO THIS DECLINE IS AN OVER-DECLINE OF A RULED CAPABILITY, KEPT LOUD AS A GAP
; PENDING E3 (R1: a loud gap, never a physics wall). The reversal would be exact
; on the collapsed rail, but it would REPLAY the post-collapse read itself
; (`xor_hl_unc(t, q, 9)` after `measure(q)`), and E3 re-targets exactly that read
; to a re-prepared register; the uncompute spine has not been composed with E3,
; so the measured-rail frontier retry refuses (`measuredParentsReadBeforeCollapse`:
; a measurement of a borrowed measured rail may not reach a DAG gate that reads
; it) and the module keeps the decline it had before bd ptue. A post-collapse
; read the reversal does NOT replay is accepted:
; lowering_uncompute_measured_parent_derived_after_collapse.ll.
;
; RETIREMENT TRIGGER (L7): when E3 (bd yiid's (b) BROAD ruling) lands, re-derive
; this file — it is expected to become an accept. (The trigger written here
; first, "when the owner rules yiid", had already fired on 2026-09-14/15.)
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @slice(i32 %x) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %x, double 2.500000e-01)
  %m  = call i32 @cq_measure_si32(i32 %q)
  %t0 = xor i32 %q, 9                                           ; reads q AFTER the collapse
  %t  = call i32 @cq_theta_si32(i32 %t0, double 5.000000e-01)   ; t DEAD after this
  ret i32 %m
}

; CHECK: error{{.*}}cq uncompute: dead chain would free a measured register
