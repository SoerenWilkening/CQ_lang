; control_inplace_ry_reject_stale_diag_alias_pure.ll — DECLINE: a PURE op reads a
; DIAGONAL ALIAS of the rotated register after the region (bd
; test_C_libtooling-drbq Inc 1, finding J; the pure-op corner of R6's alias
; closure).
;
;     int mark = cq_phi(r, .1);
;     if (q > 5) r = cq_theta(r, .9);
;     p = mark * 7;                     // `mark` and `r` are ONE physical rail
;
; Committed for the same reason `control_inplace_ry_reject_stale_pure.ll` is, and
; the reason is COVERAGE OWNERSHIP, not a second R6 assertion: this module
; declines on the PASS-WIDE `declineStaleRecordOps` (`cq opcode lowering: operand
; predates a non-diagonal gate`), which runs at `CQLoweringPass.cpp` line ~282,
; BEFORE `detectControlRegions` at ~322, and already owns tainted PURE producers
; scheduled past a non-diagonal wire gate — including ones reached through a
; diagonal alias. R6 never sees it. Measured, before AND after finding J's fix.
;
; The fixture's job is to record which guard owns which consumer kind. R6's alias
; closure covers this shape structurally as defence in depth; if a future change
; narrows `declineStaleRecordOps`, this module becomes an R6 case and THIS file is
; where that shows up.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}operand predates a non-diagonal gate
; CHECK-NOT: cqrt_ry_i32_controlled

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %u1) {
entry:
  %q    = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r    = call i32 @cq_theta_si32(i32 %u1, double 3.000000e-01)
  %mark = call i32 @cq_phi_si32(i32 %r, double 1.000000e-01)
  %c    = icmp sgt i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %rt = call i32 @cq_theta_si32(i32 %r, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi i32 [ %rt, %arm ], [ %r, %entry ]
  %p  = mul i32 %mark, 7
  %a  = call i32 @cq_measure_si32(i32 %p)
  %b  = call i32 @cq_measure_si32(i32 %rm)
  %s  = add i32 %a, %b
  ret i32 %s
}
