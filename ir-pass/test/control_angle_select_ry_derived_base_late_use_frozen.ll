; control_angle_select_ry_derived_base_late_use_frozen.ll — ACCEPT, and it is the
; FREEZE probe (bd drbq Inc 2b; Inc-1 finding L, the CONFIRMED silent miscompile
; that shipped through a green suite).
;
;     int p = 7; cq_theta(&p,.25); int r = p * 5;
;     cq_theta(&r, q == 5 ? .9 : .3);
;     int s = r + 1; ... cq_measure(s);
;
; A register a `cqrt_{ry,rz}_<W>_controlled` fired on is FROZEN: never
; reverse-played, never freed by the whole-DAG spine. A controlled gate's adjoint
; needs its CONTROL, and the flag is stripped and freed inside this very stream —
; so a spine that reversed after the rail's final user would emit an adjoint
; naming a FREED flag and then `cqrt_free` a still-dirty, condition-entangled
; register (Rules 6/8).
;
; 2b ADDS NO CODE FOR THE FREEZE, AND THIS FIXTURE IS WHY THAT CLAIM IS MEASURED
; RATHER THAN ARGUED. Since the Inc-1 round-1 fix the freeze is asked
; STRUCTURALLY of the emitted gate (`ChainWalk::railCarriesControlledRotation`
; derives the rail from the gate's own arg-1 USE), not from a recorded
; `Value *` — which is exactly what a DERIVED base breaks: `%r = mul %p, 5` is a
; raw LLVM instruction that `lowerOps`, the very NEXT stage, RAUWs to a
; `cq_template_mul_i32_hl` result and ERASES. Inc 1 shipped the recorded form and
; the set dangled.
;
; The shape here is the mul-derived base WITH a late use (`s = r + 1` read after
; the gate), i.e. the finding-L reproducer with the diamond replaced by an angle
; select. The M-A live-record WARNING fires once per non-diagonal gate on the
; derived rail — twice (the two X-bracketed controlled gates, bd dm7f.6), exactly
; as for the if/else spelling. It is a `DS_Warning`; `opt` still exits 0.
; ORACLE DISPOSITION: RED on the pre-2b binary (`rotation angle under quantum
; control`, SelectClassify gate 3) — Rule 12 red-green.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=CNT     < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
; 3qlq: migrated from register cq_phi (dead declare erased)

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %u1) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %p = call i32 @cq_theta_si32(i32 %u1, double 2.500000e-01)
  %r = mul i32 %p, 5
  %c = icmp eq i32 %q, 5
  %ang = select i1 %c, double 9.000000e-01, double 3.000000e-01
  %t = call i32 @cq_theta_si32(i32 %r, double %ang)
  %s = add i32 %t, 1
  %mq = call i32 @cq_measure_si32(i32 %q)
  %ms = call i32 @cq_measure_si32(i32 %s)
  %x = add i32 %mq, %ms
  ret i32 %x
}

; THE CONDITION REGISTER, ANCHORED AT ITS OWN ALLOC and never on a line of the
; stream under test (round-2 Rule-13 review, lens R2 N1 — see the note at the mint
; below for what stayed green without this).
; CHECK:      %[[QC:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[QC]], double 5.000000e-01)
; CHECK:      %[[P:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u1)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[P]], double 2.500000e-01)
; the DERIVED base: a fresh template rail, and the value the Inc-1 freeze used to
; be keyed on before `lowerOps` erased it
; CHECK-NEXT: %[[RB:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32_hl(i32 %[[P]], i32 5)
; the CONDITION REGISTER: `%[[QC]]` was ANCHORED above at its own `cqrt_alloc`,
; so the mint and the strip must both name THAT rail — not merely the same one as
; each other (round-1 Rule-13 review L6-N3 closed mint-vs-strip DISAGREEMENT; the
; round-2 one, lens R2 N1, found that a CONSISTENTLY wrong condition rail — both
; lines rewritten to read the ROTATED register — still passed, because `%[[QC]]`
; was first bound HERE, on a line of the stream under test. On the Ry stem that
; mutant is also a Rule-6 hazard: the controlled Ry between mint and strip
; relabels the very rail being compared, so the strip does not recompute the
; predicate the mint read, the flag does not return to |0> and its `cqrt_free` is
; a hidden measurement).
; CHECK-NEXT: %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[QC]], i32 5)
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %[[F]], i32 %[[RB]], double 9.000000e-01)
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %[[F]], i32 %[[RB]], double 3.000000e-01)
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F]], i32 %[[QC]], i32 5)
; the FLAG is freed (it is provably |0> after the strip) …
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
; … and the late in-place use lands on the SAME derived rail
; CHECK-NEXT: call void @cqrt_addc_i32(i32 %[[RB]], i32 1)
; A STRAY ROTATION AFTER THE EMITTED STREAM was invisible to every one of the 17
; accept fixtures (round-1 Rule-13 review, L6-N11): an adjacency chain stops at
; its last `CHECK-NEXT`, and a `NOROUTE`-style whole-body negative cannot be used
; on a rotation symbol because the legitimate twin and gate are rotations. A
; TRAILING `CHECK-NOT` runs from the last match to EOF, which is exactly the
; uncovered region — and it is where a leaked rotation on a FROZEN rail would sit.
; CHECK-NOT: call void @cqrt_ry_
; CHECK-NOT: call void @cqrt_rz_

; THE FREEZE, AS ASSERTIONS. No adjoint of either Ry, no adjoint of the
; mul that produced the derived rail, and NO free of that rail — it is left
; ALLOCATED, which is Rule 6's leak-rather-than-dirty-free fallback.
;
; EACH NEGATIVE NAMES A SPELLING THE SPINE WOULD ACTUALLY EMIT (round-1 Rule-13
; review, lenses L6-N2 / L3-2, measured on lens L3's `derived_mutA`: a negative
; on a value nothing emits stays green under the HALF-REVERSAL mutation, the spine
; reversing one gate but not another). Under the X-bracket route (bd dm7f.6)
; every source angle here is positive, so any adjoint carries a negative angle
; and the whole-function `double -` negative pins all of them.
; NOROUTE:     define{{.*}}@example
; NOROUTE-NOT: double -
; NOROUTE-NOT: cq_template_mul_i32_hl_unc
; NOROUTE-NOT: call void @cqrt_cswap
; NOROUTE-NOT: select

; EXACTLY ONE free in the whole function: the flag.
; CNT-COUNT-1: call void @cqrt_free(
; CNT-NOT:     call void @cqrt_free(
