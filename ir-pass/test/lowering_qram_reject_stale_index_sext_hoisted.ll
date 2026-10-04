; lowering_qram_reject_stale_index_sext_hoisted.ll — DECLINE (bd
; test_C_libtooling-r2j3.2, found while fixing it): the `int` twin with its
; widening `sext` scheduled BEFORE the in-place `cq_theta`. clang -O1 keeps that
; order for
;
;     int q = 0; cq_theta(&q, .5);
;     long w = q;                    // sext here, before the gate
;     int q2 = q; cq_theta(&q2, .3);
;     int v = tbl[w];                // `w` names the PRE-Ry record
;
; The `sext` itself reads `q` before the Ry, so the pure-op sweep accepts it; but
; `resolveQramIndex` STRIPS the widening and the b6a bracket re-casts at the call,
; so the QRAM call reads `q`'s register AT THE LOAD, after the Ry. MEASURED on the
; pre-fix binary from that plain C: exit 0, `ry(h1,.5); ry(h1,.3);
; qram_load(a0, h1)`. The sweep therefore asks about the register the emitter
; reads (`qramIndexRegister`, the strip `resolveQramIndex` itself applies).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq opcode lowering: operand predates a non-diagonal gate

@tbl = internal unnamed_addr constant [8 x i32] [i32 3, i32 1, i32 4, i32 1, i32 5, i32 9, i32 2, i32 6], align 16

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @main() {
entry:
  %q = call i32 @cq_theta_si32(i32 0, double 5.000000e-01)
  %w = sext i32 %q to i64
  %q2 = call i32 @cq_theta_si32(i32 %q, double 3.000000e-01)
  %p = getelementptr inbounds [8 x i32], ptr @tbl, i64 0, i64 %w
  %v = load i32, ptr %p, align 4
  %m = call i32 @cq_measure_si32(i32 %v)
  %n = call i32 @cq_measure_si32(i32 %q2)
  %s = add nsw i32 %n, %m
  ret i32 %s
}
