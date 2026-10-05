; control_swap_reject_abort_inplace_ry_other_register.ll — bd test_C_libtooling-x61g
; DECLINE twin of control_swap_abort_park_inplace_ry.ll: an in-place Ry chain on a
; SECOND register live across the park.
;
; SOURCE (clang -O1, attributes trimmed):
;     int q = u; cq_theta(&q,.5); int r = v; cq_theta(&r,.4); cq_theta(&r,.2);
;     if (q > 5) abort(); cq_theta(&r,.3); return cq_measure(r);
;
; The park routes ONLY Q (`%3`, the compare's tainted operand). The remainder
; reads `%5` (r after its chained pre-park `.2` gate) and `%9` (r after the
; post-park `.3`). Both are names of r's rail, whose wire `%9 -> %5 -> %4` never
; passes through Q, so r is an unparked register: the multi-register park
; (`bd memories abort-exit-park-cascade`) is not built, and the guard stays loud.
; This is the x61g accept's boundary: the guard follows Q's own wire, never "any
; chained theta". `%5` is the discriminator: it is a CHAINED theta whose own gate
; ran before the park, so it is the only name the remainder reads that sits
; ahead of every post-park gate.
; MUTANT this file kills: accepting any live name whose wire has a chained hop
; (`Names.size() > 1`) instead of asking whether Q is on that wire.
; Before x61g this module declined here too (it pins the guard, which had no
; decline fixture of its own).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq controlled lowering: control flow under quantum control

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare void @abort()

define i32 @slice(i32 noundef %0, i32 noundef %1) {
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 5.000000e-01)
  %4 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef 4.000000e-01)
  %5 = tail call i32 @cq_theta_si32(i32 noundef %4, double noundef 2.000000e-01)
  %6 = icmp sgt i32 %3, 5
  br i1 %6, label %7, label %8
7:
  tail call void @abort()
  unreachable
8:
  %9 = tail call i32 @cq_theta_si32(i32 noundef %5, double noundef 3.000000e-01)
  %10 = tail call i32 @cq_measure_si32(i32 noundef %9)
  ret i32 %10
}
