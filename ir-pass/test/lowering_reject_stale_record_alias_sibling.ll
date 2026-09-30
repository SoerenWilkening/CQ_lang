; lowering_reject_stale_record_alias_sibling.ll — a pre-theta SSA record is
; consumed by arithmetic after an in-place theta on the same wire (bd 6j1).
;
; The add reads %q, while %q2 has already rotated %q's physical register.
; Lowering both names to the same handle would make the add read the later
; state. This pins the loud fence until that earlier record can be preserved.
; The retired diagonal alias hops no longer occur in this input.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; 3qlq: migrated from register cq_phi (uncontrolled -> deleted (D2))
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, double %g, double %t2) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double %g)
  %q2 = call i32 @cq_theta_si32(i32 %q, double %t2)        ; chained Ry via the SIBLING name
  %d = add i32 %q, 3                                      ; SSA denotes the PRE-Ry record
  %m = call i32 @cq_measure_si32(i32 %d)
  ret i32 %m
}

; CHECK: error{{.*}}cq opcode lowering: operand predates a non-diagonal gate
