; lowering_reject_qram_addrspacecast.ll — DECLINE (Phase 7.5 Inc 3, the §2.8(iv)
; pattern-naming decline matrix): a tainted-index access whose pointer crosses an
; ADDRESS SPACE via `addrspacecast`. A managed-memory model owns ONE address space
; for its known-shape register block; an address-space change is exactly the kind
; of unmodeled pointer reinterpretation reversibility cannot follow (no-cloning /
; linearity, [[pointer-boundary-linearity-bennett]]). The provenance walk hits the
; `addrspacecast` and loud-declines NAMING the crossing. PERMANENT decline.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg)
declare i32 @cq_theta_si32(i32, double)

define void @asc(i32 %u0) {
entry:
  %a = alloca [8 x i32], align 16
  call void @llvm.memset.p0.i64(ptr align 16 %a, i8 0, i64 32, i1 false)
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %as = addrspacecast ptr %a to ptr addrspace(1)         ; crosses an address space
  %iq = sext i32 %q to i64
  %g = getelementptr inbounds [8 x i32], ptr addrspace(1) %as, i64 0, i64 %iq
  store i32 7, ptr addrspace(1) %g, align 4
  ret void
}

; CHECK: error{{.*}}cq QRAM access: pointer crosses an address space
