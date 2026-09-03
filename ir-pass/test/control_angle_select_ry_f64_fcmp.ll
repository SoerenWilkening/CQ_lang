; control_angle_select_ry_f64_fcmp.ll — ACCEPT at a NON-i32 width, with an
; `fcmp` condition (bd drbq Inc 2b).
;
;     double q = cq_theta(u0,.5), r = cq_theta(u1,.3);
;     r = cq_theta(r, q > 5.0 ? .9 : .3);
;
; TWO THINGS ARE PINNED HERE AND ONE OF THEM IS AN ORDERING FACT.
;
; (a) WIDTH. The accept asks `abiWidthHasControlledRotation` through the SAME
;     expression `lowerRotations` MINTS from — `wd.abiWidthFor(suffixFromName(T,
;     "cq_theta_"))`, which is why that helper is exported (RotationLowering.h).
;     Inc 1's own R4 asks `abiWidthFromType(T->getType())`; the two agree for
;     every `CQ.h` suffix measured, and asking the mint's expression is what
;     stops a divergence from becoming a decline AFTER mutation.
;
; (b) HANDLE TYPING. At i32 the register type and the handle type coincide, so a
;     rotation call with the wrong one is invisible; at f64 it is not. Both
;     `cqrt_ry_f64` calls below take an `i32` handle — that is the assertion, and
;     `NOROUTE-NOT: cqrt_ry_f64(double` is its negative half.
;
;     STATED CAREFULLY, BECAUSE THE OBVIOUS STRONGER CLAIM IS FALSE. The emitter
;     inserts the unconditional twin into `taint.ThetaCalls` IMMEDIATELY BEFORE
;     the consumer, and the first draft of this fixture said that appending at
;     the END would mint an ill-typed call. MEASURED (mutation M15): appending
;     produces BYTE-IDENTICAL output here and everywhere, because lowering the
;     consumer first creates a mistyped operand that the TWIN's own
;     RAUW-to-handle then repairs, one loop iteration later, before the verifier
;     runs. The insert position is kept because it never creates the malformed
;     instruction at all (an assertions-ON LLVM would abort on it) — not because
;     the final IR depends on it. This fixture pins the RESULT; no fixture can
;     pin the transient.
; ORACLE DISPOSITION: RED on the pre-2b binary (`rotation angle under quantum
; control`, SelectClassify gate 3) — Rule 12 red-green.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=CNT     < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll

declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)

define double @example(double %u0, double %u1) {
entry:
  %q = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  %r = call double @cq_theta_f64(double %u1, double 3.000000e-01)
  %c = fcmp ogt double %q, 5.000000e+00
  %ang = select i1 %c, double 9.000000e-01, double 3.000000e-01
  %t = call double @cq_theta_f64(double %r, double %ang)
  %mr = call double @cq_measure_f64(double %t)
  %mq = call double @cq_measure_f64(double %q)
  %s = fadd double %mr, %mq
  ret double %s
}

; CHECK:      %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_f64(double %u0)
; CHECK-NEXT: call void @cqrt_ry_f64(i32 %[[Q]], double 5.000000e-01)
; CHECK-NEXT: %[[R:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_f64(double %u1)
; CHECK-NEXT: call void @cqrt_ry_f64(i32 %[[R]], double 3.000000e-01)
; the twin, on the i32 HANDLE — this operand is what the ordering pin is about
; CHECK-NEXT: call void @cqrt_ry_f64(i32 %[[R]], double 3.000000e-01)
; CHECK-NEXT: %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_fcmp_ogt_f64_hl(i32 %[[Q]], double 5.000000e+00)
; CHECK-NEXT: call void @cqrt_ry_f64_controlled(i32 %[[F]], i32 %[[R]], double 0x3FE3333333333334)
; CHECK-NEXT: call void @cq_template_fcmp_ogt_f64_hl_unc(i32 %[[F]], i32 %[[Q]], double 5.000000e+00)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
; A STRAY ROTATION AFTER THE EMITTED STREAM was invisible to every one of the 17
; accept fixtures (round-1 Rule-13 review, L6-N11): an adjacency chain stops at
; its last `CHECK-NEXT`, and a `NOROUTE`-style whole-body negative cannot be used
; on a rotation symbol because the legitimate twin and gate are rotations. A
; TRAILING `CHECK-NOT` runs from the last match to EOF, which is exactly the
; uncovered region — and it is where a leaked rotation on a FROZEN rail would sit.
; CHECK-NOT: call void @cqrt_ry_
; CHECK-NOT: call void @cqrt_rz_

; NO rotation call may take a `double` register operand — that is the ill-typed
; form a wrong work-list position would produce.
; NOROUTE:     define{{.*}}@example
; NOROUTE-NOT: cqrt_ry_f64(double
; NOROUTE-NOT: call void @cqrt_cswap
; NOROUTE-NOT: call void @cqrt_x
; NOROUTE-NOT: select

; CNT-COUNT-1: call void @cqrt_free(
; CNT-NOT:     call void @cqrt_free(
