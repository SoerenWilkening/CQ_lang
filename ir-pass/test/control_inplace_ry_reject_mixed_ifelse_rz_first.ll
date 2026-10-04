; control_inplace_ry_reject_mixed_ifelse_rz_first.ll — DECLINE: the OTHER ARM
; ORDER of the mixed if/else (bd test_C_libtooling-drbq).
;
;     if (c) r = cq_phi(r, .9); else cq_theta(&r, .2);
;
; Committed as a PAIR with control_inplace_ry_reject_mixed_ifelse.ll because the
; property is symmetry, not either module on its own: homogeneity must hold
; whichever arm the classifier meets first. This one exercises the rotation
; clause's own test (a rotation arm after a phase arm); its twin exercises the
; three checks added to the phase / value / eq-fold accept sites for the reverse
; order.
;
;
; 3qlq(prep_a2): the asserted diagnostic was RE-SPELLED on the Inc-1 binary.
; The construct this fixture pins is unchanged; the CLAUSE that refuses it
; MOVED — this is a real disposition change, not a widening, and the new
; string does not contain the old one.
; OLD: mixed phase/value arm under quantum control
; NEW: cq controlled lowering: impure phase arm under quantum control
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq controlled lowering: impure phase arm under quantum control
; CHECK-NOT: cqrt_ry_i32_controlled
; 3qlq: migrated from register cq_phi (tainted arm -> void call, merge phi dissolved)

declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %u1) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @cq_theta_si32(i32 %u1, double 2.500000e-01)
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %armt, label %armf
armt:
  call void @cq_phi(double 9.000000e-01)
  br label %merge
armf:
  %rf = call i32 @cq_theta_si32(i32 %r, double 2.000000e-01)
  br label %merge
merge:
  %rm = phi i32 [ %r, %armt ], [ %rf, %armf ]
  %m  = call i32 @cq_measure_si32(i32 %rm)
  ret i32 %m
}
