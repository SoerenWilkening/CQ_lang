; lowering_reject_break_uninvertible_cond.ll — DECLINE (bd test_C_libtooling-zea5).
; THE INVERTIBILITY PRE-SCAN of the 7.4 break reverse-play, and the third instance of
; the class bd uow0 / 1fim each turned out to be: TWO PREDICATES, ONE GATE, DIFFERENT
; ANSWERS.
;
; `BreakReversePlay::discoverLoweredBreak` collects the break-cond chain with
; `isBreakCondTemplate` — `cq_template_` prefix, NOT `_controlled`, NOT `_unc`,
; tainted. `EmitInverse::isInverseEmittable` additionally rejects the `_inv` suffix
; (the FRESH-MINTING adjoint twin, which is the inverse *operation*, not the in-place
; uncompute *step* — DD-2). So a `cq_template_…_inv` call in the break-cond chain was
; COLLECTED by one predicate and REJECTED by the other.
;
; MEASURED on the pre-fix pass, on exactly this module (`opt` rc=0, `opt -verify`
; clean): `emitInverseChain` returned its un-invertible `false`, that bool was
; DISCARDED, and `cqrt_free` of EVERY chain member — including the `_inv` rail no
; adjoint ever zeroed — was emitted anyway, twice (the in-iteration clear and the
; backward companion loop's recompute-clear). That is the EXACT pre-WI-5 shape
; `lowering_uncompute_uninvertible.ll` documents: a dirty free is a hardware reset =
; a hidden projective collapse of the entangled rail (Rules 5/6/8). WI-5 pre-scanned
; the whole-DAG driver with `isInverseEmittable`; this module never got the same
; treatment until zea5.
;
; NOTHING ELSE CATCHES IT. `opt -verify` is clean (the structure is perfect — only the
; run-time state differs) and e2e stage 2b cannot witness it either: the loop-break
; slices necessarily run `--allow-unproven` (the whole-loop reverse-play is a Bennett
; recompute whose write history crosses a back edge), so the checker never certifies
; these rails in the first place. This lit decline is the only gate.
;
; REACHABILITY, stated exactly — this is NOT a synthetic off-ABI declaration. The
; `_inv` twins are REAL generated symbols of the frozen template surface
; (`cq_template_add_i32_hl_inv(i32, i32) -> i32`, runtime/cq_templates.h; Rule 15
; grammar) retained for the Phase-8 manual-inversion path, and `declineTaintEscapes`
; carves out every `cq_template_*` callee BY NAME (TaintPropagation.cpp step 1b) with
; no suffix check, so the call taints, survives `lowerOps` untouched (it is a call,
; not an opcode), and lands in the chain. The declared prototype below matches the
; generated one exactly.
;
; THE PREDICATES STAY ASYMMETRIC ON PURPOSE — but they are INCOMPARABLE, NOT NESTED.
; The fix does NOT teach `isBreakCondTemplate` to skip `_inv`, because an UNCOLLECTED
; link gets neither an adjoint nor a diagnostic while a collected one declines loudly
; and source-located. State the rationale that way and not the comfortable way: a
; skipped link does NOT leave a silent dirty free — its rail is left ALLOCATED (the
; sanctioned Rule-6 fallback). What it leaves is a backward companion chain that still
; names the forward body's SSA value, i.e. a BROKEN MODULE. Along other axes discovery
; is NARROWER — `isInverseEmittable` ACCEPTS `@__cq_q_*` and `isBreakCondTemplate`
; rejects it — and that direction is a live pre-existing defect this pre-scan
; structurally cannot reach (bd test_C_libtooling-9g9n, measured at rc=134 from five
; lines of plain C).
;
; THE CHAIN-HEAD AXIS: the `_inv` is the chain's ONLY non-compare link; its sibling
; `lowering_reject_break_uninvertible_cond_tail.ll` pins the MID-CHAIN axis.
;
; WHAT THIS FIXTURE DOES AND DOES NOT DISCRIMINATE, measured rather than asserted.
; It pins the INVARIANT (an un-invertible link declines loudly and frees nothing), NOT
; the mechanism: with the `emitOneBreak` pre-scan deleted and only the `OK` threading
; left, this fixture still passes — the same message, the same rc. That is by design
; (the two layers are deliberately over the SAME predicate) and it is the honest
; reading of what a lit decline can witness here. Do not add prose claiming otherwise.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq loop lowering: break reverse-play cannot invert a lowered body gate
; The CHECK-NOTs below are DOCUMENTARY — they state what must not be emitted, and they
; are structurally vacuous on this stream: a `DS_Error` diagnostic terminates `opt`
; immediately, so `-S` stdout is 0 bytes on any decline (MEASURED; same for every
; reject fixture in this suite — cf. the note in lowering_loop_break_value.ll). A
; regression is still caught, by the positive CHECK failing against that empty stdout.
; CHECK-NOT: cqrt_toffoli
; CHECK-NOT: cqrt_copy_i32_controlled
; CHECK-NOT: cq.brk.rev
; CHECK-NOT: cqrt_free

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
; The frozen `_inv` twin — the real generated prototype, verbatim.
declare i32 @cq_template_and_i32_hl_inv(i32, i32) #0

define i32 @break_uninvertible(i32 %x, i32 %n) {
entry:
  %q0 = call i32 @cq_theta_si32(i32 %x, double 2.500000e-01)
  %guard = icmp sgt i32 %n, 0
  br i1 %guard, label %loop, label %exit

loop:                                             ; preds = %entry, %loop
  %i = phi i32 [ 0, %entry ], [ %inext, %loop ]      ; classical induction
  %q = phi i32 [ %q0, %entry ], [ %qn, %loop ]       ; tainted value-mutating rail
  %qn = xor i32 %q, 9                                ; value mutation (tainted)
  ; The break-cond chain's only non-compare link is an `_inv` twin: collected by
  ; `isBreakCondTemplate`, REJECTED by `isInverseEmittable`.
  %a0 = call i32 @cq_template_and_i32_hl_inv(i32 %qn, i32 1)
  %brk = icmp eq i32 %a0, 0                          ; TAINTED break flag
  %inext = add nuw nsw i32 %i, 1
  %bound = icmp eq i32 %inext, %n                    ; CLASSICAL loop bound
  %exit.cond = select i1 %brk, i1 true, i1 %bound    ; FUSED select(brk, true, bound)
  br i1 %exit.cond, label %exit, label %loop

exit:                                             ; preds = %loop, %entry
  %ans = phi i32 [ %q0, %entry ], [ %qn, %loop ]     ; value-class escaping answer
  %m = call i32 @cq_measure_si32(i32 %ans)
  ret i32 %m
}

; The frozen templates are pure reversible bodies; the loop recognizer's §B4 body
; purity fence (`mayHaveSideEffects`) requires that to be SPELLED on the declaration.
attributes #0 = { nounwind willreturn memory(none) }
