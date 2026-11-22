; USERCHECK f
; cq-w5aet (CR rule 14 case 3 with rules 8, 9): an inner loop whose classical exit test, a switch at its header, leaves
; by two exit blocks (the outer loop's header and the return) besides a quantum exit at its latch into the outer header.
; fix-irreducible's unifySubLoopExits makes the hub cq.exits; each classical exit edge runs the exit arm in a segment of
; its own, and the join after them takes each edge's exit value (cq.which). Reduced from TinyEMU main's getopt loop
; (the outer loop given a bound, the quantum test a shifted register so that every input ends). Before:
; only the switch's last arm exit was walked, and !%cq.which was read where it was not minted (pred's joinAbove).
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

declare i8 @cq_theta_ui8(i8, double)

define i32 @f(i8 %n, i8 %qin) {
  %q = call i8 @cq_theta_ui8(i8 %qin, double 1.0)
  br label %outer

outer:
  %c = phi i8 [ 0, %0 ], [ %c1, %inner ], [ %c1, %body ]
  %c1 = add i8 %c, 1
  %done = icmp ugt i8 %c1, 5
  br i1 %done, label %fin, label %inner

inner:
  %qs = phi i8 [ %q, %outer ], [ %qs1, %body ]
  switch i8 %n, label %ret [
    i8 1, label %outer
    i8 0, label %body
    i8 -1, label %body
  ]

body:
  %b = and i8 %qs, 1
  %cond = icmp eq i8 %b, 0
  %sh = lshr i8 %qs, 1
  %qs1 = or i8 %sh, -128
  br i1 %cond, label %inner, label %outer

ret:
  ret i32 0

fin:
  %r = zext i8 %c1 to i32
  ret i32 %r
}
