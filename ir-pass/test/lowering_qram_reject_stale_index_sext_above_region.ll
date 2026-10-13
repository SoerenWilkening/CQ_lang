; lowering_qram_reject_stale_index_sext_above_region.ll — ACCEPT since bd test_C_libtooling-57ch.1 and 57ch.3 (batch 053;
; owner ruling bd 57ch (A)). ⚠ VERDICT INVERTED: this file declined before batch 053.
;
; The stale QRAM access is PLACED before its staling gate with the address `gep`
; (and any widening) it needs (StaleReadPlacement.h clause (b), a carried tainted
; read): the QRAM call is minted at its new position, so it reads the index (and
; stored value) register's pre-gate label, the stream the read-first program
; lowers to.
; The staler is the in-place controlled Ry in a TAINTED arm and the load is after
; the merge: the slot is the terminator of the block that dominates both (bd
; 57ch.1), so the QRAM call reads `q` before the region.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll 2> %t.err
; RUN: %filecheck %s < %t.ll
; RUN: %filecheck --check-prefix=WARN --allow-empty %s < %t.err
; WARN-NOT: {{error|warning}}
;
; CHECK:      call void @cqrt_ry_i32(i32 %[[H:[a-z0-9]+]], double 5.000000e-01)
; CHECK:      %[[V:[0-9]+]] = call i32 @cqrt_qram_load_i32(i32 %{{[a-z0-9]+}}, i32 %[[H]])
; CHECK:      call void @cqrt_ry_i32_controlled(i32 %{{[a-z_0-9]+}}, i32 %[[H]], double 3.000000e-01)
; CHECK:      call i32 @cqrt_measure_i32(i32 %[[V]])
;
; ── HISTORY: the pre-batch-053 header, kept verbatim (its verdict text is
; superseded by the block above) ──
; lowering_qram_reject_stale_index_sext_above_region.ll — DECLINE (bd
; test_C_libtooling-r2j3.2): the widening `sext` of the index sits ABOVE a
; tainted-condition region whose arm rotates the index register in place (an
; in-place controlled Ry arm), and the read is after the region. The strip makes
; the QRAM call read `%q`'s register at the load, after `cqrt_ry_i32_controlled`.
; MEASURED on the pre-fix binary: exit 0, `ry_controlled(h3, h1, .3)` then
; `qram_load(a0, h1)`.
;
; Why this must be asked at the EARLY sweep and not at the emitter: by the time
; `lowerQramReads` runs the arm's `cq_theta` is already `cqrt_ry_i32_controlled`,
; which no wire walk recognises as a gate. Pins that the sweep seeds the STRIPPED
; register (seeding only the `sext` finds nothing here).
;

@tbl = internal unnamed_addr constant [8 x i32] [i32 3, i32 1, i32 4, i32 1, i32 5, i32 9, i32 2, i32 6], align 16

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @main() {
entry:
  %q = call i32 @cq_theta_si32(i32 0, double 5.000000e-01)
  %c = call i32 @cq_theta_si32(i32 0, double 0x3FE6666666666666)
  %w = sext i32 %q to i64
  %cmp = icmp sgt i32 %c, 3
  br i1 %cmp, label %arm, label %merge

arm:
  %qt = call i32 @cq_theta_si32(i32 %q, double 3.000000e-01)
  br label %merge

merge:
  %r = phi i32 [ %qt, %arm ], [ %q, %entry ]
  %p = getelementptr inbounds [8 x i32], ptr @tbl, i64 0, i64 %w
  %v = load i32, ptr %p, align 4
  %m1 = call i32 @cq_measure_si32(i32 %v)
  %m2 = call i32 @cq_measure_si32(i32 %r)
  %s1 = add nsw i32 %m2, %m1
  %m3 = call i32 @cq_measure_si32(i32 %c)
  %s2 = add nsw i32 %s1, %m3
  ret i32 %s2
}
