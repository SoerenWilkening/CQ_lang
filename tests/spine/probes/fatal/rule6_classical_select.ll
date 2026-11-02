; cq-5nj9: a select on a classical condition (a classical choice over handles, rule 9) of two bijective
; updates of a dead x (x + 1, 3x): x is dead on each path after the chosen update and is cleaned from it
; there, under a classical branch at the clean-up point; not built: an internal error, never a kept dead
; old value (the shape classical_choice.ll's sel_handles had before it measured x).
; FATAL: rule 6 on a classical merge of a bijective update of a dead register
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
