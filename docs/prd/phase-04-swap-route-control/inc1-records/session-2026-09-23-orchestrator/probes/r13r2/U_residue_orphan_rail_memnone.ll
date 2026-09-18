; The rail's ONLY surviving use after the flatten is an `and i1 %rail, false`
; residue.  simplifyFlattenResiduesInFunction folds it and calls
; RecursivelyDeleteTriviallyDeadInstructions on the cone -- a SECOND eraser in
; this file, which FIX A does not guard.
declare i1 @cq_theta_i1(i1, double) memory(none) nounwind willreturn
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @probe(i32 %u) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u, double 5.000000e-01)
  %rail = call i1 @cq_theta_i1(i1 false, double 5.000000e-01)
  %dead = and i1 %rail, false
  br i1 %rail, label %arm, label %merge
arm:
  br label %merge
merge:
  %p1 = phi i1 [ false, %arm ], [ false, %entry ]
  %p2 = phi i1 [ %dead, %arm ], [ false, %entry ]
  %z1 = zext i1 %p1 to i32
  %z2 = zext i1 %p2 to i32
  %m  = call i32 @cq_measure_si32(i32 %q)
  %s  = add i32 %z1, %z2
  %s2 = add i32 %s, %m
  ret i32 %s2
}
