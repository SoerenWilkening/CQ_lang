; lowering_reject_uncompute_measured_parent_read_after_measure.ll — DECLINE (bd
; test_C_libtooling-ptue; second decline twin of
; lowering_uncompute_measured_parent_rotated_dead_copy.ll). The `clang -O1` IR of
;     int slice(int x){ int q = x; cq_theta(&q, .25); int m = cq_measure(q);
;                       int t = q ^ 9; cq_theta(&t, .5); return m; }
;
; THE DEAD CHAIN READS THE MEASURED REGISTER AFTER ITS MEASUREMENT. The reversal
; itself would be exact (q is classical after the collapse and stays put), but
; the FORWARD xor already reads the collapsed register under a name that denotes
; the pre-measurement superposition: bd yiid's owner-unruled boundary (CLAUDE.md
; lists it under r2j3 section A). Today this module declines only incidentally,
; through the dead chain's measured lineage; the measured-rail frontier retry
; must not turn that into an accept and add a customer to yiid (L9). So the retry
; requires every measurement of a borrowed measured rail to be unable to reach
; the first DAG gate that reads it, and refuses here.
;
; RETIREMENT TRIGGER (L7): when the owner rules yiid, re-derive this file.
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
