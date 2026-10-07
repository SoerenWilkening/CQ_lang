declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @arm_scramble(i32 noundef %k) #0 {
entry:
  %r = xor i32 %k, 90
  ret i32 %r
}

define i32 @finish_value(i32 noundef %v) {
entry:
  %scaled = mul i32 %v, 5
  %r = add i32 %scaled, 2
  ret i32 %r
}

define i32 @new_helper(i32 noundef %v) {
entry:
  %lo = icmp sgt i32 %v, -11
  %hi = icmp ult i32 %v, 37
  %cond = and i1 %lo, %hi
  %flip = xor i32 %v, 255
  %picked = select i1 %cond, i32 %flip, i32 %v
  %r = call i32 @finish_value(i32 %picked)
  ret i32 %r
}

define void @exercise_new(i32 noundef %seed, i32 noundef %k) {
entry:
  %q = call i32 @cq_theta_si32(i32 %seed, double 0.375)
  %guard = icmp sgt i32 %q, 7
  br i1 %guard, label %arm, label %merge
arm:
  %scrambled = call i32 @arm_scramble(i32 %k)
  br label %merge
merge:
  %choice = phi i32 [ %scrambled, %arm ], [ 17, %entry ]
  %r = call i32 @new_helper(i32 %choice)
  %m = call i32 @cq_measure_si32(i32 %r)
  ret void
}

attributes #0 = { nounwind willreturn memory(none) }
