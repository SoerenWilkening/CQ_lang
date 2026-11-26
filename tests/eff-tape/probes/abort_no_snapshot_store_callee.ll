; Rule 16 (cq-e1ebs): a noreturn arm in a loop (every block of the loop is later than the arm), then a call whose callee
; stores into memory and reads x by value. A store never modifies its value rail in place (ABI qram_store: v is
; unchanged), so x is no snapshot target: no copy_controlled, no kept snapshot rail.
target triple = "x86_64-apple-macosx16.0.0"
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare void @abort() noreturn nounwind

define internal i32 @put(i32 %v, ptr %p) noinline {
  %s = and i32 %v, 7
  store i32 %s, ptr %p
  ret i32 %s
}

define i32 @abort_store_callee(i32 %x0, double %t, i32 %k) {
entry:
  %cell = alloca i32
  %x = call i32 @cq_theta_si32(i32 %x0, double %t)
  br label %loop
loop:
  %i = phi i32 [ 0, %entry ], [ %i1, %ok ]
  %acc = phi i32 [ 0, %entry ], [ %a1, %ok ]
  %xi = add i32 %x, %i
  %f = icmp eq i32 %xi, %k
  br i1 %f, label %die, label %ok
die:
  call void @abort()
  unreachable
ok:
  %r = call i32 @put(i32 %x, ptr %cell)
  %a1 = add i32 %acc, %r
  %i1 = add i32 %i, 1
  %c = icmp ult i32 %i1, 2
  br i1 %c, label %loop, label %done
done:
  %m = call i32 @cq_measure_si32(i32 %a1)
  ret i32 %m
}
; CHECK abort_store_callee: call void @cqrt_abort_i1(i32 %{{f}})
; CHECK-COUNT abort_store_callee: cqrt_copy_i32_controlled 0
