; control_swap_reject_seq_ifelse.ll — DECLINE: if/else MERGE hosts the next
; tainted branch (sequential regions).
;
; `if (q>5) {rz a} else {rz b}; if (q>3) {rz c}` — the natural clang -O1 shape
; for two consecutive tainted ifs. Detection (pure analysis, before any
; mutation) recovers BOTH regions, with region 2's Pred == region 1's MergeBB.
; Emitting region 1 then flattenRegion-ERASES that merge block, so emitting
; region 2 dereferences freed memory: SIGSEGV (exit 139) on valid input —
; confirmed live by the test_C_libtooling-9hh §8 adversarial review
; (2026-06-10), pre-existing for an un-derived base since the WI-3 if/else
; accept; the derived base merely widened its reach.
;
; A DIAMOND gets this protection incidentally (its merge is an immediate
; successor of the branch, caught by recoverRegion's Nested check); the if/else
; merge is one hop further, so recoverRegion now checks the merge's terminator
; explicitly and declines while every block is still valid. Same imprecise-but-
; safe "nested" label as the sequential-diamond case (known-limits §3).
; Defense-in-depth: lowerControlRegions also pre-flights cross-region block
; aliasing (pointer identity only) and declines loudly rather than emit.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, double %a, double %b, double %c2a) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %qd = call i32 @cq_phi_si32(i32 %q, double 9.000000e-01)
  %c = icmp sgt i32 %qd, 5
  br i1 %c, label %then, label %else
then:
  %qt = call i32 @cq_phi_si32(i32 %qd, double %a)
  br label %merge
else:
  %qe = call i32 @cq_phi_si32(i32 %qd, double %b)
  br label %merge
merge:
  %qm = phi i32 [ %qt, %then ], [ %qe, %else ]
  %c2 = icmp sgt i32 %qm, 3                       ; region 2's tainted branch
  br i1 %c2, label %arm2, label %merge2           ;   lives in region 1's MERGE
arm2:
  %q2 = call i32 @cq_phi_si32(i32 %qm, double %c2a)
  br label %merge2
merge2:
  %qm2 = phi i32 [ %q2, %arm2 ], [ %qm, %merge ]
  %m  = call i32 @cq_measure_si32(i32 %qm2)
  ret i32 %m
}

; CHECK: error{{.*}}nested control flow under quantum control
