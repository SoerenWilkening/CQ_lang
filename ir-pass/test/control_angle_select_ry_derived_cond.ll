; control_angle_select_ry_derived_cond.ll — ACCEPT with a DERIVED condition
; operand (bd drbq Inc 2b).
;
;     if (q > 5 && q < 100) r = cq_theta(r, .9); else r = cq_theta(r, .3);
;
; `clang -O1` folds that whole conjunction into ONE compare on a derived value:
; `%d = add i32 %q, -6; %c = icmp ult i32 %d, 94` (measured — probe q13). So the
; compound-condition case that the `select` data path needs a flag NETWORK for
; arrives here as a plain single-leaf compare, and the accept takes it: S4 asks
; for a bare `CmpInst`, not for a bare OPERAND.
;
; What that costs is a real derived rail: `%d` lowers to
; `cq_template_add_i32_hl` on its OWN fresh rail, which the whole-DAG spine then
; uncomputes and frees after the strip has read it. The condition side of S8 sees
; that rail through `condProvenance` (which is why narrowing `condProvenance` is
; a Rule-13 change to S8, exactly as it is to Inc-1's R4).
;
; A REAL `and i1` TREE still declines — see
; `control_angle_select_reject_compound_cond.ll`; only ONE bare leaf is in scope
; for 2b.
; ORACLE DISPOSITION: RED on the pre-2b binary (`rotation angle under quantum
; control`, SelectClassify gate 3) — Rule 12 red-green.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=CNT     < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %u1) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @cq_theta_si32(i32 %u1, double 3.000000e-01)
  %d = add i32 %q, -6
  %c = icmp ult i32 %d, 94
  %ang = select i1 %c, double 9.000000e-01, double 3.000000e-01
  %t = call i32 @cq_theta_si32(i32 %r, double %ang)
  %mq = call i32 @cq_measure_si32(i32 %q)
  %mr = call i32 @cq_measure_si32(i32 %t)
  %s = add i32 %mq, %mr
  ret i32 %s
}

; CHECK:      %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[Q]], double 5.000000e-01)
; CHECK-NEXT: %[[R:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u1)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[R]], double 3.000000e-01)
; the derived condition rail
; CHECK-NEXT: %[[D:[a-zA-Z0-9_.]+]] = call i32 @cq_template_add_i32_hl(i32 %[[Q]], i32 -6)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[R]], double 3.000000e-01)
; CHECK-NEXT: %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_ult_i32_hl(i32 %[[D]], i32 94)
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %[[F]], i32 %[[R]], double 0x3FE3333333333334)
; CHECK-NEXT: call void @cq_template_icmp_ult_i32_hl_unc(i32 %[[F]], i32 %[[D]], i32 94)
; the derived rail is uncomputed and freed by the whole-DAG spine, AFTER the
; strip has read it
; CHECK-NEXT: call void @cq_template_add_i32_hl_unc(i32 %[[D]], i32 %[[Q]], i32 -6)
; CHECK-NEXT: call void @cqrt_free(i32 %[[D]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
; A STRAY ROTATION AFTER THE EMITTED STREAM was invisible to every one of the 17
; accept fixtures (round-1 Rule-13 review, L6-N11): an adjacency chain stops at
; its last `CHECK-NEXT`, and a `NOROUTE`-style whole-body negative cannot be used
; on a rotation symbol because the legitimate twin and gate are rotations. A
; TRAILING `CHECK-NOT` runs from the last match to EOF, which is exactly the
; uncovered region — and it is where a leaked rotation on a FROZEN rail would sit.
; CHECK-NOT: call void @cqrt_ry_
; CHECK-NOT: call void @cqrt_rz_

; NOROUTE:     define{{.*}}@example
; NOROUTE-NOT: call void @cqrt_cswap
; NOROUTE-NOT: call void @cqrt_x
; NOROUTE-NOT: select

; TWO frees: the derived condition rail and the flag. The two REGISTERS are left
; allocated (both are measured).
; CNT-COUNT-2: call void @cqrt_free(
; CNT-NOT:     call void @cqrt_free(
