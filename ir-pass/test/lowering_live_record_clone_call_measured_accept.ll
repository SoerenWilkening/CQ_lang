; lowering_live_record_clone_call_measured_accept.ll — ACCEPT: the DISCRIMINATION
; CONTROL for lowering_reject_live_record_clone_call_hop.ll (M-A Increment 1, bd
; test_C_libtooling-6uqc).
;
; SOURCE: identical to the reject twin except that the clone's result is measured
; DIRECTLY instead of through an intervening compare:
;     __attribute__((noinline)) static int inner(int x){ return x + 3; }
;     a = cq_theta(a, 0.5);
;     int r = inner(a);
;     int m = cq_measure(r);   // <-- collapsed BEFORE the gate
;     a = cq_theta(a, 0.7);
;
; Walking THROUGH the clone call must not turn every clone-calling program into a
; decline. Here the walk crosses the hop and finds NO undischarged record: the
; clone's internal `cq_template_add_i32_hl` rail is uncomputed and freed inside
; the clone body by the Bennett wrap, and the returned `cqq.out` rail is the
; deferred copy-destination class, not a clause-1 record. Nothing counts, so the
; chained `cqrt_ry` lowers.
;
; Read with the reject twin: the two modules differ by ONE instruction, and that
; instruction is the only reason one of them has a live dead record. That is the
; granularity the F1 fix claims, made testable rather than asserted.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll 2> %t.err
; RUN: %filecheck %s --check-prefix=SILENT --allow-empty < %t.err
; RUN: %filecheck %s < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @main() {
  %q  = call i32 @cq_theta_si32(i32 1, double 5.000000e-01)
  %r  = call fastcc i32 @inner(i32 %q)                        ; CLONE HOP
  %m  = call i32 @cq_measure_si32(i32 %r)                     ; collapsed before the gate
  %q2 = call i32 @cq_theta_si32(i32 %q, double 7.000000e-01)  ; chained, in-place Ry — LOWERS
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
; CHECK:      call i32 @cqrt_measure_i32(i32 %[[R]])
; CHECK:      call void @cqrt_ry_i32(i32 %[[H]], double 0x3FE6666666666666)

; THE M-A GUARD IS SILENT ON THIS PROGRAM, and since owner ruling 2026-08-29 (bd
; test_C_libtooling-lyyf, M-A Increment 7b) that has to be CHECKED rather than
; inferred. The guard now emits a `DS_Warning` and `opt` exits ZERO either way,
; so a zero exit code is no longer a witness that it accepted — every fixture in
; this family would have kept passing while silently pinning nothing. `SILENT`
; reads the pass's stderr and is the pin that survived the severity change.
; SILENT-NOT: non-diagonal gate over a live derived record
