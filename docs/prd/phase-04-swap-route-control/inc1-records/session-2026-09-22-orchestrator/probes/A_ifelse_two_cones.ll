@k = global i32 0
@j = global i32 0
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %v0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %p = call i32 @cq_theta_si32(i32 %v0, double 2.500000e-01)
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %armT, label %armF
armT:
  %a1 = load i32, ptr @k, align 4
  %a2 = mul i32 %a1, 3
  %t1 = add i32 %p, %a2
  br label %merge
armF:
  %b1 = load i32, ptr @j, align 4
  %b2 = xor i32 %b1, 9
  %f1 = add i32 %p, %b2
  br label %merge
merge:
  %pm = phi i32 [ %t1, %armT ], [ %f1, %armF ]
  %m  = call i32 @cq_measure_si32(i32 %pm)
  ret i32 %m
}
