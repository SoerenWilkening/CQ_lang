; lowering_qram_reject_stale_index_zext_hoisted.ll — DECLINE (bd
; test_C_libtooling-r2j3.2): the `unsigned` spelling of
; lowering_qram_reject_stale_index_sext_hoisted.ll. The widening is a `zext`,
; scheduled before the in-place `cq_theta`; `resolveQramIndex` strips a `zext`
; exactly like a `sext`, so the QRAM call reads `%q`'s register at the load,
; after the Ry. Pins that the sweep seeds the register `qramIndexRegister`
; strips a `zext` to (seeding the `zext` itself finds no gate here).
;
;     unsigned q = cq_theta(0u, .5);
;     unsigned long w = q;           // zext here, before the gate
;     unsigned q2 = cq_theta(q, .3);
;     int v = tbl[w];
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq opcode lowering: operand predates a non-diagonal gate

@tbl = internal unnamed_addr constant [8 x i32] [i32 3, i32 1, i32 4, i32 1, i32 5, i32 9, i32 2, i32 6], align 16

declare i32 @cq_theta_ui32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i32 @cq_measure_ui32(i32)

define i32 @main() {
entry:
  %q = call i32 @cq_theta_ui32(i32 0, double 5.000000e-01)
  %w = zext i32 %q to i64
  %q2 = call i32 @cq_theta_ui32(i32 %q, double 3.000000e-01)
  %p = getelementptr inbounds [8 x i32], ptr @tbl, i64 0, i64 %w
  %v = load i32, ptr %p, align 4
  %m = call i32 @cq_measure_si32(i32 %v)
  %n = call i32 @cq_measure_ui32(i32 %q2)
  %s = add i32 %n, %m
  ret i32 %s
}
