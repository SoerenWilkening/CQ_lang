; control_predmux_reject_i80_cmp_purecallee_constconst.ll — DECLINE (bd
; 3c6m.14.1): the fixture that exists because the arm-kill matrix produced a
; SURVIVOR and the first explanation of that survivor was WRONG.
;
; THE ARM IT PINS. `isSpeculatableDataflow`'s i80 clause admits the compare when
; `isa<ConstantInt>(op0) != isa<ConstantInt>(op1)` — EXACTLY one ConstantInt.
; Flipping that `!=` to `||` changes behaviour for one shape only: const/const,
; since the Q+Q form fails both spellings. Mutating it left the entire fixture
; suite green, and the first explanation offered was that
; `foldConstantConesInFunction` erases every all-constant instruction before any
; E-gate runs, so the shape is unreachable.
;
; THAT EXPLANATION IS FALSE AT THIS CALL SITE, and two independent Rule-13 lenses
; falsified it with a run. `flattenPredMuxRegions` calls the folder only for
; functions that CARRY TAINTED CONTROL, and only for the function whose region is
; being flattened. `isSpeculatablePureCalleeBodyImpl` walks the CALLEE's body —
; which, pre-specialization, has no taint and no tainted terminator, so it is
; never folded. The proof therefore does see an all-constant `icmp i80`. The two
; probes behind the original excuse were both written at the REGION walk, in a
; function with tainted control; they could not reach the site being defended.
; That is the "a probe that cannot reach the changed region is not evidence"
; failure, committed against my own claim (bd memory
; [[budget-in-a-memo-and-probes-with-no-power-2026-08-08]]).
;
; WHY THE `!=` SPELLING IS LOAD-BEARING, not merely tidy. Under `!=` the proof
; fails AT THE COMPARE, so the call is never admitted, the region is never
; claimed, and `opt` declines having mutated NOTHING. Under `||` the proof
; passes, the region is claimed and FLATTENED, the callee is cloned, and only
; then does a different diagnostic fire from inside `@__cq_q_leaf_1`. Measured,
; both plugins built and run:
;
;   `!=` (shipped):  pure-callee leaf fails at: %eq = icmp eq i80 <c>, <c>
;                    leave @probe ... gate=E4-dataflow at: call x86_fp80 @leaf
;                    error: cq controlled lowering: control flow under quantum control
;   `||` (mutant) :  error: in function __cq_q_leaf_1: cq specialization:
;                    mixed classical/quantum select under quantum lift
;
; So the mutant is not merely "a different decline" — it is a POST-MUTATION one,
; the detect-before-mutate class the Inc-1 fp128 finding closed. A const/const
; compare is also plainly CLASSICAL, and admitting classical leaves into a
; claimed region is what `declineClassicalMuxes` / SelectClassify GATE-2 exist to
; catch afterwards; declining at the gate is the correct, earlier place.
;
; NB the constant here must NOT be foldable away by anything upstream of the
; proof. It is written directly in the callee body, and the callee has no
; branch — do not "simplify" this fixture by giving `@leaf` control flow, which
; would make it tainted after specialization and hand the folder a reason to run.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; RUN: env CQ_PREDMUX_DBG=1 not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering \
; RUN:   -S %s -o /dev/null 2>&1 | %filecheck %s --check-prefix=DBG

target datalayout = "e-m:o-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx"

declare x86_fp80 @cq_theta_f80(x86_fp80, double)
declare x86_fp80 @cq_measure_f80(x86_fp80)

; Identical to the accept sibling's @leaf except that BOTH compare operands are
; ConstantInt (the accept has the masked bit pattern on the left).
define x86_fp80 @leaf(x86_fp80 %v) {
e:
  %eq = icmp eq i80 9223372036854775808, 9223372036854775808
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

; No interior wildcard — this must be the CONTROL-FLOW decline, not the
; specialization one the `||` mutant produces.
; CHECK: error{{.*}}cq controlled lowering: control flow under quantum control

; The discriminating pair. Under the `||` mutant NEITHER line is printed (the
; proof passes and the region is claimed), so their presence is the assertion.
; DBG: CQ_PREDMUX_DBG: pure-callee leaf fails at:{{.*}}icmp eq i80 9223372036854775808, 9223372036854775808
; DBG: CQ_PREDMUX_DBG: leave @probe entry=entry merge=merge gate=E4-dataflow at:{{.*}}call x86_fp80 @leaf
