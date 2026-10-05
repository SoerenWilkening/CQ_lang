; control_guarded_store_ifelse_phase.ll — bd test_C_libtooling-dm7f.3 ACCEPT: a
; tainted if/else with a guarded Shadow store in EACH arm and a register-free
; `cq_phi` in one arm.
;
; SOURCE (@main is the clang -O1 IR of this C, attributes, lifetime markers and
; TBAA trimmed):
;     int arr[8] = {0};
;     int c = argc + 1; cq_theta(&c, 0.5);
;     int q = argc + 2; cq_theta(&q, 0.5);
;     if (c < 3) { arr[q & 7] = 7; cq_phi(0.25); }
;     else       { arr[(q ^ 5) & 7] = 9; }
;     int p = argc + 3; cq_theta(&p, 0.5);
;     int v = arr[p & 7];
;     cq_theta(&c, -0.5);
;     return cq_measure(c) + cq_measure(q) + cq_measure(v);
; @phase_else is the same region with the phase in the ELSE arm (hand IR).
;
; WHAT WAS DECLINED. The taint-escape carve deferred a guarded store only in a
; ONE-armed diamond (`guardedShadowStoreShapeImpl` (b)), so the true arm's gep
; declined `cq taint escape: tainted value reaches an unsupported instruction`;
; and `classifyGuardedStoreArm` admitted neither an if/else nor a `cq_phi` beside
; a store.
;
; THE STREAM (h = c's rail, i = q & 7, A = the array):
;   f1 = icmp_slt(h,3);  store_controlled(f1, A, i, 7)
;   f3 = icmp_sge(h,3);  j = xor(i,5);  store_controlled(f3, A, j, 9)
;   f2 = icmp_slt(h,3);  rz_i1(f2, .25);  icmp_slt_unc(f2,h,3);  free(f2)
; THE ARGUMENT. With the state Σ_x a_x |x>_h |…>:
;   * f1 = [x<3] and f3 = [x>=3] are minted from the PRE-store h; a guarded store
;     is a no-op on its cell when its flag is 0, so exactly one store fires per
;     basis branch, the true arm's on x<3 and the else arm's on x>=3. f3 is a
;     NEGATED MINT, not `cqrt_x` around f1: the spine strips f3 with its own
;     `icmp_sge_unc` (and would reverse its store through it), so f3 must DENOTE
;     the else predicate.
;   * f2 is a fresh |0> ancilla: rz_i1 puts e^{iθ[x<3]} on the branch (a global
;     phase aside), and the strip returns f2 to |0> on every branch because no gate
;     between the mint and the strip writes h (the stores write A only). The phase
;     NEVER rides f1/f3: a branch-phase gate is an opaque consumer to the uncompute
;     spine (`ChainWalk.h`), which would leave that flag unstripped — a live copy of
;     [x<3] across the later Ry(-0.5) on h, dephasing it.
;   * both store flags are stripped (the r2j3.1 interior partition) BEFORE the
;     later Ry(-0.5) on h, so no record of h's basis survives across it.
;   * @phase_else: the else arm fires on ¬f2, so the gate is cqrt_x-bracketed on
;     the ancilla (`emitKickbackGroup`, the one spelling).
;
; MUTANTS this file kills (measured, dm7f.3): M1, the phase riding the true arm's
; STORE flag (no fresh f2, no emitter strip) — the hazard above; M2, the else
; arm's store flag minted un-negated (`icmp_slt` where `icmp_sge` is owed).
;
; DECLINE TWINS: control_guarded_store_ifelse_reject_quantum_value.ll (a quantum
; stored value in a composed region, bd r2j3.9's path),
; control_guarded_store_ifelse_reject_trapping_op.ll (a trapping classical op the
; flatten would run on every branch), …_reject_quantum_angle.ll (Rule 3),
; control_guarded_store_reject_round2_{angle,value}.ll (L1: classical at round 1,
; quantum after round 2) and
; control_guarded_store_ifelse_reject_inarm_index_later_ry.ll (an in-arm index
; and a later Ry on its source: the stale-record guard, bd 01po.7). The original
; reproducer WITH its later Ry on q accepts:
; control_guarded_store_ifelse_phase_full_repro.ll.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=STRIP1 < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=STRIP3 < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=CNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=MDTAG < %t.cqd0.ll

; ---- @main: the ordered region stream.
; CHECK-LABEL: define i32 @main(
; CHECK:      %[[A:[a-zA-Z0-9_.]+]] = call i32 @cqrt_qram_alloc_i32(i32 8)
; CHECK:      %[[C:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %{{[a-zA-Z0-9_.]+}})
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[C]], double 5.000000e-01)
; CHECK:      %[[I:[a-zA-Z0-9_.]+]] = call i32 @cq_template_and_i32_hl(i32 %{{[a-zA-Z0-9_.]+}}, i32 7)
; CHECK:      %[[F1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_slt_i32_hl(i32 %[[C]], i32 3)
; CHECK:      call void @cqrt_qram_store_i32_controlled(i32 %[[F1]], i32 %[[A]], i32 %[[I]], i32 %{{[a-zA-Z0-9_.]+}})
; CHECK:      %[[F3:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sge_i32_hl(i32 %[[C]], i32 3)
; CHECK:      %[[J:[a-zA-Z0-9_.]+]] = call i32 @cq_template_xor_i32_hl(i32 %[[I]], i32 5)
; CHECK:      call void @cqrt_qram_store_i32_controlled(i32 %[[F3]], i32 %[[A]], i32 %[[J]], i32 %{{[a-zA-Z0-9_.]+}})
; CHECK:      %[[F2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_slt_i32_hl(i32 %[[C]], i32 3)
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[F2]], double 2.500000e-01)
; CHECK-NEXT: call void @cq_template_icmp_slt_i32_hl_unc(i32 %[[F2]], i32 %[[C]], i32 3)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F2]])
; CHECK-NEXT: br label
; CHECK:      call void @cqrt_ry_i32(i32 %[[C]], double -5.000000e-01)

; ---- @phase_else: the else arm's phase fires on ¬f2 — the cqrt_x bracket on the
; ANCILLA f2, enclosing only the gate.
; CHECK-LABEL: define i32 @phase_else(
; CHECK:      %[[EF1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_slt_i32_hl(i32 %[[EC:[a-zA-Z0-9_.]+]], i32 3)
; CHECK:      call void @cqrt_qram_store_i32_controlled(i32 %[[EF1]],
; CHECK:      %[[EF3:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sge_i32_hl(i32 %[[EC]], i32 3)
; CHECK:      call void @cqrt_qram_store_i32_controlled(i32 %[[EF3]],
; CHECK:      %[[EF2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_slt_i32_hl(i32 %[[EC]], i32 3)
; CHECK-NEXT: call void @cqrt_x(i32 %[[EF2]])
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[EF2]], double 2.500000e-01)
; CHECK-NEXT: call void @cqrt_x(i32 %[[EF2]])
; CHECK-NEXT: call void @cq_template_icmp_slt_i32_hl_unc(i32 %[[EF2]], i32 %[[EC]], i32 3)
; CHECK-NEXT: call void @cqrt_free(i32 %[[EF2]])
; CHECK-NEXT: br label

; ---- @main: each STORE flag is stripped and freed before the later Ry on c.
; STRIP1-LABEL: define i32 @main(
; STRIP1:       %[[S1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_slt_i32_hl(
; STRIP1:       call void @cq_template_icmp_slt_i32_hl_unc(i32 %[[S1]],
; STRIP1:       call void @cqrt_free(i32 %[[S1]])
; STRIP1:       call void @cqrt_ry_i32(i32 %{{[a-zA-Z0-9_.]+}}, double -5.000000e-01)
; STRIP3-LABEL: define i32 @main(
; STRIP3:       %[[S3:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sge_i32_hl(
; STRIP3:       call void @cq_template_icmp_sge_i32_hl_unc(i32 %[[S3]],
; STRIP3:       call void @cqrt_free(i32 %[[S3]])
; STRIP3:       call void @cqrt_ry_i32(i32 %{{[a-zA-Z0-9_.]+}}, double -5.000000e-01)

; ---- Per function: ONE phase gate, three condition mints, no raw control left,
; and in @main no cqrt_x at all (the else STORE is a negated mint, not a bracket).
; CNT-LABEL:   define i32 @main(
; CNT-NOT:     call void @cqrt_x(
; CNT-NOT:     br i1
; CNT-NOT:     call void @cq_phi(
; CNT-COUNT-1: call void @cqrt_rz_i1(
; CNT-NOT:     call void @cqrt_rz_i1(
; CNT-NOT:     call void @cqrt_x(
; CNT-NOT:     br i1
; CNT-NOT:     call void @cq_phi(
; CNT-LABEL:   define i32 @phase_else(
; CNT-COUNT-1: call void @cqrt_rz_i1(
; CNT-NOT:     call void @cqrt_rz_i1(
; CNT-NOT:     br i1
; CNT-NOT:     call void @cq_phi(

; ---- The phase gate carries the branch-phase membership record.
; MDTAG: call void @cqrt_rz_i1({{.*}}), !cq.branchphase

declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare void @cq_phi(double)

define i32 @main(i32 noundef %0, ptr nocapture noundef readnone %1) {
  %3 = alloca [8 x i32], align 16
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 16 dereferenceable(32) %3, i8 0, i64 32, i1 false)
  %4 = add nsw i32 %0, 1
  %5 = tail call i32 @cq_theta_si32(i32 noundef %4, double noundef 5.000000e-01)
  %6 = add nsw i32 %0, 2
  %7 = tail call i32 @cq_theta_si32(i32 noundef %6, double noundef 5.000000e-01)
  %8 = icmp slt i32 %5, 3
  %9 = and i32 %7, 7
  br i1 %8, label %10, label %13

10:
  %11 = zext nneg i32 %9 to i64
  %12 = getelementptr inbounds [8 x i32], ptr %3, i64 0, i64 %11
  store i32 7, ptr %12, align 4
  tail call void @cq_phi(double noundef 2.500000e-01)
  br label %17

13:
  %14 = xor i32 %9, 5
  %15 = zext nneg i32 %14 to i64
  %16 = getelementptr inbounds [8 x i32], ptr %3, i64 0, i64 %15
  store i32 9, ptr %16, align 4
  br label %17

17:
  %18 = add nsw i32 %0, 3
  %19 = tail call i32 @cq_theta_si32(i32 noundef %18, double noundef 5.000000e-01)
  %20 = and i32 %19, 7
  %21 = zext nneg i32 %20 to i64
  %22 = getelementptr inbounds [8 x i32], ptr %3, i64 0, i64 %21
  %23 = load i32, ptr %22, align 4
  %24 = tail call i32 @cq_theta_si32(i32 noundef %5, double noundef -5.000000e-01)
  %25 = tail call i32 @cq_measure_si32(i32 noundef %24)
  %26 = tail call i32 @cq_measure_si32(i32 noundef %7)
  %27 = add nsw i32 %26, %25
  %28 = tail call i32 @cq_measure_si32(i32 noundef %23)
  %29 = add nsw i32 %27, %28
  ret i32 %29
}

define i32 @phase_else(i32 %u0, i32 %u1) {
entry:
  %arr = alloca [8 x i32], align 16
  call void @llvm.memset.p0.i64(ptr align 16 %arr, i8 0, i64 32, i1 false)
  %c = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %q = call i32 @cq_theta_si32(i32 %u1, double 5.000000e-01)
  %f = icmp slt i32 %c, 3
  %i = and i32 %q, 7
  br i1 %f, label %t, label %e

t:
  %it = zext nneg i32 %i to i64
  %gt = getelementptr inbounds [8 x i32], ptr %arr, i64 0, i64 %it
  store i32 7, ptr %gt, align 4
  br label %m

e:
  %j = xor i32 %i, 5
  %ie = zext nneg i32 %j to i64
  %ge = getelementptr inbounds [8 x i32], ptr %arr, i64 0, i64 %ie
  store i32 9, ptr %ge, align 4
  call void @cq_phi(double 2.500000e-01)
  br label %m

m:
  ret i32 0
}
