; control_classical_call_arm_reject_opaque_callee.ll — TOTALITY reject (bd wve8):
; the 6.5 classical-call arm refuses a callee that is PURE but whose BODY IS NOT
; VISIBLE, because purity is not totality and an opaque declaration carries no
; evidence of either.
;
; THIS IS THE SHAPE THAT MISCOMPILED, reduced from the reproduced end-to-end
; crash. In C:
;     __attribute__((const)) int recip100(int x);   /* body in another TU:
;                                                      return 100 / x;      */
;     int q = cq_theta_si32(0, 0.0);                /* Ry(0) = identity     */
;     int y = q;
;     if (q > 3) y = recip100(0);
;     return cq_measure_si32(y);
; `cq_theta(_, 0.0)` is Ry(0) = IDENTITY, so `q == 0` on every basis state and the
; predicate `q > 3` has ZERO AMPLITUDE: the source NEVER evaluates `recip100(0)`,
; on any component, and has no UB anywhere. `__attribute__((const))` grants exactly
; `memory(none) nounwind willreturn`, which is what the OLD gate asked for and what
; `@opaque_pure_f` below carries — so the arm was claimed, the call was HOISTED
; above the flag mint, and the compiled program called it UNCONDITIONALLY and
; SIGFPEd (run_exit=136) with `opt` exit 0, the in-process verifier clean and
; `free_pairing_check.py` reporting 1 verified / 0 violations / 0 unproven. The
; crash is the LOUD form; the silent form is the same defect with a callee that
; returns garbage instead of trapping, route-merged into `%out` by
; `cqrt_copy_i32_controlled` where no gate in the tree can see it.
;
; `mayHaveSideEffects()` is `mayWriteToMemory() || mayThrow() || !willReturn()` —
; IMMEDIATE UB INSIDE THE CALLEE IS NONE OF THOSE. The gate now additionally
; demands a TOTALITY proof: `isSafeToSpeculativelyExecute` (LLVM's own answer, the
; `speculatable` attribute) or `isSpeculatablePureCallee` (the in-tree body walk).
; An opaque declaration satisfies NEITHER and can satisfy neither, so it DECLINES
; loudly and lowers nothing (Prime Directive).
;
; ARM-KILL: add `speculatable` to attribute group `#0` below, changing nothing
; else, and the module ACCEPTS (verified in both directions). The committed
; partner control_classical_call_arm_accept_speculatable_decl.ll is that same
; edit plus a different callee name and its own CHECK lines — it is the arm-kill
; made permanent, not a byte-for-byte copy. The pair is what proves this decline
; is the TOTALITY gate and not the purity gate, the arm shape, or the declaration
; as such.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}control flow under quantum control
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

; the call-site attribute set clang gives `__attribute__((const)) int recip100(int);`
; — pure by every measure the old gate had, and TOTAL by none.
declare i32 @opaque_pure_f(i32) #0

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 0.000000e+00)
  %c = icmp sgt i32 %q, 3
  br i1 %c, label %arm, label %merge
arm:
  %r = call i32 @opaque_pure_f(i32 0)   ; the argument the source shields
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
; CHECK-NOT over this stream can never match under ANY behaviour of the gate —
; it would read as a second, independent assertion while asserting nothing. The
; decline is fully pinned by `not` (the exit code) plus the message above.
