; control_phase_kickback_reject_tree_classical_leaf.ll — DECLINE. P3's HYBRID
; classical∧quantum conjunction (bd test_C_libtooling-3qlq Inc 1 part B).
;
;     if (q == 5 && k == 3) cq_phi(0.3);   // k CLASSICAL
;
; A classical compare leaf has NO quantum flag to mint. Promoting it would put a
; classical runtime value in the i32 HANDLE slot of
; `cq_template_icmp_eq_i32_hl` — a phantom rail id aliasing an unrelated qubit,
; i.e. a verify-clean WRONG UNITARY, and the §5.2 classical-operand-as-handle
; prohibition. `classifySelectRegion` gate 2 declines the same shape with the
; same string on the 4.4 select side; this is its branch-phase mirror.
;
; FOLDING THE CLASSICAL LEAF CLASSICALLY (emit the region only on the branch
; where `k == 3` holds) is a real capability and a separate increment — it needs
; a proof that the classical predicate is loop-invariant and side-effect-free at
; the mint point. Over-declining is safe (Prime Directive).
; (Prose deliberately does not spell the lit directive token verbatim — lit
; scans EVERY line for it, so quoting it in a comment mints a bogus run line.)
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %k) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %ca = icmp eq i32 %q, 5
  %cb = icmp eq i32 %k, 3
  %c = select i1 %ca, i1 %cb, i1 false
  br i1 %c, label %arm, label %merge
arm:
  call void @cq_phi(double 3.000000e-01)
  br label %merge
merge:
  %m = call i32 @cq_measure_si32(i32 %q)
  ret i32 %m
}

; CHECK: cq controlled lowering: control flow under quantum control
