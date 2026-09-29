; control_angle_select_reject_cross_block_consumer.ll — DECLINE (S6): the consumer
; is in a LATER BLOCK than the select (bd drbq Inc 2b).
;
; S6 requires `Cond`, `Sel` and `T` in ONE block, in that order. The reason is the
; MINT POINT: this emitter mints the flag at the CONSUMER (not at the select, as
; `SelectMergeEmit` does), so everything between the compare and the consumer is
; inside the flag's staleness window. Bounding that window to one block is what
; makes the positional scan decidable at all; a cross-block window would need the
; position-free wire reasoning gate 2c prong (a) does, over the whole path set.
;
; Over-decline-safe and outside the target shape: `clang -O1` puts the whole
; construct in one block (SimplifyCFG produced the select precisely by merging the
; blocks away).
; ⚠ bd test_C_libtooling-fmt3 (2026-09-28): for `cq_theta` no merge produces the
; select any more (CQ.h `nomerge`); from C it is the user's own `c ? A : B`, which
; `-O1` also keeps in one block.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}rotation angle under quantum control
; 3qlq: migrated from register cq_phi (dead declare erased)

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %u1) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @cq_theta_si32(i32 %u1, double 3.000000e-01)
  %c = icmp eq i32 %q, 5
  %ang = select i1 %c, double 9.000000e-01, double 3.000000e-01
  br label %next
next:
  %t = call i32 @cq_theta_si32(i32 %r, double %ang)
  %m = call i32 @cq_measure_si32(i32 %t)
  ret i32 %m
}
