; lowering_live_record_clone_return_rail_measured_accept.ll — ACCEPT: clause 4
; (the COLLAPSE exemption) for the COPY-DESTINATION class (M-A Increment 3, bd
; test_C_libtooling-6uqc).
;
; HISTORY, because this file changed meaning and the old meaning is now WRONG.
; It shipped as `lowering_live_record_clone_return_rail_accept.ll` and was the
; pinned MEASURED RESIDUAL OVER-ACCEPT of Increment 1: the clone's `cqq.out` copy
; rail was said to stand as "a live undischarged basis record of the wire at the
; second cqrt_ry", accepted only because the copy-destination class was
; ruled-deferred. THAT DESCRIPTION IS PHYSICALLY STALE and was already stale when
; M-C Increment 2a shipped. `u = r + 1` now lowers IN PLACE to
; `cqrt_addc_i32(%r, 1)`, so `u` and `r` ARE ONE REGISTER and the user's
; `cq_measure(u)` MEASURES THE RETURNED RAIL ITSELF — before the gate. The rail
; is collapsed, not live, and clause 4 exempts it. The module lowers for a
; correct physical reason, not for a scope gap.
;
; The residual over-accept it used to pin now lives in
; lowering_reject_live_record_clone_return_rail.ll, which is the same program
; with `u = r * 2` (out of place, so the copy rail stays a distinct dead record)
; — and that one DECLINES under Increment 3.
;
; SOURCE (`clang -O1` emits exactly the SSA below — NO control flow anywhere):
;     __attribute__((noinline)) static int inner(int x){ return x + 3; }
;     a = cq_theta(a, 0.5);
;     int r = inner(a);        // clone hop; the Bennett wrap returns `cqq.out`
;     int u = r + 1;           // M-C: IN PLACE on the returned rail
;     int m = cq_measure(u);   // ...so this MEASURES the copy rail, before T
;     a = cq_theta(a, 0.7);    // T — chained, in-place Ry on the wire
;
; WHAT IS PINNED HERE, and they are three separate claims:
;   * CLAUSE 4 on the copy rail — `cqrt_addc_i32(%r, 1)` then
;     `cqrt_measure_i32(%r)`, both before the chained `cqrt_ry_i32(%h, 0.7)`.
;   * THE CALLER NEVER DISCHARGES THE RETURNED RAIL (NOFREE). That is still true
;     and still a qubit leak in the Rule-6 accepted sense; it is simply not a
;     dephasing hazard once the rail is measured. The guard anchors on the
;     CALLER's name for the rail, not on the clone-local `cqq.out` alloc: the
;     module prints @main first, so a body-anchored window would open only after
;     @main's `ret`, and the e2e-fixture-guard-liveness gate rightly rejects a
;     dead guard.
;   * THE `inBennettClone` FENCE — inside the CLONE BODY `%a = add nsw i32 %x, 3`
;     is STILL LOWERED OUT OF PLACE (`cq_template_add_i32_hl` + its `_unc` +
;     `cqrt_free`). `specialize` passes `inBennettClone=true` and it must: the
;     wrap builds its ForwardStream by SCANNING for `isForwardTemplate` members,
;     and a void `cqrt_addc` is not one — it would be omitted, never reversed, and
;     would leave the BORROWED argument `%x` permanently shifted for every caller
;     and for the synthesized `_unc` twin. If a `cqrt_addc` ever appears inside
;     @__cq_q_inner_1 below, that fence has been lost.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOFREE < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=CLONE < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @main() {
  %q  = call i32 @cq_theta_si32(i32 1, double 5.000000e-01)
  %r  = call fastcc i32 @inner(i32 %q)                        ; -> the `cqq.out` copy rail
  %u  = add nsw i32 %r, 1                                     ; M-C: in place ON that rail
  %m  = call i32 @cq_measure_si32(i32 %u)                     ; => the rail is COLLAPSED
  %q2 = call i32 @cq_theta_si32(i32 %q, double 7.000000e-01)  ; T — lowers
  %m2 = call i32 @cq_measure_si32(i32 %q2)
  %s  = add nsw i32 %m2, %m
  ret i32 %s
}

define internal fastcc i32 @inner(i32 %x) {
  %a = add nsw i32 %x, 3
  ret i32 %a
}

; CHECK:      %[[H:.*]] = call i32 @cqrt_alloc_i32(i32 1)
; CHECK:      call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK:      %[[R:.*]] = call fastcc i32 @__cq_q_inner_1(i32 %[[H]])
; CHECK:      call void @cqrt_addc_i32(i32 %[[R]], i32 1)
; CHECK:      call i32 @cqrt_measure_i32(i32 %[[R]])
; CHECK:      call void @cqrt_ry_i32(i32 %[[H]], double 0x3FE6666666666666)
; The clone body copies out and cleans up after ITSELF, but the copy it returns
; is never discharged by anyone:
; CHECK:      %[[OP:.*]] = call i32 @cq_template_add_i32_hl(i32 %{{.*}}, i32 3)
; CHECK-NEXT: %[[OUT:.*]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_copy_i32(i32 %[[OP]], i32 %[[OUT]])
; CHECK-NEXT: call void @cq_template_add_i32_hl_unc(i32 %[[OP]], i32 %{{.*}}, i32 3)
; CHECK-NEXT: call void @cqrt_free(i32 %[[OP]])
; CHECK-NEXT: ret i32 %[[OUT]]

; NOFREE:     %[[ROUT:.*]] = call fastcc i32 @__cq_q_inner_1(
; NOFREE-NOT: call void @cqrt_free(i32 %[[ROUT]])

; CLONE-LABEL: define internal fastcc i32 @__cq_q_inner_1(
; CLONE:       call i32 @cq_template_add_i32_hl(i32 %{{.*}}, i32 3)
; CLONE:       call void @cq_template_add_i32_hl_unc(
; CLONE-NOT:   call void @cqrt_addc_
