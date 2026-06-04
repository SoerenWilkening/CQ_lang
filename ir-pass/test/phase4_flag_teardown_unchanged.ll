; phase4_flag_teardown_unchanged.ll — Phase 5 Step 0 regression guard
; (Phase-5 IMPLEMENTATION §4.0). Step 0 adds a `TaintSet::FlagTeardown` recording
; hook inside `emitUncompute` (ControlledLowering.cpp) so Phase 5's in-shadow
; keep-alive (PRD §2.7) has a deterministic anchor for the controlled
; data-adjoint. The hook only READS the post-emit instruction frontier and WRITES
; a side-table entry — it emits NO IR — so the Phase-4 flag teardown must still
; lower byte-for-byte unchanged.
;
; This reuses the WP3 headline body from `lowering_control_gate_br_i32.ll`
; (`if (q > k) y = gate(y);`): the tainted `icmp` lowers to the control flag
; (`cq_template_icmp_sgt_i32_hl`), the in-shadow gate body to
; `cqrt_rz_i32_controlled`, and the flag is uncomputed by the compare template's
; `_inv` twin (§1.5). The `_inv` teardown is the instruction Step 0 records; this
; fixture pins that it still emits identically (same callee, same `i32 5`
; operand, exactly once) and that no spurious instruction was injected.
;
; The new `FlagTeardown` field is unread until Phase 5 Step 4 — this is purely a
; "Step 0 changed no emitted IR" regression guard.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
; CHECK:     call i32 @cq_template_icmp_sgt_i32_hl(i32 %{{[a-zA-Z0-9_.]+}}, i32 5)
; CHECK:     call void @cqrt_rz_i32_controlled(i32 %{{[a-zA-Z0-9_.]+}}, i32 %{{[a-zA-Z0-9_.]+}}, double {{.*}})
; The flag teardown (§1.5): the `_inv` twin of the forward compare template,
; byte-unchanged after the Step-0 recording hook. Asserted exactly once.
; CHECK:     call i32 @cq_template_icmp_sgt_i32_hl_inv(i32 %{{[a-zA-Z0-9_.]+}}, i32 5)
; CHECK-NOT: call i32 @cq_template_icmp_sgt_i32_hl_inv
; CHECK-NOT: br i1
; CHECK-NOT: = phi
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
define i32 @example(i32 %y0) {
entry:
  %y = call i32 @cq_theta_si32(i32 %y0, double 5.000000e-01)
  %c = icmp sgt i32 %y, 5
  br i1 %c, label %then, label %merge
then:
  %ry = call i32 @cq_phi_si32(i32 %y, double 0.25)   ; in-shadow gate body
  br label %merge
merge:
  %r = phi i32 [ %ry, %then ], [ %y, %entry ]        ; [modified, original]
  ret i32 %r
}
