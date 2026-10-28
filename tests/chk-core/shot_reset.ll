; Per-sample reset test (cq-e2i9): every mode but 0 leaves state behind that the next sample must not see.
; mode 0: clean; returns measure(x) + fegetround(), x seeded with the global counter (1 when fresh)
; mode 1: a dirty free (a rotated rail freed) and a rail left live
; mode 2: SIGFPE mid-sample (raise), after an alloc
; mode 3: a bad handle
; mode 4: _exit(7) mid-sample: no exit event
; mode 5: the rounding mode left upward, a rail left live, the counter bumped again
target triple = "x86_64-apple-macosx16.0.0"
@g = global i32 0
define i32 @sr(i32 %mode, double %th) {
entry:
  %c = load i32, ptr @g
  %c1 = add i32 %c, 1
  store i32 %c1, ptr @g
  %x = call i32 @cqrt_alloc_i32(i32 %c1)
  switch i32 %mode, label %clean [i32 1, label %dirty
                                  i32 2, label %crash
                                  i32 3, label %bad
                                  i32 4, label %quit
                                  i32 5, label %fenv]
clean:
  call void @cqrt_ry_i32(i32 %x, double %th)
  %m = call i32 @cqrt_measure_i32(i32 %x)
  %s = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_free(i32 %s)
  %rm = call i32 @fegetround()
  %r = add i32 %m, %rm
  ret i32 %r
dirty:
  %y = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_ry_i32(i32 %y, double %th)
  call void @cqrt_free(i32 %y)
  ret i32 0
crash:
  %z = call i32 @cqrt_alloc_i32(i32 3)
  %e = call i32 @raise(i32 8)
  ret i32 %e
bad:
  call void @cqrt_free(i32 12345)
  ret i32 0
quit:
  %q = call i32 @cqrt_alloc_i32(i32 4)
  call void @_exit(i32 7)
  unreachable
fenv:
  %f = call i32 @fesetround(i32 2048)
  %c2 = add i32 %c1, 1
  store i32 %c2, ptr @g
  ret i32 %f
}
declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_ry_i32(i32, double)
declare void @cqrt_free(i32)
declare i32 @cqrt_measure_i32(i32)
declare i32 @fegetround()
declare i32 @fesetround(i32)
declare i32 @raise(i32)
declare void @_exit(i32)
