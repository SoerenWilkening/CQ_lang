; loop_condtree_select_accept_hoisted_mixed_literal.ll — ACCEPT (bd
; test_C_libtooling-xdu2.16), the bd xdu2.13 CLASSICAL-LEAF LITERAL inside a
; ROLLED loop.
;
; `int a = 0; for (i < n) if (q && m == n) a += 3;` (TRACK_E_xdu2_13.md probe
; p11; xdu2.8's row-13 condition without the guarded VLA read). `clang -O1` fuses
; the condition into `and i1 (icmp eq m, n), (icmp ne q, 0)` and LICM-hoists all
; three into the preheader. Stage-1 shape verbatim, names cleaned.
;
; ON THE PRE-CHANGE ORACLE `438c77bf45c02e3e` it declines `cq loop lowering:
; round-1 iteration-local marking falsified by round-2 taint`: the hoisted `%c`
; was a round-1 (ii-d) root and the 4.4 emitter erased it. After the change the
; grant is re-derived under FINAL taint (the body now reads only `%q` through the
; emitter's in-body flag mint — a root mint) and stands.
;
; ⚠ THE CLASSICAL LEAF IS NOT ERASED AND IS NOT A ROOT. `%lit = icmp eq m, n`
; stays in the PREHEADER (it is classical, loop-invariant, and read by the node
; mint as the `_hl` LITERAL on every trip), untainted, so it never enters the
; loop layer's candidate set at all. It is passed `zeroext` at BOTH the forward
; and the `_unc` (bd xdu2.13 F-2), the SAME SSA value at both — which is what
; makes `cqrt_free(gl)` a proven-|0> free (Rule 6): `gl ^= h_cmp ∧ lit` twice.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll 2> %t.err
; RUN: %filecheck %s < %t.ll
; RUN: %filecheck %s --check-prefix=NEG < %t.ll
; RUN: %filecheck %s --check-prefix=ERR --allow-empty < %t.err
;
; CHECK-LABEL: define i32 @slice(
; CHECK:      %[[H:[a-z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 2.500000e-01)
; CHECK:      ph:
; CHECK-NEXT: %lit = icmp eq i32 %m, %n
; CHECK-NEXT: br label %body
; CHECK:      body:
; CHECK-NEXT: %i = phi i32
; CHECK-NEXT: %[[A:[a-z0-9_.]+]] = phi i32 [ %cq.carried, %ph ], [ %[[OUT:out[0-9]*]], %body ]
; CHECK-NEXT: %[[OP:h_op[0-9]*]] = call i32 @cq_template_add_i32_hl(i32 %[[A]], i32 3)
; CHECK-NEXT: %[[F:h_cmp[0-9]*]] = call i32 @cq_template_icmp_ne_i32_hl(i32 %[[H]], i32 0)
; CHECK-NEXT: %[[G:gl[0-9]*]] = call i32 @cq_template_and_i1_hl(i32 %[[F]], i1 zeroext %lit)
; CHECK-NEXT: %[[OUT]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[G]], i32 %[[OP]], i32 %[[OUT]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[G]])
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[G]], i32 %[[A]], i32 %[[OUT]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[G]])
; CHECK-NEXT: call void @cq_template_and_i1_hl_unc(i32 %[[G]], i32 %[[F]], i1 zeroext %lit)
; CHECK-NEXT: call void @cqrt_free(i32 %[[G]])
; CHECK-NEXT: call void @cq_template_icmp_ne_i32_hl_unc(i32 %[[F]], i32 %[[H]], i32 0)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
; CHECK-NEXT: %i.next = add nuw nsw i32 %i, 1
;
; NEG-NOT: and i1
; NEG-NOT: select i1
; NEG-NOT: cqrt_alloc_i1(i1 %lit)
; NEG-NOT: cqrt_toffoli
; NEG-NOT: cqrt_free(i32 %h{{[0-9]*}})
; ERR-NOT: cq loop lowering
; ERR-NOT: error

define i32 @slice(i32 %n, i32 %m) {
entry:
  %q = call i32 @cq_theta_si32(i32 0, double 2.500000e-01)
  %guard = icmp sgt i32 %n, 0
  br i1 %guard, label %ph, label %exit

ph:
  %t = icmp ne i32 %q, 0
  %lit = icmp eq i32 %m, %n
  %c = and i1 %lit, %t
  br label %body

exit:
  %a.lcssa = phi i32 [ 0, %entry ], [ %a.next, %body ]
  %mq = call i32 @cq_measure_si32(i32 %q)
  %ma = call i32 @cq_measure_si32(i32 %a.lcssa)
  %s = add nsw i32 %ma, %mq
  ret i32 %s

body:
  %i = phi i32 [ 0, %ph ], [ %i.next, %body ]
  %a = phi i32 [ 0, %ph ], [ %a.next, %body ]
  %a3 = add nsw i32 %a, 3
  %a.next = select i1 %c, i32 %a3, i32 %a
  %i.next = add nuw nsw i32 %i, 1
  %done = icmp eq i32 %i.next, %n
  br i1 %done, label %exit, label %body
}

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
