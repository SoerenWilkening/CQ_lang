; cq-5nj9: a select on a classical condition (a classical choice over handles, rule 9) of two bijective
; updates of a dead x (x + 1, 3x): x is dead on each path after the chosen update and is cleaned from it
; there, under a classical branch at the clean-up point (cq-mgkr, ruling cq-mzqo). Both images are garbage
; read only through the merge, so the clean-up is the composite through s + 5 (127): t = (s+5) - 5, then each
; path's arm inverse; x + 1 and 3x are undone first, and s + 5 is the one kept rail.
; USERCHECK sel_handles
; CHECK-COUNT sel_handles: call void @cqrt_copy_i32( 2
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @sel_handles(i32 %x0, double %t, i1 %c) {
  %x = call i32 @cq_theta_si32(i32 %x0, double %t)
  %a = add i32 %x, 1
  %b = mul i32 %x, 3
  %s = select i1 %c, i32 %a, i32 %b
  %u = add i32 %s, 5
  %r = call i32 @cq_measure_si32(i32 %u)
  ret i32 %r
}
