; lowering_qram_reject_stale_index_shadow_store.ll — ACCEPT since bd test_C_libtooling-57ch.3 (batch 053;
; owner ruling bd 57ch (A)). ⚠ VERDICT INVERTED: this file declined before batch 053.
;
; The stale QRAM access is PLACED before its staling gate with the address `gep`
; (and any widening) it needs (StaleReadPlacement.h clause (b), a carried tainted
; read): the QRAM call is minted at its new position, so it reads the index (and
; stored value) register's pre-gate label, the stream the read-first program
; lowers to.
; The STORE moves; it crosses no other memory access (the later load stays after).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll 2> %t.err
; RUN: %filecheck %s < %t.ll
; RUN: %filecheck --check-prefix=WARN --allow-empty %s < %t.err
; WARN-NOT: {{error|warning}}
;
; CHECK:      call void @cqrt_ry_i64(i32 %[[Q:[a-z0-9]+]], double 5.000000e-01)
; CHECK:      %[[X:[a-z0-9]+]] = call i32 @cq_template_trunc_i64_to_i32(i32 %[[Q]])
; CHECK-NEXT: call void @cqrt_qram_store_i32(i32 %{{[a-z0-9]+}}, i32 %[[X]], i32 %{{[a-z0-9]+}})
; CHECK-NOT:  @cqrt_ry_i64(i32 %[[Q]]
; CHECK:      call void @cqrt_ry_i64(i32 %[[Q]], double 3.000000e-01)
; CHECK:      call i32 @cqrt_qram_load_i32(
;
; ── HISTORY: the pre-batch-053 header, kept verbatim (its verdict text is
; superseded by the block above) ──
; lowering_qram_reject_stale_index_shadow_store.ll — DECLINE (bd
; test_C_libtooling-r2j3.2): a Shadow (local-array) STORE whose bare i64 index
; register was rotated in place before the store. clang -O1 of
;
;     long q = 0L; cq_theta(&q, .5);  long s = 0L; cq_theta(&s, .9); long j = s & 7;
;     long q2 = q; cq_theta(&q2, .3);
;     arr[q] = 5;                       // `q` names the PRE-Ry record
;     return cq_measure(arr[j]) + (int)cq_measure(q2);
;
; MEASURED on the pre-fix binary: exit 0, `cqrt_qram_store_i32(a0, trunc(h1), …)`
; after both `ry(h1, ·)`, i.e. the store writes through the rotated register.
;

declare i64 @cq_theta_sl(i64, double)
declare i32 @cq_measure_si32(i32)
declare i64 @cq_measure_sl(i64)
declare void @llvm.memset.p0.i64(ptr, i8, i64, i1)

define i32 @main() {
entry:
  %arr = alloca [8 x i32], align 16
  call void @llvm.memset.p0.i64(ptr %arr, i8 0, i64 32, i1 false)
  %q = call i64 @cq_theta_sl(i64 0, double 5.000000e-01)
  %j0 = call i64 @cq_theta_sl(i64 0, double 9.000000e-01)
  %j = and i64 %j0, 7
  %q2 = call i64 @cq_theta_sl(i64 %q, double 3.000000e-01)
  %ps = getelementptr inbounds [8 x i32], ptr %arr, i64 0, i64 %q
  store i32 5, ptr %ps, align 4
  %pl = getelementptr inbounds [8 x i32], ptr %arr, i64 0, i64 %j
  %v = load i32, ptr %pl, align 4
  %m = call i32 @cq_measure_si32(i32 %v)
  %n = call i64 @cq_measure_sl(i64 %q2)
  %nt = trunc i64 %n to i32
  %s = add nsw i32 %m, %nt
  ret i32 %s
}
