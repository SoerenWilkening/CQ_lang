; lowering_qram_reject_stale_index_nested_outer.ll — ACCEPT since bd test_C_libtooling-57ch.3 (batch 053;
; owner ruling bd 57ch (A)). ⚠ VERDICT INVERTED: this file declined before batch 053.
;
; The stale QRAM access is PLACED before its staling gate with the address `gep`
; (and any widening) it needs (StaleReadPlacement.h clause (b), a carried tainted
; read): the QRAM call is minted at its new position, so it reads the index (and
; stored value) register's pre-gate label, the stream the read-first program
; lowers to.
; The OUTER load (and its `gep`) is placed before the Ry on the inner load's
; result rail. The warning is the lyyf live-record class and the program's: the
; outer result is a basis copy of `w` that the source keeps across Ry on `w`.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll 2> %t.err
; RUN: %filecheck %s < %t.ll
; RUN: %filecheck --check-prefix=WARN %s < %t.err
; WARN: warning: {{.*}}cq rotation lowering: non-diagonal gate over a live derived record
;
; CHECK:      %[[W:[0-9]+]] = call i32 @cqrt_qram_load_i64(i32 %{{[a-z0-9]+}}, i32 %{{[a-z0-9]+}})
; CHECK:      %[[X:[a-z0-9]+]] = call i32 @cq_template_trunc_i64_to_i32(i32 %[[W]])
; CHECK-NEXT: %[[V:[0-9]+]] = call i32 @cqrt_qram_load_i32(i32 %{{[a-z0-9]+}}, i32 %[[X]])
; CHECK-NEXT: call void @cq_template_trunc_i64_to_i32_unc(i32 %[[X]], i32 %[[W]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[X]])
; CHECK-NEXT: call void @cqrt_ry_i64(i32 %[[W]], double 3.000000e-01)
; CHECK:      call i32 @cqrt_measure_i32(i32 %[[V]])
;
; ── HISTORY: the pre-batch-053 header, kept verbatim (its verdict text is
; superseded by the block above) ──
; lowering_qram_reject_stale_index_nested_outer.ll — DECLINE (bd
; test_C_libtooling-r2j3.2): the OUTER read of a nested access takes the inner
; read's i64 result as a bare index, and that result's register is rotated in
; place before the outer read:
;
;     long w = tbl64[q];  long w2 = w; cq_theta(&w2, .3);  v = tbl2[w];  // `w`: PRE-Ry
;
; The inner load result is a fresh copy-out rail, and the chained `cq_theta` is an
; in-place Ry on it; the outer `cqrt_qram_load` is minted at its own load, after.
; Accept twin (the widened copy is what was rotated, the strip reads the
; unrotated source): lowering_qram_stale_index_widened_copy_rotated_accept.ll.
;

@tbl64 = internal unnamed_addr constant [8 x i64] [i64 3, i64 1, i64 4, i64 1, i64 5, i64 7, i64 2, i64 6], align 16
@tbl2 = internal unnamed_addr constant [8 x i32] [i32 7, i32 7, i32 1, i32 2, i32 3, i32 4, i32 5, i32 6], align 16

declare i64 @cq_theta_sl(i64, double)
declare i32 @cq_measure_si32(i32)
declare i64 @cq_measure_sl(i64)

define i32 @main() {
entry:
  %q = call i64 @cq_theta_sl(i64 0, double 5.000000e-01)
  %p1 = getelementptr inbounds [8 x i64], ptr @tbl64, i64 0, i64 %q
  %w = load i64, ptr %p1, align 8
  %w2 = call i64 @cq_theta_sl(i64 %w, double 3.000000e-01)
  %p2 = getelementptr inbounds [8 x i32], ptr @tbl2, i64 0, i64 %w
  %v = load i32, ptr %p2, align 4
  %m = call i32 @cq_measure_si32(i32 %v)
  %n = call i64 @cq_measure_sl(i64 %w2)
  %nt = trunc i64 %n to i32
  %s = add nsw i32 %m, %nt
  ret i32 %s
}
