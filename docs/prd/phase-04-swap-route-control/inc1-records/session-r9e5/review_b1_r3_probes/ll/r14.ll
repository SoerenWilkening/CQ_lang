; r14 — AREA 1/7: a NEGATED RAIL LEAF inside a condition tree. `emitCondNode`'s
; `bracket()` fires `cqrt_x` on `N.L`/`N.R` when the child is negated, and
; `bracket` is NOT covered by the fix's `record` lambda (only `stamp` is) — but
; more basically, 1b's stated invariant is "NO `cqrt_x` on a user register, EVER"
; (`emitKickbackGroup` uses the diagonal `rz(-θ)` instead) and the 4.3 nest
; DECLINES a negated rail LEVEL explicitly (ArmClassify :4670). This asks the
; same question one level down, for a negated rail LEAF of an `and` tree.
declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)
define i32 @main() {
entry:
  %q = call i32 @cq_theta_si32(i32 0, double 5.000000e-01)
  %b = call i1 @cq_theta_i1(i1 false, double 2.500000e-01)
  %nb = xor i1 %b, true
  %c = icmp sgt i32 %q, 3
  %a = and i1 %nb, %c
  br i1 %a, label %then, label %join
then:
  call void @cq_phi(double 7.000000e-01)
  br label %join
join:
  %m = call i1 @cq_measure_i1(i1 %b)
  %z = zext i1 %m to i32
  %n = call i32 @cq_measure_si32(i32 %q)
  %t = add i32 %z, %n
  ret i32 %t
}
