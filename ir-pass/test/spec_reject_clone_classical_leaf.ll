; spec_reject_clone_classical_leaf.ll — Phase 6 / issue 5po2 I2 (Rule-13
; CONFIRMED-finding regression probe): a COMPOUND branch condition `c1 ∧ c2` where
; c1 tests the TAINTED param `%b` but c2 tests a CLASSICAL param `%k` (mask `01`)
; stays DECLINED. PredMux (claimAll) flattens the diamond to
; `select(and(icmp %b, icmp %k), …)`; `lowerCloneSelect`'s trichotomy sets
; `CondT=true` because the c1 leaf touches taint, and `mintCondNetwork` walks the
; and-tree. Without a per-leaf fence the ALL-CLASSICAL c2 leaf would fall into
; `lowerCompareToFlag`'s Q+C branch and land the classical runtime value `%k` in the
; i32 HANDLE slot (`cq_template_icmp_sgt_i32_hl(i32 %k, i32 3)`) — a phantom rail ID
; aliasing an unrelated qubit, a verify-clean WRONG UNITARY (the §5.2
; classical-operand-as-handle prohibition; the top-level `SelectClassify` gate 2
; declines the same hybrid classical∧quantum conjunction). The per-leaf fence in
; `mintCondNetwork` (a leaf with NEITHER operand tainted) loud-declines it and mints
; NO phantom handle. Folding a classical leaf classically is a separate widening.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @helper(i32 %b, i32 %k) {
entry:
  %c1 = icmp sgt i32 %b, 5
  %c2 = icmp sgt i32 %k, 3
  %and = and i1 %c1, %c2
  br i1 %and, label %t, label %f
t:
  %r1 = add i32 %b, 1
  br label %m
f:
  %r2 = add i32 %b, 2
  br label %m
m:
  %r = phi i32 [ %r1, %t ], [ %r2, %f ]
  ret i32 %r
}

define i32 @example(i32 %u0, i32 %kk) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @helper(i32 %q, i32 %kk)
  %m = call i32 @cq_measure_si32(i32 %r)
  ret i32 %m
}

; CHECK: error{{.*}}cq specialization: classical compare leaf in a quantum condition under quantum lift
; the phantom classical-value-as-handle is NEVER minted:
; CHECK-NOT: cq_template_icmp_sgt_i32_hl(i32 %k
