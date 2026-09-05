; control_inplace_rz_share_cond_flag.ll — the §6a Rz peephole on a ziov
; SHARE-COND-FLAG region: the condition compare is ALSO read as DATA
; (bd test_C_libtooling-drbq Inc 2a; PRD §12.2 keeps ShareCondFlag on the same
; path it has today, strip skipped).
;
; TWO THINGS THE OTHER Rz FIXTURES CANNOT PIN, and both are about the flag rather
; than the gate:
;   * MINT POSITION. On the share path the flag is minted at the COMPARE
;     (`Cond->getNextNode()`), not at the branch, so it dominates the data `zext`
;     that may precede the region's stream. The gate is still hoisted to just
;     before the branch, so mint < gate holds either way.
;   * NO STRIP AND NO FLAG FREE. The data lineage owns the handle (escaped or
;     measured, classifyArms-proven). Stripping here would return the flag to |0>
;     BEFORE the data read (a read-after-collapse) and freeing it would be a hidden
;     measurement. So this is the one accepted Rz shape with ZERO `cqrt_free` from
;     the region itself.
;
; Both properties are inherited verbatim from the routed path — Inc 2a changed only
; what sits between the mint and the (absent) strip.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; The ROUTE'S ABSENCE, on its own prefix anchored at the function header. A
; trailing CHECK-NOT scans only past the LAST positive of its own prefix, and every
; route line lands BEFORE that, so it could never fire (bd memory
; filecheck-check-not-window-trap). The window reaches the declares too, hence the
; `call void @` anchors.
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
; 3qlq: migrated from register cq_phi (tainted arm -> void call, merge phi dissolved)
declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u0, i32 %v0, double %a) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @cq_theta_si32(i32 %v0, double 2.500000e-01)
  %c = icmp sgt i32 %q, 5
  %d = zext i1 %c to i32
  br i1 %c, label %arm, label %merge
arm:
  call void @cq_phi(double %a)
  br label %merge
merge:
  %sum = add i32 %r, %d
  %m  = call i32 @cq_measure_si32(i32 %sum)
  ret i32 %m
}

; the flag is minted AT THE COMPARE, so it dominates the data cast below
; CHECK:      %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[Q:[a-zA-Z0-9_.]+]], i32 5)
; the SHARED flag feeds the data lineage — no second mint (the ziov bug)
; CHECK-NEXT: %[[D:[a-zA-Z0-9_.]+]] = call i32 @cq_template_zext_i1_to_i32(i32 %[[F]])
; the arm gate, controlled, in place
; CHECK-NEXT: call void @cqrt_rz_i32_controlled(i32 %[[F]], i32 %[[R:[a-zA-Z0-9_.]+]], double %a)
; the data use of the flag, downstream of the region's stream
; CHECK-NEXT: call i32 @cq_template_add_i32(i32 %[[R]], i32 %[[D]])
; NO strip and NO flag free: the data lineage reclaims it
; CHECK-NOT:  cq_template_icmp_sgt_i32_hl_unc
; CHECK-NOT:  call void @cqrt_free

; NOROUTE: define i32 @example
; NOROUTE-NOT: call void @cqrt_cswap
; NOROUTE-NOT: call i32 @cqrt_alloc_i32(i32 0)
; NOROUTE-NOT: call void @cqrt_x(
; NOROUTE-NOT: call void @cqrt_copy
; NOROUTE-NOT: phi i32
