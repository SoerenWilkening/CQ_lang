; lowering_control_escape_classical_sideeffect_nested.ll — Phase 4.x
; (test_C_libtooling-npu.3), NEGATIVE, the nested-AND sibling. In the un-flattened
; `if(a){ sink(99); if(b){ gate; } }` shape, the intermediate guard block `Mid`
; (the `if(a)` body) holds a CLASSICAL side effect BEFORE the inner `if(b)`
; branch. `matchNestedAnd` escape-guarded ONLY the innermost gate `Arm` — never
; `Mid` — yet `linearizeNested` splices `Mid`'s body (everything before its
; conditional `br`) UNCONDITIONALLY into the predecessor. So `sink(99)`, guarded
; on `a` in the source, fired on EVERY path (verify-clean, exit 0, no diagnostic).
;
; The fix scans `Mid` for side effects in `matchNestedAnd`, mirroring the arm-body
; guard in `armEscapesOrCollect` — the inner compare and other pure setup still
; splice through. Same non-physical "classical effect under quantum control"
; verdict as the diamond form (lowering_control_escape_classical_sideeffect.ll).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}classical side effect under quantum control
; CHECK-NOT: cqrt_rz_i32_controlled
; CHECK-NOT: call void @sink
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare void @sink(i32)

; if (a) { sink(99); if (b) { r = cq_phi(v, 0.1); } } — gate guarded on a ∧ b,
; but the sink() in the intermediate `mid` block guarded only on a.
define i32 @example(i32 %u0, i32 %v0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %v = call i32 @cq_theta_si32(i32 %v0, double 5.000000e-01)
  %a = icmp sgt i32 %q, 5
  br i1 %a, label %mid, label %merge
mid:
  call void @sink(i32 99)                                   ; classical side effect in Mid
  %b = icmp slt i32 %q, 20
  br i1 %b, label %arm, label %merge
arm:
  %r = call i32 @cq_phi_si32(i32 %v, double 1.000000e-01)   ; innermost gate (a ∧ b)
  br label %merge
merge:
  %res = phi i32 [ %r, %arm ], [ %v, %mid ], [ %v, %entry ] ; tainted-handle 3-way φ
  %m = call i32 @cq_measure_si32(i32 %res)
  ret i32 %m
}
