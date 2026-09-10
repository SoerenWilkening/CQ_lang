; r11 — AREA 2/report hygiene: TWO independent rails, each with its own round-2
; sibling. `reverifyRailCondReads` keeps a `Diagnosed` set and keeps looping, but
; `diagnoseUnderControl` is `DS_Error` and neither entry point installs a
; diagnostic handler, so LLVMContext's default handler `exit(1)`s on the FIRST
; one. Expectation: exactly ONE diagnostic line, i.e. the per-rail dedup and the
; loop continuation below it are VACUOUS.
declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)
define i32 @f(i32 %a) #0 { %s = add i32 %a, 100  ret i32 %s }
define i32 @main() {
entry:
  %q = call i32 @cq_theta_si32(i32 0, double 5.000000e-01)
  %c0 = icmp sgt i32 %q, 3
  br i1 %c0, label %arm, label %merge
arm:
  %r = call i32 @f(i32 4)
  br label %merge
merge:
  %y = phi i32 [ %r, %arm ], [ 5, %entry ]
  %keep = call i32 @cq_measure_si32(i32 %y)
  br label %second
second:
  %x = trunc i32 %y to i1
  %x2 = icmp sgt i32 %y, 2
  %b = call i1 @cq_theta_i1(i1 %x, double 5.000000e-01)
  %b3 = call i1 @cq_theta_i1(i1 %x, double 9.000000e-01)
  %d = call i1 @cq_theta_i1(i1 %x2, double 3.000000e-01)
  %d3 = call i1 @cq_theta_i1(i1 %x2, double 7.000000e-01)
  %a1 = select i1 %b, i32 2, i32 5
  %a2 = select i1 %d, i32 11, i32 13
  %m1 = call i32 @cq_measure_si32(i32 %a1)
  %m2 = call i32 @cq_measure_si32(i32 %a2)
  %mm = call i1 @cq_measure_i1(i1 %b3)
  %nn = call i1 @cq_measure_i1(i1 %d3)
  %z1 = zext i1 %mm to i32
  %z2 = zext i1 %nn to i32
  %t = add i32 %m1, %m2
  %u = add i32 %t, %z1
  %v = add i32 %u, %z2
  %w = add i32 %v, %keep
  ret i32 %w
}
attributes #0 = { nounwind willreturn memory(none) }
