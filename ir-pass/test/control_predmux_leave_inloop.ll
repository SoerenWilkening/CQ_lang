; control_predmux_leave_inloop.ll — ⚠ THE FILENAME IS NOW HALF WRONG AND IS KEPT
; ON PURPOSE (CLAUDE.md L8 / bd `gahu`: a `git mv` of a fixture can be
; resurrected by a merge; rename it in a change that does nothing else).
;
; STILL A LOUD DECLINE — the DISPOSITION is unchanged and that is what this
; fixture has always been for. What moved, at bd test_C_libtooling-fn1q
; increment 3 (E2's in-loop admission, 2026-09-18), is WHICH OWNER refuses it,
; and therefore the message.
;
; BEFORE: PredMux left the region at `gate=E2-cycle` because a region block sat
;   on a CFG cycle, and `ControlDetect` then declined `nested control flow under
;   quantum control`.
; NOW:  E2 admits a region lying strictly inside one loop body, so the
;   `%loop` -> `%mid` -> `%arm` -> `%latch` nest IS claimed and flattened —
;   and the LOOP LAYER refuses what is actually wrong with this program:
;   `%acc` is a tainted value that crosses the back edge and is rewritten in
;   place every trip, the (b)/(b') loop-carried rail shape the in-loop collapse
;   does not claim.
;
; ⚠ THE NEW MESSAGE IS THE MORE ACCURATE ONE, and this is the same correction
; `control_predmux_leave_fp_diamond_inloop.ll` carried through bd 8h7d.5: the
; nesting was never why this program is refused. Nothing is lowered — `opt`
; exits non-zero and `LLVMContext::diagnose` exits on the first `DS_Error`
; (bd `br4a`), so no module is written at all; the negatives below are pinned by
; the `not` inversion on the RUN line, not by the absence of text in an empty
; stdout (CLAUDE.md Rule 12 (b)).
;
; ⚠ WHAT A REVIEWER SHOULD CHECK HERE FIRST: that this is a decline and not an
; accept. An E2 widening's whole risk is that a claim MASKS a fence that used to
; fire, and this module is the closest thing in the corpus to that shape — a
; multi-arm tainted nest around a loop-carried tainted accumulator. It still
; declines, at a different and stricter owner.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
;
; CHECK: error{{.*}}cq loop lowering: loop-carried tainted value crosses iterations
; CHECK-NOT: cqrt_copy
; CHECK-NOT: cqrt_alloc
; CHECK-NOT: cqrt_free
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.0e-01)
  br label %loop
loop:
  %i = phi i32 [ 0, %entry ], [ %inext, %latch ]
  %acc = phi i32 [ %q, %entry ], [ %rm, %latch ]
  %c1 = icmp sgt i32 %acc, 5
  br i1 %c1, label %mid, label %latch
mid:
  %v1 = add i32 %acc, 1
  %c2 = icmp slt i32 %acc, 9
  br i1 %c2, label %arm, label %latch
arm:
  %v2 = xor i32 %acc, 3
  br label %latch
latch:
  %rm = phi i32 [ %acc, %loop ], [ %v1, %mid ], [ %v2, %arm ]
  %inext = add i32 %i, 1
  %cl = icmp slt i32 %inext, 3
  br i1 %cl, label %loop, label %exit
exit:
  %m = call i32 @cq_measure_si32(i32 %rm)
  ret i32 %m
}
