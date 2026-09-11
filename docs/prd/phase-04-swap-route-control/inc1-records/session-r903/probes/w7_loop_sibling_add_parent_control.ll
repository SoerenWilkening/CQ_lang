; HAND IR (r903 probe w7) — the DISCRIMINATOR for w6: the identical module with
; the in-place parent spelled `add %q, -9` (what `clang -O1` actually emits for
; `q - 9`). `collectWireValues` DOES cross Add, so the sibling is on the wire.
declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @main() {
entry:
  %q0 = call i32 @cq_theta_si32(i32 0, double 5.000000e-01)
  br label %loop

loop:
  %q = phi i32 [ %q0, %entry ], [ %a, %body ]
  %acc = phi i32 [ 0, %entry ], [ %acc1, %body ]
  %i = phi i32 [ 0, %entry ], [ %i1, %body ]
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %arm, label %body

arm:
  call void @cq_phi(double 3.000000e-01)
  br label %body

body:
  %t = add i32 %q, -9
  %a = call i32 @cq_theta_si32(i32 %t, double 1.000000e-01)
  %z = call i32 @cq_theta_si32(i32 %t, double 9.000000e-01)
  %mz = call i32 @cq_measure_si32(i32 %z)
  %acc1 = add nsw i32 %acc, %mz
  %i1 = add nuw nsw i32 %i, 1
  %done = icmp eq i32 %i1, 3
  br i1 %done, label %exit, label %loop

exit:
  %mq = call i32 @cq_measure_si32(i32 %a)
  %r = add nsw i32 %acc1, %mq
  ret i32 %r
}
