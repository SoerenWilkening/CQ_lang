; control_inplace_ry_reject_stateprep_range_forward_add.ll — DECLINE (F2, the
; RANGE clause reaching FORWARD: the pinned register is a USER of the compare's
; operand, not the operand itself).
;
; ⚠ THIS FIXTURE IS A ROUND-2 RULE-13 FINDING, NOT A DESIGN ROW. It ACCEPTED
; after the round-1 fix and the acceptance was a CONFIRMED SILENT MISCOMPILE
; reachable from ordinary `clang -O1` C (round-2 review, lens R1 finding
; F-R1-1, probe `p/x01_fwd_add5_live.c`):
;
;     int q = cq_theta(3, 0.3);
;     int t = 5 + (q & 1);              /* an IN-PLACE rail: cqrt_addc on the  */
;     int r = 6;                        /* AND's rail                           */
;     if (t != 5) r = cq_theta(t, 0.9); /* an IN-PLACE Ry on the CONDITION wire */
;     return (int) cq_measure(r) + (int) cq_measure(t);
;
; THE MECHANISM IS THE POINT, and it is MEASURED with isolated `opt` pipelines
; rather than inferred. `ipsccp` proves the pin about the register `5 + (q & 1)`
; — whose edge range really IS the singleton `{6}` — and substitutes it into the
; arm's `cq_theta`. A LATER `instcombine` then rewrites the COMPARE downward
; onto an ANCESTOR of that register: `icmp eq (add (and q,1), 5), 5` becomes
; `icmp eq (and q,1), 0`. So the operand CQ is handed is `%t`, whose edge range
; is `{1}` and never equals the seed `6`, while the register the theorem is
; about is a FORWARD USER of `%t` — and it survives, in the merge block, and the
; source MEASURES it.
;
; The round-1 fix widened F2's PREDICATE (literal → edge-restricted range) and
; kept F2's SET (`%t` alone). This is the bd `8h7d.5` F-1/F-3 lesson a third
; time: when you widen a set, ask what OTHER set is computed over the same
; closure.
;
; Emitted at the round-1 HEAD (run, not read): `and_i32_hl(h0,1) -> h1 ;
; icmp_eq_i32_hl(h1,0) -> h2 ; x(h2) ; alloc_i32(6) -> h3 ;
; ry_i32_controlled(h2,h3,.9) ; x(h2) ; …strip… ; free(h2) ; addc_i32(h1,5) ;
; measure(h3) ; measure(h1)`. `h1` — the register the source measures as `t` —
; receives NO rotation, and the program has TWO wires where the source has one.
; The control that closes the argument, measured on the PRE-Inc-4 binary: the
; same program with the guard removed emits `and_i32_hl(h0,1) -> h1 ;
; addc_i32(h1,5) ; ry_i32(h1,.9)`, i.e. CQ's own semantics for `cq_theta(t,θ)`
; is an in-place Ry on `t`'s rail.
;
; THE FENCE IS THE FORWARD CLOSURE. F2 seeds a bounded walk with (`%t`, its
; value set on this edge) and pushes forward through `%t`'s TAINTED same-type
; integer `op constant` users, evaluating with `ConstantRange::binaryOp`:
; `{1} + 5 = {6}` = the seed. Decline. Casts and φ/select are NOT followed — see
; the walk's header in `ArmClassify.cpp` for why each is a DIFFERENT wire under
; CQ rather than a missing case.
;
; THE ONE-TOKEN CONTROL is `control_inplace_ry_stateprep_cond_derived.ll`: no
; tainted `op constant` user of the compare's operand exists there at all, so
; the walk has depth 0 and the file still ACCEPTS. `..._range_mask1.ll` is the
; depth-0 control for THIS clause — same condition, seed on `%t` itself.
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
; the pinned value is a FORWARD USER of a cone member (``add %t, 5``), minted on a
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
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 3.000000e-01)
  %t = and i32 %q, 1
  %c = icmp eq i32 %t, 0
  br i1 %c, label %merge, label %arm
arm:
  %rt = call i32 @cq_theta_si32(i32 5, double 9.000000e-01)
  br label %merge
merge:
  %rm  = phi i32 [ %rt, %arm ], [ 5, %entry ]
  %fwd = add nuw nsw i32 %t, 5
  %mr  = call i32 @cq_measure_si32(i32 %rm)
  %mf  = call i32 @cq_measure_si32(i32 %fwd)
  %s   = add i32 %mr, %mf
  ret i32 %s
}
