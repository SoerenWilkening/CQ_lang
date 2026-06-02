; lowering_control_ifelse_sym_i32.ll — Family C (WP8), the symmetric
; two-content-arm diamond. A tainted `if (u > 5) { u = gate(u); } else { v =
; gate(v); }` arriving from real `clang -O1` keeps a `br` diamond where BOTH
; successors hold a gate and fall through to a common merge carrying φ(s).
; Phase-4 core's `matchDiamond` recognizes only a ONE-content-arm diamond, so
; the symmetric shape fell to `branchEscapes` (benign), the gates lowered
; UNCONTROLLED, and a residual `br i1` on the quantum-derived condition
; survived — a SILENT MISCOMPILE. WP8 matches the symmetric shape: the true
; arm's gate is controlled on the flag, the false arm's on ¬flag (a self-inverse
; `cqrt_x` flag bracket), both φ dissolve (WP7 multi-φ, keyed on the true-arm
; edge), and the diamond linearizes to one block.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
; The tainted `icmp` is the one flag. True-arm gate controlled on it; false-arm
; gate inside the `cqrt_x(flag)` ¬flag bracket; the flag is then uncomputed.
; CHECK:     call i32 @cq_template_icmp_sgt_i32_hl(i32 %{{[a-zA-Z0-9_.]+}}, i32 5)
; CHECK:     call void @cqrt_rz_i32_controlled(i32 %[[F:[a-zA-Z0-9_.]+]], i32 %{{[a-zA-Z0-9_.]+}}, double {{.*}})
; CHECK:     call void @cqrt_x(i32 %[[F]])
; CHECK:     call void @cqrt_rz_i32_controlled(i32 %[[F]], i32 %{{[a-zA-Z0-9_.]+}}, double {{.*}})
; CHECK:     call void @cqrt_x(i32 %[[F]])
; CHECK:     call i32 @cq_template_icmp_sgt_i32_hl_inv(i32 %{{[a-zA-Z0-9_.]+}}, i32 5)
; CHECK-NOT: br i1
; CHECK-NOT: = phi
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u0, i32 %v0) {
entry:
  %u = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %v = call i32 @cq_theta_si32(i32 %v0, double 5.000000e-01)
  %c = icmp sgt i32 %u, 5
  br i1 %c, label %tarm, label %farm
tarm:
  %ru = call i32 @cq_phi_si32(i32 %u, double 0.25)   ; true-arm gate (flag)
  br label %merge
farm:
  %rv = call i32 @cq_phi_si32(i32 %v, double 0.75)   ; false-arm gate (¬flag)
  br label %merge
merge:
  %u2 = phi i32 [ %ru, %tarm ], [ %u, %farm ]        ; u: gated on true edge
  %v2 = phi i32 [ %v, %tarm ], [ %rv, %farm ]        ; v: gated on false edge
  %mu = call i32 @cq_measure_si32(i32 %u2)
  %mv = call i32 @cq_measure_si32(i32 %v2)
  %r = add nsw i32 %mu, %mv
  ret i32 %r
}
