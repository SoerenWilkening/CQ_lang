; control_inplace_ry_reject_stateprep_cast_trunc_live.ll — DECLINE. The NARROWING
; direction of the F-R3-2 cast family (round-3 lens R3).
;
; The seed is `i16 5` while the compare is at `i32`, so the shipped type gate
; skipped F2 here too. The `trunc` rail is live and measured, so the fresh
; `cqrt_alloc_i16(5)` is a THIRD wire and the source's `cq_theta(t,θ)` was an
; in-place Ry on the SECOND. Written by hand rather than lifted from `-O1`
; because `clang` keeps the narrow theta operand tainted for the `short` C
; spelling (probes `g02`/`m09`, the chained class) — the shape is nevertheless
; the one InstCombine produces for a wide compare it narrows, and declining it
; costs nothing.
;
;
; ---- STILL A DECLINE AFTER THE 2026-09-11 NARROWING (bd `drbq.14`) ----
;
; F2 was narrowed on 2026-09-11 (owner ruling): a pinned value that lies on the
; CONDITION'S OWN BACKWARD WIRE — `CondWire` =
; `{Region.Condition} ∪ ⋃ railWireClosure(condProvenance(Region.Condition))` — is
; no longer a collider, and NINETEEN fixtures of this family flipped to ACCEPT
; (they are now `control_inplace_ry_stateprep_*`). **THIS ONE DID NOT, and the
; reason is not an accident:**
;
; the pinned value is a FORWARD user AND is TYPE-DISJOINT from every cone
; member (the cone is at the root's width; the seed is not), so it is out
; of `CondWire` structurally as well as directionally. A cast rail is a
; DIFFERENT PHYSICAL WIRE that EXISTS in the module, which is exactly what
; F-R3-2 measured as eight plain-C accepts through the retired type gate.
;
; So the narrowing is the WIRE and nothing wider, and this file is one of the 21
; that prove it. Measured 2026-09-11 on the narrowed binary: rc=1, same string,
; same anchor.
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}state prep seed is proven equal to the condition register under quantum control
; CHECK-NOT: cqrt_ry_

declare i32 @cq_theta_si32(i32, double)
declare i16 @cq_theta_si16(i16, double)
declare i32 @cq_measure_si32(i32)
declare i16 @cq_measure_si16(i16)

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 3.000000e-01)
  %c = icmp eq i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %rt = call i16 @cq_theta_si16(i16 5, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi i16 [ %rt, %arm ], [ 5, %entry ]
  %t  = trunc i32 %u0 to i16
  %mr = call i16 @cq_measure_si16(i16 %rm)
  %mt = call i16 @cq_measure_si16(i16 %t)
  %mq = call i32 @cq_measure_si32(i32 %q)
  ret i32 %mq
}
