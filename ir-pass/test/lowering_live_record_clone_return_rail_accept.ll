; lowering_live_record_clone_return_rail_accept.ll — ACCEPT, and it is a MEASURED
; RESIDUAL OVER-ACCEPT, not a proof of soundness. Pinned the same way
; lowering_qram_array_record_chained_theta_accept.ll pins the QRAM-array gap.
; Found by the Rule-13 round's F1 follow-up; reported on bd
; test_C_libtooling-6uqc.
;
; SOURCE (`clang -O1` emits exactly the SSA below — NO control flow anywhere):
;     __attribute__((noinline)) static int inner(int x){ return x + 3; }
;     a = cq_theta(a, 0.5);
;     int r = inner(a);        // clone hop; the Bennett wrap returns `cqq.out`
;     int u = r + 1;           // a clause-1 record OF that rail
;     int m = cq_measure(u);   // ...measured before the gate => EXEMPT
;     a = cq_theta(a, 0.7);    // <-- THIS GATE, and NOTHING declines it
;
; WHAT IS STANDING AT THE GATE. `__cq_q_inner_1` computes `x+3` into `%h_op`,
; `cqrt_copy_i32`s it into a fresh `cqrt_alloc_i32`-minted `cqq.out`, uncomputes
; and frees `%h_op`, and returns the COPY. That copy is a full basis record of the
; wire, entangled with it, never uncomputed and never freed in the caller — so the
; chained `Ry` fires over a live record and the emitted unitary is not the
; source's. This is bd 6uqc's own P4 defect, wearing a clone call.
;
; WHY THE GUARD MISSES IT, precisely. The record walk follows PRODUCER edges, and
; `cqq.out` has none to follow: its SSA value comes from `cqrt_alloc_i32(0)`,
; whose only operand is a classical seed, and the basis content arrives through a
; VOID `cqrt_copy_i32`. That is the copy-destination severance class listed in
; `RotationLowering.cpp`'s scope note — the ancestor/alloc family the owner ruled
; deferred for Increment 1 (2026-08-27, descendants-only). The F1 fix crosses the
; clone CALL so records downstream of the result are found (see
; lowering_reject_live_record_clone_call_hop.ll); it does not, and by scope must
; not, count the result rail itself.
;
; SO: INCREMENT 1 DOES NOT FULLY CLOSE P4 EVEN FOR STRAIGHT-LINE PROGRAMS. The
; two OTHER severance classes — select-merge / switch-data-mux out rails, and
; value-arm merge outs — are unreachable today only because bd
; test_C_libtooling-lom0's unrelated over-decline rejects their programs first
; (measured). THIS one has no such cover.
;
; IF THIS FIXTURE EVER STARTS TO DECLINE, that is the scope closing, not a
; regression: move it to a negative fixture and update bd 6uqc.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOFREE < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @main() {
  %q  = call i32 @cq_theta_si32(i32 1, double 5.000000e-01)
  %r  = call fastcc i32 @inner(i32 %q)                        ; -> the `cqq.out` copy rail
  %u  = add nsw i32 %r, 1                                     ; clause-1 record, measured => exempt
  %m  = call i32 @cq_measure_si32(i32 %u)
  %q2 = call i32 @cq_theta_si32(i32 %q, double 7.000000e-01)  ; chained Ry over the live copy rail
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
; CHECK:      %[[U:.*]] = call i32 @cq_template_add_i32_hl(i32 %[[R]], i32 1)
; CHECK:      call i32 @cqrt_measure_i32(i32 %[[U]])
; CHECK:      call void @cqrt_ry_i32(i32 %[[H]], double 0x3FE6666666666666)
; The clone body copies out and cleans up after ITSELF, but the copy it returns
; is never discharged by anyone:
; CHECK:      %[[OP:.*]] = call i32 @cq_template_add_i32_hl(i32 %{{.*}}, i32 3)
; CHECK-NEXT: %[[OUT:.*]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_copy_i32(i32 %[[OP]], i32 %[[OUT]])
; CHECK-NEXT: call void @cq_template_add_i32_hl_unc(i32 %[[OP]], i32 %{{.*}}, i32 3)
; CHECK-NEXT: call void @cqrt_free(i32 %[[OP]])
; CHECK-NEXT: ret i32 %[[OUT]]

; The guard anchors on the CALLER's name for the returned copy rail, not on the
; clone-local `cqq.out` alloc: the module prints @main first, so a body-anchored
; window would open only AFTER @main's ret and the liveness gate's injected free
; (placed before the FIRST ret, i.e. in @main) would fall outside it — a dead
; guard, and the e2e-fixture-guard-liveness gate rightly rejects it. Guarding the
; caller's handle is also the semantic point: the leak is the returned copy the
; CALLER never discharges.
; NOFREE:     %[[ROUT:.*]] = call fastcc i32 @__cq_q_inner_1(
; NOFREE-NOT: call void @cqrt_free(i32 %[[ROUT]])
