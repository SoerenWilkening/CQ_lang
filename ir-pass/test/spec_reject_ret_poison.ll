; spec_reject_ret_poison.ll — DECLINE (bd 3p2a).
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
; ARM: `returnDerivesFromUndef` at `scanBody`'s `ret` terminator — the ONE check
; that whitelist ever makes on a terminator.
;
; THE HOLE. `scanBody` whitelists instruction OPCODES and `continue`s past every
; terminator, so `define i32 @leaf(i32 %a) { ret i32 poison }` earned the
; specialization certificate — "this callee computes a reversible classical
; FUNCTION of its arguments" — VACUOUSLY, without a single check touching the
; returned value. That certificate is what licenses cloning the body, CACHING the
; clone per `(callee, mask)`, DUPLICATING it verbatim into an uncompute twin, and
; reversing it with an adjoint whose whole correctness argument is "the adjoint
; reads the same operands the forward read".
;
; *** BE HONEST ABOUT THE HARM: THE TICKET'S VERSION IS FALSE. *** bd 3p2a says
; the clone's poison return "is used as an i32 QUBIT HANDLE". It is not, and it
; structurally cannot be — `buildClone` sets
; `ReturnTainted = cloneTaint.Tainted.count(RV)` and a `Constant` is never in a
; taint set, so a literal-poison return is ALWAYS classified classical and lands
; in a template's LITERAL slot. Measured end-to-end on the pre-change plugin, the
; complete `-O0` stage-3 trace of this shape is
;
;     cqrt_alloc_i32(3) -> h0
;     cqrt_ry_i32(h0, 0x1p-1)
;     cq_template_add_i32_hl(h0, 0)      ; h0 is a REAL rail; `0` is the poison
;
; — no gate on a phantom rail, and no forward/adjoint pairing break either (an
; adjoint copies the forward's OPERANDS, so both reads hit one SSA register and
; see one value).
;
; SO WHY DECLINE IT. Because the one mechanism in the pass that turns a shared
; register into two INDEPENDENT materialisations — `synthUncomputeTwin`'s verbatim
; `CloneFunctionInto`, i.e. the measured bd xy9n miscompile — is fenced at a
; DIFFERENT site (`findUndefOperandInBody`), keyed on a DIFFERENT property, and is
; one widening away from not covering this. Certifying "computes a function of its
; arguments" for a body that computes nothing at all is the unproven accept
; surface the Prime Directive says should not exist, and the input is UB, so the
; decline costs no capability.
;
; REACH IS PROVEN. `int leaf(int a) { int x; return x; }` gives `ret i32 undef`
; under stock `clang -O1`. Single-TU it is unreachable (IPSCCP folds the call
; away), but CQ ships `run_slice_multi.sh` (per-TU `-O1` -> `llvm-link` -> one
; `cq-lowering`), and there the clone IS minted — measured on the pre-change
; plugin: `opt` exit 0, `@__cq_q_leaf_1` emitted with a `ret i32 undef` body,
; feeding `cq_template_add_i32_hl`. See `spec_reject_ret_undef_spelling.ll` for
; the `undef` spelling clang actually emits.
;
; RED-GREEN: the pre-change plugin ACCEPTS this module (`opt` exit 0).
;
; RUN: env CQ_DEADARG_DBG=1 not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK-NOT: CQ_DEADARG_DBG
; CHECK: error{{.*}}cq specialization: callee return value denotes no value (undef/poison)

target datalayout = "e-m:o-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @leaf(i32 %a) {
entry:
  %vsfp.c = icmp eq i32 %a, 0   ; bd vsfp r2: a BRANCH-ONLY read keeps this parameter LIVE
  br i1 %vsfp.c, label %vsfp.arm, label %vsfp.join
vsfp.arm:
  br label %vsfp.join
vsfp.join:
  ret i32 poison
}

define void @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %s = call i32 @leaf(i32 %q)
  %d = add i32 %q, %s
  %m = call i32 @cq_measure_si32(i32 %d)
  ret void
}
