; control_inplace_ry_reject_stale_diag_alias_pure.ll — ACCEPT since bd test_C_libtooling-57ch.1 and 57ch.3 (batch 053;
; owner ruling bd 57ch (A)). ⚠ VERDICT INVERTED: this file declined before batch 053.
;
; The stale pure op is PLACED before its staling gate (StaleReadPlacement.h): its
; template copies the pre-gate label, the stream the read-first program lowers to
; (twin: lowering_stale_record_add_before_theta.ll, the same CHECK chain).
; Same as control_inplace_ry_reject_stale_pure.ll (the alias closure has no
; subject since 3qlq): the slot precedes the tainted region.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll 2> %t.err
; RUN: %filecheck %s < %t.ll
; RUN: %filecheck --check-prefix=WARN --allow-empty %s < %t.err
; WARN-NOT: {{error|warning}}
;
; CHECK:      call void @cqrt_ry_i32(i32 %[[R:[a-z0-9]+]], double 3.000000e-01)
; CHECK-NEXT: %[[P:[a-z_0-9]+]] = call i32 @cq_template_mul_i32_hl(i32 %[[R]], i32 7)
; CHECK-NEXT: %[[F:[a-z_0-9]+]] = call i32 @cq_template_icmp_sgt_i32_hl(
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %[[F]], i32 %[[R]], double 9.000000e-01)
; CHECK:      call i32 @cqrt_measure_i32(i32 %[[P]])
;
; ── HISTORY: the pre-batch-053 header, kept verbatim (its verdict text is
; superseded by the block above) ──
; control_inplace_ry_reject_stale_diag_alias_pure.ll — DECLINE: a PURE op reads
; the PRE-region record of the rotated register after the region (bd
; test_C_libtooling-drbq Inc 1, finding J; the pure-op corner of R6's alias
; closure).
;
;     int mark = r;                     // pre-3qlq: cq_phi(r, .1), a diagonal alias
;     if (q > 5) cq_theta(&r, .9);
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
; 3qlq: migrated from register cq_phi (uncontrolled -> deleted (D2))

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %u1) {
entry:
  %q    = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r    = call i32 @cq_theta_si32(i32 %u1, double 3.000000e-01)
  %c    = icmp sgt i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %rt = call i32 @cq_theta_si32(i32 %r, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi i32 [ %rt, %arm ], [ %r, %entry ]
  %p  = mul i32 %r, 7
  %a  = call i32 @cq_measure_si32(i32 %p)
  %b  = call i32 @cq_measure_si32(i32 %rm)
  %s  = add i32 %a, %b
  ret i32 %s
}
