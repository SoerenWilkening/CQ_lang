; loop_condtree_select_accept_hoisted_leaf.ll — ACCEPT (bd
; test_C_libtooling-xdu2.16). The NULLED ROOT IS A COMPARE LEAF, not the fused node.
;
; `for (i < n) { int t = ((q > 1) & (r < i)) ? i : 55; s += cq_measure(t); }`.
; The tree is LOOP-VARIANT (`r < i` reads the IV), so the `and` stays in the body;
; only the invariant leaf `%c1 = icmp sgt q, 1` is LICM-hoisted to the preheader.
; It is read in the body as an operand of the in-body `and` (a data position for
; `isDataPositionCompare`), so round 1's clause (ii-d) admits IT as a root — and the
; 4.4 emitter, which mints FRESH leaf flags from `%q`/`%r` at the select, leaves it
; dead and erases it. Same wall as the hoisted-node shape, one tree level down:
; the pre-change ORACLE `438c77bf45c02e3e` declines `cq loop lowering: round-1
; iteration-local marking falsified by round-2 taint`.
;
; After the change the grant is re-derived under FINAL taint (roots `%q`, `%r`)
; and stands. Per trip: both leaf flags minted and stripped in the body, the toffoli
; node on a fresh ancilla, the copies of the CLASSICAL arms (`i` and `55`, each a
; `cqrt_alloc_i32` source rail that is only ever a copy SOURCE) into `%out`, which
; the user measures. Rolled-vs-unrolled BYTE-IDENTICAL (60 trace lines,
; TRACK_XDU2_16.md §3, cell `loopvar`).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll 2> %t.err
; RUN: %filecheck %s < %t.ll
; RUN: %filecheck %s --check-prefix=NEG < %t.ll
; RUN: %filecheck %s --check-prefix=ERR --allow-empty < %t.err
;
; CHECK-LABEL: define i32 @slice(
; CHECK:      %[[H:[a-z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 2.500000e-01)
; CHECK-NEXT: %[[H2:[a-z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 1)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H2]], double 5.000000e-01)
; CHECK:      ph:
; CHECK-NEXT: br label %body
; CHECK:      body:
; CHECK:      %[[F1:h_cmp[0-9]*]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[H]], i32 1)
; CHECK-NEXT: %[[F2:h_cmp[0-9]*]] = call i32 @cq_template_icmp_slt_i32_hl(i32 %[[H2]], i32 %i)
; CHECK-NEXT: %[[G:g[0-9]*]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_toffoli(i32 %[[F1]], i32 %[[F2]], i32 %[[G]])
; CHECK-NEXT: %[[OUT:out[0-9]*]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_xorc_i32_controlled(i32 %[[G]], i32 %[[OUT]], i32 %i)
; CHECK-NEXT: call void @cqrt_x(i32 %[[G]])
; CHECK-NEXT: call void @cqrt_xorc_i32_controlled(i32 %[[G]], i32 %[[OUT]], i32 55)
; CHECK-NEXT: call void @cqrt_x(i32 %[[G]])
; CHECK-NEXT: call void @cqrt_toffoli(i32 %[[F1]], i32 %[[F2]], i32 %[[G]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[G]])
; CHECK-NEXT: call void @cq_template_icmp_slt_i32_hl_unc(i32 %[[F2]], i32 %[[H2]], i32 %i)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F2]])
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[F1]], i32 %[[H]], i32 1)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F1]])
; CHECK-NEXT: %{{[a-z0-9_.]+}} = call i32 @cqrt_measure_i32(i32 %[[OUT]])
;
; NEG-NOT: icmp sgt i32 %q
; NEG-NOT: and i1
; NEG-NOT: select i1
; NEG-NOT: cqrt_free(i32 %h{{[0-9]*}})
; ERR-NOT: cq loop lowering
; ERR-NOT: error

define i32 @slice(i32 %n) {
entry:
  %q = call i32 @cq_theta_si32(i32 0, double 2.500000e-01)
  %r = call i32 @cq_theta_si32(i32 1, double 5.000000e-01)
  %guard = icmp sgt i32 %n, 0
  br i1 %guard, label %ph, label %exit

ph:
  %c1 = icmp sgt i32 %q, 1
  br label %body

exit:
  %s.lcssa = phi i32 [ 0, %entry ], [ %s.next, %body ]
  %mq = call i32 @cq_measure_si32(i32 %q)
  %mr = call i32 @cq_measure_si32(i32 %r)
  %s0 = add i32 %mq, %s.lcssa
  %s1 = add i32 %s0, %mr
  ret i32 %s1

body:
  %s = phi i32 [ 0, %ph ], [ %s.next, %body ]
  %i = phi i32 [ 0, %ph ], [ %i.next, %body ]
  %c2 = icmp slt i32 %r, %i
  %c = and i1 %c1, %c2
  %t = select i1 %c, i32 %i, i32 55
  %mt = call i32 @cq_measure_si32(i32 %t)
  %s.next = add nsw i32 %mt, %s
  %i.next = add nuw nsw i32 %i, 1
  %done = icmp eq i32 %i.next, %n
  br i1 %done, label %exit, label %body
}

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
