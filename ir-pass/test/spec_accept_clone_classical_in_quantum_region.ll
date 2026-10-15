; spec_accept_clone_classical_in_quantum_region.ll — ACCEPT (bd p3kd.7.2): a
; CLASSICAL branch nested inside a QUANTUM region of a lifted callee:
; `b > 0 ? ((c << k) > 7 ? b+1 : 3b) : 5`, `b` quantum, `c`/`k` classical. Clone-mode
; PredMux used to leave such a region at `E6-classicalbr`; it now if-converts the
; classical branch with the quantum one (owner ruling 2026-10-06). The classical
; condition sits in a block only some basis states reach, and `c << k` is poison for
; k >= 32, so its edge literals are FROZEN (PredMuxFlatten `literal`): conjoined with
; a false block predicate they are false rather than poison. Each literal enters the
; quantum network as the classical input of `cq_template_and_i1_hl` (the bd p3kd.3
; literal node). The `nsw` on the speculated shift is dropped by the flatten.
;
; Trace check, |b> and classical c, k (u = (c<<k) > 7):
;   sel  = [b>0 ∧ ¬u]·3b ⊕ ¬[b>0 ∧ ¬u]·5
;   sel3 = [b>0 ∧ u]·(b+1) ⊕ ¬[b>0 ∧ u]·sel
; b>0, u → b+1; b>0, ¬u → 3b; b<=0 → 5.
;
; bd p3kd.7.8: main's stage list now lowers the clone, so each mux is the 4.4
; `SelectMergeEmit` controlled-copy merge and the Bennett wrap elides each merge's
; trailing `cqrt_x` strip (it writes only the guard rail after its last read); the
; frozen literals, the dropped `nsw` and the `and_i1_hl` literal node are unchanged.
; Hand trace: forward leaves G0 negated, SEL = G0·3b ⊕ ¬G0·5, SEL3 = G1·(b+1) ⊕ ¬G1·SEL
; (as above); the mirror replays copy, `cqrt_x`, copy and `and`/`icmp` `_unc` per mux in
; reverse, restoring every rail to |0> before its free; the |5> rail stays allocated.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @helper(i32 %b, i32 %c, i32 %k) {
entry:
  %t = icmp sgt i32 %b, 0
  br i1 %t, label %inner, label %m
inner:
  %s = shl nsw i32 %c, %k
  %u = icmp sgt i32 %s, 7
  br i1 %u, label %x, label %y
x:
  %bx = add i32 %b, 1
  br label %m
y:
  %by = mul i32 %b, 3
  br label %m
m:
  %r = phi i32 [ %bx, %x ], [ %by, %y ], [ 5, %entry ]
  ret i32 %r
}

define i32 @example(i32 %u0, i32 %u1, i32 %u2) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @helper(i32 %q, i32 %u1, i32 %u2)
  %m = call i32 @cq_measure_si32(i32 %r)
  ret i32 %m
}

; CHECK-LABEL: define internal i32 @__cq_q_helper_001(i32 %b, i32 %c, i32 %k)
; CHECK-NEXT:  entry:
; CHECK-NEXT:  %[[S:[a-zA-Z0-9_.]+]] = shl i32 %c, %k
; CHECK-NEXT:  %[[U:[a-zA-Z0-9_.]+]] = icmp sgt i32 %[[S]], 7
; CHECK-NEXT:  %[[M3:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32_hl(i32 %b, i32 3)
; CHECK-NEXT:  %[[A1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_add_i32_hl(i32 %b, i32 1)
; CHECK-NEXT:  %[[NU:[a-zA-Z0-9_.]+]] = icmp sle i32 %[[S]], 7
; CHECK-NEXT:  %[[FNU:[a-zA-Z0-9_.]+]] = freeze i1 %[[NU]]
; CHECK-NEXT:  %[[T0:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %b, i32 0)
; CHECK-NEXT:  %[[G0:[a-zA-Z0-9_.]+]] = call i32 @cq_template_and_i1_hl(i32 %[[T0]], i1 zeroext %[[FNU]])
; CHECK-NEXT:  %[[SEL:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT:  call void @cqrt_copy_i32_controlled(i32 %[[G0]], i32 %[[M3]], i32 %[[SEL]])
; CHECK-NEXT:  call void @cqrt_x(i32 %[[G0]])
; CHECK-NEXT:  call void @cqrt_xorc_i32_controlled(i32 %[[G0]], i32 %[[SEL]], i32 5)
; CHECK-NEXT:  %[[FU:[a-zA-Z0-9_.]+]] = freeze i1 %[[U]]
; CHECK-NEXT:  %[[T1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %b, i32 0)
; CHECK-NEXT:  %[[G1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_and_i1_hl(i32 %[[T1]], i1 zeroext %[[FU]])
; CHECK-NEXT:  %[[SEL3:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT:  call void @cqrt_copy_i32_controlled(i32 %[[G1]], i32 %[[A1]], i32 %[[SEL3]])
; CHECK-NEXT:  call void @cqrt_x(i32 %[[G1]])
; CHECK-NEXT:  call void @cqrt_copy_i32_controlled(i32 %[[G1]], i32 %[[SEL]], i32 %[[SEL3]])
; CHECK-NEXT:  %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT:  call void @cqrt_copy_i32(i32 %[[SEL3]], i32 %[[OUT]])
; the exact mirror (reverse order, involutions replayed, templates by their `_unc`):
; CHECK-NEXT:  call void @cqrt_copy_i32_controlled(i32 %[[G1]], i32 %[[SEL]], i32 %[[SEL3]])
; CHECK-NEXT:  call void @cqrt_x(i32 %[[G1]])
; CHECK-NEXT:  call void @cqrt_copy_i32_controlled(i32 %[[G1]], i32 %[[A1]], i32 %[[SEL3]])
; CHECK-NEXT:  call void @cq_template_and_i1_hl_unc(i32 %[[G1]], i32 %[[T1]], i1 zeroext %[[FU]])
; CHECK-NEXT:  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[T1]], i32 %b, i32 0)
; CHECK-NEXT:  call void @cqrt_xorc_i32_controlled(i32 %[[G0]], i32 %[[SEL]], i32 5)
; CHECK-NEXT:  call void @cqrt_x(i32 %[[G0]])
; CHECK-NEXT:  call void @cqrt_copy_i32_controlled(i32 %[[G0]], i32 %[[M3]], i32 %[[SEL]])
; CHECK-NEXT:  call void @cq_template_and_i1_hl_unc(i32 %[[G0]], i32 %[[T0]], i1 zeroext %[[FNU]])
; CHECK-NEXT:  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[T0]], i32 %b, i32 0)
; CHECK-NEXT:  call void @cq_template_add_i32_hl_unc(i32 %[[A1]], i32 %b, i32 1)
; CHECK-NEXT:  call void @cq_template_mul_i32_hl_unc(i32 %[[M3]], i32 %b, i32 3)
; every |0> rail freed in program order; the |5> rail [[K5]] is never freed:
; CHECK-NEXT:  call void @cqrt_free(i32 %[[M3]])
; CHECK-NEXT:  call void @cqrt_free(i32 %[[A1]])
; CHECK-NEXT:  call void @cqrt_free(i32 %[[T0]])
; CHECK-NEXT:  call void @cqrt_free(i32 %[[G0]])
; CHECK-NEXT:  call void @cqrt_free(i32 %[[SEL]])
; CHECK-NEXT:  call void @cqrt_free(i32 %[[T1]])
; CHECK-NEXT:  call void @cqrt_free(i32 %[[G1]])
; CHECK-NEXT:  call void @cqrt_free(i32 %[[SEL3]])
; CHECK-NEXT:  ret i32 %[[OUT]]
; CHECK-NEXT:  }
