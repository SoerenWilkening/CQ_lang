; lowering_reject_qram_fp128_shadow_cell.ll — DECLINE (bd 38t2 Rule-13 clearance):
; the SHADOW-path twin of lowering_reject_qram_fp128_cell.ll. Both pre-existing
; kMsgQramCell probes are const-global QROM READS that only exercise the
; lowerQramReads width gate; this fixture drives an unsupported element width
; (`fp128`, abiWidthFromType == "") through the ALLOCA Shadow gate in
; processShadowAlloca — the second of the two gates 38t2 rewired from
; widthHasReversibleCopy to widthHasQramCell — so a refactor regressing the
; Shadow-side width fencing specifically can no longer pass the suite.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg)
declare i32 @cq_theta_si32(i32, double)

define void @shadow_fp128(i32 %u0) {
entry:
  %arr = alloca [4 x fp128], align 16
  call void @llvm.memset.p0.i64(ptr align 16 %arr, i8 0, i64 64, i1 false)
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %i = sext i32 %q to i64
  %g = getelementptr inbounds [4 x fp128], ptr %arr, i64 0, i64 %i
  store fp128 0xL00000000000000004001C00000000000, ptr %g, align 16
  ret void
}

; CHECK: error{{.*}}cq QRAM read: array element is not a reversible cell
