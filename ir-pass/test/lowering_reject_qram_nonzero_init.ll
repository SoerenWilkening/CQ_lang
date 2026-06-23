; lowering_reject_qram_nonzero_init.ll — DECLINE (Phase 7.5 Inc 3, the Rule-13
; initializer-mis-modeling fix; PRD-7.5 §2.6 / §6 risk #5): an alloca-backed array
; with a NON-ZERO `memset` initializer. The trace runtime models a fresh QRAM array
; as |0> cells (`cqrt_qram_alloc_<W>` records only the COUNT, never the contents).
; A `memset(arr, 0xAA, …)` seeds 0xAAAAAAAA into every cell; a later `load` of an
; un-overwritten cell (here `arr[q]` with q != the stored index p) would read 0 in
; the trace model while the TRUE value is 0xAAAAAAAA — a verify-clean WRONG-DATA
; silent miscompile. Only a ZERO-fill memset matches the |0>-init model, so a
; non-zero (or non-constant) fill loud-declines NAMING the unrepresentable
; initializer (over-declining is safe; the silent drop is the unforgivable bug).
; (A `int arr[]={3,1,…}` initializer comes as `llvm.memcpy` from a const global and
; already declines at kMsgQramEscape; the QROM read path, Inc 1, carries REAL const
; contents through the const-global origin.)
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @nz(i32 %u0, i32 %u1, i32 %x) {
entry:
  %a = alloca [8 x i32], align 16
  call void @llvm.memset.p0.i64(ptr align 16 %a, i8 -86, i64 32, i1 false)  ; 0xAA — non-zero fill
  %p = call i32 @cq_theta_si32(i32 %u1, double 5.000000e-01)
  %ip = sext i32 %p to i64
  %gp = getelementptr inbounds [8 x i32], ptr %a, i64 0, i64 %ip
  store i32 %x, ptr %gp, align 4               ; overwrites ONE cell (arr[p])
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %iq = sext i32 %q to i64
  %gq = getelementptr inbounds [8 x i32], ptr %a, i64 0, i64 %iq
  %v = load i32, ptr %gq, align 4              ; reads an INITIALIZER cell (q != p)
  %m = call i32 @cq_measure_si32(i32 %v)
  ret i32 %m
}

; CHECK: error{{.*}}cq QRAM store: alloca array has a non-zero initializer the trace model cannot represent
