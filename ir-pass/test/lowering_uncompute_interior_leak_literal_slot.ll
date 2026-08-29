; lowering_uncompute_interior_leak_literal_slot.ll — LEAK PROBE (M-B Increment
; 5, bd test_C_libtooling-4p7j Rule-13 round, finding F5). A `cq_template_*`
; consumer that reads the rail in its CLASSICAL-LITERAL slot is NOT an interior
; consumer, so the rail it reads is not an interior terminal.
;
; THE HOLE. `isInteriorConsumer` admitted any forward `isTemplateProducer` call
; that had the rail among its arguments, WITHOUT asking which slot read it. The
; `_hl` form is `(handle, classical)` — at width i32 BOTH slots are `i32` in the
; IR, so nothing about the type distinguishes them and the check has to come
; from the SYMBOL, which is where `TemplateName` spells the shape suffix. Here
; `cq_template_add_i32_hl(i32 %h, i32 %h_op)` puts `%h_op` in the literal slot,
; and at 99211ad `%h_op` was discharged (`mul_i32_hl_unc` + `cqrt_free`) on the
; strength of that call alone.
;
; WHY IT IS HYGIENE AND NOT A MISCOMPILE TODAY: no lowering the pass performs
; can produce this call — `ArithLowering` picks `_hl`/`_lh` precisely so the
; handle lands in the handle slot and the literal slot holds a `Constant`. The
; module below is hand-written IR, which the pass accepts (`cq_template_` is
; carved out of taint collection by name), and nothing wrote `%h_op`, so the
; free was not dirty. It is fenced anyway because the predicate — not the
; accident of what today's emitters mint — is what the next increment will
; widen. Over-declining a shape no emitter produces costs one leaked rail.
;
; THE CHECK IS SLOT-AWARE VIA THE ONE TABLE: `cq::isHandleSlot`, the inverse of
; `TemplateName`'s own `shapeSuffix` (`_hl` → slot 0, `_lh` → slot 1,
; `_qql`/`_qlq`/`_qll` → the fma mixed forms, no suffix → every slot). Rule 14:
; a second hand-rolled slot table in `ChainWalk` is exactly the drift the
; `railOf` / `isAbiQramStore` history warns about.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOFREEOP < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i32 @cq_template_add_i32_hl(i32, i32)

define i32 @interior_literal_slot(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = mul i32 %q, 5
  ; %r reaches the CLASSICAL slot of an `_hl` template — not a handle use:
  %t = call i32 @cq_template_add_i32_hl(i32 %q, i32 %r)
  %m = call i32 @cq_measure_si32(i32 %t)
  %m2 = call i32 @cq_measure_si32(i32 %q)
  %s = add i32 %m, %m2
  ret i32 %s
}

; The forward stream is untouched:
; CHECK-LABEL: define i32 @interior_literal_slot(
; CHECK:      %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: %[[OP:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32_hl(i32 %[[H]], i32 5)
; CHECK-NEXT: %[[T:[a-zA-Z0-9_.]+]] = call i32 @cq_template_add_i32_hl(i32 %[[H]], i32 %[[OP]])
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[T]])

; Nothing is adjointed and nothing is freed (one anchor, one prefix ⇒ window
; anchor -> EOF; bd memory [filecheck-check-not-window-trap]):
; NOFREEOP:     %[[OP2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32_hl(
; NOFREEOP-NOT: _unc(
; NOFREEOP-NOT: call void @cqrt_free(
