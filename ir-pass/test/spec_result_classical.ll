; spec_result_classical.ll — Phase 6.1 WI-1.9 (return-taint, false case, §2.7).
; ⚠ bd test_C_libtooling-vsfp (2026-09-26) — RE-SPELLED, and why. `@double_classical` used to
; IGNORE its parameter 0. `dropDeadCallArguments` (SpecializeDetect.h) now replaces an
; integer/fp argument whose callee parameter has NO USES by a constant before any
; stage reads it — what `clang -O1` does to the hand-inlined twin — so that spelling
; is no longer a Phase-6 site at all: the call stays an ordinary classical call, no
; clone is built and nothing is scrubbed, i.e. the property this file pins would have
; no subject. The ONE added line in `@double_classical`, `%vsfp.read`, is a DEAD READ that keeps
; the parameter used, so the clone is still built, still returns classical and is
; still scrubbed. (Its forward/adjoint template pair now sits in the CLONE body; the
; caller-side checks below are unchanged.) That population — a callee that READS the
; argument yet returns classical — is IR-ONLY from C at -O1. The NODROP prefix pins
; that the drop does NOT fire here; a widening of the drop retires this subject and
; must re-derive it (CLAUDE.md L8).
;
; The callee has a tainted param (arg 0) but its RETURN derives from a CLASSICAL
; param only (`return c + c`). The clone proves `ReturnTainted = false`, so
; `specialize` SCRUBS the conservatively-tainted call result (and the forward
; cone that loses all taint) back out of `taint.Tainted` — the caller's
; downstream `add %r, 5` stays a plain CLASSICAL add, never lowered. This is the
; post-drain re-seed correction: the original `propagate` over-tainted the call
; result (a call reading a tainted arg), and the post-lowering verdict fixes it.
;
; RUN: env CQ_DEADARG_DBG=1 %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll 2> %t.vsfp.err
; RUN: %filecheck %s --check-prefix=NODROP --allow-empty < %t.vsfp.err
; NODROP-NOT: CQ_DEADARG_DBG
; RUN: %filecheck %s < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @double_classical(i32 %t, i32 %c) {
entry:
  %vsfp.read = mul i32 %t, 3   ; bd vsfp: a DEAD READ keeps this parameter used
  %y = add i32 %c, %c
  ret i32 %y
}

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @double_classical(i32 %q, i32 7)
  %z = add i32 %r, 5
  ret i32 %z
}

; The call retargets (mask "01": arg 0 tainted, arg 1 classical pass-through).
; CHECK:     %[[R:[a-zA-Z0-9_.]+]] = call i32 @__cq_q_double_classical_01(i32 %{{[a-zA-Z0-9_.]+}}, i32 7)
; The caller's `add` stays a RAW classical add — `%r` was scrubbed back out of
; taint, so the op is NOT lowered to a template.
; CHECK:     %[[Z:[a-zA-Z0-9_.]+]] = add i32 %[[R]], 5
; The caller lowered nothing to a data template — the tainted arg never affects
; the (classical) return, so the caller's cone stays raw. (Since bd vsfp this
; says nothing about the CLONE body: its dead read `%vsfp.read` is a forward
; template the Bennett wrap reverses there. Scoped to the caller for that reason.)
; CHECK-NOT: cq_template
; CHECK:     ret i32 %[[Z]]
