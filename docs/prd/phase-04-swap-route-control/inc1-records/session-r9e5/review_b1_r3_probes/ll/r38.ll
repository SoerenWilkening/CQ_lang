; r38 — AREA 6 SCOPE WITNESS (bd `9pum`, NOT this round's to fix): a MIXED tree
; `b && (y > 2)` whose RAIL leaf is clean and whose COMPARE leaf sits in the
; round-2 window — a chained theta on `%y`'s own wire before the compare. The
; classifier asks the rail ladder over ONE `Prov` (the union of both leaves'
; provenance); `reverifyRailCondReads` seeds `{Rail}` alone, so the compare
; leaf's wire is NOT re-verified. Expected: ACCEPT on both binaries, with the
; flag minted from the post-`.3` register while `%y` names the pre-`.3` one.
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
  %b = call i1 @cq_theta_i1(i1 %x, double 5.000000e-01)
  %g = call i32 @cq_theta_si32(i32 %y, double 3.000000e-01)
  %cmp = icmp sgt i32 %y, 2
  %a = and i1 %b, %cmp
  br i1 %a, label %then, label %join
then:
  call void @cq_phi(double 7.000000e-01)
  br label %join
join:
  %mg = call i32 @cq_measure_si32(i32 %g)
  %t = add i32 %mg, %keep
  ret i32 %t
}
attributes #0 = { nounwind willreturn memory(none) }
