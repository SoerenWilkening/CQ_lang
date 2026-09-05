; control_phase_nest_kickback_compound_inner.ll — ACCEPT. P4 whose INNER level is
; itself a COMPOUND condition tree.
;
;     if (q > 5) { cq_phi(0.25); if (q < 9 && r == 3) cq_phi(0.75); }
;
; Both levels go through the same `CondTreeEmit` network, so an inner tree costs
; one more ancilla and nothing else; the conjunction node then ANDs the outer
; ROOT with the inner ROOT.
;
; ⚠ THIS FIXTURE FOUND A USE-AFTER-FREE IN ITS OWN EMITTER, WHICH IS WHY IT
; EXISTS. The inner condition tree lives in `Mid`, and `flattenRegionTree` erases
; `Mid` WHOLESALE — so the post-flatten cascade that erases dead tree interiors
; was calling `use_empty()` on instructions the block destructor had already
; freed. SIGSEGV inside `ValueSymbolTable::reinsertValue`, on the first run of
; this module; the single-compare nests were silently fine only because their
; inner "tree" is just the root, which the cascade skips. The fix snapshots the
; `Pred`-RESIDENT survivors BEFORE the flatten. A count-only or accept-only test
; would not have found it — only a nest with a NON-TRIVIAL inner tree does.
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll

declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %u1) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @cq_theta_si32(i32 %u1, double 2.500000e-01)
  %c1 = icmp sgt i32 %q, 5
  br i1 %c1, label %mid, label %merge
mid:
  call void @cq_phi(double 2.500000e-01)
  %ca = icmp slt i32 %q, 9
  %cb = icmp eq i32 %r, 3
  %c2 = select i1 %ca, i1 %cb, i1 false
  br i1 %c2, label %inner, label %merge
inner:
  call void @cq_phi(double 7.500000e-01)
  br label %merge
merge:
  %m = call i32 @cq_measure_si32(i32 %q)
  %n = call i32 @cq_measure_si32(i32 %r)
  %s = add i32 %m, %n
  ret i32 %s
}

; THE EMITTED STREAM, DERIVED FROM THE PASS OUTPUT (never typed: the Inc-4
; round-1 review found 9 of 20 fixtures naming an SSA value the pass never
; produced). Ordered CHECK-NEXT, so a gate inserted anywhere in the run fails.
; CHECK:      %[[V0:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %[[V1:[a-zA-Z0-9_.]+]])
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[V0]], double 5.000000e-01)
; CHECK-NEXT: %[[V2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %[[V3:[a-zA-Z0-9_.]+]])
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[V2]], double 2.500000e-01)
; CHECK-NEXT: %[[V4:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[V0]], i32 5)
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[V4]], double 2.500000e-01)
; CHECK-NEXT: %[[V5:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_slt_i32_hl(i32 %[[V0]], i32 9)
; CHECK-NEXT: %[[V6:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[V2]], i32 3)
; CHECK-NEXT: %[[V7:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_toffoli(i32 %[[V5]], i32 %[[V6]], i32 %[[V7]])
; CHECK-NEXT: %[[V8:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_toffoli(i32 %[[V4]], i32 %[[V7]], i32 %[[V8]])
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[V8]], double 7.500000e-01)
; CHECK-NEXT: call void @cqrt_toffoli(i32 %[[V4]], i32 %[[V7]], i32 %[[V8]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[V8]])
; CHECK-NEXT: call void @cqrt_toffoli(i32 %[[V5]], i32 %[[V6]], i32 %[[V7]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[V7]])
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[V6]], i32 %[[V2]], i32 3)
; CHECK-NEXT: call void @cqrt_free(i32 %[[V6]])
; CHECK-NEXT: call void @cq_template_icmp_slt_i32_hl_unc(i32 %[[V5]], i32 %[[V0]], i32 9)
; CHECK-NEXT: call void @cqrt_free(i32 %[[V5]])
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[V4]], i32 %[[V0]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[V4]])
; CHECK-NEXT: %[[V9:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[V0]])
; CHECK-NEXT: %[[V10:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[V2]])

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
