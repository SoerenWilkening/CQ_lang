; control_swap_reject_value_mixed_ifelse.ll — HETEROGENEOUS phase/value if/else
; declines (4.2 WI-3; PRD Part II §0 + §8.3: "a region is phase-armed or
; value-armed per arm chain, and any mixture ... across the two if/else arms
; declines"). The WI-5 dual-rail emitter routes BOTH arms with ONE method: a
; phase arm wants the in-place answer + icmp_inv strip; a value arm wants
; copy-out + reverse-play — one region cannot do both (the copy dephases the
; phase arm's answer, Rule 7).
;
; `if (q > 5) { rz(p, a); } else { p = p * 7; }` — then-arm is a pure phase
; spine over %p; else-arm is a pure value chain over the same %p. Each arm is
; individually well-formed; the MIXTURE is the defect.
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
; 3qlq: migrated from register cq_phi (tainted arm -> void call, merge phi dissolved)
declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u0, i32 %v0, double %a) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %p = call i32 @cq_theta_si32(i32 %v0, double 2.500000e-01)
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %then, label %else
then:
  call void @cq_phi(double %a)  ; PHASE arm over %p
  br label %merge
else:
  %pe = mul i32 %p, 7                              ; VALUE arm over %p
  br label %merge
merge:
  %pm = phi i32 [ %p, %then ], [ %pe, %else ]
  %m  = call i32 @cq_measure_si32(i32 %pm)
  ret i32 %m
}
