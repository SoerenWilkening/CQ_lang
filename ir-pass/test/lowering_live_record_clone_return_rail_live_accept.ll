; lowering_live_record_clone_return_rail_live_accept.ll — ACCEPT: the
; COPY-DESTINATION class exempts by clause 3 when the returned rail has an
; OBSERVING sink after the gate (M-A Increment 3, bd test_C_libtooling-6uqc).
;
; SOURCE (`clang -O1` emits exactly the SSA below; NO control flow anywhere):
;     __attribute__((noinline)) static int inner(int x){ return x + 3; }
;     cq_theta(&a, 0.5);
;     int r = inner(a);        // clone hop; the Bennett wrap returns `cqq.out`
;     cq_theta(&a, 0.7);    // T — chained, in-place Ry on the wire
;     int m = cq_measure(r);   // the copy rail is MEASURED AFTER the gate
;     return cq_measure(a) + m;
;
; Increment 3 makes a `__cq_q_*` clone result a RECORD (the copy-destination
; class — see lowering_reject_live_record_clone_return_rail.ll). This file is the
; control that the widening did not become "every clone-calling program
; declines": here the returned rail is READ after the gate, so under the ruled
; predicate it is the program's own live data and its dephasing of `T` is source
; semantics — ACCEPT. Together with lowering_live_record_clone_call_measured_accept.ll
; (clause 4, measured BEFORE the gate) and the reject twin (dead at the gate),
; the three files partition the copy-rail's dispositions.
;
; THREE PROPERTIES ARE PINNED BELOW, and they are different claims:
;   * CLAUSE 3 — `cqrt_measure_i32` on the clone's result AFTER the chained
;     `cqrt_ry`. That is the exemption this file is named for.
;   * THE CLONE BODY CONTRIBUTES NO STANDING RECORD — the Bennett wrap uncomputes
;     and frees its own `%h_op` INSIDE the body, before the caller's gate ever
;     runs. Note the record walk never enters the body (SSA users are
;     function-local, and a clone is theta-free by construction, so it holds no
;     guard site of its own); the CLONE prefix asserts the discharge on the
;     emitted stream rather than relying on that argument.
;   * THE `inBennettClone` FENCE — a void `cqrt_addc` must never appear inside
;     @__cq_q_inner_1. The wrap builds its ForwardStream by scanning for
;     `isForwardTemplate` members; a void `cqrt_addc` is not one, so an M-C
;     rewrite there would be omitted from the reversal, never undone, and would
;     leave the BORROWED argument `%x` permanently shifted for every caller.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll 2> %t.err
; RUN: %filecheck %s --check-prefix=SILENT --allow-empty < %t.err
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=CLONE < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @main() {
  %q  = call i32 @cq_theta_si32(i32 1, double 5.000000e-01)
  %r  = call fastcc i32 @inner(i32 %q)                        ; -> the `cqq.out` copy rail
  %q2 = call i32 @cq_theta_si32(i32 %q, double 7.000000e-01)  ; T — chained, in-place Ry
  %m  = call i32 @cq_measure_si32(i32 %r)                     ; OBSERVING sink AFTER T
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
; CHECK-NEXT: %[[R:.*]] = call fastcc i32 @__cq_q_inner_1(i32 %[[H]])
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 0x3FE6666666666666)
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[R]])
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[H]])

; The clone body computes out of place, copies out, and discharges its own
; interior rail — and the `inBennettClone` fence keeps that shape.
; CLONE-LABEL: define internal fastcc i32 @__cq_q_inner_1(
; CLONE:       %[[OP:.*]] = call i32 @cq_template_add_i32_hl(i32 %{{.*}}, i32 3)
; CLONE-NEXT:  %[[OUT:.*]] = call i32 @cqrt_alloc_i32(i32 0)
; CLONE-NEXT:  call void @cqrt_copy_i32(i32 %[[OP]], i32 %[[OUT]])
; CLONE-NEXT:  call void @cq_template_add_i32_hl_unc(i32 %[[OP]], i32 %{{.*}}, i32 3)
; CLONE-NEXT:  call void @cqrt_free(i32 %[[OP]])
; CLONE-NEXT:  ret i32 %[[OUT]]
; CLONE-NOT:   call void @cqrt_addc_

; THE M-A GUARD IS SILENT ON THIS PROGRAM, and since owner ruling 2026-08-29 (bd
; test_C_libtooling-lyyf, M-A Increment 7b) that has to be CHECKED rather than
; inferred. The guard now emits a `DS_Warning` and `opt` exits ZERO either way,
; so a zero exit code is no longer a witness that it accepted — every fixture in
; this family would have kept passing while silently pinning nothing. `SILENT`
; reads the pass's stderr and is the pin that survived the severity change.
; SILENT-NOT: non-diagonal gate over a live derived record
