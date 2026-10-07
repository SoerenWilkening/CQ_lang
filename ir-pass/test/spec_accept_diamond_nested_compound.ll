; spec_accept_diamond_nested_compound.ll — Phase 6 / issue 5po2 I2: a DEPTH-2
; NESTED value diamond `helper(b) = c1 ? (c2 ? b+2 : b+1) : b+3` now LIFTS. PredMux
; flattens it to a `select` whose inner condition is a COMPOUND boolean `c1 ∧ ¬c2`
; (a `cqrt_toffoli` conjunction of two `cq_template_icmp` leaf flags);
; `lowerCloneSelect` mints that condition NETWORK forward-only (leaf flags LIVE +
; the toffoli), gates the 4.4 controlled-XOR muxes on the root flag, and the
; Bennett wrap plays the single LIFO reverse — copy⁻¹, the self-inverse
; `cqrt_toffoli`, then the leaf `icmp _unc`s — before freeing every proven-|0⟩ rail
; (the i1 ancilla included). This was the I1 decline fixture
; `spec_reject_diamond_nested_compound.ll`, flipped to accept when I2 added the
; compound-condition network mint. All arms are derived (no materialization).
;
; bd p3kd.7.8: the clone is now lowered by MAIN's stage list (CondTreeEmit network
; + SelectMergeEmit merge; `lowerCloneSelect` and its `cqq.g` / `cqq.sel` names are
; gone). The compound inner condition still mints two leaf flags + a toffoli onto
; a |0> i1 ancilla G; main's emitters strip their networks inline, and inside a
; clone the Bennett wrap elides every strip, so G and both leaf flags stay LIVE
; through the forward and the single mirror unwinds them. The outer select now
; mints its own flag NC1 = [b<=5] and the inner mux result feeds it as a data arm.
; Hand trace, |b>: R0=b+3, R1=b+1, R2=b+2; C1=[b>5], C2N=[b>=9], G=C1∧C2N=[b>=9];
; IN = G?R1:R2 (G left flipped to [b<9]); OUT = NC1?R0:IN (NC1 left flipped to
; [b>5]); so b<=5 → b+3, 5<b<9 → b+2, b>=9 → b+1 = helper(b). The mirror undoes OUT
; (NC1 back to [b<=5], then its `_unc`), then IN (G back to [b>=9]), the toffoli
; zeroes G, the leaf `_unc`s zero C2N/C1, the arm `_unc`s zero R2/R1/R0: all nine
; freed rails are |0>. No arm is a constant, so no rail is materialized.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @helper(i32 %b) {
entry:
  %r0 = add i32 %b, 3
  %c1 = icmp sgt i32 %b, 5
  br i1 %c1, label %outer, label %merge
outer:
  %r1 = add i32 %b, 1
  %c2 = icmp slt i32 %b, 9
  br i1 %c2, label %inner, label %merge
inner:
  %r2 = add i32 %b, 2
  br label %merge
merge:
  %rm = phi i32 [ %r0, %entry ], [ %r1, %outer ], [ %r2, %inner ]
  ret i32 %rm
}

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @helper(i32 %q)
  %m = call i32 @cq_measure_si32(i32 %r)
  ret i32 %m
}

; CHECK-LABEL: define internal i32 @__cq_q_helper_1(i32 %b)
; The three derived arms (order-free), then the network.
; CHECK-DAG:  %[[R0:[a-zA-Z0-9_.]+]] = call i32 @cq_template_add_i32_hl(i32 %b, i32 3)
; CHECK-DAG:  %[[R1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_add_i32_hl(i32 %b, i32 1)
; CHECK-DAG:  %[[R2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_add_i32_hl(i32 %b, i32 2)
; the compound inner condition `c1 ∧ ¬c2` mints two leaf flags + a toffoli onto a
; |0> i1 ancilla, forward-only (kept LIVE: the merge's strip is elided):
; CHECK:      %[[C1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %b, i32 5)
; CHECK-NEXT: %[[C2N:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sge_i32_hl(i32 %b, i32 9)
; CHECK-NEXT: %[[G:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_toffoli(i32 %[[C1]], i32 %[[C2N]], i32 %[[G]])
; CHECK-NEXT: %[[IN:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[G]], i32 %[[R1]], i32 %[[IN]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[G]])
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[G]], i32 %[[R2]], i32 %[[IN]])
; the outer select on its own flag [b<=5], the inner mux as its false arm:
; CHECK-NEXT: %[[NC1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sle_i32_hl(i32 %b, i32 5)
; CHECK-NEXT: %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[NC1]], i32 %[[R0]], i32 %[[OUT]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[NC1]])
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[NC1]], i32 %[[IN]], i32 %[[OUT]])
; CHECK-NEXT: %[[RES:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_copy_i32(i32 %[[OUT]], i32 %[[RES]])
; the single Bennett reverse: the exact mirror, ending in the self-inverse toffoli
; and the leaf `_unc`s:
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[NC1]], i32 %[[IN]], i32 %[[OUT]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[NC1]])
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[NC1]], i32 %[[R0]], i32 %[[OUT]])
; CHECK-NEXT: call void @cq_template_icmp_sle_i32_hl_unc(i32 %[[NC1]], i32 %b, i32 5)
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[G]], i32 %[[R2]], i32 %[[IN]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[G]])
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[G]], i32 %[[R1]], i32 %[[IN]])
; CHECK-NEXT: call void @cqrt_toffoli(i32 %[[C1]], i32 %[[C2N]], i32 %[[G]])
; CHECK-NEXT: call void @cq_template_icmp_sge_i32_hl_unc(i32 %[[C2N]], i32 %b, i32 9)
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[C1]], i32 %b, i32 5)
; the arm `_unc`s (order-free here; the forward order was not pinned), then every
; freed rail, the i1 ancilla included:
; CHECK-DAG:  call void @cq_template_add_i32_hl_unc(i32 %[[R2]], i32 %b, i32 2)
; CHECK-DAG:  call void @cq_template_add_i32_hl_unc(i32 %[[R1]], i32 %b, i32 1)
; CHECK-DAG:  call void @cq_template_add_i32_hl_unc(i32 %[[R0]], i32 %b, i32 3)
; CHECK-DAG:  call void @cqrt_free(i32 %[[R0]])
; CHECK-DAG:  call void @cqrt_free(i32 %[[R1]])
; CHECK-DAG:  call void @cqrt_free(i32 %[[R2]])
; CHECK-DAG:  call void @cqrt_free(i32 %[[C1]])
; CHECK-DAG:  call void @cqrt_free(i32 %[[C2N]])
; CHECK-DAG:  call void @cqrt_free(i32 %[[G]])
; CHECK-DAG:  call void @cqrt_free(i32 %[[IN]])
; CHECK-DAG:  call void @cqrt_free(i32 %[[NC1]])
; CHECK-DAG:  call void @cqrt_free(i32 %[[OUT]])
; CHECK:      ret i32 %[[RES]]
; CHECK-NEXT: }
