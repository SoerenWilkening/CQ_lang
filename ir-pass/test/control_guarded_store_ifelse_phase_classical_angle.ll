; control_guarded_store_ifelse_phase_classical_angle.ll — bd test_C_libtooling-dm7f.3
; ACCEPT (review round 1, finding 2): a composed guarded-store region whose phase
; ANGLE and stored VALUE are classical values that pass through a `select` or a
; φ, and stay classical after round 2.
;
; SOURCE (each function is the clang -O1 IR of its C, attributes, lifetime
; markers and TBAA trimmed):
;   @main       if (c < 3) { arr[q & 7] = 7; cq_phi(argc > 2 ? 0.25 : 0.5); }
;               else       { arr[(q ^ 5) & 7] = 9; }
;               (then the rest of control_guarded_store_ifelse_phase.ll's @main)
;               -O1 makes the angle `select i1 (argc > 2), 0.25, 0.5` inside the arm.
;   @phi_value  double ang; if (a > 2) { puts("big"); ang = 0.25; } else ang = 0.5;
;               int s = 0; for (int i = 0; i < a; i++) s += i;
;               … if (c < 3) { arr[q & 7] = s; cq_phi(ang); }
;                 else       { arr[(q ^ 5) & 7] = 9; }
;               -O1 makes `ang` the merge φ of a classical branch and `s` the merge
;               φ of the loop's (closed-form) zero-trip guard.
;
; WHAT WAS DECLINED. `mayTaintAtRound2` (the L1 guard against an angle or stored
; value that turns quantum after round 2) answered "may" for ANY φ or `select` in
; the operand cone, so both functions declined `rotation angle under quantum
; control` although every value involved is classical for the whole run. It now
; walks through a `select` (condition and arms) and refuses a φ only when a
; branch that decides it has a tainted or may-turn-tainted condition: the shape
; of every round-2 `%out` (control_guarded_store_reject_round2_angle.ll still
; declines). Here every deciding condition (`argc > 2`, `a > 2`, `a > 0`) is
; classical.
;
; THE STREAM is the composed region's (control_guarded_store_ifelse_phase.ll)
; with a RUN-TIME angle: f2 = icmp_slt(h_c,3); rz_i1(f2, %sel_or_phi);
; icmp_slt_unc(f2,h_c,3); free(f2). The angle is evaluated classically before the
; gate (the `select` is spliced into the pred with its arm), so P(θ) with θ ∈
; {0.25, 0.5} lands on the c<3 branch. @phi_value's store writes the classical
; `s` through `cqrt_alloc_i32(%s)`, guarded by f1. Linked trace of @main at argc=1
; (MEASURED): `cqrt_rz_i1(h9, 0x1p-1)`, θ = 0.5, between the f2 mint and strip.
;
; MUTANT this file kills (measured, review round 1): restoring the first rule,
; "any φ or `select` in the cone may turn quantum". Its sound twin, dropping the
; deciding-branch check for a φ, is killed by
; control_guarded_store_reject_round2_angle.ll (measured).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll

; CHECK-LABEL: define i32 @main(
; CHECK:      %[[C:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %{{[a-zA-Z0-9_.]+}})
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[C]], double 5.000000e-01)
; CHECK:      call void @cqrt_qram_store_i32_controlled(
; CHECK:      %[[SEL:[a-zA-Z0-9_.]+]] = select i1 %{{[a-zA-Z0-9_.]+}}, double 2.500000e-01, double 5.000000e-01
; CHECK:      call void @cqrt_qram_store_i32_controlled(
; CHECK:      %[[F2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_slt_i32_hl(i32 %[[C]], i32 3)
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[F2]], double %[[SEL]]), !cq.branchphase
; CHECK-NEXT: call void @cq_template_icmp_slt_i32_hl_unc(i32 %[[F2]], i32 %[[C]], i32 3)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F2]])
; CHECK-NEXT: br label
; CHECK-NOT:  call void @cq_phi(

; CHECK-LABEL: define i32 @phi_value(
; CHECK:      %[[ANG:[0-9]+]] = phi double [ 2.500000e-01, %{{[0-9]+}} ], [ 5.000000e-01, %{{[0-9]+}} ]
; CHECK:      %[[S:[0-9]+]] = phi i32 [ 0, %{{[0-9]+}} ], [ %{{[0-9]+}}, %{{[0-9]+}} ]
; CHECK:      %[[PC:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_slt_i32_hl(i32 %[[PH:[a-zA-Z0-9_.]+]], i32 3)
; CHECK-NEXT: %[[QV:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %[[S]])
; CHECK-NEXT: call void @cqrt_qram_store_i32_controlled(i32 %[[PC]], i32 %{{[a-zA-Z0-9_.]+}}, i32 %{{[a-zA-Z0-9_.]+}}, i32 %[[QV]])
; CHECK:      %[[PF2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_slt_i32_hl(i32 %[[PH]], i32 3)
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[PF2]], double %[[ANG]]), !cq.branchphase
; CHECK-NEXT: call void @cq_template_icmp_slt_i32_hl_unc(i32 %[[PF2]], i32 %[[PH]], i32 3)
; CHECK-NEXT: call void @cqrt_free(i32 %[[PF2]])
; CHECK-NEXT: br label
; CHECK-NOT:  call void @cq_phi(

@.str = private unnamed_addr constant [4 x i8] c"big\00", align 1

declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg)
declare i32 @cq_theta_si32(i32 noundef, double noundef)
declare i32 @cq_measure_si32(i32 noundef)
declare void @cq_phi(double noundef)
declare noundef i32 @puts(ptr nocapture noundef readonly)

define i32 @main(i32 noundef %0, ptr nocapture noundef readnone %1) {
  %3 = alloca [8 x i32], align 16
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 16 dereferenceable(32) %3, i8 0, i64 32, i1 false)
  %4 = add nsw i32 %0, 1
  %5 = tail call i32 @cq_theta_si32(i32 noundef %4, double noundef 5.000000e-01)
  %6 = add nsw i32 %0, 2
  %7 = tail call i32 @cq_theta_si32(i32 noundef %6, double noundef 5.000000e-01)
  %8 = icmp slt i32 %5, 3
  %9 = and i32 %7, 7
  br i1 %8, label %10, label %15

10:
  %11 = zext nneg i32 %9 to i64
  %12 = getelementptr inbounds [8 x i32], ptr %3, i64 0, i64 %11
  store i32 7, ptr %12, align 4
  %13 = icmp sgt i32 %0, 2
  %14 = select i1 %13, double 2.500000e-01, double 5.000000e-01
  tail call void @cq_phi(double noundef %14)
  br label %19

15:
  %16 = xor i32 %9, 5
  %17 = zext nneg i32 %16 to i64
  %18 = getelementptr inbounds [8 x i32], ptr %3, i64 0, i64 %17
  store i32 9, ptr %18, align 4
  br label %19

19:
  %20 = add nsw i32 %0, 3
  %21 = tail call i32 @cq_theta_si32(i32 noundef %20, double noundef 5.000000e-01)
  %22 = and i32 %21, 7
  %23 = zext nneg i32 %22 to i64
  %24 = getelementptr inbounds [8 x i32], ptr %3, i64 0, i64 %23
  %25 = load i32, ptr %24, align 4
  %26 = tail call i32 @cq_theta_si32(i32 noundef %5, double noundef -5.000000e-01)
  %27 = tail call i32 @cq_measure_si32(i32 noundef %26)
  %28 = tail call i32 @cq_measure_si32(i32 noundef %7)
  %29 = add nsw i32 %28, %27
  %30 = tail call i32 @cq_measure_si32(i32 noundef %25)
  %31 = add nsw i32 %29, %30
  ret i32 %31
}

define i32 @phi_value(i32 noundef %0) {
  %2 = alloca [8 x i32], align 16
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 16 dereferenceable(32) %2, i8 0, i64 32, i1 false)
  %3 = icmp sgt i32 %0, 2
  br i1 %3, label %4, label %6

4:
  %5 = tail call i32 @puts(ptr noundef nonnull dereferenceable(1) @.str)
  br label %6

6:
  %7 = phi double [ 2.500000e-01, %4 ], [ 5.000000e-01, %1 ]
  %8 = icmp sgt i32 %0, 0
  br i1 %8, label %9, label %19

9:
  %10 = add nsw i32 %0, -1
  %11 = zext i32 %10 to i33
  %12 = add nsw i32 %0, -2
  %13 = zext i32 %12 to i33
  %14 = mul i33 %11, %13
  %15 = lshr i33 %14, 1
  %16 = trunc nuw i33 %15 to i32
  %17 = add i32 %16, %0
  %18 = add i32 %17, -1
  br label %19

19:
  %20 = phi i32 [ 0, %6 ], [ %18, %9 ]
  %21 = add nsw i32 %0, 1
  %22 = tail call i32 @cq_theta_si32(i32 noundef %21, double noundef 5.000000e-01)
  %23 = add nsw i32 %0, 2
  %24 = tail call i32 @cq_theta_si32(i32 noundef %23, double noundef 5.000000e-01)
  %25 = icmp slt i32 %22, 3
  %26 = and i32 %24, 7
  br i1 %25, label %27, label %30

27:
  %28 = zext nneg i32 %26 to i64
  %29 = getelementptr inbounds [8 x i32], ptr %2, i64 0, i64 %28
  store i32 %20, ptr %29, align 4
  tail call void @cq_phi(double noundef %7)
  br label %34

30:
  %31 = xor i32 %26, 5
  %32 = zext nneg i32 %31 to i64
  %33 = getelementptr inbounds [8 x i32], ptr %2, i64 0, i64 %32
  store i32 9, ptr %33, align 4
  br label %34

34:
  %35 = add nsw i32 %24, 1
  %36 = and i32 %35, 7
  %37 = zext nneg i32 %36 to i64
  %38 = getelementptr inbounds [8 x i32], ptr %2, i64 0, i64 %37
  %39 = load i32, ptr %38, align 4
  %40 = tail call i32 @cq_measure_si32(i32 noundef %39)
  ret i32 %40
}
