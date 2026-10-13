; control_classical_call_arm_reject_interposable_callee.ll — TOTALITY reject, the
; LINKAGE row (bd wve8). The body here is visible, pure, single-block, total and
; terminating — it would pass every content clause of the walk — and the region
; declines anyway, on `hasExactDefinition()`.
;
; THE OBLIGATION IS NOT ABOUT THIS BODY, IT IS ABOUT WHICH BODY RUNS. The 6.5 arm
; hoists the call to unconditional execution on the strength of a proof read off
; the MODULE-LOCAL definition. An `available_externally` definition is an inlining
; hint that is DISCARDED before code generation and resolved to whatever the
; linker finds; `weak_odr`/`linkonce_odr` may be replaced by an equivalent-but-not
; identical body; the interposable set (`weak_any`/`linkonce_any`/`common`/
; `extern_weak`) may be replaced outright. In every case the totality proof would
; be baked into a speculated hoist while a DIFFERENT function runs at stage 3 —
; the fence PredMuxFlatten.cpp states for the shared walk ("a purity/termination
; proof over the module-local body would be baked into the speculated hoist ...
; while a different function runs at stage 3").
;
; `available_externally` is chosen deliberately as the ordinary spelling: it is
; what a C99 `inline` function becomes in an importing translation unit. (bd
; p3kd.2 measured, clang 19 -O1: only in the frontend's IR; the -O1 pipeline
; inlines such a body or turns it into a declaration, so plain C at -O1 does not
; deliver it to the pass.) `hasExactDefinition()` is `!isDeclaration() &&
; !mayBeDerefined()`, and per bd gxhi (verified against LLVM 19) `mayBeDerefined()`
; is TRUE for `weak_odr`/`linkonce_odr`/`available_externally` as well as for the
; arbitrary-replacement set — so all of them decline. bd p3kd.2 decided that they
; stay declined HERE (`calleeBodyTrusted(F, AssumeOfLinkedCall)`, CalleeBody.h):
; the hoisted call runs the LINKED body. The ODR widening applies only where the
; body is cloned and the call retargeted to the clone (spec_accept_odr_callee.ll).
;
; WHY IT NEEDED ITS OWN FIXTURE (found by the wve8 Rule-13 round, lens
; over-decline): the other totality declines pin CONTENT clauses —
; ..._reject_qrom_callee.ll pins the deferred-bounds memory op (the `sdiv`-on-a-
; register and conditional-branch rows, ..._twin_accept_partial_callee.ll and
; ..._twin_accept_poisonbr_callee.ll, accept as twins since batch 053; the linkage
; guard refuses the twin too: `calleeBodyTrusted`). NONE of them exercises the
; linkage guard, which carries an independent soundness rationale and is the row
; most likely to be "simplified away" by someone reading only the body clauses.
;
; ARM-KILL: delete the single token `available_externally`. The body, attributes,
; call and diamond are otherwise byte-identical, the linkage becomes ordinary
; external, `hasExactDefinition()` becomes true, and the module ACCEPTS and lowers.
; Verified in both directions.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}control flow under quantum control
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

; a body good enough in every other respect — the linkage is the whole finding.
define available_externally i32 @f(i32 noundef %a) #0 {
  %s = add i32 %a, 100
  ret i32 %s
}

define i32 @example(i32 noundef %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %r = call i32 @f(i32 noundef 7)
  br label %merge
merge:
  %y = phi i32 [ %r, %arm ], [ %q, %entry ]
  %m = call i32 @cq_measure_si32(i32 %y)
  ret i32 %m
}

attributes #0 = { nounwind willreturn memory(none) }

; NOTE, so nobody adds a vacuous assertion here: there is deliberately NO
; `CHECK-NOT` for the emitted stream. On a `DS_Error` the diagnostic handler exits
; before the module is printed, so cq-opt writes ZERO bytes to stdout and a
; CHECK-NOT over this stream can never match under ANY behaviour of the gate.
