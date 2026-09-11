; control_inplace_ry_stateprep_condwire_alias_accept.ll — ACCEPT.
;
; THE FIXTURE THAT PINS **WHICH HELPER BUILDS `CondWire`**. The set is built by
; calling R4's own `railWireClosure` over `condProvenance(Region.Condition)`,
; and this file is the one shape in the corpus where that is not the same as
; `{Region.Condition} ∪ Prov`.
;
; OWNER RULING 2026-09-11, verbatim: *"WE DO NOT WANT TO WRITE `int b1`. also
; WE DO NOT WANT ANOTHER cq function. it should just be an application of gates
; … I dont see the need for the over-decline."* (bd `drbq.14`; F2's `CondWire`
; narrowing — a pinned value on the CONDITION'S OWN BACKWARD WIRE is no longer a
; collider.)
;
; THE SHAPE — a CHAINED theta between the pin and the condition:
;
;     %q = cq_theta(%u0, .5)        ; the taint root
;     %t = and %q, 0                ; a tainted value with a SINGLETON range {0}
;     %b = cq_theta(%t, .3)         ; CHAINED: `%b` and `%t` are ONE physical
;                                   ; rail (lowerRotations RAUWs both to one
;                                   ; handle)
;     %c = icmp eq %b, 5
;     if (%c) r = cq_theta(0, .9);  ; seed 0 — which is what `%t` is pinned to
;
; `condProvenance` STOPS AT A THETA (`if (isThetaCall(I)) continue;` — it
; collects the result and deliberately does not enter arg-0, so it cannot walk
; into a source theta's classical seed), so `Prov = {%b}` and `%t` is NOT in it.
; `railWireClosure` DOES cross that edge — a chained Ry is in place, same rail —
; so `CondWire = {%c, %b, %t}` and the pin on `%t` is excluded. `%t` and `%b`
; are the SAME REGISTER, so excluding it is exactly the rule, not a widening of
; it.
;
; ⚠ RED-GREEN, MEASURED 2026-09-11, and stated as TWO measurements because that
; is what it is. A deliberate mutant (M-W) builds `CondWire` as
; `{Region.Condition} ∪ Prov`, dropping both `railWireClosure` calls.
;   (i) On THIS module M-W reads rc=1 (DECLINE) where the shipped spelling reads
;       rc=0. So the `railWireClosure` calls are what accept it.
;   (ii) Over the state-prep family as it stood at that moment (109 files, before
;       this increment's 8 new ones) M-W reads **53 ACCEPT / 56 DECLINE** — the
;       shipped binary's split EXACTLY. So nothing ELSE in the tree moves, and
;       this module is the whole of the two spellings' difference.
; Together: the `railWireClosure` spelling is load-bearing and measurably so, and
; the Rule-14 "call R4's helper, never re-spell it" instruction is a verdict here
; rather than hygiene.
;
; ⚠ IT IS ALSO THE TRIPWIRE FOR A FUTURE NARROWING OF `condProvenance`. That
; function's own header already says narrowing it is a Rule-13 change to R4;
; since 2026-09-11 it is a Rule-13 change to **F2 as well**, and this fixture is
; where that shows up.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=ACNT    < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=FCNT    < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=XCNT    < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=RYCNT   < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=CCNT    < %t.cqd0.ll

; CHAINED-THETA RAIL HOP: the pin is on %t, which is in CondWire ONLY through
; railWireClosure (condProvenance STOPS at the theta and never enters arg-0).
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %t  = and i32 %q, 0
  %b  = call i32 @cq_theta_si32(i32 %t, double 3.000000e-01)
  %c  = icmp eq i32 %b, 5
  br i1 %c, label %arm, label %merge
arm:
  %rt = call i32 @cq_theta_si32(i32 0, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi i32 [ %rt, %arm ], [ 0, %entry ]
  %mb = call i32 @cq_measure_si32(i32 %b)
  %mr = call i32 @cq_measure_si32(i32 %rm)
  %s  = add i32 %mb, %mr
  ret i32 %s
}

; CHECK:      %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: %[[H_OP:[a-zA-Z0-9_.]+]] = call i32 @cq_template_and_i32_hl(i32 %[[H]], i32 0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H_OP]], double 3.000000e-01)
; CHECK-NEXT: %[[H_CMP:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[H_OP]], i32 5)
; CHECK-NEXT: %[[H1:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %[[H_CMP]], i32 %[[H1]], double 9.000000e-01)
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[H_CMP]], i32 %[[H_OP]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[H_CMP]])
; CHECK-NEXT: %[[M:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[H_OP]])
; CHECK-NEXT: %[[M2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[H1]])

; ------------------------------------------------------------------
; NEGATIVES — WHOLE-FILE AND PURE (no positive directive inside the
; NOROUTE prefix: a positive `-COUNT-n` WINDOWS every negative after
; it, the drbq Inc-4 round-1 lesson). The counts below are the
; injection matrix's answer: an extra uncontrolled `cqrt_ry` on the
; CONDITION register moves RYCNT, an extra `cqrt_free` moves FCNT, and
; a `_controlled` on the WRONG flag breaks the CHECK capture.
; NOROUTE-NOT: cqrt_cswap
; NOROUTE-NOT: cqrt_copy
; NOROUTE-NOT: _controlled_inv
; NOROUTE-NOT: _controlled_unc
; NOROUTE-NOT: = phi
; NOROUTE-NOT: cq_theta
; NOROUTE-NOT: cq_phi
; THE FREEZE: no `cqrt_free` may ever name the PREPPED rail.
; NOROUTE-NOT: call void @cqrt_free(i32 %h1)
; …and the arm gate must not become UNCONDITIONAL.
; NOROUTE-NOT: call void @cqrt_ry_i32(i32 %h1, double 9.000000e-01)

; ACNT-COUNT-2: call i32 @cqrt_alloc_
; ACNT-NOT:     call i32 @cqrt_alloc_
; FCNT-COUNT-1: call void @cqrt_free(
; FCNT-NOT:     call void @cqrt_free(
; XCNT-NOT:     call void @cqrt_x(
; RYCNT-COUNT-3: call void @cqrt_ry_
; RYCNT-NOT:     call void @cqrt_ry_
; CCNT-COUNT-1: call void @cqrt_ry_i32_controlled(
; CCNT-NOT:     call void @cqrt_ry_i32_controlled(

