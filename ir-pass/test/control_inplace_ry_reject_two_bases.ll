; control_inplace_ry_reject_two_bases.ll — DECLINE. R3's "ONE base" clause, which
; PRD §4 names explicitly and which had NO fixture until the round-1 Rule-13
; review found it reachable and unpinned (lens L6 §4).
;
;     if (q > 5) cq_theta(&r, .9);
;     else       cq_theta(&p, .2);   /* a DIFFERENT register in the else arm */
;
; An if/else anchors the routed base on the first arm and R3 requires the second
; to match by SSA identity (`Routed && RotBase != Routed`). Two arms rotating two
; DIFFERENT registers is a cross-handle MULTIPLEXER, not a rotation arm: the
; merge φ would have to select between two live rails, which the in-place recipe
; has no mechanism for (it RAUWs the φ to the ONE base register). Emitting it
; anyway would rewire every downstream consumer to whichever rail happened to be
; anchored first — a verify-clean wrong register.
;
; WHY THE TWO `mixed_ifelse` FIXTURES DO NOT COVER THIS: both of them rotate the
; SAME `%r` in both arms and decline on the MIXTURE (`mixed phase/value arm`), so
; nothing in the family exercised the base-mismatch clause.
;
; The string is the SHARED generic `control flow` (99 sites), so what this
; asserts is non-acceptance plus the absence of any emitted controlled gate; the
; clause that fires is identified here rather than by the message.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s
; CHECK: error{{.*}}control flow under quantum control
; CHECK-NOT: cqrt_ry_i32_controlled

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %u1, i32 %u2) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @cq_theta_si32(i32 %u1, double 2.500000e-01)
  %p = call i32 @cq_theta_si32(i32 %u2, double 1.500000e-01)
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %armt, label %armf
armt:
  %rt = call i32 @cq_theta_si32(i32 %r, double 9.000000e-01)
  br label %merge
armf:
  %rf = call i32 @cq_theta_si32(i32 %p, double 2.000000e-01)
  br label %merge
merge:
  %rm = phi i32 [ %rt, %armt ], [ %rf, %armf ]
  %m  = call i32 @cq_measure_si32(i32 %rm)
  ret i32 %m
}
