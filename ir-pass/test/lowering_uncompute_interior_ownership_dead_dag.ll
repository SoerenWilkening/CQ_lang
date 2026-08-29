; lowering_uncompute_interior_ownership_dead_dag.ll — ACCEPT + OWNERSHIP PIN (M-B
; Increment 5a, bd test_C_libtooling-6uqc). EXACTLY ONE OWNER PER RAIL.
;
; A fully DEAD chain: `%h_op1` is a dead terminal, so the EXISTING whole-DAG
; partition recovers `{%h_op1, %h_op, %h}` and reverses all of it, including the
; `cqrt_ry` and the source rail's free — which is correct there and correct ONLY
; there, because with no surviving record of the wire `Ry† Ry |0> = |0>`.
;
; `%h_op` sits in the middle of that chain and looks exactly like an interior
; rail. Adjointing it a SECOND time would apply `mul_unc` twice (leaving the rail
; at the forward value again) and `cqrt_free` twice — the shared-prefix
; double-uncompute Rule 8 names, i.e. a use-after-free plus a double free that
; `opt -verify` cannot see and that `free_pairing_check.py` would report as a
; structurally-perfect pairing.
;
; TWO INDEPENDENT FENCES STOP IT, and the fixture is here because relying on
; either alone would be resting on a coincidence:
;   1. STRUCTURAL — once the dead-terminal group has emitted, `%h_op`'s users
;      include `cq_template_mul_i32_hl_unc(%h_op1, %h_op, 5)`, an `_unc` twin,
;      which `isInteriorConsumer` does not admit.
;   2. BOOKKEEPING — `reverseTerminalGroup` records every gate and rail it
;      actually reversed, and the interior partition subtracts them before it
;      even builds a candidate list. This is the load-bearing image, in the same
;      discipline as `ControlOwnedRails`/`OutputRails`/`GraveyardRails`.
; The deeper reason they agree is that a successful dead-terminal group is CLOSED,
; so an interior rail (which by definition has a consumer outside any set that
; owns it) cannot be inside one.
;
; The assertion is that the stream is BYTE-IDENTICAL to what HEAD emitted: three
; adjoints, three frees, nothing added.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)

define void @ownership_dead(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %a = mul i32 %q, 3
  %b = mul i32 %a, 5
  ret void
}

; CHECK-LABEL: define void @ownership_dead(
; CHECK:      %[[H:.*]] = call i32 @cqrt_alloc_i32(
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: %[[A:.*]] = call i32 @cq_template_mul_i32_hl(i32 %[[H]], i32 3)
; CHECK-NEXT: %[[B:.*]] = call i32 @cq_template_mul_i32_hl(i32 %[[A]], i32 5)
; CHECK-NEXT: call void @cq_template_mul_i32_hl_unc(i32 %[[B]], i32 %[[A]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[B]])
; CHECK-NEXT: call void @cq_template_mul_i32_hl_unc(i32 %[[A]], i32 %[[H]], i32 3)
; CHECK-NEXT: call void @cqrt_free(i32 %[[A]])
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double -5.000000e-01)
; CHECK-NEXT: call void @cqrt_free(i32 %[[H]])
; CHECK-NEXT: ret void
