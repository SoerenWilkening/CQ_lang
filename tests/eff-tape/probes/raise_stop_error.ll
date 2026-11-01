; Rule 16: raise of a stop signal (SIGSTOP) with no handler: its default action is neither terminate nor ignore.
; EXPECT-ERROR: cq: unimplemented: eff-tape: raise of a signal with no handler whose default action
target triple = "x86_64-apple-macosx16.0.0"
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i32 @raise(i32)
declare ptr @signal(i32, ptr)

define i32 @raise_s(i32 %x0, double %t, i32 %k) {
entry:
  %x = call i32 @cq_theta_si32(i32 %x0, double %t)
  %f = icmp sgt i32 %x, %k
  br i1 %f, label %then, label %done
then:
  %r = call i32 @raise(i32 17)
  br label %done
done:
  %m = call i32 @cq_measure_si32(i32 %x)
  ret i32 %m
}
