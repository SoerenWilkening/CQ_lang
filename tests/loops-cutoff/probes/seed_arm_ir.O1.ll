; tests/loops-cutoff probe (CR rules 5, 9, 14): musl mbsrtowcs' head. A classically bounded loop with a quantum exit under a quantum predicate whose atom is
; minted in one classical arm above a join; the other arm's edge carries a don't-care seed of the flag, and a repeated classical test at
; the join excludes that arm from the loop. The seed exists on the excluded arm only, so the loop's reverse must not free it. Written as
; IR: clang -O1 threads the repeated test away.
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

declare i32 @cq_theta_si32(i32 noundef, double noundef)
declare i32 @cq_measure_si32(i32 noundef)

define i32 @sa_scan(i32 noundef %x0, i64 noundef %w, i64 noundef %n, double noundef %th) {
entry:
  %x = call i32 @cq_theta_si32(i32 noundef %x0, double noundef %th)
  %c = icmp eq i64 %w, 0
  br i1 %c, label %b, label %j

b:
  %a2 = and i32 %x, 2
  %q = icmp eq i32 %a2, 0
  br i1 %q, label %end, label %j

j:
  br i1 %c, label %ph, label %end

ph:
  %g = icmp sgt i64 %n, 0
  br i1 %g, label %l, label %end

l:
  %i = phi i64 [ 0, %ph ], [ %i1, %t ]
  %s = phi i32 [ 0, %ph ], [ %s1, %t ]
  %sh = trunc i64 %i to i32
  %m = and i32 %sh, 7
  %y = lshr i32 %x, %m
  %b1 = and i32 %y, 1
  %q2 = icmp eq i32 %b1, 0
  br i1 %q2, label %t, label %end

t:
  %s1 = add i32 %s, 2
  %i1 = add i64 %i, 1
  %e = icmp eq i64 %i1, %n
  br i1 %e, label %end, label %l

end:
  %r = phi i32 [ 5, %b ], [ 6, %j ], [ 7, %ph ], [ %s, %l ], [ %s1, %t ]
  %o = call i32 @cq_measure_si32(i32 noundef %r)
  ret i32 %o
}
