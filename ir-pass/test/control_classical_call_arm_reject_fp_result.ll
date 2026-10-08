; control_classical_call_arm_reject_fp_result.ll — ACCEPT (dm7f.16.1).
; A retained total classical f64 call supplies data in a quantum value arm.
; The measured value is 107.0 when q>5 and borrowed q otherwise. This
; reaches shared f64 controlled-copy lowering; no rotation-angle use occurs.
; Historical filename retained.
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll

declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)
; bd wve8 — DEFINED, not declared, and it is LOAD-BEARING for what this fixture
; pins. The 6.5 arm now demands a TOTALITY proof of the callee before it accepts;
; an opaque `declare` fails it, so with the old declaration this file would still
; go red-to-green but from the CLASSIFIER's totality gate, character-for-character
; the same message, leaving the EMITTER's `copyControlledFn` fp gate — its actual
; stated subject — with no fixture anywhere in the tree. A visible total body
; carries the region past classification so the fp decline is reached. (Found by
; the wve8 Rule-13 round, lens test-integrity: the exact "a fixture satisfied by
; another site's guard" trap.)
define double @fp_f(double %a) #0 {
  %s = fadd double %a, 1.000000e+02
  ret double %s
}

define double @example(double %u0) {
entry:
  %q = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  %c = fcmp ogt double %q, 5.000000e+00
  br i1 %c, label %arm, label %merge
arm:
  %r = call double @fp_f(double 7.000000e+00)   ; PURE but fp result — angle, not data
  br label %merge
merge:
  %y = phi double [ %r, %arm ], [ %q, %entry ]
  %m = call double @cq_measure_f64(double %y)
  ret double %m
}

attributes #0 = { nounwind willreturn memory(none) }

; CHECK-LABEL: define double @example(
; CHECK: %[[U:[a-zA-Z0-9_.]+]] = freeze double %u0
; CHECK: %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_f64(double %[[U]])
; CHECK: %[[R:[a-zA-Z0-9_.]+]] = call double @fp_f(double 7.000000e+00)
; CHECK: %[[G:[a-zA-Z0-9_.]+]] = call i32 @cq_template_fcmp_ogt_f64_hl(i32 %[[Q]], double 5.000000e+00)
; CHECK: %[[O:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_f64(double 0.000000e+00)
; CHECK: %[[S:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_f64(double %[[R]])
; CHECK-NEXT: call void @cqrt_copy_f64_controlled(i32 %[[G]], i32 %[[S]], i32 %[[O]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[G]])
; CHECK-NEXT: call void @cqrt_copy_f64_controlled(i32 %[[G]], i32 %[[Q]], i32 %[[O]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[G]])
; CHECK: call void @cq_template_fcmp_ogt_f64_hl_unc(i32 %[[G]], i32 %[[Q]], double 5.000000e+00)
; CHECK: call void @cqrt_free(i32 %[[G]])
; CHECK: call double @cqrt_measure_f64(i32 %[[O]])
