; lowering_reject_qram_coherent_return_arith.ll — DECLINE (bug test_C_libtooling-l6xk,
; the reported follow-up shape). A non-`main` function loads TWO cells from a local
; alloca Shadow array at superposed indices, ADDS them, and returns the sum:
; `return arr[p] + arr[r]`. The escaped terminal is the `add` result — one arithmetic
; op ABOVE the loads — so the loaded values are non-terminal and the whole-DAG
; reversal would uncompute and FREE the local index rails the sum is entangled with,
; dephasing the returned carrier (the coherent-return no-cloning fence; the same class
; as the direct return in lowering_reject_qram_coherent_return.ll). The forward
; coherent-escape walk (`coherentlyEscapesToReturn`) follows the load result through
; the `add` to the `ret` and loud-declines. A MEASURE of the arith result is immune
; and is NOT declined (measurement collapse; left a Rule-6 safe leak).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg)
declare i32 @cq_theta_si32(i32, double)

define i32 @shadow_return_arith(i32 %u0, i32 %u1, i32 %u2) {
entry:
  %arr = alloca [8 x i32], align 16
  call void @llvm.memset.p0.i64(ptr align 16 %arr, i8 0, i64 32, i1 false)
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %p = call i32 @cq_theta_si32(i32 %u1, double 5.000000e-01)
  %r = call i32 @cq_theta_si32(i32 %u2, double 5.000000e-01)
  %iq = sext i32 %q to i64
  %gq = getelementptr inbounds [8 x i32], ptr %arr, i64 0, i64 %iq
  store i32 7, ptr %gq, align 4
  %ip = sext i32 %p to i64
  %gp = getelementptr inbounds [8 x i32], ptr %arr, i64 0, i64 %ip
  %x = load i32, ptr %gp, align 4              ; arr[p]
  %ir = sext i32 %r to i64
  %gr = getelementptr inbounds [8 x i32], ptr %arr, i64 0, i64 %ir
  %y = load i32, ptr %gr, align 4              ; arr[r]
  %sum = add i32 %x, %y                         ; arith on loaded values
  ret i32 %sum                                  ; <- coherent return of arith result — DECLINE
}

; CHECK: error{{.*}}cq QRAM load: coherently escaping value is entangled with a local index (no-cloning)
