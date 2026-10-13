; lowering_qram_reject_stale_index_sext_hoisted.ll — ACCEPT since bd test_C_libtooling-57ch.3 (batch 053;
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
; CHECK:      call void @cqrt_ry_i32(i32 %[[H:[a-z0-9]+]], double 5.000000e-01)
; CHECK-NEXT: %[[V:[0-9]+]] = call i32 @cqrt_qram_load_i32(i32 %{{[a-z0-9]+}}, i32 %[[H]])
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 3.000000e-01)
; CHECK:      call i32 @cqrt_measure_i32(i32 %[[V]])
;
; ── HISTORY: the pre-batch-053 header, kept verbatim (its verdict text is
; superseded by the block above) ──
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
