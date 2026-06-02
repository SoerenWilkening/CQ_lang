; lowering_control_mux_handles_i64.ll — Family F (WP11), reopens Phase 4.2. A
; both-arms-handle `select` mux (mux.2) whose arms are DIRECT `cq_theta_sll`
; (i64) results. Rotation lowering launders every quantum handle to i32 (handles
; are always i32 — PRD §"Width unification"), so by the time `dissolveSelect`
; runs the select's arms are i32-typed handles even though their LOGICAL width
; is i64. Phase 4.2 read the reduction width off `A->getType()` = i32, emitting
; `cqrt_alloc_i32(0)` + `cq_template_add_i32_controlled` to accumulate i64 data
; — a SILENT width-collapse miscompile. WP11 recovers the logical width from the
; §2.4 `taint.HandleWidth` side-table for a tainted arm (falling back to the LLVM
; type only for a classical arm or a still-stock op), so the ancilla and the
; controlled adds are i64.
;
; (Phase 4.2 i32 muxes are unaffected: their arms are i32 ARITHMETIC ops, not
; laundered handles, so the type fallback still returns i32 — see
; lowering_control_mux_handles_i32.ll, which stays byte-identical.)
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
; The fresh ancilla and BOTH controlled adds are i64; no i32 collapse anywhere.
; CHECK:     call i32 @cqrt_alloc_i64(i64 0)
; CHECK:     call i32 @cq_template_add_i64_controlled(i32 %{{[a-zA-Z0-9_.]+}}, i32 %{{[a-zA-Z0-9_.]+}}, i32 %{{[a-zA-Z0-9_.]+}})
; CHECK:     call void @cqrt_x(i32 %{{[a-zA-Z0-9_.]+}})
; CHECK:     call i32 @cq_template_add_i64_controlled(i32 %{{[a-zA-Z0-9_.]+}}, i32 %{{[a-zA-Z0-9_.]+}}, i32 %{{[a-zA-Z0-9_.]+}})
; CHECK-NOT: cqrt_alloc_i32
; CHECK-NOT: add_i32_controlled
; CHECK-NOT: select i1
declare i64 @cq_theta_sll(i64, double)
declare i64 @cq_measure_sll(i64)
define i64 @example(i64 %u0, i64 %v0) {
entry:
  %u = call i64 @cq_theta_sll(i64 %u0, double 5.000000e-01)
  %v = call i64 @cq_theta_sll(i64 %v0, double 5.000000e-01)
  %c = icmp sgt i64 %u, 0
  %y = select i1 %c, i64 %u, i64 %v       ; both arms direct i64 handles (mux.2)
  %m = call i64 @cq_measure_sll(i64 %y)
  ret i64 %m
}
