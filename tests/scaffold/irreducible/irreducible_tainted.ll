; cq-5k5: an irreducible loop whose entry is chosen by a quantum value, next to an irreducible
; loop that is purely classical. `tainted` must be made reducible (its irr.guard phi merges a
; quantum branch decision) and the taint over the final CFG must be a fresh computeTaint;
; `classical` carries no taint and must never be rewritten (NORTHSTAR principle 1).
; Hand-written: the two-entry cycle a/b is the shape FixIrreduciblePass rewrites.
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx"

declare i32 @cq_theta_si32(i32 noundef, double noundef)

define i32 @tainted(i32 %x0, double %th, i32 %n) {
entry:
  %x = tail call i32 @cq_theta_si32(i32 noundef %x0, double noundef %th)
  %c = icmp slt i32 %x, 0
  br i1 %c, label %a, label %b

a:
  %ia = phi i32 [ 0, %entry ], [ %ib.next, %b ]
  %ia.next = add i32 %ia, 1
  %ca = icmp slt i32 %ia.next, %n
  br i1 %ca, label %b, label %exit

b:
  %ib = phi i32 [ 0, %entry ], [ %ia.next, %a ]
  %ib.next = add i32 %ib, 2
  %cb = icmp slt i32 %ib.next, %n
  br i1 %cb, label %a, label %exit

exit:
  %r = phi i32 [ %ia.next, %a ], [ %ib.next, %b ]
  ret i32 %r
}

define i32 @classical(i32 %y, i32 %n) {
entry:
  %c = icmp slt i32 %y, 0
  br i1 %c, label %a, label %b

a:
  %ia = phi i32 [ 0, %entry ], [ %ib.next, %b ]
  %ia.next = add i32 %ia, 1
  %ca = icmp slt i32 %ia.next, %n
  br i1 %ca, label %b, label %exit

b:
  %ib = phi i32 [ 0, %entry ], [ %ia.next, %a ]
  %ib.next = add i32 %ib, 2
  %cb = icmp slt i32 %ib.next, %n
  br i1 %cb, label %a, label %exit

exit:
  %r = phi i32 [ %ia.next, %a ], [ %ib.next, %b ]
  ret i32 %r
}
