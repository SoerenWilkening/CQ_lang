; lowering_reject_qram_read_coherent_return.ll — DECLINE (Phase 7.5 Inc 1 regression;
; the coherent-return no-cloning fence). A tainted-index READ of a const-global table
; `return tbl[q]` returns a value ENTANGLED with the LOCAL (`cq_theta`) index `q`
; (`tbl[q]` is a function of the superposed address). There are no stores to reverse,
; but the loaded value is still entangled with `q`; with `q` uncomputed/leaked the
; returned carrier is dephased to a classical mixture from the caller's view — a
; verify-clean SILENT DEPHASING MISCOMPILE (the SAME no-cloning wall as the Shadow
; path, bd memory 7-5-qram-coherent-return-nocloning). No reversible circuit can
; return a clean coherent `tbl[q]` once its local address is erased, so the only
; correct action is a LOUD DECLINE.
;
; The MEASURE form stays accepted (immune — the collapse makes the lost coherence
; unobservable and the diagonal is the correct distribution):
; lowering_qram_read_const_global_i32.ll / lowering_qram_read_select_origin.ll. A
; `main`-resident return is the process-exit observation and is not declined.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
@tbl = internal unnamed_addr constant [8 x i32] [i32 3, i32 1, i32 4, i32 1, i32 5, i32 9, i32 2, i32 6]
declare i32 @cq_theta_si32(i32, double)

define i32 @qrom_read_return(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %i = sext i32 %q to i64
  %g = getelementptr inbounds [8 x i32], ptr @tbl, i64 0, i64 %i
  %v = load i32, ptr %g
  ret i32 %v                                  ; <- coherent return of tbl[q] — DECLINE
}

; CHECK: error{{.*}}cq QRAM load: coherently escaping value is entangled with a local index (no-cloning)
