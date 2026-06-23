; lowering_reject_qram_mid_seq.ll — DECLINE (Phase 7.5 Inc 2, §2.8(iii)): a
; mid-sequence observation. The array is stored (arr[q]=7), then a cell is loaded
; and MEASURED (`measure(arr[p])`), then ANOTHER store mutates it (arr[r]=9). The
; measurement observes an INTERMEDIATE array state that a later store-reversal would
; corrupt; acceptance is conditioned on the reversal-ensured contract (owner
; decision 6 — an unprovable reversal invariant is a LOUD decline, never a silent
; leak). The array may Escape only AFTER its last store.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @midseq(i32 %u0, i32 %u1, i32 %u2) {
entry:
  %arr = alloca [8 x i32], align 16
  call void @llvm.memset.p0.i64(ptr align 16 %arr, i8 0, i64 32, i1 false)
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %p = call i32 @cq_theta_si32(i32 %u1, double 5.000000e-01)
  %r = call i32 @cq_theta_si32(i32 %u2, double 5.000000e-01)
  %iq = sext i32 %q to i64
  %gq = getelementptr inbounds [8 x i32], ptr %arr, i64 0, i64 %iq
  store i32 7, ptr %gq, align 4                ; store
  %ip = sext i32 %p to i64
  %gp = getelementptr inbounds [8 x i32], ptr %arr, i64 0, i64 %ip
  %v = load i32, ptr %gp, align 4
  %m = call i32 @cq_measure_si32(i32 %v)       ; mid-sequence OBSERVATION
  %ir = sext i32 %r to i64
  %gr = getelementptr inbounds [8 x i32], ptr %arr, i64 0, i64 %ir
  store i32 9, ptr %gr, align 4                ; store AFTER the observation
  ret i32 %m
}

; CHECK: error{{.*}}cq QRAM store: array is observed before its last store
