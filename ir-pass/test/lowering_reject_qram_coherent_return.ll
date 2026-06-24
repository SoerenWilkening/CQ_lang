; lowering_reject_qram_coherent_return.ll — DECLINE (bug test_C_libtooling-l6xk + the
; sxuk direct-return regression; the coherent-return no-cloning fence). A value
; LOADED from a local alloca Shadow array at a SUPERPOSED (tainted) index is
; ENTANGLED with that index (`arr[p] = [p==q]·v`, a function of the load AND store
; addresses). Returning it COHERENTLY from a non-`main` function is a verify-clean
; SILENT DEPHASING MISCOMPILE: the whole-DAG reversal would uncompute and FREE the
; LOCAL (`cq_theta`) index rails it is entangled with — a dirty free (hidden
; measurement, Rule 6) that collapses the returned carrier to a classical mixture
; (off-diagonal coherence exactly 0). By no-cloning NO reversible circuit can return
; a clean coherent `arr[p]` once its local address is erased; leaving the index
; allocated only DEFERS the collapse. So the only correct action is a LOUD DECLINE
; (VERIFIED physics 2026-06-24; bd memory 7-5-qram-coherent-return-nocloning).
;
; This supersedes the earlier sxuk return-form ACCEPT fixture (which copied the value
; out and reversed — itself the dephasing bug for the coherent case). The MEASURE
; form stays accepted (immune): lowering_qram_store_alloca_i32.ll / _flat_gep.ll. The
; ARITH-then-return (l6xk) shape declines in lowering_reject_qram_coherent_return_arith.ll.
; NO measurement is inserted (Rule 5).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg)
declare i32 @cq_theta_si32(i32, double)

; DIRECT coherent return: return arr[p]   (the sxuk direct-return regression)
define i32 @shadow_return_direct(i32 %u0, i32 %u1) {
entry:
  %arr = alloca [8 x i32], align 16
  call void @llvm.memset.p0.i64(ptr align 16 %arr, i8 0, i64 32, i1 false)
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %p = call i32 @cq_theta_si32(i32 %u1, double 5.000000e-01)
  %iq = sext i32 %q to i64
  %gq = getelementptr inbounds [8 x i32], ptr %arr, i64 0, i64 %iq
  store i32 7, ptr %gq, align 4                ; arr[q] = 7
  %ip = sext i32 %p to i64
  %gp = getelementptr inbounds [8 x i32], ptr %arr, i64 0, i64 %ip
  %v = load i32, ptr %gp, align 4             ; arr[p]  (tainted-index load)
  ret i32 %v                                  ; <- coherent return — DECLINE
}

; CHECK: error{{.*}}cq QRAM load: coherently escaping value is entangled with a local index (no-cloning)
