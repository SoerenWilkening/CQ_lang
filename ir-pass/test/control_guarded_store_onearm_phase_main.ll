; control_guarded_store_onearm_phase_main.ll — DECLINE (bd test_C_libtooling-01po.25, batch 055; the `@main` half
; of control_guarded_store_onearm_phase.ll, split out so that file keeps its helper subject).
;
; Delegated ruling ruling-r2j3-7-qram-copyout-and-backedge-2026-10-16: since bd r2j3.7
; `main` runs the helper's dead-record discipline and `emitCopyOutIfDirectMeasure`
; no longer skips `main`, so the measured load is copied out and the local array's
; history is planned for reversal exactly as in a helper body, which declines with
; the message below (the helper spelling of this body declines identically on base
; ef72239c). Base `main` left the dead array record standing across the later
; Ry on `c`: a wrong unitary by the 2026-10-05 dead-record ruling (silent -> loud).
; RETIREMENT TRIGGER: bd test_C_libtooling-01po.26 (build the store reversal); then
; fold this body back into control_guarded_store_onearm_phase.ll with the accept-era
; directives below renamed from `ACC01PO25<prefix>` to `<prefix>`.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s --check-prefix=DECL
; DECL: error{{.*}}in function main{{.*}}cq uncompute: dead record cut from the uncompute frontier is not reversed before its parent's next non-diagonal gate
;
; The accept-era pins of this body (pre-01po.25), kept for the retirement:
; ACC01PO25CHECK-LABEL: define i32 @main(
; ACC01PO25CHECK:      %[[A:[a-zA-Z0-9_.]+]] = call i32 @cqrt_qram_alloc_i32(i32 8)
; ACC01PO25CHECK:      %[[C:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %{{[a-zA-Z0-9_.]+}})
; ACC01PO25CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[C]], double 5.000000e-01)
; ACC01PO25CHECK:      %[[F1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_slt_i32_hl(i32 %[[C]], i32 3)
; ACC01PO25CHECK-NEXT: %[[I:[a-zA-Z0-9_.]+]] = call i32 @cq_template_and_i32_hl(i32 %{{[a-zA-Z0-9_.]+}}, i32 7)
; ACC01PO25CHECK:      call void @cqrt_qram_store_i32_controlled(i32 %[[F1]], i32 %[[A]], i32 %[[I]], i32 %{{[a-zA-Z0-9_.]+}})
; ACC01PO25CHECK:      %[[F2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_slt_i32_hl(i32 %[[C]], i32 3)
; ACC01PO25CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[F2]], double 2.500000e-01), !cq.branchphase
; ACC01PO25CHECK-NEXT: call void @cq_template_icmp_slt_i32_hl_unc(i32 %[[F2]], i32 %[[C]], i32 3)
; ACC01PO25CHECK-NEXT: call void @cqrt_free(i32 %[[F2]])
; ACC01PO25CHECK-NEXT: br label
; ACC01PO25CHECK:      call void @cqrt_ry_i32(i32 %[[C]], double -5.000000e-01)
; ACC01PO25CHECK-NOT:  call void @cqrt_rz_i1(
; ACC01PO25CHECK-NOT:  call void @cq_phi(
; ACC01PO25STRIP-LABEL: define i32 @main(
; ACC01PO25STRIP:       %[[S1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_slt_i32_hl(
; ACC01PO25STRIP:       call void @cq_template_icmp_slt_i32_hl_unc(i32 %[[S1]],
; ACC01PO25STRIP:       call void @cqrt_free(i32 %[[S1]])
; ACC01PO25STRIP:       call void @cqrt_ry_i32(i32 %{{[a-zA-Z0-9_.]+}}, double -5.000000e-01)

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
  br i1 %8, label %9, label %13

9:
  %10 = and i32 %7, 7
  %11 = zext nneg i32 %10 to i64
  %12 = getelementptr inbounds [8 x i32], ptr %3, i64 0, i64 %11
  store i32 7, ptr %12, align 4
  tail call void @cq_phi(double noundef 2.500000e-01)
  br label %13

13:
  %14 = add nsw i32 %0, 3
  %15 = tail call i32 @cq_theta_si32(i32 noundef %14, double noundef 5.000000e-01)
  %16 = and i32 %15, 7
  %17 = zext nneg i32 %16 to i64
  %18 = getelementptr inbounds [8 x i32], ptr %3, i64 0, i64 %17
  %19 = load i32, ptr %18, align 4
  %20 = tail call i32 @cq_theta_si32(i32 noundef %5, double noundef -5.000000e-01)
  %21 = tail call i32 @cq_measure_si32(i32 noundef %20)
  %22 = tail call i32 @cq_measure_si32(i32 noundef %7)
  %23 = add nsw i32 %22, %21
  %24 = tail call i32 @cq_measure_si32(i32 noundef %19)
  %25 = add nsw i32 %23, %24
  ret i32 %25
}
