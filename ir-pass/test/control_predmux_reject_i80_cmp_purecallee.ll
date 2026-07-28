; control_predmux_reject_i80_cmp_purecallee.ll — DECLINE (bd 3c6m.61): the
; SCOPE fence on the Inc-7 widening, and the fixture that exists because the
; Rule-13 round caught the first draft over-reaching.
;
; `isSpeculatableDataflow` is NOT private to the E4 region-body walk. It is also
; the per-instruction predicate of `isSpeculatablePureCalleeBodyImpl`, whose
; result feeds TWO further accept decisions:
;   (1) E4's own CALL admission — a pure/total callee invoked from inside a
;       claimed arm is speculated and then specialized through the Phase-6
;       clone-on-taint + Bennett-wrap path; and
;   (2) `isSpeculatablePureCallee`, EXPORTED via PredMuxFlatten.h and consumed by
;       the fp80-union SEED-CONE walk in a different module (Fp80Union.cpp:599).
; Written unparameterized, the i80-compare widening therefore silently widened
; all three at once — measured: this exact input compiled, minting a Bennett
; clone `@__cq_q_leaf_*` carrying `cq_template_icmp_eq_i80_hl` and its `_unc`
; adjoint. Neither (1) nor (2) is this increment's target shape, and neither had
; a probe family, so `AdmitI80Compare` is passed TRUE by the region-body walk
; ALONE and both keep the old blanket i80-compare exclusion.
;
; @leaf below is otherwise a perfect pure-callee candidate — visible, exact
; definition, acyclic, non-varargs, total, template-width result — so the ONLY
; thing declining it is the i80 compare. Widening (1)/(2) is a separate
; increment with its own probes (bd 3c6m.14.1); until then this is a deliberate
; over-decline, which is always safe (Prime Directive).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; RUN: env CQ_PREDMUX_DBG=1 not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering \
; RUN:   -S %s -o /dev/null 2>&1 | %filecheck %s --check-prefix=DBG

target datalayout = "e-m:o-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx"

declare x86_fp80 @cq_theta_f80(x86_fp80, double)
declare x86_fp80 @cq_measure_f80(x86_fp80)

; Pure, acyclic, total. Its ONLY instruction outside the pure-callee grid is the
; i80 `_hl` compare — which the E4 REGION walk now admits and this proof does not.
define x86_fp80 @leaf(x86_fp80 %v) {
e:
  %bc = bitcast x86_fp80 %v to i80
  %man = and i80 %bc, 18446744073709551615
  %eq = icmp eq i80 %man, 9223372036854775808
  %r = select i1 %eq, x86_fp80 %v, x86_fp80 0xK3FFF8000000000000000
  ret x86_fp80 %r
}

define x86_fp80 @probe(x86_fp80 %u0) {
entry:
  %q = call x86_fp80 @cq_theta_f80(x86_fp80 %u0, double 5.000000e-01)
  %c = fcmp olt x86_fp80 %q, 0xK3FFE8000000000000000
  br i1 %c, label %arm, label %norm

arm:
  %r = call x86_fp80 @leaf(x86_fp80 %q)
  %k1 = fadd x86_fp80 %r, 0xKBFFE8000000000000000
  br label %merge

norm:
  %k2 = fmul x86_fp80 %q, 0xK40008000000000000000
  br label %merge

merge:                                  ; 2 merge phis = the W3 claim witness
  %z = phi x86_fp80 [ %k1, %arm ], [ %k2, %norm ]
  %z2 = phi x86_fp80 [ %r, %arm ], [ %q, %norm ]
  %s = fadd x86_fp80 %z, %z2
  %m = call x86_fp80 @cq_measure_f80(x86_fp80 %s)
  ret x86_fp80 %m
}

; CHECK: error{{.*}}cq controlled lowering: control flow under quantum control

; The discriminating evidence, and the reason this fixture is DBG-pinned where
; the other Inc-7 declines are only forward-pinned: these two lines DO split
; against the over-reaching first draft, which printed neither (it claimed the
; region and specialized the call instead).
; DBG: CQ_PREDMUX_DBG: pure-callee leaf fails at:{{.*}}icmp eq i80
; DBG: CQ_PREDMUX_DBG: leave @probe entry=entry merge=merge gate=E4-dataflow at:{{.*}}call x86_fp80 @leaf
