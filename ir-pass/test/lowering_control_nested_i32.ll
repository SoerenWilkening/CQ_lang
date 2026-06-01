; lowering_control_nested_i32.ll — WP5 nested control (the single-flag AND
; model, PRD §2.7, IMPLEMENTATION §5.3). A tainted `if (q > k1) { if (q < k2)
; y = gate(y); }`. `clang -O1` FLATTENS adjacent nested ifs into one range
; check when it can, so this fixture is the genuine UN-flattened form `-O1`
; produces when the inner guard can't be folded into the outer (here distinct
; operands `5` vs `%k`): two real `br`-diamonds sharing one merge —
;   entry  -[%co]-> {o.then, end}
;   o.then -[%ci]-> {i.then, end}
;   i.then ->        end
;   end:   3-way φ [gate-arm, o.then, entry]   ; verify accepts this
; Nesting reuses the conjunction flag machinery verbatim: each guard lowers to
; its own HL flag, and ONE `cqrt_toffoli` ANDs the outer with the inner into a
; fresh `cqrt_alloc_i1(0)` (`f_both`). The gate body is single-controlled by
; that ONE flag (§1.2) — never doubly-controlled. The flag is uncomputed LIFO:
; the `cqrt_toffoli_inv` FIRST, then each guard's compare `_inv` (innermost
; first, risk R4). All four blocks collapse to one; no `br i1`/`phi` survives.
;
; "One `cqrt_toffoli` per level": a 2-level nest combines its two guards with a
; single Toffoli (depth-N reuses depth-1 verbatim — one more Toffoli per added
; level). Host-agnostic explicit i32 throughout.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
;
; ORDERED CHECK lines pin the compute/uncompute ORDER (FileCheck matches in
; order): both guard flags, then ONE Toffoli BEFORE the controlled rz, then the
; Toffoli uncompute AFTER it, innermost guard uncomputed first.
; CHECK:     call i32 @cq_template_icmp_sgt_i32_hl(i32 %{{[a-zA-Z0-9_.]+}}, i32 5)
; CHECK:     call i32 @cq_template_icmp_slt_i32_hl(i32 %{{[a-zA-Z0-9_.]+}}, i32 %{{[a-zA-Z0-9_.]+}})
; CHECK:     call i32 @cqrt_alloc_i1(i1 false)
; CHECK:     call void @cqrt_toffoli(i32 %{{[a-zA-Z0-9_.]+}}, i32 %{{[a-zA-Z0-9_.]+}}, i32 %{{[a-zA-Z0-9_.]+}})
; CHECK:     call void @cqrt_rz_i32_controlled(i32 %{{[a-zA-Z0-9_.]+}}, i32 %{{[a-zA-Z0-9_.]+}}, double {{.*}})
; CHECK:     call void @cqrt_toffoli_inv(i32 %{{[a-zA-Z0-9_.]+}}, i32 %{{[a-zA-Z0-9_.]+}}, i32 %{{[a-zA-Z0-9_.]+}})
; CHECK:     call i32 @cq_template_icmp_slt_i32_hl_inv(i32 %{{[a-zA-Z0-9_.]+}}, i32 %{{[a-zA-Z0-9_.]+}})
; CHECK:     call i32 @cq_template_icmp_sgt_i32_hl_inv(i32 %{{[a-zA-Z0-9_.]+}}, i32 5)
;
; The ordered lines above already pin the single-flag AND model (one Toffoli
; per level: one forward + one inverse for this 2-level nest). The diamond
; collapses fully — no control flow, no merge `φ`, no flag-select survives.
; CHECK-NOT: br i1
; CHECK-NOT: = phi
; CHECK-NOT: select i1
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
define i32 @example(i32 %y0, i32 %k) {
entry:
  %y = call i32 @cq_theta_si32(i32 %y0, double 5.000000e-01)
  %co = icmp sgt i32 %y, 5
  br i1 %co, label %o.then, label %end
o.then:
  %ci = icmp slt i32 %y, %k
  br i1 %ci, label %i.then, label %end
i.then:
  %ry = call i32 @cq_phi_si32(i32 %y, double 0.25)
  br label %end
end:
  %r = phi i32 [ %ry, %i.then ], [ %y, %o.then ], [ %y, %entry ]
  ret i32 %r
}
