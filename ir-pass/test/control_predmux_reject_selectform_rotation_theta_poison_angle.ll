; control_predmux_reject_selectform_rotation_theta_poison_angle.ll — REJECT
; (bd u1rp). THE FIXTURE THAT PINS THE ROTATION-ARGUMENT SCAN for a `cq_theta`,
; moved onto the ANGLE by bd z9t1 (owner ruling 2026-09-14).
;
; ⚠ WHY IT EXISTS AT ALL — read this with
; `control_predmux_reject_selectform_rotation_theta_poison_seed.ll`, which used
; to be this pin and is now an ACCEPT. `classifyConeNode` (PredMuxFlatten.cpp)
; handles the two rotations differently, on purpose:
;   * `cq_phi`   -> ConeNode::PassThrough. Its result IS operand 0, so the walk
;                  FOLLOWS operand 0 and a poison there is caught by recursion.
;   * `cq_theta` -> ConeNode::Leaf. Its result is a fresh `cqrt_alloc_<W>` handle
;                  that does not depend on the seed, so the walk STOPS and the
;                  arguments are never recursed into.
; That asymmetry makes the explicit `Call->args()` undef/poison scan REDUNDANT
; for `cq_phi` and the ONLY protection for `cq_theta`. Measured by arm-kill:
; deleting the scan leaves `..._rotation_poison_arg.ll` green (PassThrough
; catches that one anyway) — so without a `cq_theta` file the scan is an
; accept-predicate no fixture pins, which Rule 12 forbids.
;
; *** THE POISON IS IN THE ANGLE, AND THAT IS THE WHOLE POINT OF THE MOVE. ***
; The z9t1 normalizer rewrites a whole-value `undef`/`poison` SEED to a concrete
; zero before any classifier runs, so the seed spelling can no longer reach this
; scan. ARG-1 IS THE ANGLE AND THE RULE NEVER TOUCHES IT (Rule 3: the angle
; operand of a rotation is classical, and allocating or rewriting for it is the
; f64/angle miscompile family) — so the angle spelling reaches the scan exactly
; as the seed one used to, and a poison angle is a garbage `cqrt_ry` parameter
; whichever rotation family it belongs to.
;
; MEASURED ON BOTH BINARIES (2026-09-14): the oracle f7b65d8c and the z9t1 build
; both decline this module with the SAME string and the same anchor, so the
; substitution preserves the pin rather than inventing a new decline.
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
  %q = call i32 @cq_theta_si32(i32 %u, double poison)
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
