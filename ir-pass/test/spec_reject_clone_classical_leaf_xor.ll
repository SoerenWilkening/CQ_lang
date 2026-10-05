; spec_reject_clone_classical_leaf_xor.ll — DECLINE twin of
; spec_accept_clone_classical_leaf.ll (bd test_C_libtooling-p3kd.3). The
; classical leaf `%k > 3` is now a classical LITERAL of an `and`/`or` node
; (`cq_template_<and|or>_i1_hl`), but under an `xor` node it is not: the grammar
; never offers an `xor` child as a literal (`collectCondTree`'s `IsLiteral`, the
; top-level 4.4 select's scope, CondLiteral.h), and the runtime has no
; `cq_template_xor_i1_hl`. The leaf therefore stays a compare LEAF with no tainted
; operand, and the per-leaf fence in `mintCondNetwork` keeps refusing it: minting
; it would land the runtime value `%k` in the i32 HANDLE slot of
; `cq_template_icmp_sgt_i32_hl` (a phantom rail id, a verify-clean wrong unitary).
; Loud, character for character. Building it needs an `xor` literal template (a
; gap shared with the top level, not a physics limit).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @helper(i32 %b, i32 %k) {
entry:
  %c1 = icmp sgt i32 %b, 5
  %c2 = icmp sgt i32 %k, 3
  %x = xor i1 %c1, %c2
  br i1 %x, label %t, label %f
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

; CHECK: error{{.*}}in function __cq_q_helper_01{{.*}}cq specialization: classical compare leaf in a quantum condition under quantum lift
