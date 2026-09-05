; control_angle_select_reject_runtime_arms_rz.ll — ⚠ THE NAME IS NOW WRONG AND IS
; KEPT ON PURPOSE. This file ACCEPTS. It is the **Rz / `cq_phi` STEM** twin of
; `control_angle_select_reject_runtime_arms.ll`, which still DECLINES, and the
; pair is the whole point; renaming it would break the pairing a reader follows
; from the Ry file's header. (Retiring the misleading name is a follow-on for
; whoever next touches this family.)
;
; THE STEM SEPARATOR, AND IT SEPARATES THE OTHER WAY NOW.
;
;     if (c) cq_phi(x); else cq_phi(y);          // x, y RUN-TIME doubles
;
; UNDER THE PRE-3qlq (REGISTER) SURFACE this was a DECLINE, and the reason was
; arithmetic, not basis labels: bd drbq Inc 2b lowered an angle select BY
; DIFFERENCE — one unconditional `R(h, B)` plus one `R_controlled(f, h, A−B)` —
; so the compiler SYNTHESIZED an `fsub` the source never wrote. Its error
; `|δ| ≤ ½ ulp(A−B)` is unbounded in absolute radians (measured: `Ry(π)` realized
; as `Ry(4.0)` from `π`/`1e16`) and can be `inf`/`NaN` from two FINITE arms. That
; residual rides on BOTH stems identically, which is why the Rz spelling declined
; too (the clearance measured it directly at `clearance2b/p3/r04_rt_rz_pi_sel.c`).
;
; ⚠ 3qlq(prep_a2): HAND DECISION — REWRITTEN AS AN ACCEPT, on the owner's PRD §12
; Q3 answer (run-time arms ARE admitted for the phase stem). THE GROUND IS NOT A
; RELAXED TOLERANCE — IT IS THAT THE SUBTRACTION IS GONE. Under D1 the phase is a
; KICKBACK: each arm's angle reaches its OWN `cqrt_rz_i1` on the flag, under its
; own polarity bracket, VERBATIM. Nothing is subtracted, nothing is rounded, and
; no arm value is ever combined with another, so the entire 2b residual — the
; rounding, the `inf`/`NaN` from finite arms, the 2^-40 `kAngleSelectMaxRoundingRad`
; fence — has no object here. Exactness is structural, not measured-and-hoped.
;
; ⚠ WHAT KEEPS THIS FILE FROM BEING A DUPLICATE of the implementer's
; `control_angle_select_phase_runtime.ll` (which accepts the same source shape):
; that file pins the CAPABILITY; this one pins the STEM SPLIT — the Ry twin
; `control_angle_select_reject_runtime_arms.ll` is STILL a decline
; (`rotation angle under quantum control`, MEASURED on this same binary), because
; the Ry stem still lowers by difference and still performs the `fsub`. Delete
; either half and the split stops being asserted anywhere.
;
; ⚠ ORACLE DISPOSITION, and read it precisely: the pre-3qlq binary on THIS module
; declines `tainted value consumed by an unknown callee` — the RESERVED-NAME/
; unknown-prototype path, because `void @cq_phi(double)` does not exist on that
; surface at all. It is NOT the old `rotation angle` decline, and this file is
; therefore NOT a red-green against the oracle; the red-green that matters is
; against the Ry twin on the SAME binary, above.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=ACNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=FCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=XCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=MDCNT < %t.cqd0.ll

declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %u1, double %x, double %y) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @cq_theta_si32(i32 %u1, double 3.000000e-01)
  %c = icmp eq i32 %q, 5
  %ang = select i1 %c, double %x, double %y
  call void @cq_phi(double %ang)
  %mq = call i32 @cq_measure_si32(i32 %q)
  %mr = call i32 @cq_measure_si32(i32 %r)
  %s = add i32 %mq, %mr
  ret i32 %s
}

; THE EMITTED STREAM, IN ORDER — DERIVED from this fixture's own pass output.
; Each RUN-TIME arm reaches its own gate VERBATIM: `%y` on the ¬flag (inside the
; `cqrt_x` bracket) and `%x` on the flag. The two `cqrt_x` are the same
; self-inverse gate opening and closing ONE bracket, not two brackets.
; CHECK:      %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: %[[H1:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u1)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H1]], double 3.000000e-01)
; CHECK-NEXT: %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[H]], i32 5)
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[F]], double %y)
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[F]], double %x)
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F]], i32 %[[H]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])

; ---------------------------------------------------------------------------
; WHOLE-FILE, PURE-NEGATIVE. `fsub` is the load-bearing one here: it is the
; by-difference arithmetic whose ABSENCE is this file's entire argument, and a
; reviewer re-enabling the 2b path would reintroduce exactly that instruction.
; NOROUTE-NOT: fsub
; NOROUTE-NOT: fadd
; NOROUTE-NOT: cqrt_cswap
; NOROUTE-NOT: cqrt_copy
; NOROUTE-NOT: _controlled
; NOROUTE-NOT: call void @cqrt_rz_{{(i8|i16|i32|i64|f16|f32|f64|f80)}}(
; NOROUTE-NOT: call void @cq_phi(
; NOROUTE-NOT: cq_phi_

; ---------------------------------------------------------------------------
; COUNTS — one pattern per prefix.
; ACNT-COUNT-2: call void @cqrt_rz_i1(
; ACNT-NOT:     call void @cqrt_rz_i1(
; FCNT-COUNT-1: call void @cqrt_free(
; FCNT-NOT:     call void @cqrt_free(
; XCNT-COUNT-2: call void @cqrt_x(
; XCNT-NOT:     call void @cqrt_x(
; MDCNT-COUNT-2: !cq.branchphase
; MDCNT-NOT:     !cq.branchphase
