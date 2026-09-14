; control_phase_kickback_rail_after_prep.ll — ACCEPT, and it is GREEN ON THE
; FROZEN ORACLE (`59ac5b7`) TOO. That is the entire point of the file.
;
; bd `3qps` (Track P) — THE DISCRIMINATOR THAT THE WIDENING ADDS AN *ACCEPT* AND
; NOT A *STREAM*. This module is `control_phase_kickback_mergephi_rail_negated.ll`
; AFTER `emitInPlaceRotationRegion` has run: the prep's arm theta hoisted into the
; entry block, the cancelling clone chained onto it, and the merge φ RAUW'd to
; that clone (M-β, `SwapRouteEmit`). So the condition here is what the φ BECOMES —
; an ordinary `cq_theta_i1` CALL — and the gates below are exactly the ones the
; ORACLE already emitted for a bare rail condition before this increment existed.
;
; HOW TO USE IT. If a future change makes the φ path emit something ELSE, this
; file stays green while `control_phase_kickback_mergephi_rail_negated.ll`'s
; CHECK block moves — and the pair is what tells you the emitter drifted rather
; than the classifier. Neither file alone can say that.
;
; ⚠ THE ONE EXPECTED DIFFERENCE between this stream and the φ spelling's: the
; cancelling rotation is UNCONTROLLED here (`cqrt_ry_i1(h1, −θ)`) and
; CONTROLLED there (`cqrt_ry_i1_controlled(h0, h1, −θ)`), because this hand-IR
; twin has no prep region left to control it. Everything else — the diagonal
; `cqrt_rz_i1` on the user's register, no mint, no `cqrt_x`, no strip, no free —
; is identical.
;
; The e2e counterpart is `tests/e2e/slice_control_phase_mergephi.expected.log`
; (20 lines), whose lines 1-6 are this stream with line 5 controlled.
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOX < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=FCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=MDTAG < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=MINT < %t.cqd0.ll

declare void @cq_phi(double)
declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)

define i1 @example(i1 %u0) {
entry:
  %b0 = call i1 @cq_theta_i1(i1 %u0, double 5.000000e-01)
  %t = call i1 @cq_theta_i1(i1 false, double 2.500000e-01)
  %tneg = call i1 @cq_theta_i1(i1 %t, double -2.500000e-01)
  br i1 %tneg, label %ph, label %done
ph:
  call void @cq_phi(double 9.000000e-01)
  br label %done
done:
  %m0 = call i1 @cq_measure_i1(i1 %b0)
  %m = call i1 @cq_measure_i1(i1 %tneg)
  %r = xor i1 %m0, %m
  ret i1 %r
}

; CHECK:      %[[H0:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 %u0)
; CHECK-NEXT: call void @cqrt_ry_i1(i32 %[[H0]], double 5.000000e-01)
; CHECK-NEXT: %[[H1:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_ry_i1(i32 %[[H1]], double 2.500000e-01)
; CHECK-NEXT: call void @cqrt_ry_i1(i32 %[[H1]], double -2.500000e-01)
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[H1]], double 9.000000e-01), !cq.branchphase
; CHECK-NEXT: %[[M0:[a-zA-Z0-9_.]+]] = call i1 @cqrt_measure_i1(i32 %[[H0]])
; CHECK-NEXT: %[[M:[a-zA-Z0-9_.]+]] = call i1 @cqrt_measure_i1(i32 %[[H1]])

; NOX-NOT: call void @cqrt_x(
; NOX-NOT: cqrt_cswap
; NOX-NOT: cqrt_copy
; NOX-NOT: cqrt_toffoli
; FCNT-NOT: call void @cqrt_free(
; MDTAG-COUNT-1: call void @cqrt_rz_i1({{.*}}), !cq.branchphase
; MDTAG-NOT: call void @cqrt_rz_i1(
; MINT-NOT: cq_template_
; MINT-NOT: _unc(
