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
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq opcode lowering: operand predates a non-diagonal gate

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
