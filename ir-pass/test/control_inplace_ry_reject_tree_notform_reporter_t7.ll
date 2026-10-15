; control_inplace_ry_reject_tree_notform_reporter_t7.ll — DECLINE: the
; reporter's original `t7.c` (docs/CQ_FINDINGS.md F2, ~/Desktop/alg_test/dicke):
;
;     bool a = 0, b = 0, t = 1;
;     cq_theta(&a, 1.0); cq_theta(&b, 1.0);
;     b ^= a;                        /* CNOT a->b */
;     if (a & b) cq_theta(&t, 0.5);  /* CCRy */
;     b ^= a;
;
; Pinned at the coordinator's request as the dm7f.51-family decline, AND THE
; REASON IS NOT dm7f.51's — measured, bd dm7f.52. The target `t` is DISJOINT from
; every condition wire. `clang -O1` folds `a & (b ^ a)` to `a & !b` and cancels
; the two `b ^= a` outright, so the module below holds no CNOT at all: the
; condition is `and i1 %a, (xor i1 %b, true)`, and the `xor %b, true` NOT-form is
; refused by `collectCondTree` — the same grammar gap that makes the `cq_phi` twin
; `if (!a & b) cq_phi(.7)` decline (`control_phase_kickback_reject_tree_notform.ll`).
; The program is physically valid (`¬b` is realizable as a CNOT copy of the rail
; into a fresh ancilla, X-bracketed there — never a `cqrt_x` on the user's `b`,
; which the nest's `NegL`/`NegR` bracket would put on a rail leaf), so this is an
; OVER-DECLINE of the condition-tree GRAMMAR (`SelectClassify::collectCondTree`,
; shared by four consumers), filed as a follow-up of dm7f.52.
; RETIREMENT TRIGGER: when the grammar admits a NOT leaf, this file must flip to
; an accept whose stream is `toffoli` on (a, ¬b) — an `x` bracket on a COPY or
; ancilla, never a `cqrt_x` on the user's `b` — then `alloc_i1(1)` + cRy(.5).
;
; FOLLOW-UP: bd test_C_libtooling-dm7f.55 (the NOT-form leaf grammar).
;
; ⚠ FLIPPED TO AN ACCEPT by bd test_C_libtooling-dm7f.77 — the retirement trigger
; above, for this consumer (the file keeps its name, L8; the kickback twin
; control_phase_kickback_reject_tree_notform.ll stays declined: the branch phase
; does not read register conditions). The condition `a & !b` holds a NOT no
; network takes, so its own out-of-place rail is a fresh REGISTER CONDITION
; (RegCondLeaf.h, Bennett's one-resolved-wire condition): `!b` is a `_hl` copy of
; `b` (never a `cqrt_x` on the user's `b`), `and` onto a fresh rail, the prep
; `alloc_i1(1)` + cRy(.5), then both discharged LIFO and freed (ChainWalk row
; (c′)). Analytic: the textbook CNOT(a,b); CCRy(a,b -> t,.5); CNOT(a,b) and this
; stream give identical distributions (reporter-tree twin with a later Ry on `a`:
; control_regcond_not_tree_discharge_accept.ll).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll 2> %t.err
; RUN: %filecheck %s < %t.ll
; RUN: %filecheck %s --check-prefix=NOERR --allow-empty < %t.err
; NOERR-NOT: error
; RUN: %filecheck %s --check-prefix=NOX < %t.ll
; CHECK:       %[[NB:[a-zA-Z0-9_.]+]] = call i32 @cq_template_xor_i1_hl(i32 %[[B:[a-zA-Z0-9_.]+]], i1 true)
; CHECK-NEXT:  %[[C:[a-zA-Z0-9_.]+]] = call i32 @cq_template_and_i1(i32 %[[A:[a-zA-Z0-9_.]+]], i32 %[[NB]])
; CHECK-NEXT:  %[[T:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 true)
; CHECK-NEXT:  call void @cqrt_ry_i1_controlled(i32 %[[C]], i32 %[[T]], double 5.000000e-01)
; CHECK-NEXT:  call void @cq_template_and_i1_unc(i32 %[[C]], i32 %[[A]], i32 %[[NB]])
; CHECK-NEXT:  call void @cqrt_free(i32 %[[C]])
; CHECK-NEXT:  call void @cq_template_xor_i1_hl_unc(i32 %[[NB]], i32 %[[B]], i1 true)
; CHECK-NEXT:  call void @cqrt_free(i32 %[[NB]])
; NOX-NOT:     call void @cqrt_x(

declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)

define i32 @example() {
  %1 = call i1 @cq_theta_i1(i1 false, double 1.000000e+00)
  %2 = call i1 @cq_theta_i1(i1 false, double 1.000000e+00)
  %3 = xor i1 %2, true
  %4 = and i1 %1, %3
  br i1 %4, label %5, label %7

5:
  %6 = call i1 @cq_theta_i1(i1 true, double 5.000000e-01)
  br label %7

7:
  %8 = phi i1 [ %6, %5 ], [ true, %0 ]
  %9 = call i1 @cq_measure_i1(i1 %1)
  %10 = zext i1 %9 to i32
  %11 = call i1 @cq_measure_i1(i1 %2)
  %12 = zext i1 %11 to i32
  %13 = call i1 @cq_measure_i1(i1 %8)
  %14 = zext i1 %13 to i32
  %15 = add i32 %10, %12
  %16 = add i32 %15, %14
  ret i32 %16
}

