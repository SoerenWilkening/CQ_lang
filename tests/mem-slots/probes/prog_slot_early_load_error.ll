; 102 (program slot): a load of the slot after the guarded clone call but before the predicate's quantum
; source is measured: rule 2's collapse does not apply there (not built: the rail would stay the slot's).
; EXPECT-ERROR: a guarded clone store wrote while its predicate is not classical at the load
target triple = "x86_64-apple-macosx16.0.0"
@hit = internal global i32 0, align 4
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i32 @raise(i32)
declare ptr @signal(i32, ptr)

define internal void @h(i32 %s) {
  store volatile i32 %s, ptr @hit, align 4
  ret void
}

define i32 @raise_h(i32 %x0, double %t, i32 %k) {
entry:
  %x = call i32 @cq_theta_si32(i32 %x0, double %t)
  %old = call ptr @signal(i32 30, ptr @h)
  %f = icmp sgt i32 %x, %k
  br i1 %f, label %then, label %done
then:
  %r = call i32 @raise(i32 30)
  br label %done
done:
  %hv = load volatile i32, ptr @hit, align 4
  %hm = call i32 @cq_measure_si32(i32 %hv)
  %m = call i32 @cq_measure_si32(i32 %x)
  %s = add nsw i32 %hm, %m
  ret i32 %s
}
