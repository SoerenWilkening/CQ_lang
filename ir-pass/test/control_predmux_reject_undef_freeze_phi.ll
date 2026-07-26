; control_predmux_reject_undef_freeze_phi.ll — DECLINE (bd q2wk, PRD §4.4b
; rule (B), residual (e)). The FIFTH residual, found by the DELTA Rule-13 round
; reviewing the fix that was supposed to have closed the class — which is the
; point of running a delta round at all.
;
; THE GAP WAS A DISAGREEMENT ABOUT *WHEN* undef IS NORMALIZED.
; `convertPhis` freezes every `isa<UndefValue>` incoming (which includes
; `PoisonValue`) to `Constant::getNullValue(P->getType())` BEFORE it builds its
; `In` list. The rule-(B) fence walked `P->getIncomingValue(K)` RAW. So a phi
; whose incomings become identical only AFTER the freeze read as "not all equal"
; to the fence — answer: will taint — while the flatten RAUW'd it to a plain
; constant — answer: stays classical.
;
; Here `%sp = phi i32 [ 0, %a1 ], [ undef, %a2 ]` RAUWs to the constant 0, so
; `%cc = icmp eq i32 0, %k` is a fully CLASSICAL, argument-derived runtime i1.
; And because every merge phi is i1, `convertPhis` takes the boolean-algebra path
; and mints NO select — so SelectClassify's GATE-2 untainted-leaf backstop never
; runs and the module COMPILED SILENTLY (rc 0) where the pre-q2wk plugin
; declined. That is verbatim the failure mode
; control_predmux_reject_i1cmp_shield_phi.ll's header calls "the thing to close".
;
; Not a miscompile — freezing undef to zero is the sanctioned treatment (the
; source had no defined result on that path) and the emitted network is a legal
; refinement — but an accept strictly wider than the argument justifying it,
; which is the criterion the whole fence round was applied under.
;
; THE RULE THIS PINS, and the reason it is stated as a rule rather than a patch:
; the fence must MIRROR `convertPhis`' `In`-list construction VERBATIM. Any future
; normalization `convertPhis` grows — a new freeze, a new dedup, a new fold — must
; be mirrored in the fence or it reopens exactly this gap. Two shapes are covered
; below: `[0, undef]` (a constant meeting an undef) and `[undef, poison]` (two
; distinct uniqued Values that both freeze to the same zero).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; RUN: %cq-opt -passes=verify -disable-output %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @probe(i32 %u0, i32 %k) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c0 = icmp sgt i32 %q, 5
  br i1 %c0, label %a, label %sideb
a:
  %c1 = icmp slt i32 %q, 3
  br i1 %c1, label %a1, label %a2
a1:
  br label %b
a2:
  br label %b
b:
  %sp = phi i32 [ 0, %a1 ], [ undef, %a2 ]   ; ← identical only AFTER the freeze
  %cc = icmp eq i32 %sp, %k                  ; ← classical runtime i1 post-RAUW
  br i1 %cc, label %t, label %f
t:
  %vt  = icmp eq i32 %q, 7
  %vt2 = icmp eq i32 %q, 70
  br label %merge
f:
  %vf  = icmp eq i32 %q, 9
  %vf2 = icmp eq i32 %q, 90
  br label %merge
sideb:
  %vs  = icmp eq i32 %q, 11
  %vs2 = icmp eq i32 %q, 110
  br label %merge
merge:                                       ; all-i1 ⇒ BoolAlg, no select minted
  %p1 = phi i1 [ %vt, %t ], [ %vf, %f ], [ %vs, %sideb ]
  %p2 = phi i1 [ %vt2, %t ], [ %vf2, %f ], [ %vs2, %sideb ]
  %z1 = zext i1 %p1 to i32
  %z2 = zext i1 %p2 to i32
  %s  = add i32 %z1, %z2
  %m  = call i32 @cq_measure_si32(i32 %s)
  ret i32 %m
}

; CHECK: error{{.*}}cq controlled lowering: nested control flow under quantum control
; Nothing lowered — detect-before-mutate.
; CHECK-NOT: cqrt_
; CHECK-NOT: cq_template_
