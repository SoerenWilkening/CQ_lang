; lowering_control_and_i32.ll — WP5 compound `&&` (PRD §2.5, IMPLEMENTATION
; §5.3, §6). A tainted `if (q > k1 && q > k2) y = gate(y);` arrives from real
; `clang -O1` as a short-circuit `i1`-select over two flags
; (`select i1 %fa, i1 %fb, i1 false`) feeding a `br`-diamond + `φ[modified,
; original]`. This is NOT a data select — it COMBINES two control flags into
; one wire (§1.2): each sub-compare lowers to its own HL flag, then a single
; `cqrt_toffoli` ANDs them into a fresh `cqrt_alloc_i1(0)` ancilla. The gate
; body is single-controlled by that ONE combined flag; the flag is uncomputed
; LIFO (the `cqrt_toffoli_inv` first, then each sub-flag's compare `_inv`),
; mirroring the compute bracket (§1.5). The diamond linearizes; no `br i1`, no
; `phi`, no `select i1` survives.
;
; Host-agnostic: explicit i32 throughout.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
;
; The two sub-compares each lower to an HL flag (the compound's inputs):
; CHECK:     call i32 @cq_template_icmp_sgt_i32_hl(i32 %{{[a-zA-Z0-9_.]+}}, i32 5)
; CHECK:     call i32 @cq_template_icmp_slt_i32_hl(i32 %{{[a-zA-Z0-9_.]+}}, i32 100)
; Fresh combined-flag ancilla, then the AND via one Toffoli (§2.5):
; CHECK:     call i32 @cqrt_alloc_i1(i1 false)
; CHECK:     call void @cqrt_toffoli(i32 %{{[a-zA-Z0-9_.]+}}, i32 %{{[a-zA-Z0-9_.]+}}, i32 %{{[a-zA-Z0-9_.]+}})
; The gate body, single-controlled by the ONE combined flag (§1.2):
; CHECK:     call void @cqrt_rz_i32_controlled(i32 %{{[a-zA-Z0-9_.]+}}, i32 %{{[a-zA-Z0-9_.]+}}, double {{.*}})
; Uncompute, LIFO reverse of the compute (§1.5): Toffoli uncompute first …
; CHECK:     call void @cqrt_toffoli_inv(i32 %{{[a-zA-Z0-9_.]+}}, i32 %{{[a-zA-Z0-9_.]+}}, i32 %{{[a-zA-Z0-9_.]+}})
; … then each sub-flag's compare uncompute (innermost first):
; CHECK:     call i32 @cq_template_icmp_slt_i32_hl_inv(i32 %{{[a-zA-Z0-9_.]+}}, i32 100)
; CHECK:     call i32 @cq_template_icmp_sgt_i32_hl_inv(i32 %{{[a-zA-Z0-9_.]+}}, i32 5)
;
; CHECK-NOT: br i1
; CHECK-NOT: = phi
; CHECK-NOT: select i1
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
define i32 @example(i32 %y0) {
entry:
  %y = call i32 @cq_theta_si32(i32 %y0, double 5.000000e-01)
  %fa = icmp sgt i32 %y, 5
  %fb = icmp slt i32 %y, 100
  %and = select i1 %fa, i1 %fb, i1 false
  br i1 %and, label %then, label %merge
then:
  %ry = call i32 @cq_phi_si32(i32 %y, double 0.25)
  br label %merge
merge:
  %r = phi i32 [ %ry, %then ], [ %y, %entry ]
  ret i32 %r
}
