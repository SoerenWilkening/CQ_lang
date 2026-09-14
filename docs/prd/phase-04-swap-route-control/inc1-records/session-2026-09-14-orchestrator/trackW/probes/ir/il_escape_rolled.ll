; il_escape_rolled.ll — ITERATION-LOCAL rotated base that ESCAPES the loop, with a
; DERIVED condition (so the spine, not the emitter, owns the per-trip discharge).
; This is the program R7-loop clause (c3) exists to refuse; its hand-unrolled twin
; is il_escape_flat.ll.
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %u1) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  br label %loop
loop:
  %i = phi i32 [ 0, %entry ], [ %inext, %merge ]
  %rl = call i32 @cq_theta_si32(i32 %u1, double 2.500000e-01)
  %sh = lshr i32 %q, %i
  %an = and i32 %sh, 1
  %c = icmp eq i32 %an, 1
  br i1 %c, label %arm, label %merge
arm:
  %rt = call i32 @cq_theta_si32(i32 %rl, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi i32 [ %rt, %arm ], [ %rl, %loop ]
  %inext = add i32 %i, 1
  %done = icmp sgt i32 %inext, 1
  br i1 %done, label %exit, label %loop
exit:
  %m = call i32 @cq_measure_si32(i32 %rm)
  ret i32 %m
}
