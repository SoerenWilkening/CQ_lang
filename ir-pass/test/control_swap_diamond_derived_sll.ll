; control_swap_diamond_derived_sll.ll — ACCEPT: derived base at 64-bit width (sll).
;
; The derived-base diamond (test_C_libtooling-9hh) at the `sll` (i64) width.
; Pins the width-dispatch interaction: every fixture in the control_swap family
; is si32, which could hide an i32 width assumption in the emitter's
; suffix-derived Rz/template minting. Width comes from the FIRST arm gate's
; cq_phi suffix (never from the derived Q's SSA type — §4 width-source): arm gates
; as cqrt_rz_i64_controlled, the flag pair as cq_template_icmp_sgt_i64_hl[/_unc]
; carrying the i64 LITERAL — while every HANDLE stays i32 (Rule 15: width-only ABI,
; handles are always i32).
;
; Under the §6a control-in-place peephole the work rail is gone, so the width probe
; moves onto the CONTROLLED rotation twin: a suffix-derived i32 assumption in the
; emitter would now mint `cqrt_rz_i32_controlled` here and this fixture reddens. The
; only remaining alloc is q's own seeded `cqrt_alloc_i64(i64 %u0)`.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=CNT < %t.cqd0.ll
; The route's ABSENCE, anchored at the function header so the window is the whole
; function (a trailing CHECK-NOT scans only past the LAST positive of its prefix,
; and every route line would land BEFORE that — it could never fire).
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
declare i64 @cq_theta_sll(i64, double)
declare i64 @cq_phi_sll(i64, double)
declare i64 @cq_measure_sll(i64)

define i64 @example(i64 %u0, double %a) {
entry:
  %q = call i64 @cq_theta_sll(i64 %u0, double 5.000000e-01)
  %qd = call i64 @cq_phi_sll(i64 %q, double 9.000000e-01)
  %c = icmp sgt i64 %qd, 5
  br i1 %c, label %arm, label %merge
arm:
  %q1 = call i64 @cq_phi_sll(i64 %qd, double %a)
  br label %merge
merge:
  %qm = phi i64 [ %q1, %arm ], [ %qd, %entry ]
  %m  = call i64 @cq_measure_sll(i64 %qm)
  ret i64 %m
}

; i32 HANDLES everywhere; i64 only in the alloc seed and the template literal
; CHECK:     %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i64(i64 %u0)
; CHECK:     call void @cqrt_ry_i64(i32 %[[Q]], double 5.000000e-01)
; CHECK:     call void @cqrt_rz_i64(i32 %[[Q]], double 9.000000e-01)
; CHECK:     %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i64_hl(i32 %[[Q]], i64 5)
; the arm gate, controlled and in place — i64-dispatched controlled twin, i32 handles
; CHECK-NEXT: call void @cqrt_rz_i64_controlled(i32 %[[F]], i32 %[[Q]], double %a)
; CHECK-NEXT: call void @cq_template_icmp_sgt_i64_hl_unc(i32 %[[F]], i32 %[[Q]], i64 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
; CHECK:     call i64 @cqrt_measure_i64(i32 %[[Q]])
; CHECK-NOT: call void @cqrt_free
; CHECK-NOT: cqrt_copy
; CHECK-NOT: phi i64
; width-dispatch guard: no i32-width controlled twin anywhere
; CHECK-NOT: cqrt_rz_i32_controlled

; CNT-COUNT-1: call void @cqrt_free(
; CNT-NOT:     call void @cqrt_free(

; No swap route survives: no |0> work rail, no CSWAP, no copy, no data mux —
; window is `define` -> EOF, so a re-introduced route WOULD trip these.
; NOROUTE:     define i64 @example
; NOROUTE-NOT: cqrt_cswap
; NOROUTE-NOT: call i32 @cqrt_alloc_i64(i64 0)
; NOROUTE-NOT: cqrt_copy
; NOROUTE-NOT: phi i64
; NOROUTE-NOT: cqrt_rz_i32_controlled
