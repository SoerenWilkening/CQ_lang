; lowering_reject_qram_multi_origin.ll — DECLINE (Phase 7.5 Inc 3, the §2.8(iv)
; pattern-naming decline matrix): a tainted-index read whose address gep base is a
; pointer `select` resolving to TWO DISTINCT array origins (`%a` or `%b`). The
; provenance walk cannot prove a single `PtrOrigin`, so reversibility is impossible
; (a quantum array register cannot straddle two physical allocations — no-cloning /
; linearity, [[pointer-boundary-linearity-bennett]]). LOUD decline NAMING the
; multi-origin pattern. This is the realistic clang -O1 shape for `(c?a:b)[q]`.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @multi(i32 %u0, i1 %c) {
entry:
  %a = alloca [8 x i32], align 16
  %b = alloca [8 x i32], align 16
  call void @llvm.memset.p0.i64(ptr align 16 %a, i8 0, i64 32, i1 false)
  call void @llvm.memset.p0.i64(ptr align 16 %b, i8 0, i64 32, i1 false)
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %base = select i1 %c, ptr %a, ptr %b           ; TWO distinct origins
  %i = sext i32 %q to i64
  %g = getelementptr inbounds i32, ptr %base, i64 %i
  %v = load i32, ptr %g, align 4
  %m = call i32 @cq_measure_si32(i32 %v)
  ret i32 %m
}

; CHECK: error{{.*}}cq QRAM access: pointer resolves to multiple array origins
