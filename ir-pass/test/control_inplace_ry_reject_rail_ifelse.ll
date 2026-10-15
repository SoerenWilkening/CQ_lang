; control_inplace_ry_reject_rail_ifelse.ll — DECLINE: a TWO-ARM if/else with a
; rotation in EACH arm, under a bare `_Bool` (rail-root) condition.
;
; UNREACHABLE FROM PLAIN C — `-O1` (SimplifyCFG) merges two rotation arms into
; ONE `cq_theta` call whose ANGLE is a tainted-condition `select`, which is
; `classifyAngleSelect`'s Ry stem and is sub-increment **l4x4.a**, a separate
; increment. So this is a hand-IR shape and the decline is a SCOPE boundary.
; ⚠ bd test_C_libtooling-fmt3 (2026-09-28): NO LONGER UNREACHABLE FROM PLAIN C. With
; `nomerge` on every `cq_theta_*` (CQ.h) the two arms are not merged, so
; `bool b = …; if (b) cq_theta(&r,A); else cq_theta(&r,B);` arrives as this
; if/else and declines here with the SAME string it got at the l4x4.a gate before
; (`fmt3_probes/src/n23.c`, measured on both headers).
;
; WHY IT IS NOT FREE. l4x4.b's answer to anti-control is Ry ADDITIVITY —
; `ry(h,θ); cry(h_b,h,−θ)` — argued and pinned for ONE content arm. For two the
; stream becomes `ry(h,B); cry(h_b,h,−B); cry(h_b,h,A)`: three gates, a different
; emission order, and a different M-β RAUW target (`Gates.back()` must still be
; the LAST gate in the stream). That is a real emission change and owes its own
; adversarial round, not an extra `if` in this one.
;
; The string is `bare i1 register condition` because the refusal is about the
; CONDITION KIND — a compare-conditioned if/else with two rotation arms lowers
; today and is unaffected.;
; ---- §2.6, THE PER-ARM-CLASS RE-DECLINE, AND WHY IT IS NOT RED-GREEN ---------
;
; This file declines with the SAME STRING on `main` 0c7380c, on the F2 checkpoint
; and here — but for DIFFERENT REASONS, and the difference is the whole point.
; Before l4x4.b every rail-condition region died at `classifyArms`' FIRST GATE;
; now the gate admits the rail and runs the §13.3 ladder, and this arm class is
; refused at its own ACCEPT SITE instead. Widening a gate that six arm classes
; share and re-declining only at the end would hand the other five an accept
; nobody cleared them for (hazard H-8), which is exactly the shape the file's own
; `SawRotationArm` comment records as having been wrong once already ("Luck is
; not a fence").
;
; THE DISCRIMINATOR IS THE RECORDED MUTATION, not a second binary: delete this
; class's `if (RailCond) return declineRailClass();` and the region is ACCEPTED
; by `classifyArms`, whereupon `emitRegion`'s rail dispatch refuses it with
; `control flow` — a DIFFERENT string, from a DIFFERENT layer. The fence is
; therefore load-bearing and the emitter backstop is the second line of defence,
; not the first.
;
; ⚠ FLIPPED TO AN ACCEPT BY bd test_C_libtooling-dm7f.54 (2026-10-15), NAME KEPT
; (gahu precedent, L8). Neither spelling the paragraphs above weigh was built:
; the additivity chain `ry(h,B); cry(b,h,−B); cry(b,h,A)` reads `B` twice and
; puts `Ry(B)Ry(−B)` on the `b = 1` branch, which the owner ruling
; `owner-ruling-angle-select-xbracket-2026-10-13` retired for the angle select.
; The two-arm rail region instead takes a CNOT COPY flag (`CondTreeEmit`'s
; `CopyRailRoot`) and the compare path's X-bracket form on it — the ruling's
; stream, byte-identical to the ternary twin
; `control_angle_select_reject_rail_ry.ll` (also flipped):
;   bf = |0>; cnot(c, bf); ry_c(bf, r, .9); x(bf); ry_c(bf, r, .3); x(bf);
;   cnot(c, bf); free(bf)
; ANALYTIC: c = 1 -> Ry(.9) on r, c = 0 -> Ry(.3) on r; each angle in ONE gate;
; c is read only in the two cnot control slots and is never freed. The M-β RAUW
; targets the last hoisted gate (the else arm's), as on the compare path.
; The ONE-arm rail region keeps the additivity form (byte-unchanged).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
; RUN: %filecheck %s --check-prefix=NEG < %t.ll

declare i1 @cq_theta_i1(i1, double)
declare i32 @cq_theta_si32(i32, double)
declare i1 @cq_measure_i1(i1)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u1) {
entry:
  %c = call i1 @cq_theta_i1(i1 false, double 1.100000e+00)
  %r = call i32 @cq_theta_si32(i32 %u1, double 3.000000e-01)
  br i1 %c, label %armt, label %armf
armt:
  %rt = call i32 @cq_theta_si32(i32 %r, double 9.000000e-01)
  br label %merge
armf:
  %rf = call i32 @cq_theta_si32(i32 %r, double 3.000000e-01)
  br label %merge
merge:
  %rm = phi i32 [ %rt, %armt ], [ %rf, %armf ]
  %mc = call i1 @cq_measure_i1(i1 %c)
  %zc = zext i1 %mc to i32
  %mr = call i32 @cq_measure_si32(i32 %rm)
  %s  = add i32 %mr, %zc
  ret i32 %s
}

; CHECK:      %[[C:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_ry_i1(i32 %[[C]], double 1.100000e+00)
; CHECK-NEXT: %[[R:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u1)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[R]], double 3.000000e-01)
; CHECK-NEXT: %[[F:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_cnot(i32 %[[C]], i32 %[[F]])
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %[[F]], i32 %[[R]], double 9.000000e-01)
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %[[F]], i32 %[[R]], double 3.000000e-01)
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cqrt_cnot(i32 %[[C]], i32 %[[F]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
; CHECK:      call i1 @cqrt_measure_i1(i32 %[[C]])
; CHECK:      call i32 @cqrt_measure_i32(i32 %[[R]])
; CHECK-NOT:  call void @cqrt_free(

; NEG-NOT: br i1
; NEG-NOT: phi
; NEG-NOT: cq_theta_
