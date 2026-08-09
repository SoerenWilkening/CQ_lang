; control_predmux_reject_selectform_rotation_theta_poison_seed.ll — REJECT
; (bd u1rp). THE FIXTURE THAT PINS THE ROTATION-ARGUMENT CHECK, and it has to be
; a `cq_theta` one.
;
; `classifyConeNode` handles the two rotations differently, on purpose:
;   * `cq_phi`   -> ConeNode::PassThrough. Its result IS operand 0
;                  (RotationLowering RAUWs it verbatim), so the walk FOLLOWS
;                  operand 0 and a poison there is caught by the recursion.
;   * `cq_theta` -> ConeNode::Leaf. Its result is a fresh `cqrt_alloc_<W>`
;                  handle that does not depend on the seed, so the walk stops
;                  and the seed is NEVER RECURSED INTO.
;
; That asymmetry means the explicit `Call->args()` undef/poison scan is REDUNDANT
; for `cq_phi` — the recursion already catches it — and is the ONLY protection
; for `cq_theta`. Measured by arm-kill: deleting the argument scan leaves
; control_predmux_reject_selectform_rotation_poison_arg.ll GREEN, because
; PassThrough catches that one anyway. Without THIS file the argument scan would
; be an accept-predicate no fixture pins, which Rule 12 forbids.
;
; WHY DECLINE AT ALL, when `cq_theta`'s handle does not depend on the seed. It is
; a deliberate, cheap over-decline. The poison does reach exactly one emitted
; site — `cqrt_alloc_i32(i32 poison)` — and one site cannot break a
; forward/`_unc` pair, so this is not the miscompile its `cq_phi` sibling is.
; Measured cost of refusing it anyway: ZERO. No rotation call site in 965
; fixtures, 257 e2e stage-1 modules or 251 openlibm modules has an undef/poison
; argument. Prime Directive: an unprovable input declines.
;
; The angle slot rides the same scan for both families, which is the other
; reason not to special-case it away: a poison angle is a garbage `cqrt_ry` /
; `cqrt_rz` parameter regardless of which rotation it belongs to.
;
; POSITIVE CONTROL: control_predmux_accept_selectform_seed_flags_preserved.ll —
; a `cq_theta` whose seed is a DEFINED, non-trivial expression must still accept,
; and its flags must survive (the bd u1rp narrowing).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:  | %filecheck %s

target datalayout = "e-m:o-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @probe(i32 %u) {
entry:
  %q = call i32 @cq_theta_si32(i32 poison, double 5.000000e-01)
  %a = icmp sgt i32 %q, 3
  %b = icmp sgt i32 %q, 11
  %sc = select i1 %a, i1 %b, i1 false
  br i1 %sc, label %arm, label %merge

arm:
  %k = add i32 %q, 7
  %k2 = mul i32 %q, 3
  br label %merge

merge:
  %p = phi i32 [ %k, %arm ], [ %q, %entry ]
  %p2 = phi i32 [ %k2, %arm ], [ %q, %entry ]
  %s2 = add i32 %p, %p2
  %m2 = call i32 @cq_measure_si32(i32 %s2)
  ret i32 %m2
}

; CHECK: error: {{.*}}in function probe i32 (i32): cq controlled lowering: control flow under quantum control
