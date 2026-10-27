; cq-bym: the only CQ.h call is cq_phi. Owner ruling 2 on cq-arch: cq_phi alone does not take the
; early exit (rule 12 deletes it), so cq-lower runs its pipeline on this module.
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx"

declare void @cq_phi(double)

define i32 @f(i32 %x) {
entry:
  call void @cq_phi(double 0x3FE921FB54442D18)
  %a = add i32 %x, 1
  ret i32 %a
}
