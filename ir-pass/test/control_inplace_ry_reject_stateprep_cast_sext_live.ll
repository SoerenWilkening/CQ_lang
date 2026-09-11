; control_inplace_ry_reject_stateprep_cast_sext_live.ll — DECLINE (F2-semantic:
; the pinned register sits at a DIFFERENT WIDTH, and the shipped type gate
; skipped ALL of F2 for exactly that case).
;
; ⚠ ROUND-3 RULE-13 FINDING (lens R3, F-R3-2, CONFIRMED-MISCOMPILE, 8 plain-C
; programs). Source `$S/review3/R3/p/g03_ll_eq5.c`:
;
;     long long slice(void){ int q = cq_theta(3,0.3);
;                            long long t = (long long)q;      /* a CAST rail    */
;                            long long r = 5;
;                            if (t == 5) r = cq_theta(t, 0.9);
;                            return cq_measure(r) + cq_measure(t); }
;
; `-O1` narrows `icmp eq (sext i32 %1 to i64), 5` to `icmp eq i32 %1, 5` (the
; standard `foldICmpSExtConstant`) while the theta's arg-0 folds to `i64 5`. The
; compare literal is `i32` and the seed is `i64`, so the shipped
; `K->getType() == SeedI->getType()` precondition — one line above F2's body —
; skipped the LITERAL test, the RANGE test and the forward walk WHOLESALE, and
; the `sext` rail was minted after the region, measured, and never rotated.
;
; ⚠ AND IT RETIRES A WRITTEN RATIONALE, WHICH IS THE PART TO CARRY. The walk's
; own header said "a cast of `H` is a DIFFERENT PHYSICAL WIRE …, so following
; casts would be a pure over-decline". Both halves of the premise are true and
; the conclusion does not follow: the cast rail being a DIFFERENT wire is
; exactly why preparing a THIRD wire is wrong when the source rotates the second
; one and then reads it. What actually separates this file from the ACCEPT
; `control_inplace_ry_stateprep_cond_cast_seed.ll` is not the TYPE at all — it
; is whether the other wire EXISTS: there `-O1` folded the cast away entirely
; and no `sext` survives to be asked about; here the `sext` is live and MEASURED.
;
; Control, byte-identical on BOTH binaries (`p/u03_uncond_sext.c`): the guard
; removed emits `sext(h0) -> h1 ; ry_i64(h1,.9) ; measure(h1) ; measure(h1)` —
; CQ rotates the CAST RAIL in place.
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
declare i64 @cq_theta_sll(i64, double)
declare i64 @cq_measure_sll(i64)

define i64 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 3.000000e-01)
  %c = icmp eq i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %rt = call i64 @cq_theta_sll(i64 5, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi i64 [ %rt, %arm ], [ 5, %entry ]
  %t  = sext i32 %q to i64
  %mr = call i64 @cq_measure_sll(i64 %rm)
  %mt = call i64 @cq_measure_sll(i64 %t)
  %s  = add i64 %mr, %mt
  ret i64 %s
}
