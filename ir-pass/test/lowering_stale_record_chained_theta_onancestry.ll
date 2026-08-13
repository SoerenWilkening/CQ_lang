; lowering_stale_record_chained_theta_onancestry.ll — ACCEPT: the
; on-ancestry-producer boundary of the chained-theta fix (test_C_libtooling-6vk,
; the positive twin of lowering_reject_stale_record_chained_theta_sibling.ll).
;
; `%d = add i32 %q2, 3` reads the CHAINED theta `%q2 = cq_theta(%q, %t2)`, and
; the ONLY theta on `%q`'s wire below the source is `%q2` itself — the gate
; that PRODUCES the record `%q2` denotes. The fix crosses the chained-theta
; arg-0 hop to the wire origin `%q` but EXEMPTS the on-ancestry producing
; thetas (`%q2`, `%q`) from the staling-gate frontier; with no OFF-ancestry
; sibling re-rotating the wire, nothing stales `%q2`'s record and the add
; lowers. This is the load-bearing don't-over-decline boundary: flagging the
; producing theta would reject every legitimate chained-rotation consumer in
; the language. The template fires AFTER both ry calls, reading the wire
; exactly as `%q2`'s record prescribes.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
;
; CHECK:      %[[H:.*]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK:      call void @cqrt_ry_i32(i32 %[[H]], double %g)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double %t2)
; CHECK-NEXT: %[[D:.*]] = call i32 @cq_template_add_i32_hl(i32 %[[H]], i32 3)
; CHECK:      call i32 @cqrt_measure_i32(i32 %[[D]])

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, double %g, double %t2) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double %g)
  %q2 = call i32 @cq_theta_si32(i32 %q, double %t2)   ; chained Ry — the only theta on %q's wire
  %d  = add i32 %q2, 3                                ; reads the producing record, no sibling
  %m  = call i32 @cq_measure_si32(i32 %d)
  ret i32 %m
}
