; control_swap_select_cmp_inloop_iterlocal_measure_after.ll — ACCEPT (Track A.1,
; bd test_C_libtooling-r10v). THE PIN FOR RUNG (ii)'s PER-ACTIVATION BARRIER, and
; the fixture that separates "a measure can reach this read" from "a measure can
; reach this read ON THE SAME REGISTER".
;
;     for (int i = 0; i < 3; ++i) {
;         int q = cq_theta(ext(i), .5);          // a FRESH register every trip
;         int a = (q == 1) ? i : 5;              // loop-VARIANT arm: select stays
;         acc += cq_measure(a) + cq_measure(q);  // owns THIS trip's register
;     }
;
; VERBATIM `clang -O1` (probe `a7_sel_cmp_inloop_iterlocal_measure_after.c`), and
; BYTE-UNCHANGED from `main` 0c7380c. It is the r10v reproducer's twin in every
; structural respect — same loop, same loop-variant arm, same in-body measure,
; same read point ON THE CYCLE — and differs in exactly one thing: `q` is minted
; INSIDE the body, so every path from the measure back to the select re-executes
; a SOURCE `cq_theta`, which lowers to a fresh `cqrt_alloc_i32` + `cqrt_ry_i32`.
; The register the measure collapsed is not the register the next mint reads.
;
; `railMeasuredBeforeReadPoint`'s barrier is exactly that origin, admitted ONLY
; when it is a source theta (a CHAINED theta is an in-place Ry and refreshes
; nothing; a template/cast/phi origin is refused because M-C can lower the very
; same op in place). Delete the barrier and this fixture goes red — together with
; `control_swap_inloop_diamond_iterlocal.ll`, `control_swap_inloop_seq.ll` and
; the three `control_swap_reject_inloop_{irreducible,multilatch,second_cycle}.ll`
; declines, which would start declining on the WRONG rung. Its decline twin is
; `..._reject_select_cmp_inloop_measure_after.ll`.

; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=ORD < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=FCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=RYCNT < %t.cqd0.ll

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i32 @ext(i32)

define i32 @main() local_unnamed_addr {
  br label %2

1:
  ret i32 %7

2:
  %3 = phi i32 [ 0, %0 ], [ %7, %2 ]
  %4 = phi i32 [ 0, %0 ], [ %8, %2 ]
  %5 = tail call i32 @ext(i32 noundef %4)
  %6 = tail call i32 @cq_theta_si32(i32 noundef %5, double noundef 5.000000e-01)
  %c = icmp eq i32 %6, 1
  %a = select i1 %c, i32 %4, i32 5
  %m1 = call i32 @cq_measure_si32(i32 noundef %a)
  %m2 = call i32 @cq_measure_si32(i32 noundef %6)
  %s = add i32 %m1, %3
  %7 = add i32 %s, %m2
  %8 = add nuw nsw i32 %4, 1
  %9 = icmp eq i32 %8, 3
  br i1 %9, label %1, label %2
}

; THE MINT IS INSIDE THE BODY, one `cqrt_alloc_i32` per activation, and the two
; measures follow the whole merge stream.
; CHECK:      %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %{{[a-zA-Z0-9_.]+}})
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[H]], i32 1)
; CHECK:      call void @cqrt_free(i32 %[[F]])
; CHECK-NEXT: {{.*}} = call i32 @cqrt_measure_i32(
; CHECK-NEXT: {{.*}} = call i32 @cqrt_measure_i32(i32 %[[H]])

; ORD: call void @cqrt_ry_i32(
; ORD: call i32 @cq_template_icmp_eq_i32_hl(
; ORD: call void @cqrt_free(
; ORD: call i32 @cqrt_measure_i32(

; NOROUTE-NOT: cqrt_cswap
; NOROUTE-NOT: cqrt_rz
; NOROUTE-NOT: call i32 @cq_theta_
; FCNT-COUNT-1: call void @cqrt_free(
; FCNT-NOT:     call void @cqrt_free(
; RYCNT-COUNT-1: call void @cqrt_ry_
; RYCNT-NOT:     call void @cqrt_ry_
