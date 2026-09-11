; control_swap_select_cmp_round2_opaque_seed_accept.ll — ACCEPT (Track A.1, bd
; test_C_libtooling-9pum): the OPAQUE-CLASSICAL-SEED accept, the second half of
; the discriminator pair. The compare twin of
; `control_swap_select_rail_round2_opaque_seed_accept.ll`.
;
;     volatile int gint = 0;
;     int x  = gint;                 // classical at round 1 AND STILL classical
;     int b  = cq_theta(x, 0.5);
;     int b3 = cq_theta(x, 0.9);
;     int a  = (b == 1) ? 2 : 5;
;
; Same two-sibling SHAPE as the round-2 miscompile, with a seed nothing ever
; taints. Both thetas stay SOURCE thetas at FINAL taint, so `lowerRotations`
; mints TWO SEPARATE registers — one `cqrt_alloc_i32(%1)` and one `cqrt_ry_i32`
; each — and the merge flag is minted from the first alone. THE TWO MINTS ARE THE
; ASSERTION: with one rail there would be a single alloc and the compare would
; follow BOTH rotations.
;
; THIS IS WHAT MAKES `reverifyCmpCondReads` A RE-VERIFICATION AND NOT A REFUSAL
; OF THE SHAPE. A fence that treated any non-`Constant` theta arg-0 as chained —
; the review's option 3 — would decline a program with no shared rail in it.
; VERBATIM `clang -O1` (probe `a5_sel_cmp_round2_opaque_seed.c`), BYTE-UNCHANGED
; from `main` 0c7380c.

; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=ORD < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=ACNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=RYCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=FCNT < %t.cqd0.ll

@gint = global i32 0, align 4

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @main() local_unnamed_addr {
  %1 = load volatile i32, ptr @gint, align 4
  %2 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef 5.000000e-01)
  %3 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef 9.000000e-01)
  %4 = icmp eq i32 %2, 1
  %5 = select i1 %4, i32 2, i32 5
  %6 = tail call i32 @cq_measure_si32(i32 noundef %5)
  %7 = tail call i32 @cq_measure_si32(i32 noundef %3)
  %8 = add nsw i32 %7, %6
  ret i32 %8
}

; TWO REGISTERS, one rotation each, and the flag names the FIRST.
; CHECK:      %[[H1:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %{{[0-9]+}})
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H1]], double 5.000000e-01)
; CHECK-NEXT: %[[H2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %{{[0-9]+}})
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H2]], double 9.000000e-01)
; CHECK-NEXT: %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[H1]], i32 1)

; ORD: call void @cqrt_ry_i32({{.*}}, double 5.000000e-01)
; ORD: call void @cqrt_ry_i32({{.*}}, double 9.000000e-01)
; ORD: call i32 @cq_template_icmp_eq_i32_hl(
; ORD: call void @cqrt_free(

; NOROUTE-NOT: cqrt_cswap
; NOROUTE-NOT: cqrt_rz
; NOROUTE-NOT: call i32 @cq_theta_
; ACNT-COUNT-5: call i32 @cqrt_alloc_
; ACNT-NOT:     call i32 @cqrt_alloc_
; RYCNT-COUNT-2: call void @cqrt_ry_
; RYCNT-NOT:     call void @cqrt_ry_
; FCNT-COUNT-1: call void @cqrt_free(
; FCNT-NOT:     call void @cqrt_free(
