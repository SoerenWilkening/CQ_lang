; control_peel_guarded_store_ctrl_unchanged.ll — ACCEPT CONTROL, GREEN AND
; BYTE-IDENTICAL ON BOTH BINARIES (bd test_C_libtooling-b6ap, Rule-13 ROUND-1
; finding F-B6-2): the SHIPPED 7.5 guarded Shadow store, with two extra measured
; registers that are NOT in the merge — so the merge holds no phi, the peel's
; `>= 2`-phi containment gate never fires, and P10 is never even asked.
;
; ⚠ IT IS THE DISCRIMINATOR FOR P10, and that is its whole job. P10 refuses to peel
; any site whose ARM writes memory; without this control that clause could be a
; blanket refusal of the guarded-store shape and nothing would notice. The complete
; reversal spine below — `cqrt_qram_load_i32_unc`,
; `cqrt_qram_store_i32_controlled_unc`, the `icmp_slt` strip, `cqrt_free` of the
; path-predicate flag, both `cqrt_ry(-0.5)` inverses — is exactly what its two-phi
; sibling `control_peel_reject_guarded_store.ll` LOST when the peel flipped that
; region to an accept at the hand-back tree (probes `g02_guarded_ctrl.c` /
; `g01_guarded_store_2phi.c`).
;
; MEASURED: `cq-opt` output on the SUBJECT is byte-identical to the ORACLE's
; (`main` 0c7380c), so this fixture asserts that the F-B6-2 fence costs nothing.;
; bd `test_C_libtooling-b6ap` — THE MULTI-PHI MERGE PEEL (`MergePhiPeel.cpp`), a
; CONTAINMENT WITNESS: the peel is ACCEPT-ONLY and leaves an off-pattern shape
; BYTE-UNTOUCHED for its existing owner.

; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=FCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=UCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll

define internal fastcc i32 @guarded_local() unnamed_addr {
  %1 = alloca [8 x i32], align 16
  call void @llvm.lifetime.start.p0(i64 32, ptr nonnull %1)
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 16 dereferenceable(32) %1, i8 0, i64 32, i1 false)
  %2 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01)
  %3 = tail call i32 @cq_theta_si32(i32 noundef 1, double noundef 5.000000e-01)
  %4 = tail call i32 @cq_theta_si32(i32 noundef 2, double noundef 5.000000e-01)
  %5 = tail call i32 @cq_theta_si32(i32 noundef 3, double noundef 5.000000e-01)
  %6 = icmp slt i32 %2, 3
  br i1 %6, label %7, label %10

7:
  %8 = sext i32 %3 to i64
  %9 = getelementptr inbounds [8 x i32], ptr %1, i64 0, i64 %8
  store i32 7, ptr %9, align 4
  br label %10

10:
  %11 = sext i32 %2 to i64
  %12 = getelementptr inbounds [8 x i32], ptr %1, i64 0, i64 %11
  %13 = load i32, ptr %12, align 4
  %14 = tail call i32 @cq_measure_si32(i32 noundef %13)
  %15 = tail call i32 @cq_measure_si32(i32 noundef %4)
  %16 = add nsw i32 %15, %14
  %17 = tail call i32 @cq_measure_si32(i32 noundef %5)
  %18 = add nsw i32 %16, %17
  call void @llvm.lifetime.end.p0(i64 32, ptr nonnull %1)
  ret i32 %18
}

define noundef i32 @main() local_unnamed_addr {
  %1 = tail call fastcc i32 @guarded_local()
  ret i32 %1
}

declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture)
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture)
declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr
declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr

; CHECK: %[[ARR:[a-zA-Z0-9_.]+]] = call i32 @cqrt_qram_alloc_i32(i32 8)
; CHECK: %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_slt_i32_hl(i32 %[[Q:[a-zA-Z0-9_.]+]], i32 3)
; CHECK-NEXT: %[[V:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 7)
; CHECK-NEXT: call void @cqrt_qram_store_i32_controlled(i32 %[[F]], i32 %[[ARR]], i32 %[[I:[a-zA-Z0-9_.]+]], i32 %[[V]])
; ---- THE REVERSAL SPINE. Every line below is what the F-B6-2 accept dropped.
; CHECK: call void @cqrt_qram_load_i32_unc(
; CHECK-NEXT: call void @cqrt_free(
; CHECK-NEXT: call void @cqrt_qram_store_i32_controlled_unc(i32 %[[F]], i32 %[[ARR]], i32 %[[I]], i32 %[[V]])
; CHECK-NEXT: call void @cq_template_icmp_slt_i32_hl_unc(i32 %[[F]], i32 %[[Q]], i32 3)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[I]], double -5.000000e-01)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[Q]], double -5.000000e-01)

; NOROUTE-NOT: cqrt_cswap
; NOROUTE-NOT: = select
; NOROUTE-NOT: cqrt_copy_i32_controlled
; FCNT-COUNT-2: call void @cqrt_free(
; FCNT-NOT:     call void @cqrt_free(
; UCNT-COUNT-6: _unc(
; UCNT-NOT:     _unc(
