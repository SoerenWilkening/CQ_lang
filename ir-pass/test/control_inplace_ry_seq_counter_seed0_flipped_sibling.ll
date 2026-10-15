; control_inplace_ry_seq_counter_seed0_flipped_sibling.ll — ACCEPT: seed 0, polarity-flipped sibling.
;
; bd test_C_libtooling-dm7f.53, delegated ruling
; `ruling-dm7f53-p4-sibling-cond-prep-amend-any-const-seed-2026-10-15`: the
; sibling-condition exclusion applies to ANY constant seed, and "the sibling
; equals the seed" is decided by SSA VALUE ON THE EDGE (`f2Exact(V, S) == Seed`,
; LLVM uniqued-constant identity), never by source polarity (R8: -O1 turns
; `x < 2` into `!(x > 1)` and swaps successors). A ¬flag arm is cqrt_x-bracketed
; on the minted ANCILLA flag only, never on a user register.
;
;   bool t = 0; if (x < 3) Ry(t,.3); if (!(x >= 2)) Ry(t,.7);
; -O1 spells the sibling `sgt x,1` with its arm on the FALSE edge. Its SSA value
; on region 1's straight-through edge (x >= 3) is TRUE, not the seed, so it is
; no collision at all (the source predicate x < 2 would be false = seed — the
; polarity reading this ruling forbids). Trace: slt flag cRy(.3); sgt flag
; X-bracketed cRy(.7). x < 2 -> Ry(1.0); x == 2 -> Ry(.3); else |0>.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.d53.ll
; RUN: %filecheck %s < %t.d53.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.d53.ll
; RUN: %filecheck %s --check-prefix=FCNT < %t.d53.ll
; RUN: %filecheck %s --check-prefix=CRCNT < %t.d53.ll

declare i32 @cq_theta_si32(i32, double)
declare i1 @cq_theta_i1(i1, double)
declare i32 @cq_measure_si32(i32)
declare i1 @cq_measure_i1(i1)

define i32 @example() {
  %1 = call i32 @cq_theta_si32(i32 0, double 1.000000e+00)
  %2 = icmp slt i32 %1, 3
  br i1 %2, label %3, label %6

3:
  %4 = call i1 @cq_theta_i1(i1 false, double 3.000000e-01)
  %5 = zext i1 %4 to i8
  br label %6

6:
  %7 = phi i8 [ %5, %3 ], [ 0, %0 ]
  %8 = icmp sgt i32 %1, 1
  br i1 %8, label %13, label %9

9:
  %10 = trunc nuw i8 %7 to i1
  %11 = call i1 @cq_theta_i1(i1 %10, double 0x3FE6666666666666)
  %12 = zext i1 %11 to i8
  br label %13

13:
  %14 = phi i8 [ %7, %6 ], [ %12, %9 ]
  %15 = call i32 @cq_measure_si32(i32 %1)
  %16 = trunc nuw i8 %14 to i1
  %17 = call i1 @cq_measure_i1(i1 %16)
  %18 = zext i1 %17 to i32
  %19 = add nsw i32 %15, %18
  ret i32 %19
}

; CHECK:      %[[H0:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H0]], double 1.000000e+00)
; CHECK-NEXT: %[[H1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_slt_i32_hl(i32 %[[H0]], i32 3)
; CHECK-NEXT: %[[H2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_ry_i1_controlled(i32 %[[H1]], i32 %[[H2]], double 3.000000e-01)
; CHECK-NEXT: call void @cq_template_icmp_slt_i32_hl_unc(i32 %[[H1]], i32 %[[H0]], i32 3)
; CHECK-NEXT: call void @cqrt_free(i32 %[[H1]])
; CHECK-NEXT: %[[H3:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[H0]], i32 1)
; CHECK-NEXT: call void @cqrt_x(i32 %[[H3]])
; CHECK-NEXT: call void @cqrt_ry_i1_controlled(i32 %[[H3]], i32 %[[H2]], double 0x3FE6666666666666)
; CHECK-NEXT: call void @cqrt_x(i32 %[[H3]])
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[H3]], i32 %[[H0]], i32 1)
; CHECK-NEXT: call void @cqrt_free(i32 %[[H3]])
; CHECK-NEXT: %[[H4:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[H0]])
; CHECK-NEXT: %[[H5:[a-zA-Z0-9_.]+]] = call i1 @cqrt_measure_i1(i32 %[[H2]])
;
; Whole-file, pure negatives (a positive in a prefix windows the negatives
; after it): no route / copy / adjoint gate, every arm theta and region phi
; consumed; FCNT/CRCNT count the frees and the controlled Ry gates.
; NOROUTE-NOT: cqrt_cswap
; NOROUTE-NOT: cqrt_copy
; NOROUTE-NOT: _controlled_inv
; NOROUTE-NOT: call i1 @cq_theta
; NOROUTE-NOT: = phi
; NOROUTE-NOT: = trunc
; NOROUTE-NOT: zext i1 {{.*}} to i8
; FCNT-COUNT-2: call void @cqrt_free(
; FCNT-NOT:     call void @cqrt_free(
; CRCNT-COUNT-2: call void @cqrt_ry_{{[a-z0-9]+}}_controlled(
; CRCNT-NOT:     call void @cqrt_ry_{{[a-z0-9]+}}_controlled(
