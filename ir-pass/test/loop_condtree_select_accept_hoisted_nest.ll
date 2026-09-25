; loop_condtree_select_accept_hoisted_nest.ll — ACCEPT (bd
; test_C_libtooling-xdu2.16), the hoisted tree in a NEST.
;
; `for (j < m) { int s = 0; for (i < n) { int t = ((q > 1) & (r < 5)) ? i : 55;
;  s += cq_measure(t); } a += s; }` — `clang -O1` hoists the invariant tree OUT OF
; BOTH LOOPS into the OUTER preheader `%oph`. Round 1 grants the INNER loop on the
; (ii-d) root `%c` (`loopExitDischargePoint` asked of the INNER loop — the bd `4jok`
; F-1 quantifier; here it never matters, because the rail is never minted); the
; OUTER loop is not granted (its body contains the inner loop's quantum content).
; The 4.4 emitter erases `%c`, `%c1`, `%c2`; the pre-change ORACLE
; `438c77bf45c02e3e` then declines `cq loop lowering: round-1 iteration-local
; marking falsified by round-2 taint`.
;
; After the change the INNER grant is re-derived under FINAL taint (roots `%q`,
; `%r`, read by the in-body flag mints) and stands. What this fixture pins beyond
; the flat-loop ones: the per-trip stream lands in the INNERMOST body and NOTHING
; of the tree survives in either preheader — no outer-loop placement, and the
; (ii-d) exit obligation recorded for `%c` at round 1 names an erased value, so the
; postcondition `declineUndischargedExitObligations` reads it as vacuously
; discharged (there is no rail to leak) and does not fire.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll 2> %t.err
; RUN: %filecheck %s < %t.ll
; RUN: %filecheck %s --check-prefix=NEG < %t.ll
; RUN: %filecheck %s --check-prefix=CNT < %t.ll
; RUN: %filecheck %s --check-prefix=ERR --allow-empty < %t.err
;
; CHECK-LABEL: define i32 @slice(
; CHECK:      oph:
; CHECK-NEXT: %iguard = icmp sgt i32 %n, 0
; CHECK-NEXT: br label %outer
; CHECK:      inner:
; CHECK:      %[[F1:h_cmp[0-9]*]] = call i32 @cq_template_icmp_sgt_i32_hl(
; CHECK-NEXT: %[[F2:h_cmp[0-9]*]] = call i32 @cq_template_icmp_slt_i32_hl(
; CHECK-NEXT: %[[G:g[0-9]*]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_toffoli(i32 %[[F1]], i32 %[[F2]], i32 %[[G]])
; CHECK:      call void @cqrt_toffoli(i32 %[[F1]], i32 %[[F2]], i32 %[[G]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[G]])
; CHECK-NEXT: call void @cq_template_icmp_slt_i32_hl_unc(
; CHECK-NEXT: call void @cqrt_free(i32 %[[F2]])
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(
; CHECK-NEXT: call void @cqrt_free(i32 %[[F1]])
; CHECK-NEXT: %{{[a-z0-9_.]+}} = call i32 @cqrt_measure_i32(
;
; NEG-NOT: and i1
; NEG-NOT: select i1
; NEG-NOT: cqrt_free(i32 %h{{[0-9]*}})
; CNT-COUNT-2: call void @cqrt_toffoli(
; CNT-NOT: call void @cqrt_toffoli(
; ERR-NOT: cq loop lowering
; ERR-NOT: error

define i32 @slice(i32 %n, i32 %m) {
entry:
  %q = call i32 @cq_theta_si32(i32 0, double 2.500000e-01)
  %r = call i32 @cq_theta_si32(i32 1, double 5.000000e-01)
  %oguard = icmp sgt i32 %m, 0
  br i1 %oguard, label %oph, label %exit

oph:
  %iguard = icmp sgt i32 %n, 0
  %c1 = icmp sgt i32 %q, 1
  %c2 = icmp slt i32 %r, 5
  %c = and i1 %c1, %c2
  br label %outer

outer:
  %a = phi i32 [ 0, %oph ], [ %a.next, %olatch ]
  %j = phi i32 [ 0, %oph ], [ %j.next, %olatch ]
  br i1 %iguard, label %inner, label %olatch

exit:
  %a.lcssa = phi i32 [ 0, %entry ], [ %a.next, %olatch ]
  %mq = call i32 @cq_measure_si32(i32 %q)
  %mr = call i32 @cq_measure_si32(i32 %r)
  %s0 = add nsw i32 %mr, %mq
  %s1 = add nsw i32 %s0, %a.lcssa
  ret i32 %s1

olatch:
  %s.lcssa = phi i32 [ 0, %outer ], [ %s.next, %inner ]
  %a.next = add nsw i32 %s.lcssa, %a
  %j.next = add nuw nsw i32 %j, 1
  %odone = icmp eq i32 %j.next, %m
  br i1 %odone, label %exit, label %outer

inner:
  %i = phi i32 [ %i.next, %inner ], [ 0, %outer ]
  %s = phi i32 [ %s.next, %inner ], [ 0, %outer ]
  %t = select i1 %c, i32 %i, i32 55
  %mt = call i32 @cq_measure_si32(i32 %t)
  %s.next = add nsw i32 %mt, %s
  %i.next = add nuw nsw i32 %i, 1
  %idone = icmp eq i32 %i.next, %n
  br i1 %idone, label %olatch, label %inner
}

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
