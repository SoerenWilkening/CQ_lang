; control_angle_select_rz_runtime_arms.ll — ACCEPT. The **Rz / `cq_phi` STEM**
; with RUN-TIME arms. It was named `control_angle_select_reject_runtime_arms_rz.ll`
; and kept that wrong name to stay paired with the Ry file
; `control_angle_select_reject_runtime_arms.ll`, which declined. Since bd dm7f.6
; (owner ruling 2026-10-03) the Ry file ACCEPTS too, as
; `control_angle_select_ry_runtime_arms.ll`, so the pairing that justified the
; name is gone and both files were renamed.
;
; THE STEM SEPARATOR, AND THE HISTORY OF IT.
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
; rounding, the `inf`/`NaN` from finite arms, the 2^-40 residual bound (retired
; outright by bd dm7f.6) — has no object here. Exactness is structural, not
; measured-and-hoped.
;
; Near-duplicate of `control_angle_select_phase_runtime.ll` (same source shape);
; this file additionally pins the four count prefixes below. The STEM SPLIT it
; used to pin (the Ry twin declining on the same binary) no longer exists: both
; stems perform no arithmetic on an arm since bd dm7f.6.
;
; ⚠ ORACLE DISPOSITION, and read it precisely: the pre-3qlq binary on THIS module
; declines `tainted value consumed by an unknown callee` — the RESERVED-NAME/
; unknown-prototype path, because `void @cq_phi(double)` does not exist on that
; surface at all. It is NOT the old `rotation angle` decline, and this file is
; therefore NOT a red-green against the oracle.
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
