; lowering_qram_reject_stale_index_gep_hoisted.ll — DECLINE (bd
; test_C_libtooling-r2j3.2): the address gep is scheduled BEFORE the in-place
; `cq_theta` on the index register, the load AFTER it. The QRAM call is minted at
; the LOAD, so the read happens after the Ry. Pins that the stale question is
; asked with the ACCESS as the emission point, never the gep (`-O1` hoists and
; sinks freely, CLAUDE.md R8; a gep-positioned check accepts this module).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq opcode lowering: operand predates a non-diagonal gate

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
