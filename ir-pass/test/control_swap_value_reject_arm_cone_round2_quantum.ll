; control_swap_value_reject_arm_cone_round2_quantum.ll — DECLINE, and it is the
; fixture the increment's OWN RECORD said could not be written (bd
; test_C_libtooling-fn1q increment 1, Rule-13 round 1, attack D).
;
; THE L1 SHAPE, EXHIBITED. The cone's conjunct (K1) — "every cone member is
; CLASSICAL" — is asked by `classifyArms` inside `detectControlRegions`, i.e. at
; ROUND-1 taint. `repropagateControlMerges` then re-seeds taint from the 6.5/4.5
; merge `%out` rails. A cone member that reads such a merge φ is UNTAINTED at
; round 1 and TAINTED after the fixpoint — leaving a region already hoisted,
; merged and FLATTENED on the premise that its chain link was Q+C, while
; `lowerOps` at final taint would mint the Q+Q template. Q+Q in a value arm is a
; shape `classifyArms` DEFERS by design (`Chain.HasQQ` → `value-arm swap-route`),
; so accepting it here would be an unreviewed widening of exactly the class the
; Prime Directive refuses to widen silently.
;
; `declineRound2TaintedArmCone` is the fence, in the post-fixpoint slot beside
; `reverifyRailCondReads` / `reverifyCmpCondReads` / `declineUnmarkedRolledIterLocal`,
; in BOTH entry points. Backtrace-confirmed as the firing predicate, not inferred.
;
; ⚠ THE `mid` BLOCK IS LOAD-BEARING AND IT IS WHY THE IMPLEMENTER'S OWN PROBES
; MISSED THIS. Without a block between the 6.5 merge and the value region's
; branch, the PAIR declines earlier, at `lowerControlRegions`' `reorderable`
; precedence check (bd `test_C_libtooling-35t0`) — a decline that hides the one
; being tested. A probe that reaches the wrong fence first measures the wrong
; fence. Do not "simplify" this file by deleting `mid`.
;
; ⚠ THE RECORD IT CORRECTS. `IMPL_INC1.md` §2 and `TaintSet::ValueArmConeOps`'
; header both said "Reachability is NOT claimed … no probe produced the shape".
; That was true of the implementer's probes and FALSE of the shape, and both sites
; are corrected in the same change as this file lands — a record correction that is
; not applied to the source is not a correction (standing lesson L7).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @f(i32 %a) #0 {
  %s = add i32 %a, 100
  ret i32 %s
}
define i32 @example(i32 %u0, i32 %v0, i32 %a) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %p = call i32 @cq_theta_si32(i32 %v0, double 2.500000e-01)
  %c = icmp sgt i32 %q, 3
  br i1 %c, label %arm1, label %merge1
arm1:
  %r = call i32 @f(i32 %a)
  br label %merge1
merge1:
  %y = phi i32 [ %r, %arm1 ], [ 5, %entry ]
  br label %mid
mid:
  %c2 = icmp sgt i32 %q, 7
  br i1 %c2, label %arm2, label %merge2
arm2:
  %k1 = mul i32 %y, 3
  %v1 = add i32 %p, %k1
  br label %merge2
merge2:
  %pm = phi i32 [ %v1, %arm2 ], [ %p, %mid ]
  %m = call i32 @cq_measure_si32(i32 %pm)
  ret i32 %m
}
attributes #0 = { nounwind willreturn memory(none) }

; CHECK: cq controlled lowering: value arm classical operand became quantum under quantum control
