; lowering_reject_break_uninvertible_cond_tail.ll — DECLINE (bd test_C_libtooling-zea5).
; THE MID-CHAIN axis of the break reverse-play invertibility pre-scan; read the full
; mechanism in its sibling `lowering_reject_break_uninvertible_cond.ll` (chain-head
; axis), which this fixture deliberately does not repeat.
;
; Here an INVERTIBLE link (`%a0 = and %qn, 1` → `cq_template_and_i32_hl`) PRECEDES the
; un-invertible `_inv` twin in the break-cond chain. It is the axis on which the
; pre-fix behaviour was at its worst: `emitInverseChain` walks in REVERSE program order
; and ANDs the per-link results, so it emitted nothing for the `_inv` link, then went
; on to emit `%a0`'s `_unc` — a genuinely HALF-REVERSED chain — and the discarded
; `false` let both members be freed anyway. `%a0`'s own free is the subtle one: it is
; sound only if `%a0` was recomputed from sources still holding their forward values,
; and the skipped link means it was not.
;
; WHAT IT PINS, stated exactly (the first draft of this header overclaimed and was
; corrected in the zea5 Rule-13 round): it pins that a MID-CHAIN un-invertible link
; declines rather than lowers. It does NOT discriminate a whole-chain pre-scan from a
; head-only one — MEASURED: with the `emitOneBreak` pre-scan deleted, or scanning only
; the chain head, this fixture still declines with the same message and rc, because
; `clearChainAndFree` reports the same verdict. Nothing at the lit layer can separate
; those two implementations; the two layers are deliberately over the SAME predicate.
;
; Same three properties as the sibling: `opt -verify` clean, stage 2b structurally
; unable to witness it (the loop-break slices run `--allow-unproven`), and the `_inv`
; prototype below is the real generated one, not a synthetic off-ABI declaration.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq loop lowering: break reverse-play cannot invert a lowered body gate
; DOCUMENTARY, and vacuous on this stream for the reason spelled out in the sibling
; (a `DS_Error` terminates `opt`, so `-S` stdout is 0 bytes on any decline): no
; half-reversed chain, and neither member freed.
; CHECK-NOT: cq_template_and_i32_hl_unc
; CHECK-NOT: cqrt_toffoli
; CHECK-NOT: cq.brk.rev
; CHECK-NOT: cqrt_free

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i32 @cq_template_add_i32_hl_inv(i32, i32) #0

define i32 @break_uninvertible_tail(i32 %x, i32 %n) {
entry:
  %q0 = call i32 @cq_theta_si32(i32 %x, double 2.500000e-01)
  %guard = icmp sgt i32 %n, 0
  br i1 %guard, label %loop, label %exit

loop:                                             ; preds = %entry, %loop
  %i = phi i32 [ 0, %entry ], [ %inext, %loop ]      ; classical induction
  %q = phi i32 [ %q0, %entry ], [ %qn, %loop ]       ; tainted value-mutating rail
  %qn = xor i32 %q, 9                                ; value mutation (tainted)
  %a0 = and i32 %qn, 1                               ; INVERTIBLE link (lowers to _hl)
  %a1 = call i32 @cq_template_add_i32_hl_inv(i32 %a0, i32 3)  ; un-invertible, MID-chain
  %brk = icmp eq i32 %a1, 0                          ; TAINTED break flag
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
