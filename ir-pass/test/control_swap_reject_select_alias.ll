; control_swap_reject_select_alias.ll — DECLINE: an ALIASING-operand select (4.4
; WI-1 gate 6, the §16.9 conservative aliasing guard). The two value operands
; must resolve to provably-disjoint post-lowering registers; here both are
; `cq_phi` rotations of the SAME base `%q`, so rotation lowering RAUWs them to one
; i32 handle — the two copies would read/write the same physical register the
; merge is muxing against. `operandsAlias` materializes `%qa`'s `cq_phi` arg-0
; diagonal-alias closure ({%qa, %q}) and `diagonalAliasHit(%qb, …)` walks `%qb`'s
; chain to the shared `%q` → decline `control flow`.
;
; Gates 3–5 all pass: `%sel` feeds only a measure (no arg-1 angle, gate 3); the
; result is i32 (gate 4); neither operand is rotated DOWNSTREAM of the select
; (the producing `cq_phi`s are UPSTREAM, invisible to the forward gate-5 scan) —
; so the decline is squarely the gate-6 alias guard. (Handwritten/foreign IR:
; clang -O1 would not fold two distinct-angle rotations into a select, but the
; probe pins the guard; same posture as lowering_reject_classical_mux_select_*.)
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}control flow under quantum control
; CHECK-NOT: cqrt_copy
; 3qlq: migrated from register cq_phi (uncontrolled -> deleted (D2))
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0) {
entry:
  %q   = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c   = icmp sgt i32 %q, 5
  %sel = select i1 %c, i32 %q, i32 %q     ; both operands alias %q's register
  %m   = call i32 @cq_measure_si32(i32 %sel)
  ret i32 %m
}
