; control_swap_reject_select_cmp_round2_sibling_theta.ll — DECLINE (Track A.1,
; bd test_C_libtooling-9pum). THE ROUND-2 TAINT WINDOW, COMPARE LEAF — the twin
; of `control_swap_reject_select_rail_round2_sibling_theta.ll` (Inc 1b-B.1's
; F-B1R2-1) with an `int` register and an `icmp` condition.
;
;     int q = cq_theta(3, .5);
;     int y = 5; if (q > 5) y = f(4);   // a 6.5 classical-call arm -> %out
;     int b  = cq_theta(y, .5);         // SOURCE theta at round 1
;     int b3 = cq_theta(y, .9);         // its SIBLING — one rail at FINAL taint
;     int a  = (b == 1) ? 2 : 5;        // the 4.4 merge, minted from b
;
; THE DEFECT, MEASURED on `main` 0c7380c: `opt` exit 0, verify-clean, STRICT
; stage 2b clean, and the emitted stream is `ry(h,.5); ry(h,.9); icmp_eq(h,1)` —
; the flag minted from `Ry(.9)Ry(.5)|y>` while the source compares `Ry(.5)|y>`. A
; different unitary, with no diagnostic anywhere.
;
; WHY BOTH FENCES MISS IT. `y` is a 6.5 `%out` derivative: CLASSICAL when
; `detectControlRegions` runs and TAINTED after `repropagateControlMerges`
; re-seeds. So `b` and `b3` are two SOURCE thetas — two rails — to gate 2c's
; walk (`findNonDiagonalWireGate`'s F-1b-1 ancestry crosses a chained theta's
; arg-0 only when it is TAINTED), and ONE rail to `lowerRotations`, which decides
; `Chained = taint.Tainted.count(arg0)` at FINAL taint. "A stage that runs ONCE
; has a round-2-FALSE premise", stated of a PREDICATE — the standing lesson in
; CLAUDE.md's CORRECTNESS-RISK section.
;
; THE FIX IS A RE-VERIFICATION, NOT A PREDICTION: `lowerCompareToFlag` records
; `(condProvenance cone, the minted cq_template_*cmp call)` and
; `reverifyCmpCondReads` re-asks the ladder after the round-2 fixpoint. Its
; accept twins are `control_swap_select_cmp_round2_window_accept.ll` (the sibling
; AFTER the select — correct by source order) and
; `..._round2_opaque_seed_accept.ll` (a seed nothing ever taints: genuinely two
; registers). The plain-C two-TU spelling of THIS module is
; `..._reject_select_cmp_round2_plainc_twotu.ll`.

; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @f(i32 %a) #0 {
  %s = add i32 %a, 100
  ret i32 %s
}

define i32 @main() {
entry:
  %q = call i32 @cq_theta_si32(i32 0, double 5.000000e-01)
  %c = icmp sgt i32 %q, 3
  br i1 %c, label %arm, label %merge

arm:
  %r = call i32 @f(i32 4)
  br label %merge

merge:
  %y = phi i32 [ %r, %arm ], [ 5, %entry ]
  %b = call i32 @cq_theta_si32(i32 %y, double 5.000000e-01)
  %b3 = call i32 @cq_theta_si32(i32 %y, double 9.000000e-01)
  %cc = icmp eq i32 %b, 1
  %a = select i1 %cc, i32 2, i32 5
  %mm = call i32 @cq_measure_si32(i32 %b3)
  %m = call i32 @cq_measure_si32(i32 %a)
  %t = add i32 %m, %mm
  ret i32 %t
}

attributes #0 = { nounwind willreturn memory(none) }

; CHECK: cq controlled lowering: condition predates a non-diagonal gate under quantum control
