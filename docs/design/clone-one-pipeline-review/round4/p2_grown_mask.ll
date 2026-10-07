declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @arm_bias(i32 noundef %k) #0 {
entry:
  %r = add i32 %k, 9
  ret i32 %r
}

define i32 @finish_pair(i32 noundef %v) {
entry:
  %r = xor i32 %v, 682
  ret i32 %r
}

define i32 @growing_helper(i32 noundef %a, i32 noundef %b) {
entry:
  %lo = icmp slt i32 %a, 64
  %hi = icmp ult i32 %b, 11
  %cond = and i1 %lo, %hi
  %mix = xor i32 %a, %b
  %picked = select i1 %cond, i32 %mix, i32 %b
  %r = call i32 @finish_pair(i32 %picked)
  ret i32 %r
}

define void @exercise_growth(i32 noundef %seed, i32 noundef %other, i32 noundef %k) {
entry:
  %q = call i32 @cq_theta_si32(i32 %seed, double 0.125)
  %second = call i32 @cq_theta_si32(i32 %other, double 0.75)
  %guard = icmp sgt i32 %q, 13
  br i1 %guard, label %arm, label %merge
arm:
  %biased = call i32 @arm_bias(i32 %k)
  br label %merge
merge:
  %choice = phi i32 [ %biased, %arm ], [ -4, %entry ]
  %r = call i32 @growing_helper(i32 %choice, i32 %second)
  %m = call i32 @cq_measure_si32(i32 %r)
  ret void
}

attributes #0 = { nounwind willreturn memory(none) }
