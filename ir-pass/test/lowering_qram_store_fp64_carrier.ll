; lowering_qram_store_fp64_carrier.ll — ACCEPT (bd 38t2): a DEAD-scratch fp cell
; store of a COHERENT CARRIER. `%cp = Rz(Ry(theta))` is a superposition-with-relative-
; phase fp carrier; `arr[q] = %cp` stores it into a `[8 x double]` cell at a tainted
; index. This is FAITHFUL reversible QRAM: the store CNOT-copies the fp BIT PATTERN
; into the |0> cell, and the whole-DAG LIFO uncompute fires `cqrt_qram_store_f64_unc`
; FIRST — disentangling the carrier from the cell — and only THEN reverse-plays the
; carrier's own `cqrt_rz_f64`/`cqrt_ry_f64` adjoints and frees it clean (the Bennett
; order, NOT method-B: a CNOT-copy of a carrier into |0> preserves the phase in the
; JOINT amplitude, so the reversal is a clean identity — bd
; [38t2-fp-cell-commits-to-basis-sound]). PARITY with the shipped integer
; lowering_qram_store_dead_lifo.ll (the fp store is the identical W-bit CNOT-write;
; handles are always i32, only the symbol name changes). The array handle is a
; classical resource token, NEVER freed (§2.9). NO measurement (Rule 5).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg)
declare double @cq_theta_f64(double, double)
declare double @cq_phi_f64(double, double)

define void @shadow_fp_carrier(double %u0) {
entry:
  %arr = alloca [8 x double], align 16
  call void @llvm.memset.p0.i64(ptr align 16 %arr, i8 0, i64 64, i1 false)
  %c  = call double @cq_theta_f64(double %u0, double 5.000000e-01)   ; Ry superposition carrier
  %cp = call double @cq_phi_f64(double %c, double 3.000000e-01)      ; Rz relative phase — the "answer"
  %q  = call double @cq_theta_f64(double 0.0, double 1.000000e-01)   ; tainted fp index
  %qi = fptosi double %q to i32
  %iq = sext i32 %qi to i64
  %gq = getelementptr inbounds [8 x double], ptr %arr, i64 0, i64 %iq
  store double %cp, ptr %gq, align 8                                 ; arr[q] = carrier (tainted fp value)
  ret void
}

; Array birth at fp width, the carrier (ry+rz), the tainted index, then the fp store:
; CHECK:     %[[ARR:[a-zA-Z0-9_.]+]] = call i32 @cqrt_qram_alloc_f64(i32 8)
; CHECK:     call void @cqrt_ry_f64(i32 %[[H:[a-zA-Z0-9_.]+]], double 5.000000e-01)
; CHECK:     call void @cqrt_rz_f64(i32 %[[H]], double 3.000000e-01)
; CHECK:     call void @cqrt_qram_store_f64(i32 %[[ARR]], i32 %[[IDX:[a-zA-Z0-9_.]+]], i32 %[[H]])
; Reversal: the store `_unc` fires BEFORE the carrier's Rz/Ry adjoints — the carrier is
; disentangled from the cell FIRST, then uncomputed to |0> and freed clean:
; CHECK:     call void @cqrt_qram_store_f64_unc(i32 %[[ARR]], i32 %[[IDX]], i32 %[[H]])
; CHECK:     call void @cqrt_rz_f64(i32 %[[H]], double -3.000000e-01)
; CHECK:     call void @cqrt_ry_f64(i32 %[[H]], double -5.000000e-01)
; CHECK:     call void @cqrt_free(i32 %[[H]])
; The array handle is NEVER freed (a classical resource, §2.9); no measurement:
; CHECK-NOT: call void @cqrt_free(i32 %[[ARR]])
; CHECK-NOT: cqrt_measure
; CHECK-NOT: cqrt_copy
; CHECK-NOT: cq taint escape
