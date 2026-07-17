; lowering_predmux_leave_speccall_loop.ll — DECLINE probe (bd adia): the
; pending-spec pure-callee proof REJECTS a callee whose CFG carries a cycle
; (termination unprovable — a data-bounded loop has no static trip witness).
; E4 leaves the nested region unclaimed and it falls to the existing loud
; nested-control decline, char-for-char.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq controlled lowering: nested control flow under quantum control
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @purefn(i32 %a) {
entry:
  br label %loop
loop:
  %i = phi i32 [ 0, %entry ], [ %i2, %loop ]
  %acc = phi i32 [ %a, %entry ], [ %acc2, %loop ]
  %acc2 = add i32 %acc, 3
  %i2 = add i32 %i, 1
  %d = icmp slt i32 %i2, %a
  br i1 %d, label %loop, label %done
done:
  ret i32 %acc2
}
define i32 @example(i32 %u) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u, double 5.000000e-01)
  %c1 = icmp sgt i32 %q, 5
  br i1 %c1, label %outer, label %merge
outer:
  %c2 = icmp sgt i32 %q, 10
  br i1 %c2, label %inner, label %outmerge
inner:
  %v = call i32 @purefn(i32 %q)
  br label %outmerge
outmerge:
  %p1 = phi i32 [ %v, %inner ], [ %q, %outer ]
  br label %merge
merge:
  %p2 = phi i32 [ %p1, %outmerge ], [ 0, %entry ]
  %m = call i32 @cq_measure_si32(i32 %p2)
  ret i32 %m
}
