; spec_result_classical.ll — Phase 6.1 WI-1.9 (return-taint, false case, §2.7).
; ⚠ bd test_C_libtooling-vsfp (2026-09-26) — RE-SPELLED, and why. `@double_classical` used to
; IGNORE its parameter 0. `dropDeadCallArguments` (SpecializeDetect.h) now replaces an
; integer/fp argument whose callee parameter has NO USES by a constant before any
; stage reads it — what `clang -O1` does to the hand-inlined twin — so that spelling
; is no longer a Phase-6 site at all: the call stays an ordinary classical call, no
; clone is built and nothing is scrubbed, i.e. the property this file pins would have
; no subject. The added lines in `@double_classical` (a branch-only read — see ROUND 2 below) keep the
; parameter live, so the clone is still built, still returns classical and is
; still scrubbed. (The clone's own flatten removes the read, so the clone body carries no
; template for it; the caller-side checks below are unchanged.)
; That population — a callee that READS the
; argument yet returns classical — is IR-ONLY from C at -O1. The NODROP prefix pins
; that the drop does NOT fire here; a widening of the drop retires this subject and
; must re-derive it (CLAUDE.md L8).
; ⚠ ROUND 2 (bd vsfp, Rule-13 r1A/r1B): round 1's DEAD `mul` read no longer keeps the
; parameter used — the drop now asks LIVENESS (`DeadValueLiveness.h`), and a value that
; reaches no root is dead. The read is therefore a BRANCH-ONLY one now: `%vsfp.c` and an
; EMPTY diamond on it. A branch condition is a liveness ROOT (the predicate has no
; control dependence — see its LIMITS), so the parameter is LIVE in the original callee,
; the drop does not fire (the NODROP / CHECK-NOT pin below), and the clone is built as
; before; the clone's own flatten then removes the branch and the specializer records
; the slot dead. Where this module ACCEPTS, its operand is a `cq_theta` result (the
; phantom-read backstop's one exemption); where it DECLINES, the owner named here fires
; before the backstop is asked. A predicate WITH control dependence (ADCE) retires this
; subject — the pin below then turns red and the subject must be re-derived (L8).
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
  %vsfp.c = icmp eq i32 %t, 0   ; bd vsfp r2: a BRANCH-ONLY read keeps this parameter LIVE
  br i1 %vsfp.c, label %vsfp.arm, label %vsfp.join
vsfp.arm:
  br label %vsfp.join
vsfp.join:
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

; The call retargets (mask "01": arg 0 tainted, arg 1 classical pass-through). Nothing
; in the caller before it lowered to a data template:
; CHECK-LABEL: define i32 @example(
; CHECK-NOT: cq_template
; (bd vsfp round 3, bd tzfa: slot 0 is one the specializer RECORDED dead — the clone never
; reads it — so `resolvePhantomCloneArgReads` NEUTRALISES it to `0` after `specialize()`;
; the operand is a `cq_theta` result, which the twin keeps, so nothing is declined.)
; CHECK:     %[[R:[a-zA-Z0-9_.]+]] = call i32 @__cq_q_double_classical_01(i32 0, i32 7)
; The caller's `add` stays a RAW classical add — `%r` was scrubbed back out of
; taint, so the op is NOT lowered to a template.
; CHECK-NEXT: %[[Z:[a-zA-Z0-9_.]+]] = add i32 %[[R]], 5
; CHECK-NEXT: ret i32 %[[Z]]
;
; Nothing after the caller (the clone body, the declarations) lowered to a data template
; either — the whole-file window main had. ⚠ bd vsfp round 2, Rule-13 r1A F-VA-6: round
; 1 moved this NOT between two ADJACENT lines (`add` … `ret`), where it checked nothing,
; because round 1's dead `mul` read put a template pair in the clone body. The round-2
; branch-only read is removed by the clone's own flatten, so the clone body has no
; template and the original whole-file window is restored.
; CHECK-NOT: cq_template
