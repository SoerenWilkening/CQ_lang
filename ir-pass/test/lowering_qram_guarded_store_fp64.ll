; lowering_qram_guarded_store_fp64.ll — ACCEPT (bd 38t2 + iw81.7): a tainted-index fp
; Shadow STORE UNDER tainted control — `if (q < 3) { arr[i] = 7.0; }  v = arr[q];
; measure(v)`. The fp twin of lowering_qram_guarded_store.ll (decision #2: guarded fp
; store IN scope). The side-effect-only store is GENUINELY CONTROLLED — the emitter
; mints the path-predicate flag, flattens the diamond, and `lowerShadowMemory` emits
; `cqrt_qram_store_f64_controlled(flag, arr, idx, val)`. The post-diamond load `arr[q]`
; is a direct-sole-measure, so it copies out to a kept carrier via the fp copy-out
; `cqrt_copy_f64` (the live consumer of the uncontrolled fp copy — bd 38t2). Reversal
; (LIFO): load_unc + free, then the guarded store `_controlled_unc` with the flag STILL
; LIVE (arg 0), THEN the flag strip — the store-reverse-BEFORE-strip pred-lifetime
; invariant. The array handle is NEVER freed (§2.9).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg)
declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)

define double @guarded_fp(double %u0, double %u1) {
entry:
  %arr = alloca [8 x double], align 16
  call void @llvm.memset.p0.i64(ptr align 16 %arr, i8 0, i64 64, i1 false)
  %q = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  %i = call double @cq_theta_f64(double %u1, double 5.000000e-01)
  %qi = fptosi double %q to i32
  %f = icmp slt i32 %qi, 3
  br i1 %f, label %arm, label %merge

arm:                                              ; the side-effect-only fp store arm
  %ii = fptosi double %i to i32
  %si = sext i32 %ii to i64
  %g = getelementptr inbounds [8 x double], ptr %arr, i64 0, i64 %si
  store double 7.000000e+00, ptr %g, align 8      ; arr[i] = 7.0 — tainted index, guarded
  br label %merge

merge:
  %sq = sext i32 %qi to i64
  %gq = getelementptr inbounds [8 x double], ptr %arr, i64 0, i64 %sq
  %v = load double, ptr %gq, align 8              ; arr[q] — unconditional (post-dominates)
  %m = call double @cq_measure_f64(double %v)
  ret double %m
}

; Array birth, flag mint, materialized classical fp value, then the GUARDED fp store:
; CHECK:     %[[ARR:[a-zA-Z0-9_.]+]] = call i32 @cqrt_qram_alloc_f64(i32 8)
; CHECK:     %[[FLAG:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_slt_i32_hl(i32 %[[Q:[a-zA-Z0-9_.]+]], i32 3)
; CHECK:     %[[VAL:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_f64(double 7.000000e+00)
; CHECK:     call void @cqrt_qram_store_f64_controlled(i32 %[[FLAG]], i32 %[[ARR]], i32 %[[IDX:[a-zA-Z0-9_.]+]], i32 %[[VAL]])
; The direct-sole-measure load copies out to a kept carrier via the fp copy-out:
; CHECK:     %[[V:[a-zA-Z0-9_.]+]] = call i32 @cqrt_qram_load_f64(i32 %[[ARR]], i32 %[[Q]])
; CHECK:     %[[RET:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_f64(double 0.000000e+00)
; CHECK:     call void @cqrt_copy_f64(i32 %[[V]], i32 %[[RET]])
; Reversal (LIFO): load_unc + free, then the guarded store `_controlled_unc` (flag STILL
; LIVE), then the flag STRIP — the store-reverse-BEFORE-strip pred-lifetime invariant:
; CHECK:     call void @cqrt_qram_load_f64_unc(i32 %[[V]], i32 %[[ARR]], i32 %[[Q]])
; CHECK:     call void @cqrt_qram_store_f64_controlled_unc(i32 %[[FLAG]], i32 %[[ARR]], i32 %[[IDX]], i32 %[[VAL]])
; CHECK:     call void @cq_template_icmp_slt_i32_hl_unc(i32 %[[FLAG]], i32 %[[Q]], i32 3)
; CHECK:     call void @cqrt_free(i32 %[[FLAG]])
; The carrier is measured; the array handle is NEVER freed:
; CHECK:     call double @cqrt_measure_f64(i32 %[[RET]])
; CHECK-NOT: call void @cqrt_free(i32 %[[ARR]])
; CHECK-NOT: br i1
; CHECK-NOT: store double
; CHECK-NOT: = icmp
