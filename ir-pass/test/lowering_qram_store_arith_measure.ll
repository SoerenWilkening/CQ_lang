; lowering_qram_store_arith_measure.ll — ACCEPT (bug test_C_libtooling-l6xk, the
; measure-side contrast to the coherent-return decline). A non-`main` function loads
; a cell from a local alloca Shadow array at a superposed index, does ARITHMETIC, and
; MEASURES the result: `cq_measure(arr[p] + 1)`. Unlike the coherent RETURN of the
; same arithmetic (lowering_reject_qram_coherent_return_arith.ll — a no-cloning
; DECLINE), the measurement COLLAPSES the value, so the entanglement with the local
; index is unobservable and the measured distribution is correct (measurement
; immunity; bd memory 7-5-qram-coherent-return-nocloning). It therefore ACCEPTS.
;
; The load result's direct user is the `add` (not the measure), so the direct-measure
; copy-out (emitCopyOutIfDirectMeasure) does NOT fire: the array + index + arith rails
; are LEFT ALLOCATED — a Rule-6 SAFE LEAK that is CORRECT under measurement immunity
; (the alternative, reversing + freeing the index, is sound here too but is not done,
; to keep the spine change minimal; reversal is only emitted for the DIRECT-measure
; sxuk shape). No store_unc / load_unc / free is emitted. NO measurement is inserted
; that the user did not write (Rule 5).
;
; M-C NOTE (bd test_C_libtooling-6uqc, Increment 2a): the `q + c` lowers IN PLACE
; to the frozen `cqrt_addc_<W>` (its parent handle has no data use after it), so
; no ancestor rail is minted and the measurement reads the rail itself. Nothing
; else this file pins has moved.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @shadow_arith_measure(i32 %u0, i32 %u1) {
entry:
  %arr = alloca [8 x i32], align 16
  call void @llvm.memset.p0.i64(ptr align 16 %arr, i8 0, i64 32, i1 false)
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %p = call i32 @cq_theta_si32(i32 %u1, double 5.000000e-01)
  %iq = sext i32 %q to i64
  %gq = getelementptr inbounds [8 x i32], ptr %arr, i64 0, i64 %iq
  store i32 7, ptr %gq, align 4
  %ip = sext i32 %p to i64
  %gp = getelementptr inbounds [8 x i32], ptr %arr, i64 0, i64 %ip
  %v = load i32, ptr %gp, align 4              ; arr[p]
  %s = add i32 %v, 1                            ; arith on the loaded value
  %m = call i32 @cq_measure_si32(i32 %s)        ; OBSERVED — collapses (immune)
  ret i32 %m
}

; The store/load/arith lower; the measured value collapses; NOTHING is reversed/freed
; (a correct safe leak under measurement immunity):
; CHECK:     %[[ARR:[a-zA-Z0-9_.]+]] = call i32 @cqrt_qram_alloc_i32(i32 8)
; CHECK:     call void @cqrt_qram_store_i32(i32 %[[ARR]], i32 %{{[a-zA-Z0-9_.]+}}, i32 %{{[a-zA-Z0-9_.]+}})
; CHECK:     %[[V:[a-zA-Z0-9_.]+]] = call i32 @cqrt_qram_load_i32(i32 %[[ARR]], i32 %{{[a-zA-Z0-9_.]+}})
; CHECK:     call void @cqrt_addc_i32(i32 %[[V]], i32 1)
; CHECK:     %[[M:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[V]])
; CHECK:     ret i32 %[[M]]
; CHECK-NOT: cqrt_qram_store_i32_unc
; CHECK-NOT: cqrt_qram_load_i32_unc
; CHECK-NOT: cqrt_copy
; CHECK-NOT: cqrt_free
; CHECK-NOT: = load
; CHECK-NOT: getelementptr
