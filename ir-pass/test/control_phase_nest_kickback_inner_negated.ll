; control_phase_nest_kickback_inner_negated.ll — ACCEPT. P4 where the INNER
; content arm is the inner branch's FALSE successor (Rule 9).
;
;     if (q > 5) { cq_phi(0.25); if (!(q < 9)) { cq_phi(0.75); } }
;
; The polarity is expressed as a `cqrt_x` bracket on the INNER root INSIDE the
; conjunction node (`CondNetwork::Node::NegR`), never as a second flag mint:
; `x(f2); toffoli(f1,f2,g); x(f2)` computes `g = f1 ∧ ¬f2` and leaves `f2`
; exactly as it found it — which is what lets the LIFO strip re-emit the SAME
; bracketed node as its own inverse and still return `g` to |0> and `f2` to its
; minted value. Both brackets appear in the ordered run below, on the FORWARD
; node and on the UNDO; a bracket that escaped one of them would leave a rail
; complemented at its free, i.e. a dirty free (Rule 6).
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll

declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c1 = icmp sgt i32 %q, 5
  br i1 %c1, label %mid, label %merge
mid:
  call void @cq_phi(double 2.500000e-01)
  %c2 = icmp slt i32 %q, 9
  br i1 %c2, label %merge, label %inner
inner:
  call void @cq_phi(double 7.500000e-01)
  br label %merge
merge:
  %m = call i32 @cq_measure_si32(i32 %q)
  ret i32 %m
}

; THE EMITTED STREAM, DERIVED FROM THE PASS OUTPUT (never typed: the Inc-4
; round-1 review found 9 of 20 fixtures naming an SSA value the pass never
; produced). Ordered CHECK-NEXT, so a gate inserted anywhere in the run fails.
; CHECK:      %[[V0:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %[[V1:[a-zA-Z0-9_.]+]])
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[V0]], double 5.000000e-01)
; CHECK-NEXT: %[[V2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[V0]], i32 5)
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[V2]], double 2.500000e-01)
; CHECK-NEXT: %[[V3:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_slt_i32_hl(i32 %[[V0]], i32 9)
; CHECK-NEXT: %[[V4:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_x(i32 %[[V3]])
; CHECK-NEXT: call void @cqrt_toffoli(i32 %[[V2]], i32 %[[V3]], i32 %[[V4]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[V3]])
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[V4]], double 7.500000e-01)
; CHECK-NEXT: call void @cqrt_x(i32 %[[V3]])
; CHECK-NEXT: call void @cqrt_toffoli(i32 %[[V2]], i32 %[[V3]], i32 %[[V4]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[V3]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[V4]])
; CHECK-NEXT: call void @cq_template_icmp_slt_i32_hl_unc(i32 %[[V3]], i32 %[[V0]], i32 9)
; CHECK-NEXT: call void @cqrt_free(i32 %[[V3]])
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[V2]], i32 %[[V0]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[V2]])
; CHECK-NEXT: %[[V5:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[V0]])

; ---------------------------------------------------------------------------
; WHOLE-FILE, PURE-NEGATIVE (the Inc-3 F-L6-1 / Inc-4 F-L7-1 discipline: a
; POSITIVE directive inside a prefix WINDOWS every negative one of that prefix,
; so counts live in their own prefixes and NOROUTE carries no positives). The
; four things a register-free kickback must NEVER emit: a route of any kind, a
; `_controlled` gate, a `cqrt_rz_<W>` for W != i1 (the TENSORED per-register Rz
; PRD §1 records as the defect), and a surviving `@cq_phi` call.
; NOROUTE-NOT: cqrt_cswap
; NOROUTE-NOT: cqrt_copy
; NOROUTE-NOT: _controlled
; NOROUTE-NOT: cqrt_rz_i8
; NOROUTE-NOT: cqrt_rz_i16
; NOROUTE-NOT: cqrt_rz_i32
; NOROUTE-NOT: cqrt_rz_i64
; NOROUTE-NOT: cqrt_rz_f32
; NOROUTE-NOT: cqrt_rz_f64
; NOROUTE-NOT: call void @cq_phi(
; NOROUTE-NOT: cq_phi_
