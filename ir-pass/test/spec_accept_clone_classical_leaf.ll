; spec_accept_clone_classical_leaf.ll — ACCEPT (bd test_C_libtooling-p3kd.3; this
; file was spec_reject_clone_classical_leaf.ll, a decline, until the flip). A
; COMPOUND branch condition `c1 ∧ c2` in a lifted callee, where c1 tests the
; TAINTED param `%b` and c2 tests the CLASSICAL param `%k` (mask `01`).
;
; WAS: `cq specialization: classical compare leaf in a quantum condition under
; quantum lift`. The clone's PredMux flatten turns the diamond into
; `select(and(c1, c2), …)`, and `mintCondNetwork` minted a flag per compare
; LEAF; c2 has no tainted operand, so minting it would have put the runtime value
; `%k` in the i32 HANDLE slot of `cq_template_icmp_sgt_i32_hl` (a phantom rail id,
; a verify-clean wrong unitary). The per-leaf fence refused it.
;
; NOW: c2 is a classical INPUT of the condition network, never a rail. It is the
; top-level 4.4 select's classical LITERAL (bd xdu2.13, CondLiteral.h), asked and
; emitted by the SAME owners: `lowerCloneSelect` collects the tree with
; `collectCondTree(…, IsLiteral = condLiteralAdmissible(·, cloneTaint))`, and the
; mixed node is `emitCondLiteralNode`'s `gl = cq_template_and_i1_hl(f1, c2)`.
; c2 stays a stock `icmp` on `%k`, computed classically once in the clone.
;
; SEMANTIC EVIDENCE (basis-state trace). For a basis value v of `%b` and the
; classical K of `%k`: `f1 = icmp_sgt_i32_hl(b, 5)` is a fresh rail holding
; [v>5]; `gl = and_i1_hl(f1, c2)` is a fresh rail holding [v>5]∧[K>3], the
; source's condition; `out` (fresh |0>) receives `r1 = v+1` under gl and, inside
; the `cqrt_x(gl)` bracket, `r2 = v+2` under ¬gl, so out = cond ? v+1 : v+2, the
; source's phi. The Bennett wrap copies out to the result, then plays the forward
; stream backwards: the two XOR copies return `out` to |0>,
; `and_i1_hl_unc(gl, f1, c2)` reads the SAME SSA literal c2 as the forward and
; returns gl to |0>, `icmp_sgt_i32_hl_unc` returns f1 to |0>, the arm `_unc`s
; return r1/r2 to |0>; every freed rail is |0>. The `_unc`'s `bool` literal is
; passed `zeroext` (the runtime's C ABI, the CondLiteral round-2 F-2 finding): the
; forward carries it at the call site, the wrap's adjoint through its declaration.
; Decline twin: spec_reject_clone_classical_leaf_xor.ll (a classical leaf under an
; `xor` node, which has no `_hl` literal template, keeps this fence's message).
;
; bd p3kd.7.8: the clone is now lowered by MAIN's stage list; `lowerCloneSelect`
; (named above) is gone. The SAME literal owners now answer through main's 4.4
; path: SelectClassify admits c2 with `condLiteralAdmissible`, CondTreeEmit mints
; the mixed node with `emitCondLiteralNode`, SelectMergeEmit does the two copies.
; What moved: main's merge strips its own network inline (trailing `cqrt_x(gl)`,
; then the `_unc`s and frees); inside a clone the Bennett wrap elides that strip,
; so the forward ends with the bracket OPEN (gl = ¬cond) and the mirror's single
; `cqrt_x` closes it. The trace above still holds with that one change: forward
; out = cond ? v+1 : v+2; the mirror XORs [¬cond]·(v+2) then (after gl→cond)
; cond·(v+1) back (out = 0), `and_i1_hl_unc` reads the SAME literal c2 and zeroes
; gl, then f1 and the arms R1/R2 are `_unc`'d; all five freed rails are |0>.
; The adjoint's literal must reach the runtime `bool` with `zeroext`, like the
; forward's. This fixture caught its loss in the first p3kd.7.8 draft (the wrap
; elides main's strip, which stamped it, and the mirror minted the `_unc` bare;
; the removed path had stamped the DECLARATION). Fixed at the one spelling:
; `emitInverseCall` carries the forward's `zeroext`/`signext` to the `_unc`'s
; slots, so it is pinned on the mirror's CALL now (the declaration stays bare).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll 2> %t.err
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=ERR --allow-empty < %t.err
; RUN: %filecheck %s --check-prefix=PHANTOM < %t.cqd0.ll
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

; ERR-NOT: error
; ERR-NOT: warning
;
; CHECK-LABEL: define i32 @example(
; CHECK:     %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK:     %[[R:[a-zA-Z0-9_.]+]] = call i32 @__cq_q_helper_01(i32 %[[H]], i32 %kk)
; CHECK:     call i32 @cqrt_measure_i32(i32 %[[R]])
;
; CHECK-LABEL: define internal i32 @__cq_q_helper_01(i32 %b, i32 %k)
; The classical leaf stays a stock compare on the classical parameter.
; CHECK-DAG: %[[C2:[a-zA-Z0-9_.]+]] = icmp sgt i32 %k, 3
; CHECK-DAG: %[[R1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_add_i32_hl(i32 %b, i32 1)
; CHECK-DAG: %[[R2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_add_i32_hl(i32 %b, i32 2)
; CHECK:     %[[F1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %b, i32 5)
; CHECK-NEXT: %[[GL:[a-zA-Z0-9_.]+]] = call i32 @cq_template_and_i1_hl(i32 %[[F1]], i1 zeroext %[[C2]])
; CHECK-NEXT: %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[GL]], i32 %[[R1]], i32 %[[OUT]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[GL]])
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[GL]], i32 %[[R2]], i32 %[[OUT]])
; Bennett copy-out (the merge's strip was elided: the bracket is still open), then
; the exact mirror.
; CHECK-NEXT: %[[RES:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_copy_i32(i32 %[[OUT]], i32 %[[RES]])
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[GL]], i32 %[[R2]], i32 %[[OUT]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[GL]])
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[GL]], i32 %[[R1]], i32 %[[OUT]])
; CHECK-NEXT: call void @cq_template_and_i1_hl_unc(i32 %[[GL]], i32 %[[F1]], i1 zeroext %[[C2]])
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[F1]], i32 %b, i32 5)
; The arm `_unc`s (order-free: the forward order of R1/R2 is not pinned), then
; every freed rail.
; CHECK-DAG: call void @cq_template_add_i32_hl_unc(i32 %[[R1]], i32 %b, i32 1)
; CHECK-DAG: call void @cq_template_add_i32_hl_unc(i32 %[[R2]], i32 %b, i32 2)
; CHECK-DAG: call void @cqrt_free(i32 %[[R1]])
; CHECK-DAG: call void @cqrt_free(i32 %[[R2]])
; CHECK-DAG: call void @cqrt_free(i32 %[[GL]])
; CHECK-DAG: call void @cqrt_free(i32 %[[F1]])
; CHECK-DAG: call void @cqrt_free(i32 %[[OUT]])
; CHECK:     ret i32 %[[RES]]
; CHECK-NEXT: }
;
; The phantom classical-value-as-handle is never minted, anywhere in the module.
; PHANTOM-NOT: cq_template_icmp_sgt_i32_hl(i32 %k
; The adjoint's `bool` literal is zero-extended by its declaration.
