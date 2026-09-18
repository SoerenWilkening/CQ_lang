; control_swap_value_reject_arm_cone_cq_call.ll — DECLINE: cone conjunct (K5),
; and it is the one conjunct that exists because a REVIEWER MEASURED THE HOLE
; (bd test_C_libtooling-fn1q increment 1, Rule-13 round 1, finding F-1).
;
; THE HOLE, AND WHY IT WAS INVISIBLE. Before the increment, CQ's own front-end
; calls were kept out of a value arm STRUCTURALLY: any non-chain arm op declined,
; so no predicate had to name them. The cone's four original conjuncts replaced
; that structure and NONE of them named a `cq_*` call. `cq_phi` takes no tainted
; operand and is not a taint source, so (K1) cannot see it; with
; `speculatable memory(none) nounwind willreturn` on its declaration, (K2), (K3)
; and (K4) all pass. MEASURED on the four-conjunct binary: the branch phase was
; HOISTED into the pred, where it is uncontrolled, and `deleteGlobalPhases` then
; DELETED it — `opt` exit 0 and NO `cqrt_rz_i1` anywhere in the stream. A
; vanishing user gate, which is the stray rule's own named hazard (Rule 5).
;
; ⚠ THE FIX ASKS THE QUESTION IT MEANS, NOT A NAME — the bd `11qv` round-4 (P4)
; lesson, which cost a P1 there for exactly this shape. (K5) refuses a cone member
; that is a NON-INTRINSIC `CallInst`: a call the lowering owns is a declared
; external (`cq_theta`, `cq_phi`, `cq_measure`, `cq_invert_*`, and every family
; added later), while a legitimate classical cone call is an `@llvm.*` intrinsic.
; A name-prefix test would need re-editing for every future family.
;
; ⚠ NOT REACHABLE FROM C, AND THAT IS WHY IT IS A HAND-IR FIXTURE. `clang` lowers
; `__attribute__((const))` to `nounwind willreturn memory(none)` and never emits
; `speculatable`, and that attribute set still declines at (K4). Hand-written
; `.ll` is this tree's primary fixture surface, so the shape is in scope.
;
; The `cq_measure` and `__cq_invert_begin` siblings of this shape decline the same
; way and for the same conjunct; they are recorded in the session's probe set
; rather than given three near-identical fixtures.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare void @cq_phi(double) #9

define i32 @example(i32 %u0, i32 %v0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %p = call i32 @cq_theta_si32(i32 %v0, double 2.500000e-01)
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  call void @cq_phi(double 3.000000e+00)   ; (K5) — a call the LOWERING owns
  %v1 = add i32 %p, 3
  br label %merge
merge:
  %pm = phi i32 [ %v1, %arm ], [ %p, %entry ]
  %m  = call i32 @cq_measure_si32(i32 %pm)
  ret i32 %m
}

attributes #9 = { nounwind willreturn speculatable memory(none) }

; CHECK: cq controlled lowering: impure value arm under quantum control
