; spec_reject_ret_undef_spelling.ll — DECLINE (bd 3p2a).
; ⚠ bd test_C_libtooling-vsfp (2026-09-26) — RE-SPELLED, and why. `@leaf` used to
; IGNORE its parameter 0. `dropDeadCallArguments` (SpecializeDetect.h) now replaces
; an integer/fp argument whose callee parameter has NO USES by a constant before any
; stage reads it — what `clang -O1` does to the hand-inlined twin — so that spelling
; never reaches the specializer: the call became an ordinary classical call,
; `scanBody`'s return fence was never asked, and the module ACCEPTED (the caller reads
; the call's RESULT as one runtime value, so no undef literal is duplicated).
; The added lines in `@leaf` (a branch-only read — see ROUND 2 below) keep the parameter live, so this file still reaches the fence it was written for. That
; residual population — a callee that READS the argument yet returns classical — is
; IR-ONLY from C at -O1 (the library TU deletes a dead read). The `env
; CQ_DEADARG_DBG=1` + `CHECK-NOT: CQ_DEADARG_DBG` pair pins that the drop does NOT
; fire here: a widening of the drop (e.g. to dataflow liveness) retires this subject
; and must re-derive it (CLAUDE.md L8).
; ⚠ bd test_C_libtooling-cepm (2026-09-28) — the "IR-ONLY from C at -O1" claim just above
; is FALSE: a read that reaches a call the pass cannot prove pure (a callee in another TU
; whose own callee is in yet another TU: `h(a,k) { g(a); return k + 1; }`) keeps the
; parameter live from C. Since bd cepm such a call's RESULT is left classical at
; propagation (`predictReturnTainted` false): it is never tainted at all. THIS file's
; subject still is, because its read is a BRANCH and the predictor counts any tainted
; conditional terminator as a tainted return — so its result is tainted conservatively
; exactly as before (retirement trigger: a predictor that asks whether the branch
; reaches the return).
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
; ARM: the `undef` SPELLING, which is the one stock `clang -O1` actually emits —
; `poison` (spec_reject_ret_poison.ll) is the hand-IR canonical form.
;
; `PoisonValue` derives from `UndefValue`, so the single `isa<UndefValue>` inside
; `slotCarriesUndef` covers both and this file cannot diverge from its sibling by
; construction. It is here because the REACH argument runs through this spelling
; and a reader should be able to see the real shape: this body is verbatim what
;
;     int leaf(int a) { int x; return x; }
;
; compiles to under `clang -I<inc> -O1 -emit-llvm` (measured — `ret i32 undef`,
; no warning), and the `@example` below is the linked caller from a
; `run_slice_multi.sh` two-TU program. Single-TU the shape is unreachable (IPSCCP
; replaces the call with `undef` and deletes it); across `llvm-link` it reaches the
; clone gate, which is why this is a real accept-surface hole rather than a
; hand-written-IR curiosity.
;
; RUN: env CQ_DEADARG_DBG=1 not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK-NOT: CQ_DEADARG_DBG
; CHECK: error{{.*}}cq specialization: callee return value denotes no value (undef/poison)

target datalayout = "e-m:o-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @leaf(i32 noundef %0) local_unnamed_addr {
  %vsfp.c = icmp eq i32 %0, 0   ; bd vsfp r2: a BRANCH-ONLY read keeps this parameter LIVE
  br i1 %vsfp.c, label %vsfp.arm, label %vsfp.join
vsfp.arm:
  br label %vsfp.join
vsfp.join:
  ret i32 undef
}

define void @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %s = call i32 @leaf(i32 noundef %q)
  %d = add nsw i32 %s, %q
  %m = call i32 @cq_measure_si32(i32 %d)
  ret void
}
