; lowering_uncompute_interior_leak_region_addc_inside.ll — LEAK PROBE (M-B
; Increment 6, clause (d2); bd test_C_libtooling-160a Rule-13 round, finding
; F1e). Second of three: the write on the routed base sits AFTER the region but
; BEFORE the chain rail's last reader, so it is still inside the interval.
;
; This is the position the exemption is most likely to be misread at. The
; recorded route group IS fully inside and IS exempted; the `cqrt_addc_i32(%h,5)`
; that follows it is inside the SAME interval and is NOT. `%h_op` is read again
; afterwards (`%h_op & 7`, measured), so `At` lands past the addc — and the
; would-be `mul_unc(%h_op, %h, 37)` there would read `%h + 5` where the forward
; `mul` read `%h`. The scan refuses it and the component LEAKS.
;
; TOGETHER WITH ITS TWO SIBLINGS this is the whole clause-(d2) statement:
;   * ..._leak_region_addc_before.ll        write between forward gate and region
;   * this file                             write after the region, before the last reader
;   * ..._region_addc_after_readers.ll      write after every reader -> RIGHT -> discharges
; The exemption moves NONE of that; it only removes the route pair from the set
; of writes the scan must clear.
;
; NO RED STATE on an earlier plugin (it leaks on `439dae3` and `f27c7fd` too, for
; different reasons); its discriminator is the same clause-(d) mutation as the
; `_before` sibling — MEASURED: turning that clause's final `return false` into
; a `continue` reddens both leak fixtures while the accept twin stays green.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOCHAIN < %t.cqd0.ll
; 3qlq: migrated from register cq_phi (tainted arm -> void call, merge phi dissolved)
declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare void @cqrt_addc_i32(i32, i32)

define i32 @addc_inside_interval(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %d = mul nsw i32 %q, 37
  %k = and i32 %d, -8
  %c = icmp eq i32 %k, 40
  br i1 %c, label %arm, label %merge
arm:
  call void @cq_phi(double 0x400921FB54442D18)
  br label %merge
merge:
  call void @cqrt_addc_i32(i32 %q, i32 5)
  %t = and i32 %d, 7
  %m1 = call i32 @cq_measure_si32(i32 %q)
  %m2 = call i32 @cq_measure_si32(i32 %t)
  %s = add i32 %m1, %m2
  ret i32 %s
}

; CHECK-LABEL: define i32 @addc_inside_interval(
; CHECK:      %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: %[[D:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32_hl(i32 %[[H]], i32 37)
; CHECK-NEXT: %[[K:[a-zA-Z0-9_.]+]] = call i32 @cq_template_and_i32_hl(i32 %[[D]], i32 -8)
; CHECK-NEXT: %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[K]], i32 40)
; the region, CONTROL-IN-PLACE since drbq Inc 2a: one `cqrt_rz_<W>_controlled` on
; the user's own register in place of the route quintuple — no work rail, no
; CSWAP, nothing to free but the flag.
; CHECK-NEXT: call void @cqrt_rz_i32_controlled(i32 %[[F]], i32 %[[H]], double 0x400921FB54442D18)
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F]], i32 %[[K]], i32 40)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
; The write that is inside the interval and is NOT a route member:
; CHECK-NEXT: call void @cqrt_addc_i32(i32 %[[H]], i32 5)
; CHECK-NEXT: %[[T:[a-zA-Z0-9_.]+]] = call i32 @cq_template_and_i32_hl(i32 %[[D]], i32 7)
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[H]])
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[T]])

; Nothing of the chain is reversed or freed anywhere past the strip:
; NOCHAIN:      call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F2:[a-zA-Z0-9_.]+]], i32 {{.*}}, i32 40)
; NOCHAIN-NEXT: call void @cqrt_free(i32 %[[F2]])
; NOCHAIN-NOT:  call void @cq_template
; NOCHAIN-NOT:  call void @cqrt_free(
