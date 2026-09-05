; control_swap_reject_switch_phase_width.ll — DECLINE: a phase switch whose merge is
; over a wider/different rail than the scrutinee (i8 scrutinee %q, i32 merge with an
; i32 straight-through constant 0 and i32 arm consts; i8 case literals). FIRING PATH:
; the straight-through (i32 0) is not the i8 scrutinee, so proveSwitchPhase's
; straight-through == scrutinee guard (Rule-13 round-2 R2-1) declines "control flow"
; first. The case-literal-vs-arm-const WIDTH divergence (i8 -1 case vs i32 255 arm,
; whose raw words coincide at 0xFF) is a SYMPTOM of merging over a non-q rail; the
; per-arm getType()/APInt width guard (Rule-13 H1, D4) is the defense-in-depth that
; would also catch it. Over-decline is always safe.
;
; 3qlq(prep_a2): the asserted diagnostic was WIDENED to the whole DS_Error
; text on the Inc-1 binary.  The refusing CLAUSE is UNCHANGED — the new
; string ENDS WITH the old one — and this is Rule 12's
; character-for-character mirror rather than a disposition change: a
; suffix-only assertion would still match if some OTHER subsystem grew a
; message with the same tail.
; OLD: control flow under quantum control
; NEW: cq controlled lowering: control flow under quantum control
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq controlled lowering: control flow under quantum control
; 3qlq: migrated from register cq_phi (tainted arm -> void call, merge phi dissolved)
declare void @cq_phi(double)
declare i8 @cq_theta_si8(i8, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i8 %u0) {
entry:
  %q = call i8 @cq_theta_si8(i8 %u0, double 5.000000e-01)
  switch i8 %q, label %merge [ i8 -1, label %a0
                               i8 1, label %a1 ]
a0:
  call void @cq_phi(double 1.000000e-01)
  br label %merge
a1:
  call void @cq_phi(double 2.000000e-01)
  br label %merge
merge:
  %qm = phi i32 [ 0, %entry ], [ 255, %a0 ], [ 1, %a1 ]
  %m = call i32 @cq_measure_si32(i32 %qm)
  ret i32 %m
}
