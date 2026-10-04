; control_reject_measure_classical_in_arm.ll — DECLINE, and a BOUNDARY PIN for bd
; test_C_libtooling-21mg verdict (c): a CLASSICAL `cq_measure` inside a TAINTED
; region's value arm. 21mg lowers a classical measure to its operand wherever
; `lowerMeasures` sees it; this fixture pins that the widening did NOT leak into
; the region classifier, which still refuses the construct BEFORE `lowerMeasures`
; ever runs.
;
; SOURCE INTENT (probe `trackC/probes/c7_measure_in_arm.c`, its `-O1` `main`
; transcribed without the dbg metadata):
;     int a = 5; bool b0 = 0; int c = 3;
;     if (a >= 3) { cq_theta(&b0, 0.5); }   // folded away: a >= 3 is constant
;     if (b0 == 1) { a = cq_measure(c); }       // a CLASSICAL measure, under control
;     return a + cq_measure(b0);
;
; MEASURED, BOTH BINARIES, IDENTICAL (2026-09-13): `cq controlled lowering:
; value-arm swap-route under quantum control`, from `classifyArms` —
; `emitValueRegion` must HOIST the arm's chain into the pred and a `cq_measure`
; call is not a hoistable pure op. Unchanged by 21mg by ORDER: the first
; `DS_Error` terminates the process (`LLVMContext::diagnose` → `exit(1)`), and
; this one fires in `detectControlRegions`, long before `lowerMeasures`.
;
; ⚠ THE DECLINE STRING NAMES A RETIRED MECHANISM ("swap-route", bd OQ-13) and is
; nonetheless the correct, loud verdict — see CLAUDE.md CORRECTNESS RISK §2.
;
; ⚠ RETIREMENT TRIGGER / OPEN OVER-DECLINE. For a measure of a TAINTED handle the
; refusal is a Rule-5 unitary hazard (hoisting it would measure on the inactive
; branch — `control_swap_reject_measure_in_arm.ll`). For a CLASSICAL one the hoist
; is INERT under 21mg (it emits no gate, no rail and no trace line), so this is a
; candidate over-decline, filed from this session rather than fixed here (21mg's
; scope is `MeasureLowering.cpp` only, and admitting it means teaching the ARM
; classifier about a disposition `lowerMeasures` has not yet computed — the L1
; round-2 hazard in miniature). If a later increment admits it, this file becomes
; an ACCEPT whose emitted stream has the classical 3 flowing into the value arm's
; hoisted chain; re-derive it then, do not delete it.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s --check-prefix=NOGATE
declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)
declare i32 @cq_measure_si32(i32)

define i32 @example() {
entry:
  %q = call i1 @cq_theta_i1(i1 false, double 5.000000e-01)
  br i1 %q, label %arm, label %merge

arm:
  %mc = call i32 @cq_measure_si32(i32 3)   ; a CLASSICAL measure under quantum control
  br label %merge

merge:
  %y = phi i32 [ %mc, %arm ], [ 5, %entry ]
  %mq = call i1 @cq_measure_i1(i1 %q)
  %z = zext i1 %mq to i32
  %r = add nsw i32 %y, %z
  ret i32 %r
}

; CHECK: error{{.*}}cq controlled lowering: value-arm swap-route under quantum control

; Rule 12 (b): the property is pinned by the `not` on the RUN line; these name
; what a regression did. Nothing may be emitted for the region — in particular no
; controlled copy merge built on a measure the emitter cannot hoist.
; NOGATE-NOT: cqrt_copy_i32_controlled
; NOGATE-NOT: cqrt_measure_
