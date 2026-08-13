; lowering_qram_fp64_measure_no_dirty_free.ll — ACCEPT (bd 38t2): the SHARP
; DISCRIMINATOR at fp width. A coherent fp carrier (`%cp = Rz(Ry)`) is stored at a
; tainted index, LOADED BACK at a DIFFERENT tainted index, put through a chained
; `cq_theta_f64` (an in-place Ry that converts a relative PHASE into an amplitude — the
; only interference OBSERVABLE through the CQ surface), then MEASURED. This is the shape
; a naive "storing a carrier dephases → miscompile" analysis flags — but it is SOUND:
; the compiler emits EXACTLY the user's forward gate stream (alloc/ry/rz/ry/store/ry/
; load/ry/measure) with ZERO cqrt_free and ZERO `_unc` in the measured cone (the
; measured terminal takes the whole-DAG `InsertTerms`-empty bail). Emitted == written =
; correct-by-construction; the never-freed carrier/cell/index entanglement is
; unobservable at a computational-basis measure (measurement immunity, memory
; 7-5-qram-coherent-return-nocloning). NO compiler-inserted measurement/dirty-free can
; diverge from the faithful reversible-QRAM semantics (bd
; [38t2-fp-cell-commits-to-basis-sound]). Distinct tainted indices q != p defeat
; store->load forwarding and keep the array live.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %cq-opt -passes=verify -disable-output - < %t.cqd0.ll
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg)
declare double @cq_theta_f64(double, double)
declare double @cq_phi_f64(double, double)
declare double @cq_measure_f64(double)

define double @shadow_fp_measure(double %u0) {
entry:
  %arr = alloca [8 x double], align 16
  call void @llvm.memset.p0.i64(ptr align 16 %arr, i8 0, i64 64, i1 false)
  %c  = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  %cp = call double @cq_phi_f64(double %c, double 3.000000e-01)
  %q  = call double @cq_theta_f64(double 0.0, double 1.000000e-01)
  %qi = fptosi double %q to i32
  %iq = sext i32 %qi to i64
  %gq = getelementptr inbounds [8 x double], ptr %arr, i64 0, i64 %iq
  store double %cp, ptr %gq, align 8
  %p  = call double @cq_theta_f64(double 0.0, double 2.000000e-01)
  %pi = fptosi double %p to i32
  %ip = sext i32 %pi to i64
  %gp = getelementptr inbounds [8 x double], ptr %arr, i64 0, i64 %ip
  %v  = load double, ptr %gp, align 8                              ; load-back at a DIFFERENT index
  %w  = call double @cq_theta_f64(double %v, double 1.000000e+00)  ; chained Ry — phase->amplitude (OBSERVABLE)
  %m  = call double @cq_measure_f64(double %w)
  ret double %m
}

; The forward stream, verbatim (alloc / carrier ry+rz / index ry / store / index ry /
; load / chained ry / measure):
; CHECK:     %[[ARR:[a-zA-Z0-9_.]+]] = call i32 @cqrt_qram_alloc_f64(i32 8)
; CHECK:     call void @cqrt_ry_f64(i32 %[[H:[a-zA-Z0-9_.]+]], double 5.000000e-01)
; CHECK:     call void @cqrt_rz_f64(i32 %[[H]], double 3.000000e-01)
; CHECK:     call void @cqrt_qram_store_f64(i32 %[[ARR]], i32 %{{[a-zA-Z0-9_.]+}}, i32 %[[H]])
; CHECK:     %[[V:[a-zA-Z0-9_.]+]] = call i32 @cqrt_qram_load_f64(i32 %[[ARR]], i32 %{{[a-zA-Z0-9_.]+}})
; CHECK:     call void @cqrt_ry_f64(i32 %[[V]], double 1.000000e+00)
; CHECK:     call double @cqrt_measure_f64(i32 %[[V]])
; NO compiler-inserted reversal or free enters the measured cone (measure-immune):
; CHECK-NOT: cqrt_qram_store_f64_unc
; CHECK-NOT: cqrt_qram_load_f64_unc
; CHECK-NOT: call void @cqrt_free
; CHECK-NOT: cqrt_copy
