; condtree_classical_leaf_accept_predmux_ruleb.ll — ACCEPT (bd
; test_C_libtooling-xdu2.13, the q2wk rule-(B) record).
;
; A PredMux region whose entry condition is the MIXED `and (m == n), (q != 0)`
; and whose inner branch condition `%c = icmp eq %kk, 0` is admitted by E6 rule
; (B) (untainted now, derived from the region φ `%kk` the flatten taints). The
; flatten MARKS `%c`'s i1 cone and the edge literals built from it
; (`!cq.predmux.predicted`); here the prediction HOLDS (`%c` lowers as the
; tainted `icmp_ne_i32_hl(%out, 0)` flag), and the genuine classical leaf `%g`
; (and PredMux's De Morgan clone `icmp ne %m, %n` on the ¬-edge, which lowers
; through `cq_template_or_i1_hl`) is a literal in every select tree.
; Pins: (1) a mark does NOT refuse an unrelated genuine literal in the same
; region, (2) the marks are STRIPPED before output, (3) PredMux-minted trees
; carry literals through both `and` and `or` nodes. ⚠ The DECLINE direction of
; the record (a rule-(B) residue that stays untainted) has no constructed
; subject — see the E6 block in PredMuxFlatten.cpp.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
; RUN: %filecheck %s --check-prefix=NEG < %t.ll
;
; CHECK-LABEL: define i32 @f(
; CHECK: entry:
; CHECK: %[[V0:[a-z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[V0]], double 2.500000e-01)
; CHECK-NEXT: %g = icmp eq i32 %m, %n
; CHECK-NEXT: %[[V1:[a-z0-9_.]+]] = call i32 @cq_template_icmp_ne_i32_hl(i32 %[[V0]], i32 0)
; CHECK-NEXT: %[[V2:[a-z0-9_.]+]] = call i32 @cq_template_and_i1_hl(i32 %[[V1]], i1 zeroext %g)
; CHECK-NEXT: %[[V3:[a-z0-9_.]+]] = call i32 @cq_template_icmp_sle_i32_hl(i32 %[[V0]], i32 2)
; CHECK-NEXT: %[[V4:[a-z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_toffoli(i32 %[[V2]], i32 %[[V3]], i32 %[[V4]])
; CHECK-NEXT: %[[V5:[a-z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: %[[V6:[a-z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %x)
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[V4]], i32 %[[V6]], i32 %[[V5]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[V4]])
; CHECK-NEXT: %[[V7:[a-z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %y)
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[V4]], i32 %[[V7]], i32 %[[V5]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[V4]])
; CHECK-NEXT: call void @cqrt_toffoli(i32 %[[V2]], i32 %[[V3]], i32 %[[V4]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[V4]])
; CHECK-NEXT: call void @cq_template_and_i1_hl_unc(i32 %[[V2]], i32 %[[V1]], i1 zeroext %g)
; CHECK-NEXT: call void @cqrt_free(i32 %[[V2]])
; CHECK-NEXT: call void @cq_template_icmp_sle_i32_hl_unc(i32 %[[V3]], i32 %[[V0]], i32 2)
; CHECK-NEXT: call void @cqrt_free(i32 %[[V3]])
; CHECK-NEXT: call void @cq_template_icmp_ne_i32_hl_unc(i32 %[[V1]], i32 %[[V0]], i32 0)
; CHECK-NEXT: call void @cqrt_free(i32 %[[V1]])
; CHECK-NEXT: %[[V8:[a-z0-9_.]+]] = call i32 @cq_template_icmp_ne_i32_hl(i32 %[[V0]], i32 0)
; CHECK-NEXT: %[[V9:[a-z0-9_.]+]] = call i32 @cq_template_and_i1_hl(i32 %[[V8]], i1 zeroext %g)
; CHECK-NEXT: %[[V10:[a-z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[V0]], i32 2)
; CHECK-NEXT: %[[V11:[a-z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_toffoli(i32 %[[V9]], i32 %[[V10]], i32 %[[V11]])
; CHECK-NEXT: %[[V12:[a-z0-9_.]+]] = call i32 @cq_template_icmp_sle_i32_hl(i32 %[[V0]], i32 2)
; CHECK-NEXT: %[[V13:[a-z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_toffoli(i32 %[[V9]], i32 %[[V12]], i32 %[[V13]])
; CHECK-NEXT: %[[V14:[a-z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_cnot(i32 %[[V11]], i32 %[[V14]])
; CHECK-NEXT: call void @cqrt_cnot(i32 %[[V13]], i32 %[[V14]])
; CHECK-NEXT: call void @cqrt_toffoli(i32 %[[V11]], i32 %[[V13]], i32 %[[V14]])
; CHECK-NEXT: %[[V15:[a-z0-9_.]+]] = call i32 @cq_template_icmp_ne_i32_hl(i32 %[[V5]], i32 0)
; CHECK-NEXT: %[[V16:[a-z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_toffoli(i32 %[[V14]], i32 %[[V15]], i32 %[[V16]])
; CHECK-NEXT: %[[V17:[a-z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: %[[V18:[a-z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 8)
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[V16]], i32 %[[V18]], i32 %[[V17]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[V16]])
; CHECK-NEXT: %[[V19:[a-z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 9)
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[V16]], i32 %[[V19]], i32 %[[V17]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[V16]])
; CHECK-NEXT: call void @cqrt_toffoli(i32 %[[V14]], i32 %[[V15]], i32 %[[V16]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[V16]])
; CHECK-NEXT: call void @cqrt_toffoli(i32 %[[V11]], i32 %[[V13]], i32 %[[V14]])
; CHECK-NEXT: call void @cqrt_cnot(i32 %[[V13]], i32 %[[V14]])
; CHECK-NEXT: call void @cqrt_cnot(i32 %[[V11]], i32 %[[V14]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[V14]])
; CHECK-NEXT: call void @cqrt_toffoli(i32 %[[V9]], i32 %[[V12]], i32 %[[V13]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[V13]])
; CHECK-NEXT: call void @cqrt_toffoli(i32 %[[V9]], i32 %[[V10]], i32 %[[V11]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[V11]])
; CHECK-NEXT: call void @cq_template_and_i1_hl_unc(i32 %[[V9]], i32 %[[V8]], i1 zeroext %g)
; CHECK-NEXT: call void @cqrt_free(i32 %[[V9]])
; CHECK-NEXT: call void @cq_template_icmp_ne_i32_hl_unc(i32 %[[V15]], i32 %[[V5]], i32 0)
; CHECK-NEXT: call void @cqrt_free(i32 %[[V15]])
; CHECK-NEXT: call void @cq_template_icmp_sle_i32_hl_unc(i32 %[[V12]], i32 %[[V0]], i32 2)
; CHECK-NEXT: call void @cqrt_free(i32 %[[V12]])
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[V10]], i32 %[[V0]], i32 2)
; CHECK-NEXT: call void @cqrt_free(i32 %[[V10]])
; CHECK-NEXT: call void @cq_template_icmp_ne_i32_hl_unc(i32 %[[V8]], i32 %[[V0]], i32 0)
; CHECK-NEXT: call void @cqrt_free(i32 %[[V8]])
; CHECK-NEXT: %[[V20:[a-z0-9_.]+]] = icmp ne i32 %m, %n
; CHECK-NEXT: %[[V21:[a-z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[V0]], i32 0)
; CHECK-NEXT: %[[V22:[a-z0-9_.]+]] = call i32 @cq_template_or_i1_hl(i32 %[[V21]], i1 zeroext %[[V20]])
; CHECK-NEXT: %[[V23:[a-z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: %[[V24:[a-z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 7)
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[V22]], i32 %[[V24]], i32 %[[V23]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[V22]])
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[V22]], i32 %[[V17]], i32 %[[V23]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[V22]])
; CHECK-NEXT: call void @cq_template_or_i1_hl_unc(i32 %[[V22]], i32 %[[V21]], i1 zeroext %[[V20]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[V22]])
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[V21]], i32 %[[V0]], i32 0)
; CHECK-NEXT: call void @cqrt_free(i32 %[[V21]])
; CHECK-NEXT: br label %M
; CHECK: M:
; CHECK-NEXT: %[[V25:[a-z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[V0]])
; CHECK-NEXT: %[[V26:[a-z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[V23]])
; CHECK-NEXT: %s = add i32 %[[V25]], %[[V26]]
; CHECK-NEXT: ret i32 %s
;
; NEG-NOT: cqrt_alloc_i1(i1 %g)
; NEG-NOT: select i1
; NEG-NOT: cq.predmux

define i32 @f(i32 %x, i32 %y, i32 %m, i32 %n) {
entry:
  %q = call i32 @cq_theta_si32(i32 0, double 2.500000e-01)
  %t = icmp ne i32 %q, 0
  %g = icmp eq i32 %m, %n
  %tg = and i1 %g, %t
  br i1 %tg, label %A, label %M

A:
  %u = icmp sgt i32 %q, 2
  br i1 %u, label %B, label %D

B:
  br label %D

D:
  %kk = phi i32 [ %x, %A ], [ %y, %B ]
  %c = icmp eq i32 %kk, 0
  br i1 %c, label %E, label %M

E:
  br label %M

M:
  %r = phi i32 [ 7, %entry ], [ 8, %D ], [ 9, %E ]
  %m0 = call i32 @cq_measure_si32(i32 %q)
  %m1 = call i32 @cq_measure_si32(i32 %r)
  %s = add i32 %m0, %m1
  ret i32 %s
}

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
