; dm7f.16.1 R11 round 3: calling convention mismatches cause immediate UB.
; The outer call matches, but its exact pure callee contains a mismatched
; inner call. On an untaken arm that call never executes in the source.
; The totality contract must apply transitively before any speculation.
; Fixing this gap for such calls needs a lowering that respects the source ABI;
; it is not a physics prohibition.
; RUN: not %cq-opt -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: cq controlled lowering: control flow under quantum control

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define fastcc i32 @leaf(i32 %x) noinline {
  ret i32 %x
}
define i32 @outer(i32 %x) noinline {
  %v = call i32 @leaf(i32 %x)
  ret i32 %v
}
define i32 @probe(i32 %seed, i32 noundef %n) {
entry:
  %q = call i32 @cq_theta_si32(i32 %seed, double 0.5)
  %qc = icmp sgt i32 %q, 0
  br i1 %qc, label %inner, label %merge
inner:
  %cc = icmp sgt i32 %n, 0
  br i1 %cc, label %arm, label %merge
arm:
  %v = call i32 @outer(i32 %n)
  %r = add i32 %q, %v
  br label %merge
merge:
  %out = phi i32 [ %r, %arm ], [ %q, %inner ], [ 5, %entry ]
  %m = call i32 @cq_measure_si32(i32 %out)
  ret i32 %m
}
