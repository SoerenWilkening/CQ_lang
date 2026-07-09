; lowering_reject_qram_pun_store_fp.ll — DECLINE (bd 38t2 Rule-13 clearance): a
; TYPE-PUNNED sub-width fp store into a wider fp cell — `store float` through a
; `[8 x double]` gep (real C: `*(float*)&arr[q] = x;` at -O1). matchQramAccess
; derives the cell width from the ORIGIN array; without the accessed-type == cell-type
; pun fence this ACCEPTED and emitted `cqrt_qram_store_f64(arr, idx, h)` where `h` is
; an f32 rail (cqrt_alloc_f32 + cqrt_ry_f32) — a 64-bit cell CNOT-write sourced from a
; 32-bit register, verify-clean and diagnostic-free (the defining silent miscompile;
; pre-38t2 the blanket integer-only width gate incidentally fenced it). With the fence
; the access is NOT a qram shape and the tainted store loud-declines at the pass-wide
; taint-escape guard.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg)
declare float @cq_theta_f32(float, double)
declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)

define double @pun_store(double %u0, float %u1) {
entry:
  %arr = alloca [8 x double], align 16
  call void @llvm.memset.p0.i64(ptr align 16 %arr, i8 0, i64 64, i1 false)
  %q = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  %x = call float @cq_theta_f32(float %u1, double 5.000000e-01)
  %qi = fptosi double %q to i64
  %g = getelementptr inbounds [8 x double], ptr %arr, i64 0, i64 %qi
  store float %x, ptr %g, align 4              ; PUN: f32 store into an f64 cell
  %g2 = getelementptr inbounds [8 x double], ptr %arr, i64 0, i64 1
  %v = load double, ptr %g2, align 8
  %m = call double @cq_measure_f64(double %v)
  ret double %m
}

; CHECK: error{{.*}}cq taint escape: tainted value stored to memory
