; lowering_uncompute_interior_qq_fanout.ll — ACCEPT (M-B Increment 5a, bd
; test_C_libtooling-6uqc). FAN-OUT IS A DAG SHAPE, NOT A BAIL — the WI-4 property,
; now on the INTERIOR partition.
;
; `%h_op` (the Q+Q `mul`) has TWO forward consumers (`shl` and `lshr`) that
; reconverge in a Q+Q `add`. Rule 8 forbids reversing a shared prefix TWICE, and
; the whole-DAG spine's answer is a visited-set worklist that recovers it ONCE;
; the interior partition inherits exactly that, because it hands the SAME
; `recoverDataDag` a set of terminals. What it adds is the frontier: the two
; `cqrt_alloc`-minted source wires `%h`/`%h1` are BORROWED, so the walk stops
; there instead of collecting their `cqrt_ry`s and freeing the registers the
; program still owns.
;
; THE ORDERING CLAIM, which is the whole reason a fan-out rail needs its own
; fixture: `%h_op`'s `cqrt_free` must come after BOTH readers' `_unc`s, not after
; the first one. `emitDagReversal` keys the free on the EARLIEST gate that
; READS-OR-WRITES the rail (bd uow0), which in reverse is its LAST reverse-touch —
; so `mul_unc` (the writer, earliest in forward order) carries the free and both
; `shl_unc`/`lshr_unc` have already run. A free keyed on writes alone would be a
; use-after-free here.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @interior_qq(i32 %u0, i32 %u1) {
entry:
  %q1 = call i32 @cq_theta_si32(i32 %u0, double 2.500000e-01)
  %q2 = call i32 @cq_theta_si32(i32 %u1, double 5.000000e-01)
  %p  = mul i32 %q1, %q2
  %s1 = shl i32 %p, 2
  %s2 = lshr i32 %p, 3
  %j  = add i32 %s1, %s2
  %c  = icmp slt i32 %j, 100
  %z  = zext i1 %c to i32
  %m  = call i32 @cq_measure_si32(i32 %z)
  ret i32 %m
}

; CHECK-LABEL: define i32 @interior_qq(
; CHECK:      %[[H0:.*]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK:      %[[H1:.*]] = call i32 @cqrt_alloc_i32(i32 %u1)
; CHECK:      %[[P:.*]] = call i32 @cq_template_mul_i32(i32 %[[H0]], i32 %[[H1]])
; CHECK-NEXT: %[[S1:.*]] = call i32 @cq_template_shl_i32_hl(i32 %[[P]], i32 2)
; CHECK-NEXT: %[[S2:.*]] = call i32 @cq_template_lshr_i32_hl(i32 %[[P]], i32 3)
; CHECK-NEXT: %[[J:.*]] = call i32 @cq_template_add_i32(i32 %[[S1]], i32 %[[S2]])
; CHECK-NEXT: %[[C:.*]] = call i32 @cq_template_icmp_slt_i32_hl(i32 %[[J]], i32 100)
; CHECK-NEXT: %[[Z:.*]] = call i32 @cq_template_zext_i1_to_i32(i32 %[[C]])
; CHECK-NEXT: call void @cq_template_icmp_slt_i32_hl_unc(i32 %[[C]], i32 %[[J]], i32 100)
; CHECK-NEXT: call void @cqrt_free(i32 %[[C]])
; CHECK-NEXT: call void @cq_template_add_i32_unc(i32 %[[J]], i32 %[[S1]], i32 %[[S2]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[J]])
; CHECK-NEXT: call void @cq_template_lshr_i32_hl_unc(i32 %[[S2]], i32 %[[P]], i32 3)
; CHECK-NEXT: call void @cqrt_free(i32 %[[S2]])
; CHECK-NEXT: call void @cq_template_shl_i32_hl_unc(i32 %[[S1]], i32 %[[P]], i32 2)
; CHECK-NEXT: call void @cqrt_free(i32 %[[S1]])
; CHECK-NEXT: call void @cq_template_mul_i32_unc(i32 %[[P]], i32 %[[H0]], i32 %[[H1]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[P]])
; CHECK-NEXT: %[[M:.*]] = call i32 @cqrt_measure_i32(i32 %[[Z]])

; The shared prefix is adjointed EXACTLY ONCE (Rule 8) and the two source wires
; are never touched.
; CHECK-NOT: call void @cq_template_mul_i32_unc
