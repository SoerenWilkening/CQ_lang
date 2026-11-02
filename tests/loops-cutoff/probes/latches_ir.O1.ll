; tests/loops-cutoff latch probes in IR (cq-b58q, CR rule 14 "`continue` ... same chain"): K-loops with two latches,
; the form -O1 leaves when SimplifyCFG folds the latch merge away. Hand-written; each entry is checked §6 against
; itself as the C program (cqcheck user).
source_filename = "latches_ir.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Both latches exit (the multi-exit form), the exit values joined by a phi.
define i32 @ml2_both(i32 noundef %x0, double noundef %th) #0 {
entry:
  %x = tail call i32 @cq_theta_si32(i32 noundef %x0, double noundef %th) #2
  br label %head
head:
  %acc = phi i32 [ 1, %entry ], [ %a1, %cont ], [ %a2, %fall ]
  %i = phi i32 [ 0, %entry ], [ %i1, %cont ], [ %i1, %fall ]
  %i1 = add nuw nsw i32 %i, 1
  %m = shl nuw i32 16, %i
  %b = and i32 %m, %x
  %z = icmp eq i32 %b, 0
  br i1 %z, label %fall, label %cont
cont:
  %t = mul nsw i32 %acc, 5
  %a1 = add nsw i32 %t, 1
  %s = and i32 %a1, 64
  %sz = icmp eq i32 %s, 0
  br i1 %sz, label %head, label %out
fall:
  %u = mul nsw i32 %acc, 3
  %a2 = add nsw i32 %i1, %u
  %m2 = shl nuw i32 2, %i
  %b2 = and i32 %m2, %x
  %z2 = icmp eq i32 %b2, 0
  br i1 %z2, label %out, label %head
out:
  %r = phi i32 [ %a1, %cont ], [ %a2, %fall ]
  %res = tail call i32 @cq_measure_si32(i32 noundef %r) #3
  ret i32 %res
}

; A `continue` latch that never exits and one exiting latch (the body form), a phase on the `continue` arm.
define i32 @ml2_one(i32 noundef %x0, double noundef %th) #0 {
entry:
  %x = tail call i32 @cq_theta_si32(i32 noundef %x0, double noundef %th) #2
  br label %head
head:
  %acc = phi i32 [ 1, %entry ], [ %a1, %cont ], [ %a2, %fall ]
  %i = phi i32 [ 0, %entry ], [ %i1, %cont ], [ %i1, %fall ]
  %i1 = add nuw nsw i32 %i, 1
  %m = shl nuw i32 16, %i
  %b = and i32 %m, %x
  %z = icmp eq i32 %b, 0
  br i1 %z, label %fall, label %cont
cont:
  %t = mul nsw i32 %acc, 5
  %a1 = add nsw i32 %t, 1
  tail call void @cq_phi(double noundef 2.500000e-01) #3
  br label %head
fall:
  %u = mul nsw i32 %acc, 3
  %a2 = add nsw i32 %i1, %u
  %m2 = shl nuw i32 2, %i
  %b2 = and i32 %m2, %x
  %z2 = icmp eq i32 %b2, 0
  br i1 %z2, label %out, label %head
out:
  %res = tail call i32 @cq_measure_si32(i32 noundef %a2) #3
  ret i32 %res
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) #1
declare i32 @cq_measure_si32(i32 noundef) #1
declare void @cq_phi(double noundef) #1

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "no-trapping-math"="true" "target-cpu"="penryn" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "target-cpu"="penryn" }
attributes #2 = { nomerge nounwind }
attributes #3 = { nounwind }
