; control_swap_value_accept_qq_compare_on_merge.ll — ACCEPT spec: a DOWNSTREAM
; Q+Q DATA COMPARE off a VALUE-arm merge, at i32 — the FLAGSHIP width.
;
; ⚠ THE LOAD-BEARING ROW OF AN ACCEPT-CLASS WIDENING (bd test_C_libtooling-3qlq
; Inc 2, Rule-13 round-1 review F-V1-1; owner disposition OQ-22 KEEP+PIN). The
; widening is NOT a sub-i32 artefact: `CompareLowering::rewriteCompare`'s Q+Q
; path needs a RECORDED logical width and never falls back to the SSA type, so
; `int e = (p == r);` after a value arm declined at i32 too. MEASURED on this
; module: ORACLE 52d7764 rc=1
; `no template for opcode 'icmp i1' in tainted context`; SUBJECT rc=0, the
; stream below, `free_pairing_check.py` STRICT rc=0.
;
; MECHANISM: Inc 2 routes the value diamond through `emitSelectRegion`, which
; records `taint.HandleWidth[out] = Abi` (bd p119.6). The retired
; `emitValueRegion` wrote no such entry. Every merge gate below is the 4.4
; select merge's own — the widening is that the CONSUMER now resolves.
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=FCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=CCNT < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %v0, i32 %w0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %p = call i32 @cq_theta_si32(i32 %v0, double 2.500000e-01)
  %r = call i32 @cq_theta_si32(i32 %w0, double 1.250000e-01)
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %v1 = mul i32 %p, 5
  %v2 = add i32 %v1, 15
  br label %merge
merge:
  %pm = phi i32 [ %v2, %arm ], [ %p, %entry ]
  %e  = icmp eq i32 %pm, %r
  %ez = zext i1 %e to i32
  %m  = call i32 @cq_measure_si32(i32 %ez)
  ret i32 %m
}

; CHECK:      %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[Q]], double 5.000000e-01)
; CHECK-NEXT: %[[P:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %v0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[P]], double 2.500000e-01)
; CHECK-NEXT: %[[R:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %w0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[R]], double 1.250000e-01)
; CHECK-NEXT: %[[V:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32_hl(i32 %[[P]], i32 5)
; CHECK-NEXT: call void @cqrt_addc_i32(i32 %[[V]], i32 15)
; CHECK-NEXT: %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[Q]], i32 5)
; CHECK-NEXT: %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[F]], i32 %[[V]], i32 %[[OUT]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[F]], i32 %[[P]], i32 %[[OUT]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; THE WIDENING: a Q+Q data compare whose LEFT operand is the merged register.
; It mints its own flag rail, is stripped by its own `_unc` and freed — the
; ordinary data-compare discipline, at the RECORDED i32 width.
; CHECK-NEXT: %[[E:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32(i32 %[[OUT]], i32 %[[R]])
; CHECK-NEXT: %[[EZ:[a-zA-Z0-9_.]+]] = call i32 @cq_template_zext_i1_to_i32(i32 %[[E]])
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_unc(i32 %[[E]], i32 %[[OUT]], i32 %[[R]])
; bd r2j3.32: the merge rail is reversed after its last reader -- the copy
; core re-emitted in reverse under the SAME flag, the flag strip DEFERRED to
; after it, then the rail freed (it used to leak; a later gate on the
; condition register dephased against it).
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[F]], i32 %[[P]], i32 %[[OUT]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[F]], i32 %[[V]], i32 %[[OUT]])
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[F]], i32 %[[Q]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[OUT]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[E]])
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[EZ]])

; NOROUTE-NOT: cqrt_cswap
; NOROUTE-NOT: call void @cqrt_copy_i32(
; NOROUTE-NOT: phi i32
; NOROUTE-NOT: call i32 @cq_theta
; NOROUTE-NOT: icmp eq i32
; the Q+Q compare must NOT be minted as a one-handle `_hl`/`_lh` form
; NOROUTE-NOT: cq_template_icmp_eq_i32_hl
; NOROUTE-NOT: cq_template_icmp_eq_i32_lh

; TWO frees: the region's flag and the downstream data compare's own flag. The
; merge out-rail, `%p` and the chain final stay ALLOCATED (Rule 6).
; FCNT-COUNT-3: call void @cqrt_free(
; FCNT-NOT:     call void @cqrt_free(
; CCNT-COUNT-4: call void @cqrt_copy_i32_controlled(
; CCNT-NOT:     call void @cqrt_copy_i32_controlled(
