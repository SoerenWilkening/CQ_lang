; spec_reject_ret_poison.ll — DECLINE (bd 3p2a).
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
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq specialization: callee return value denotes no value (undef/poison)

target datalayout = "e-m:o-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @leaf(i32 %a) {
entry:
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
