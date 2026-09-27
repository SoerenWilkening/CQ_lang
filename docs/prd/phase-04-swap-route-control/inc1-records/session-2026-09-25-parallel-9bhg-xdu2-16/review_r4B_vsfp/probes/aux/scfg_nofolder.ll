define i1 @f(i32 %q) {
entry:
  %c = icmp sgt i32 %q, 3
  br i1 %c, label %a, label %s
a:
  br label %s
s:
  %p = phi i1 [ true, %a ], [ false, %entry ]
  ret i1 %p
}
