; control_inplace_ry_stateprep_fcmp_oeq_twin.ll — ACCEPT, and it is the CONTROL
; that turns `..._reject_stateprep_fcmp_oeq_folded.ll` from an assertion into a
; measurement.
;
; It is that module with the DIAMOND REMOVED and nothing else changed: the same
; `%q`, the same `%t = fmul %q, 2.0`, the same `@cq_theta_f64(?, 0.9)`, the same two
; measurements. Here the rotation's arg-0 is the REGISTER `%t` rather than the
; constant `5.0`, which is precisely the reading the declined module is
; ambiguous BETWEEN. It lowers to an IN-PLACE `cqrt_ry_f64` on `%t`'s OWN rail
; (`%h_op`), and BOTH measurements read that same rotated rail:
;
;     cqrt_alloc_f64(%u0) -> %h ; cqrt_ry_f64(%h, 0.5)
;     cq_template_fmul_f64_hl(%h, 2.0) -> %h_op
;     cqrt_ry_f64(%h_op, 0.9)
;     cqrt_measure_f64(%h_op) ; cqrt_measure_f64(%h_op)
;
; ⚠ ROUND-4 RULE-13 (lens R4, F-R4-1). This is R4's `h/hf04_uncond_fmul.ll`,
; whose lowered IR is `diff`-CLEAN between the pre-Inc-4 ORACLE and HEAD (and is
; unchanged by the fp anchor — the anchor only ever fires inside a state-prep
; classification, and there is no region here). It is what makes the fp anchor's
; decline a statement about a WRONG UNITARY rather than a taste: the accepted
; circuit for the declined module allocated a SECOND rail at 5.0, rotated that,
; and measured `%t` unrotated, while CQ's own semantics for `cq_theta` on a live
; f64 register is the single in-place rotation above.
;
; AN IDENTITY WITNESS MUST NOT SHARE THE TRANSFORMATION IT WITNESSES: this file
; never reaches `ArmClassify`'s state-prep clause at all (no tainted branch), so
; it cannot be made to pass by the same code the decline exercises.
;
; NOTE the `warnLiveRecordRotations` WARNING this module emits (`non-diagonal
; gate over a live derived record`) is EXPECTED and PRE-EXISTING on both
; binaries — it is a warning, not a decline, and F-R3-7 item 3 records that it
; fires here and is silent on the declined twin for the `RecordSet::push`
; clause-5 reason.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll

declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)

define double @example(double %u0) {
entry:
  %q = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  %t = fmul double %q, 2.000000e+00
  %rt = call double @cq_theta_f64(double %t, double 9.000000e-01)
  %mr = call double @cq_measure_f64(double %rt)
  ; bd test_C_libtooling-3d8q: `%rt`, NOT `%t`. `%rt = cq_theta(%t, .9)` CONSUMES
  ; the name `%t` (`docs/frontend.md` §3.2's linear rule), so the second
  ; measurement naming `%t` was a READ OF THE PRE-GATE VALUE — a member of the P1
  ; stale-reader class, and it declines since `recordStaleQuantumReaders` landed.
  ; ⚠ THE WITNESS IS UNCHANGED, and that is why this edit is the right one rather
  ; than converting the file: the header's claim is "BOTH measurements read that
  ; same rotated rail", `%rt` is RAUW'd to `%t`'s own handle by the chained-theta
  ; rule, and the emitted stream is BYTE-IDENTICAL — every CHECK below is the
  ; line it always was. Only the SOURCE became well formed.
  %mt = call double @cq_measure_f64(double %rt)
  %s  = fadd double %mr, %mt
  ret double %s
}

; CHECK:      %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_f64(double %u0)
; CHECK:      call void @cqrt_ry_f64(i32 %[[H]], double 5.000000e-01)
; CHECK:      %[[T:[a-zA-Z0-9_.]+]] = call i32 @cq_template_fmul_f64_hl(i32 %[[H]], double 2.000000e+00)
; CHECK-NEXT: call void @cqrt_ry_f64(i32 %[[T]], double 9.000000e-01)
; CHECK-NEXT: call double @cqrt_measure_f64(i32 %[[T]])
; CHECK-NEXT: call double @cqrt_measure_f64(i32 %[[T]])

; NOROUTE-NOT: cqrt_ry_f64_controlled
; NOROUTE-NOT: cqrt_cswap
; NOROUTE-NOT: cqrt_copy
; NOROUTE-NOT: = phi
; NOROUTE-NOT: cq_theta
