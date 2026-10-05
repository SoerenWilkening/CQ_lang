; lowering_reject_uncompute_uninvertible_taped.ll — DECLINE. THE MECHANISM FIXTURE
; for the bd 261j(a) record freeze: it does not pin a physics claim, it pins WHERE
; the freeze is allowed to act.
;
; This is `lowering_uncompute_uninvertible.ll`'s shape (a `cqrt_cnot` primitive the
; spine has no adjoint for, feeding a dead `cq_template_add` terminal) PLUS a tape
; write on that terminal. The tape write makes the terminal RECORDED, so the freeze
; engages on this module — and the module must STILL decline loudly, with `opt`
; exiting non-zero and the message unchanged.
;
; WHY THIS MATTERS. The freeze is recorded as a `FrozenRails` set on the recovered
; DAG and consumed ONLY at emission (`Uncomputation::emitDagReversal`). It is very
; tempting to implement it instead by PRUNING the frozen gates out of `D.Calls`
; inside `recoverDataDag` — that also happens to make `D.Calls.empty()` do the bail
; for free. Do not: THREE conservative scans iterate `D.Calls` after recovery and
; before emission — the invertibility pre-scan (this message), the InLoop acyclic
; backstop, and the dominance scan (`…spans divergent control-flow arms`). A prune
; blinds all three, and this module — which the compiler currently REFUSES — would
; start compiling rc=0 with un-reversed garbage in it (MEASURED during the bd
; 261j(a) analysis: the prune variant accepts rc=0, and a "generous" prune even
; emits a partial reversal).
;
; The same argument rules out the blunt DAG-global alternative (`D.NotClosed = true`
; at the output-sink site): `NotClosed` returns UPSTREAM of all three scans, so it
; silently disarms this decline too. That outcome is still a safe LEAK rather than a
; miscompile — but a module that will not compile today would start compiling, and
; the diagnostic Rule 12 pins would be gone. Hence: subtractive, at emission, only.
;
; SIBLINGS that make the same point on the other two scans:
;   lowering_reject_uncompute_divergent_arm_taped.ll   (the dominance scan)
;   lowering_reject_uncompute_premeasure_taped.ll      (the measured-lineage reject;
;     an ACCEPT since bd ptue, which borrows the measured rail read-only)
;
;
; VEHICLE-OP NOTE (bd test_C_libtooling-6uqc, M-C Increment 2a — `add` only).
; The `cq_template_*` terminal below is built with `mul`, not `add`, and that is
; load-bearing since M-C: a dead-parent `q + c` now lowers to the VOID in-place
; `cqrt_addc_<W>`, which mints NO rail — so with `add` there would be no data
; producer for `Uncomputation` to select as a terminal, no DAG would be
; recovered, and this file's decline would silently stop firing (measured: `opt`
; exit 0, nothing emitted, nothing reversed — a Rule-6 SAFE LEAK, but the probe
; would be dead). `mul` is information-losing and therefore outside the dtzb
; in-place bijection family at every batch, so it keeps minting the rail this
; probe needs. The un-invertible primitive under test is unchanged.
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cqrt_cnot(i32)
declare i32 @printf(ptr, ...)
@.str = private constant [3 x i8] c"%d\00"

define void @slice(i32 %x) {
entry:
  %q   = call i32 @cq_theta_si32(i32 %x, double 2.500000e-01)
  %bad = call i32 @cqrt_cnot(i32 %q)             ; un-invertible primitive (no _unc form)
  %t   = mul i32 %bad, 7                          ; cq_template terminal off %bad
  %r   = call i32 (ptr, ...) @printf(ptr @.str, i32 %t)  ; RECORDED onto the kept tape
  ret void
}

; CHECK: error{{.*}}cq uncompute: dead chain contains an un-invertible primitive
