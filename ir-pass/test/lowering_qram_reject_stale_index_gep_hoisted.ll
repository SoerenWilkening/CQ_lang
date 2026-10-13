; lowering_qram_reject_stale_index_gep_hoisted.ll — ACCEPT since bd test_C_libtooling-57ch.3 (batch 053;
; owner ruling bd 57ch (A)). ⚠ VERDICT INVERTED: this file declined before batch 053.
;
; The stale QRAM access is PLACED before its staling gate with the address `gep`
; (and any widening) it needs (StaleReadPlacement.h clause (b), a carried tainted
; read): the QRAM call is minted at its new position, so it reads the index (and
; stored value) register's pre-gate label, the stream the read-first program
; lowers to.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll 2> %t.err
; RUN: %filecheck %s < %t.ll
; RUN: %filecheck --check-prefix=WARN --allow-empty %s < %t.err
; WARN-NOT: {{error|warning}}
;
; CHECK:      call void @cqrt_ry_i64(i32 %[[H:[a-z0-9]+]], double 5.000000e-01)
; CHECK-NEXT: %[[X:[a-z0-9]+]] = call i32 @cq_template_trunc_i64_to_i32(i32 %[[H]])
; CHECK-NEXT: %[[V:[0-9]+]] = call i32 @cqrt_qram_load_i32(i32 %{{[a-z0-9]+}}, i32 %[[X]])
; CHECK-NEXT: call void @cq_template_trunc_i64_to_i32_unc(i32 %[[X]], i32 %[[H]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[X]])
; CHECK-NEXT: call void @cqrt_ry_i64(i32 %[[H]], double 3.000000e-01)
; CHECK:      call i32 @cqrt_measure_i32(i32 %[[V]])
;
; ── HISTORY: the pre-batch-053 header, kept verbatim (its verdict text is
; superseded by the block above) ──
; lowering_qram_reject_stale_index_gep_hoisted.ll — DECLINE (bd
; test_C_libtooling-r2j3.2): the address gep is scheduled BEFORE the in-place
; `cq_theta` on the index register, the load AFTER it. The QRAM call is minted at
; the LOAD, so the read happens after the Ry. Pins that the stale question is
; asked with the ACCESS as the emission point, never the gep (`-O1` hoists and
; sinks freely, CLAUDE.md R8; a gep-positioned check accepts this module).
;

@tbl = internal unnamed_addr constant [8 x i32] [i32 3, i32 1, i32 4, i32 1, i32 5, i32 9, i32 2, i32 6], align 16

declare i64 @cq_theta_sl(i64, double)
declare i32 @cq_measure_si32(i32)
declare i64 @cq_measure_sl(i64)

define i32 @main() {
entry:
  %q = call i64 @cq_theta_sl(i64 0, double 5.000000e-01)
  %p = getelementptr inbounds [8 x i32], ptr @tbl, i64 0, i64 %q   ; before the gate
  %q2 = call i64 @cq_theta_sl(i64 %q, double 3.000000e-01)         ; in-place Ry
  %v = load i32, ptr %p, align 4                                     ; the read: after
  %m = call i32 @cq_measure_si32(i32 %v)
  %n = call i64 @cq_measure_sl(i64 %q2)
  %nt = trunc i64 %n to i32
  %s = add nsw i32 %m, %nt
  ret i32 %s
}
