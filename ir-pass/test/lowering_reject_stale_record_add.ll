; lowering_reject_stale_record_add.ll — ACCEPT since bd test_C_libtooling-57ch.3 (batch 053;
; owner ruling bd 57ch (A)). ⚠ VERDICT INVERTED: this file declined before batch 053.
;
; The stale pure op is PLACED before its staling gate (StaleReadPlacement.h): its
; template copies the pre-gate label, the stream the read-first program lowers to
; (twin: lowering_stale_record_add_before_theta.ll, the same CHECK chain).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll 2> %t.err
; RUN: %filecheck %s < %t.ll
; RUN: %filecheck --check-prefix=WARN --allow-empty %s < %t.err
; WARN-NOT: {{error|warning}}
;
; CHECK:      %[[H:[a-z0-9]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double %g)
; CHECK-NEXT: %[[D:[a-z_0-9]+]] = call i32 @cq_template_add_i32_hl(i32 %[[H]], i32 1)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double %t2)
; CHECK:      call i32 @cqrt_measure_i32(i32 %[[D]])
;
; ── HISTORY: the pre-batch-053 header, kept verbatim (its verdict text is
; superseded by the block above) ──
; lowering_reject_stale_record_add.ll — DECLINE: straight-line stale-record
; pure producer (test_C_libtooling-uzb), NO control flow involved.
;
; `%d = add i32 %q, 1` denotes, by SSA semantics, the value of `%q` at `%q`'s
; definition — the PRE-Ry record — but the lowering emits `cq_template_add` at
; the add's SCHEDULED position, AFTER the chained, in-place, NON-diagonal
; `cq_theta(%q, %t2)`: the template reads the post-Ry basis. Before the guard
; the pass ACCEPTED this shape (exit 0, verify-clean, confirmed 2026-06-10:
; `cq_template_add_i32_hl(%h, 1)` emitted after `cqrt_ry(%h, %t2)`) — the same
; stale-record family as the in-region condition instance closed by
; test_C_libtooling-ee5, but outside ArmClassify's reach entirely (no branch).
; Oracle: docs/design/rssa-swap-control/investigation_mint_at_compare.py P2
; (stream fidelity cos^2(t2/2)). The source semantics IS well-defined (an
; entangling record at the operand's wire window, MINT_AT_COMPARE.md §0/P6);
; a future ACCEPT would need wire-window emission placement — until then,
; decline loudly (Prime Directive). Guard:
; OpcodeLowering::declineStaleRecordOps (position-aware: the sibling fixture
; lowering_stale_record_add_before_theta.ll pins the accept boundary).
;
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, double %g, double %t2) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double %g)
  %q2 = call i32 @cq_theta_si32(i32 %q, double %t2)   ; chained, in-place Ry
  %d = add i32 %q, 1                                  ; SSA denotes the PRE-Ry record
  %m = call i32 @cq_measure_si32(i32 %d)
  ret i32 %m
}
