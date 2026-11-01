; cq-3fjt: a sample that logs a violation (v) or prints a byte (p) per trip, n trips: the disk caps
target triple = "x86_64-apple-macosx16.0.0"
define i32 @v(i32 %n, double %th) {
entry:
  br label %loop
loop:
  %i = phi i32 [ 0, %entry ], [ %i1, %loop ]
  call void @cqrt_free(i32 12345)
  %i1 = add i32 %i, 1
  %c = icmp slt i32 %i1, %n
  br i1 %c, label %loop, label %done
done:
  ret i32 %n
}
define i32 @p(i32 %n, double %th) {
entry:
  br label %loop
loop:
  %i = phi i32 [ 0, %entry ], [ %i1, %loop ]
  %r = call i32 @putchar(i32 120)
  %i1 = add i32 %i, 1
  %c = icmp slt i32 %i1, %n
  br i1 %c, label %loop, label %done
done:
  ret i32 %n
}
declare void @cqrt_free(i32)
declare i32 @putchar(i32)
