; control_inplace_ry_reject_stateprep_range_forward_lshr.ll — DECLINE (F2, the
; RANGE clause reaching FORWARD, the SECOND direction: the compare was rewritten
; onto the ANCESTOR and the pinned register hangs off it).
;
; ⚠ A ROUND-2 RULE-13 FINDING, NOT A DESIGN ROW — one of the SIX plain-C
; spellings that ACCEPTED after the round-1 fix (round-2 review, lens R1 finding
; F-R1-1, CONFIRMED-MISCOMPILE, probe `p/x23_lshr31_live.c`):
;
;     int q = cq_theta(3, 0.3);
;     unsigned s = ((unsigned) q) >> 31;
;     unsigned r = 1;
;     if (s) r = cq_theta(s, 0.9);          /* an IN-PLACE Ry on s's own rail */
;     return (int) cq_measure(r) + (int) cq_measure(s);
;
; THIS IS THE OTHER HALF OF F-R1-1'S MECHANISM, and it is why one fixture was
; not enough. In `..._range_forward_add.ll` `instcombine` PEELED an `add` off
; the compare; here it replaced the whole test — `icmp ne (lshr %q, 31), 0`
; becomes `icmp sgt i32 %q, -1` — so the operand CQ is handed is the SOURCE
; register `%q` and the pinned register `%s` hangs off it as a sibling of the
; compare. Measured with isolated pipelines:
;
;   opt -passes='function(mem2reg),ipsccp'             -> cq_theta_ui32(i32 1, …)
;        with the compare still `icmp ne (lshr %1,31), 0`
;   opt -passes='function(mem2reg,instcombine)'        -> the compare REWRITTEN
;        to `icmp sgt %1, -1`, the arm operand left as `%2`
;
; `%s` is ALIVE in the emitted circuit (`lshr_i32_hl(h0,31) -> h3`), is MEASURED
; by the source, and receives no rotation; the rotation went onto a fresh
; `alloc_i32(1)` rail. The unconditional control (`p/u02`, identical on both
; binaries) emits `lshr_i32_hl(h0,31) -> h1 ; ry_i32(h1,.9)`, so CQ's own
; reading of `cq_theta(s,θ)` really is an in-place Ry on `s`'s rail.
;
; THIS FILE'S ALGEBRA: the false edge of `sgt -1` pins `%q` to `[INT_MIN, 0)`,
; and `ConstantRange::lshr` of that by `{31}` is `[1,2)` — the singleton `{1}`,
; which IS the seed.
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
; the pinned value is a FORWARD USER of a cone member (``lshr %q, 31``), minted on a
; FRESH rail — there is no in-place ABI for that opcode — and `CondWire`
; is built `WireDir::BackwardOnly`, so a forward user is not in it. This is
; the F-R1-1 class: six CONFIRMED plain-C silent miscompiles, whose defect
; was precisely that `-O1` rewrote the compare DOWNWARD onto an ANCESTOR of
; the rotated register, so the backward walk from the compare can never
; reach it. Widening `CondWire` to `BothWays` would swallow all six.
;
; So the narrowing is the WIRE and nothing wider, and this file is one of the 21
; that prove it. Measured 2026-09-11 on the narrowed binary: rc=1, same string,
; same anchor.
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}state prep seed is proven equal to the condition register under quantum control
; CHECK-NOT: cqrt_ry_i32_controlled

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_theta_ui32(i32, double)
declare i32 @cq_measure_ui32(i32)

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 3.000000e-01)
  %c = icmp sgt i32 %q, -1
  br i1 %c, label %merge, label %arm
arm:
  %rt = call i32 @cq_theta_ui32(i32 1, double 9.000000e-01)
  br label %merge
merge:
  %rm  = phi i32 [ %rt, %arm ], [ 1, %entry ]
  %fwd = lshr i32 %q, 3
  %mr  = call i32 @cq_measure_ui32(i32 %rm)
  %mf  = call i32 @cq_measure_ui32(i32 %fwd)
  %s   = add i32 %mr, %mf
  ret i32 %s
}
