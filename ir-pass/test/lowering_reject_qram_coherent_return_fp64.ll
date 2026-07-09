; lowering_reject_qram_coherent_return_fp64.ll — DECLINE (bd 38t2 Rule-13 clearance):
; the FP twin of the coherent-escape no-cloning fence (lowering_reject_qram_
; coherent_return{,_arith}.ll). A `double` loaded from a local Shadow array at a
; SUPERPOSED index is entangled with that index; coherently escaping it from a
; non-`main` function would let the whole-DAG reversal dirty-free the local index
; rails it is entangled with — a hidden measurement (Rule 6). 38t2 makes fp the first
; new shape class to reach this guard (kMsgQramCohEscape), which must keep firing
; BEFORE the fp emit (the PRD load-bearing invariant). NOTE the fp escape must be
; LAUNDERED to i32 (`fptosi` → `ret i32`): a naked `ret double` declines EARLIER at
; the generic non-i32-width taint-escape guard and never exercises this fence.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg)
declare i32 @cq_theta_si32(i32, double)

define i32 @shadow_return_fp(i32 %u0, i32 %u1) {
entry:
  %arr = alloca [8 x double], align 16
  call void @llvm.memset.p0.i64(ptr align 16 %arr, i8 0, i64 64, i1 false)
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %p = call i32 @cq_theta_si32(i32 %u1, double 5.000000e-01)
  %iq = sext i32 %q to i64
  %gq = getelementptr inbounds [8 x double], ptr %arr, i64 0, i64 %iq
  store double 7.000000e+00, ptr %gq, align 8   ; arr[q] = 7.0
  %ip = sext i32 %p to i64
  %gp = getelementptr inbounds [8 x double], ptr %arr, i64 0, i64 %ip
  %v = load double, ptr %gp, align 8            ; arr[p]  (tainted-index fp load)
  %c = fptosi double %v to i32                  ; launder to i32 …
  ret i32 %c                                    ; … then coherent escape — DECLINE
}

; CHECK: error{{.*}}cq QRAM load: coherently escaping value is entangled with a local index (no-cloning)
