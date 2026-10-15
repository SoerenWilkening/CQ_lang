; control_swap_select_rail_fp_data.ll — ACCEPT (bd test_C_libtooling-r9e5, Inc
; 1b-B.1): the kjd1 fp-DATA copy family under a rail condition — `b ? 1.5 : 2.5`
; whose sole consumer is a `cq_measure_f64` DATA sink, never a rotation's arg-1
; angle. Gate 3 (the §3.2 angle BLOCKER) runs BEFORE gate 4 and is what makes
; this safe; gate 4 then takes the `abiWidthHasControlledFpCopy` arm and the
; merge mints `cqrt_copy_f64_controlled` from the select-local
; `copyControlledFpFn`. The rail changes NOTHING about that decision — it is a
; question about the select's RESULT TYPE and its ARM OPERANDS, never about the
; condition — which is exactly why gates 4/5/6 are untouched by 1b-B.1.
; bd test_C_libtooling-r9e5 (Inc 1b-B.1) — THE 4.4 DATA SELECT ON A BARE RAIL.
; `_Bool b = b0; cq_theta(&b, θ)` is a one-qubit REGISTER; `int a = b ? T : F` hands
; the pass `select i1 %b, …` with no compare to mint a flag from. The merge
; stream is the shipped §5a controlled-XOR copy merge, INSTRUCTION FOR
; INSTRUCTION — what changes is only where the FLAG comes from: a fresh |0> i1
; ancilla `bf` with `cqrt_cnot(h_b, bf)` copying the register's basis label into
; it (`CondTreeEmit`'s `CopyRailRoot`), un-copied and freed by the LIFO strip.
;
; WHY A COPIED ANCILLA AND NOT THE REGISTER ITSELF (the decision, PRD §14.2):
; step 4 must fire the second copy on `¬flag`, and the project's only spelling of
; that is a self-inverse `cqrt_x` bracket. A rail root is the USER'S REGISTER and
; may never carry a `cqrt_x` — bd memory [diagonal-only-on-user-registers-3qlq4]:
; `Uncomputation::preservesBorrowedParent` admits an uncontrolled `cqrt_rz_` BY
; NAME and fails CLOSED on anything else (a bracket would freeze and leak every
; chain that borrows the register), `ChainWalk::isInPlaceGateOn` never recovers a
; `cqrt_x`, and every `ArmClassify` wire fence argues from "no non-diagonal gate
; on any condition register". The phase path escaped this with the DIAGONAL
; identity `X·P(θ)·X = e^{iθ}·P(−θ)`; a controlled basis COPY has no diagonal
; form for its ¬-half, so the flag is copied out instead. Both gates that touch
; the register are `cqrt_cnot(h_b, ·)` with it at arg 0 — a READ-ONLY control,
; the same gate class the Inc-1b nest already puts on a rail.
;
; UNITARY (analytic, Rule 2 — `opt -verify` proves nothing here): after
; `cnot(b,bf)` the pair is `Σ α_x |x⟩_b |x⟩_bf`; `copy_c(bf,T,out)` writes T iff
; x=1 and the X-bracketed `copy_c(bf,F,out)` writes F iff x=0, so `out = b?T:F`
; with ONE write per basis branch; `b` is untouched throughout (the copies write
; `out`, the brackets act on `bf`), so the second `cnot(b,bf)` returns `bf` to
; `x ⊕ x = 0` on EVERY branch and its `cqrt_free` is a proven-|0> free (Rule 6).
; The register, `%out` and both sources are LEFT ALLOCATED (Rules 6/8).

; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=ORD < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOX < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOUNC < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=XCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=FCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=CNCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=CPCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=RYCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=ACNT < %t.cqd0.ll

declare void @cq_phi(double)
declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)

define double @example(i1 %u0) {
entry:
  %b = call i1 @cq_theta_i1(i1 %u0, double 5.000000e-01)
  %d = select i1 %b, double 1.500000e+00, double 2.500000e+00
  %n = call double @cq_measure_f64(double %d)
  %m = call i1 @cq_measure_i1(i1 %b)
  %z = uitofp i1 %m to double
  %r = fadd double %n, %z
  ret double %r
}

; CHECK:      %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 %u0)
; CHECK-NEXT: call void @cqrt_ry_i1(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: %[[BF:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_cnot(i32 %[[H]], i32 %[[BF]])
; CHECK-NEXT: %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_f64(double 0.000000e+00)
; CHECK-NEXT: call void @cqrt_xorc_f64_controlled(i32 %[[BF]], i32 %[[OUT]], double 1.500000e+00)
; CHECK-NEXT: call void @cqrt_x(i32 %[[BF]])
; CHECK-NEXT: call void @cqrt_xorc_f64_controlled(i32 %[[BF]], i32 %[[OUT]], double 2.500000e+00)
; CHECK-NEXT: call void @cqrt_x(i32 %[[BF]])
; CHECK-NEXT: call void @cqrt_cnot(i32 %[[H]], i32 %[[BF]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[BF]])

; THE ¬flag BRACKET SCOPE is order-sensitive and verify-clean-invisible (§16.3):
; a mis-bracket (x before BOTH copies) has the IDENTICAL symbol multiset and
; computes `out = f ? 0 : (a^b)`. Pin copy -> x -> copy -> x, and pin the two
; `cqrt_cnot` around the whole thing (mint FIRST, strip LAST — the LIFO the
; ancilla's |0> free depends on).
; ORD: call void @cqrt_cnot(
; ORD: call void @cqrt_xorc_f64_controlled(
; ORD: call void @cqrt_x(
; ORD: call void @cqrt_xorc_f64_controlled(
; ORD: call void @cqrt_x(
; ORD: call void @cqrt_cnot(
; ORD: call void @cqrt_free(

; ---- Whole-file negatives, each in its OWN pure-negative prefix (a positive
; line inside one WINDOWS every negative after it — the Inc-4 F-L6-1 lesson).
; NOROUTE-NOT: cqrt_cswap
; NOROUTE-NOT: cqrt_rz{{.*}}_controlled
; NOROUTE-NOT: cqrt_ry{{.*}}_controlled
; NOROUTE-NOT: call void @cq_phi(
; NOROUTE-NOT: cq_phi_
; NOROUTE-NOT: call void @cqrt_rz_
; NOROUTE-NOT: call i1 @cq_theta_i1(
; NOROUTE-NOT: cq_template_
; NO `cqrt_x` ON A USER REGISTER, EVER — the whole reason the flag is a copied
; ancilla and not the rail itself. The register handle is named below because a
; pure-negative prefix cannot bind a capture; it is DERIVED from the pass output.
; NOX-NOT: call void @cqrt_x(i32 %h)
; A rail condition mints NO compare, so it strips NOTHING: there is no `_unc`
; anywhere, and a data `_unc` here would mean the spine adjointed a chain the
; controlled copy entangled with `%out` (Rules 6/8).
; NOUNC-NOT: _unc(
; XCNT-COUNT-2: call void @cqrt_x(
; XCNT-NOT:     call void @cqrt_x(
; FCNT-COUNT-1: call void @cqrt_free(
; FCNT-NOT:     call void @cqrt_free(
; CNCNT-COUNT-2: call void @cqrt_cnot(
; CNCNT-NOT:     call void @cqrt_cnot(
; (bd dm7f.81: a constant or classical merge arm is a literal operand of cqrt_xorc_<W>_controlled, no longer an alloc'd rail + cqrt_copy_<W>_controlled; a zero arm emits no gate and no bracket. Counts below re-measured.)
; CPCNT-NOT: call void @cqrt_copy_f64_controlled(
; CPCNT-COUNT-2: call void @cqrt_xorc_f64_controlled(
; CPCNT-NOT: call void @cqrt_xorc_f64_controlled(
; CPCNT-NOT:     call void @cqrt_copy
; RYCNT-COUNT-1: call void @cqrt_ry_
; RYCNT-NOT:     call void @cqrt_ry_
; ACNT-COUNT-3: call i32 @cqrt_alloc_
; ACNT-NOT:     call i32 @cqrt_alloc_
