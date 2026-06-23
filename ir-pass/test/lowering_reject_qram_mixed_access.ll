; lowering_reject_qram_mixed_access.ll — DECLINE (Phase 7.5 Inc 2, §6.6): an alloca
; mixing a tainted-index access and a CLASSICAL-index access on the SAME array. A
; tainted store `arr[q]=x` forces the `alloca [8 x i32]` to survive clang -O1, and a
; static-index read `arr[1]` becomes a real classical-index `getelementptr`/`load`.
; The stub model cannot keep a quantum array register (for arr[q]) and a classical
; pointer view (for arr[1]) of the SAME memory coherent — that is aliasing (the
; copy/diagonal map linearity forbids, [[pointer-boundary-linearity-bennett]]) — so
; the whole alloca DECLINES. (A fully-classical SEPARATE array is never a candidate
; and is left untouched — see lowering_qram_store_mixed_classical_separate.ll.)
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @mixed(i32 %u0, i32 %ux) {
entry:
  %arr = alloca [8 x i32], align 16
  call void @llvm.memset.p0.i64(ptr align 16 %arr, i8 0, i64 32, i1 false)
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %x = call i32 @cq_theta_si32(i32 %ux, double 5.000000e-01)
  %iq = sext i32 %q to i64
  %gq = getelementptr inbounds [8 x i32], ptr %arr, i64 0, i64 %iq
  store i32 %x, ptr %gq, align 4               ; tainted-index store
  %g1 = getelementptr inbounds i8, ptr %arr, i64 4   ; arr[1] — CLASSICAL-index access
  %c = load i32, ptr %g1, align 4
  %m = call i32 @cq_measure_si32(i32 %c)
  ret i32 %m
}

; CHECK: error{{.*}}cq QRAM store: alloca array mixes a tainted-index and a classical access
