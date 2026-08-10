; lowering_reject_uncompute_exclusive_arm_sink.ll — NEGATIVE (Phase 5 §2.4). The
; DECLINE that comes with the bd 8gi5(3)/e4zs preserving-sink anchors, pinned
; because it is a REGRESSION IN EXPRESSIVENESS and the safe direction is not an
; excuse for leaving it undocumented (Rule 12: every accept-predicate change ships
; a decline fixture).
;
; THE SHAPE. The recovered gate `%b = %a + 2` lives in arm `%A`; the preserving read
; `cqrt_tape_write_i32(%tape, %a)` lives in the mutually EXCLUSIVE arm `%B`. They can
; never both execute, so HEAD's placement of the reversal inside `%A` was already
; correct — there is no use-after-free on this input to fix. MEASURED: HEAD 1ec8c45
; compiles it rc=0.
;
; WHY IT NOW DECLINES. The anchor fold is unconditional: `%B`'s sink joins the anchor
; set, `dagInsertPoint` drags the common post-dominator down to the merge `%m`, and
; the every-gate-dominates-`At` scan then fails on the `%A` gate. The pass has no
; mutual-exclusion analysis, so it cannot tell "this sink can never run alongside
; these gates" from "this sink reads a rail these gates own".
;
; WHY THAT IS THE RIGHT TRADE, stated rather than assumed. Over-declining is safe and
; over-accepting is a silent miscompile (the Prime Directive), and the alternative —
; admitting an anchor only when it can co-execute with the gates — is a
; path-sensitivity analysis whose failure mode is exactly the use-after-free the
; anchors exist to prevent. The cost is one accepted shape; the benefit is that a
; preserving read can never be left unaccounted for. Filed as a widening candidate,
; not fixed here.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cqrt_tape_alloc()
declare i32 @cqrt_tape_write_i32(i32, i32)

define void @excl_arm(i32 %u0, i1 %c) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %a = add i32 %q, 1
  %tape = call i32 @cqrt_tape_alloc()
  br i1 %c, label %A, label %B

A:                                        ; the recovered gates + the dead terminal
  %b = add i32 %a, 2
  br label %m

B:                                        ; the preserving read — mutually exclusive
  %w = call i32 @cqrt_tape_write_i32(i32 %tape, i32 %a)
  br label %m

m:
  ret void
}

; Mirrored CHARACTER-FOR-CHARACTER from Uncomputation.cpp's kMsgDivergentArm so code
; and fixture cannot drift (Rule 12):
; CHECK: cq uncompute: dead chain spans divergent control-flow arms
