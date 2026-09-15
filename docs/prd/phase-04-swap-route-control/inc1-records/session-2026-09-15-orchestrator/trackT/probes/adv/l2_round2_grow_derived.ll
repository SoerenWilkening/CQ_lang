; l2_round2_grow_derived.ll — the SIBLING of `l1_round2_grow_65arm.ll`: the body
; reads a value DERIVED from the 6.5 `%out` rail (`%m2 = mul i32 %m, 2`) rather
; than the rail itself. At round 1 `%m2` is an untainted `mul` of two untainted
; values, so the grant is made; after the fixpoint it is a tainted TEMPLATE rail
; defined outside the loop and read as DATA inside it — neither a root mint nor a
; merge out-rail nor measure-owned, so re-deriving the roots under FINAL taint does
; NOT re-justify the grant and `declineRound2FalsifiedRailGrants` fires.
;
; ⚠ THIS IS THE CORRECT DIRECTION AND NOT A CONSERVATISM: `%m2`'s forward gate is
; in the loop PREHEADER and runs ONCE while a marked body's discharge point runs K
; times, so leaving the grant standing is the multiplicity hazard
; `Uncomputation.cpp:982-1000` names (K adjoints against one forward gate), not a
; leak. It is the same shape `loop_pairing_reject_root_hoisted_template_data.ll`
; refuses at round 1, reached through the round-2 taint delta instead.
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @f(i32 %a) #0 {
  %s = add i32 %a, 100
  ret i32 %s
}

define i32 @slice(i32 %u0, i32 %a) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %y = call i32 @cq_theta_si32(i32 7, double 3.000000e-01)
  %c = icmp sgt i32 %q, 3
  br i1 %c, label %arm, label %merge
arm:
  %r = call i32 @f(i32 %a)
  br label %merge
merge:
  %m = phi i32 [ %r, %arm ], [ 5, %entry ]
  %m2 = mul i32 %m, 2
  br label %loop
loop:
  %k = phi i32 [ 1, %merge ], [ %k2, %loop ]
  %acc = phi i32 [ 0, %merge ], [ %s2, %loop ]
  %sh = lshr i32 %y, %k
  %an = and i32 %sh, %m2
  %ms = call i32 @cq_measure_si32(i32 %an)
  %s2 = add i32 %ms, %acc
  %k2 = add i32 %k, 1
  %e = icmp eq i32 %k2, 3
  br i1 %e, label %out, label %loop
out:
  %y2 = call i32 @cq_theta_si32(i32 %y, double 9.000000e-01)
  %mm = call i32 @cq_measure_si32(i32 %y2)
  %t = add i32 %s2, %mm
  ret i32 %t
}

attributes #0 = { nounwind willreturn memory(none) }
