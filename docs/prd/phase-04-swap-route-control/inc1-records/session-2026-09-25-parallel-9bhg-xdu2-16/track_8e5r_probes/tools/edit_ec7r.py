#!/usr/bin/env python3
"""bd ec7r / Rule-13 r2 F-R2-1: the bd 2qyz lift re-sweep is gated on the lift
EVENT (`taint.LiftedMergePhis`, d88e's per-lift record, never shrinks) instead of
the self-cleaning `taint.LiftedConsumers`, whose only reader that was; the
now write-only `LiftedConsumers` is REMOVED; every comment that named it as the
witness, and the two false F-EA-8 comments, are corrected at the source (L7)."""
W = "/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a2cf1f874e5ec99d2/"


def rep(path, a, b):
    p = W + path
    s = open(p).read()
    assert s.count(a) == 1, (path, a[:90], s.count(a))
    open(p, "w").write(s.replace(a, b))


# ---- the gate (LOGIC) + its comment ------------------------------------------
rep("ir-pass/src/OpcodeLowering.cpp",
    """  // Gated on a lift having occurred (`LiftedConsumers` is the witness, populated
  // by `liftOneRegisterMergePhi`): a module with no lift skips the re-sweep
  // entirely, so NO message-ownership churn on non-lift fixtures (opt exits at
  // the first DS_Error).""",
    """  // Gated on a lift having occurred: a module with no lift skips the re-sweep
  // entirely, so NO message-ownership churn on non-lift fixtures (opt exits at
  // the first DS_Error).
  // ⚠ THE WITNESS IS THE LIFT **EVENT**, `taint.LiftedMergePhis` (bd
  // test_C_libtooling-ec7r, Rule-13 delta round r2 F-R2-1). It used to be the
  // lift's direct consumers (`LiftedConsumers`), and that broke in the
  // COMPOSITION of two correct changes: bd 8e5r made the set self-cleaning
  // (`empty()` = "no LIVE consumer"), and bd d88e moved this re-sweep AFTER
  // `specialize()`, whose `retargetSite` REBUILDS an fp-return spec call and
  // ERASES the old one — so when that call was the lift's only consumer the set
  // emptied, the re-sweep was SKIPPED, and a module every pre-merge binary
  // declined was accepted (`lowering_reject_lift_resweep_spec_rebuilt_consumer.ll`).
  // The question this sweep asks is module-wide and does not depend on any
  // consumer still being alive, so the gate must not either. `LiftedMergePhis`
  // gets one record per accepted lift and is never shrunk (its handles may null;
  // its LENGTH cannot), and every lifted phi has >= 1 Instruction user
  // (`declineClassicalMuxes` skips `use_empty()` phis), so this is exactly the
  // fact the pre-merge raw consumer set encoded.""")
rep("ir-pass/src/OpcodeLowering.cpp",
    """  // ⚠ `empty()` counts LIVE members only (bd 8e5r, r1A F-EA-8): this asks "a
  // lift occurred and a recorded consumer is still alive". Argued equal to "a
  // lift occurred" here — nothing erases between `declineClassicalMuxes` and
  // this re-sweep, and a lifted φ that was itself a recorded consumer contributes
  // its own consumers. An erasing stage placed in that window must re-ask it.
  if (taint.LiftedConsumers.empty())
    return;  // no lift occurred — nothing to re-adjudicate.""",
    """  // ⚠ CORRECTED (L7): the note that stood here argued a self-cleaning consumer
  // set was equivalent because "nothing erases between `declineClassicalMuxes`
  // and this re-sweep". FALSE since the d88e merge — `specialize()` is in that
  // window and erases rebuilt spec calls. Written after the merge, measured on
  // the pre-merge binary: the bd 8e5r lesson that a claim about a WINDOW must be
  // re-asked whenever a stage moves into it.
  if (taint.LiftedMergePhis.empty())
    return;  // no lift occurred — nothing to re-adjudicate.""")

# ---- the member: REMOVED (its only reader was the gate) ----------------------
rep("ir-pass/include/TaintPropagation.h",
    """  // One-register merge-phi lift WITNESS (test_C_libtooling-2qyz). The lift
  // (`liftOneRegisterMergePhi`) RAUWs a proven pure-renaming merge phi to its
  // wire BASE and erases it — AFTER `declineStaleRecordOps` already ran — so a
  // consumer that read the phi now resolves to the base, and a sibling Ry
  // re-rotating the base's wire (invisible behind the PHINode at the earlier
  // guard) would make the consumer's template stale. The lift inserts its
  // direct Instruction consumers here so the orchestrator knows a lift OCCURRED
  // and re-runs the FULL stale-record sweep (`declineLiftedStaleRecordOps`,
  // since bd d88e after `specialize()` and the lift's own re-ask
  // `declineFalsifiedMergePhiLifts`, before any rotation lowering). The
  // re-sweep is NOT scoped to these entries — a stale op can sit any number of
  // in-place-gate hops downstream of the lifted phi (a Rule-13 adversarial
  // finding), so the complete sweep is required for soundness; this set is the
  // lift-occurred gate (non-empty ⇒ re-sweep, so non-lift modules incur no
  // diagnostic churn). Pointers stay valid — consumers are not erased before
  // the re-sweep.
  ScrubPtrSet<llvm::Instruction *, 4> LiftedConsumers;
""",
    """  // ⚠ `LiftedConsumers` — the one-register merge-phi lift's direct consumers,
  // once the "a lift OCCURRED" witness for the bd 2qyz re-sweep — was REMOVED by
  // bd test_C_libtooling-ec7r (Rule-13 delta round r2 F-R2-1). Its only reader
  // was that gate, and as a SELF-CLEANING set it answered "a consumer is still
  // alive", which `specialize()` (moved into the window by bd d88e) can falsify
  // by erasing a rebuilt spec call. The gate now reads the lift EVENT,
  // `LiftedMergePhis` below (one record per accepted lift, never shrunk).
""")
rep("ir-pass/src/TaintPropagation.cpp",
    """  // Recording the direct consumers flags the lift to the orchestrator, which
  // re-runs the FULL stale-record sweep (`declineLiftedStaleRecordOps`) — since
  // bd d88e AFTER `specialize()` and the re-ask of this lift's own premise, so it
  // only ever adjudicates a lift that survived that re-ask. The sweep is
  // complete, not scoped to these
  // entries: the genuine stale op may be a TRANSITIVE consumer separated from
  // the phi by in-place-gate hops (Rz / chained Ry) — a Rule-13 adversarial
  // finding — so only re-walking every consumer's full wire is sound.
  for (User *U : Phi->users())
    if (auto *I = dyn_cast<Instruction>(U))
      taint.LiftedConsumers.insert(I);
""",
    """  // The record pushed below flags the lift to the orchestrator, which re-runs
  // the FULL stale-record sweep (`declineLiftedStaleRecordOps`) — since bd d88e
  // AFTER `specialize()` and the re-ask of this lift's own premise, so it only
  // ever adjudicates a lift that survived that re-ask. The sweep is complete,
  // not scoped to the phi's consumers: the genuine stale op may be a TRANSITIVE
  // consumer separated from the phi by in-place-gate hops (Rz / chained Ry) — a
  // Rule-13 adversarial finding — so only re-walking every consumer's full wire
  // is sound. (bd ec7r: the witness is the RECORD, i.e. the lift event; the
  // self-cleaning direct-consumer set that used to be the witness is removed.)
""")
rep("ir-pass/include/OpcodeLowering.h",
    """// (`taint.LiftedConsumers` non-empty) it re-runs the COMPLETE""",
    """// (`taint.LiftedMergePhis` non-empty — the lift EVENT, bd ec7r) it re-runs the COMPLETE""")
rep("ir-pass/src/CQLoweringPass.cpp",
    """  // (witnessed by taint.LiftedConsumers) this re-runs the FULL stale-record""",
    """  // (witnessed by taint.LiftedMergePhis, the lift EVENT — bd ec7r) this re-runs the FULL stale-record""")
rep("ir-pass/src/MergePhiPeel.cpp",
    """        // ORDER (`LiftedConsumers`, empty until `declineClassicalMuxes` runs
        // AFTER both peel sites) — is in `IMPL_b6ap.md` §2d, with the two""",
    """        // ORDER (`LiftedConsumers`, empty until `declineClassicalMuxes` runs
        // AFTER both peel sites; the member is removed since bd ec7r) — is in
        // `IMPL_b6ap.md` §2d, with the two""")
rep("ir-pass/src/TaintPropagation.cpp",
    """  // (`LiftedConsumers` — `declineClassicalMuxes` runs after BOTH peel sites;""",
    """  // (`LiftedConsumers`, removed since bd ec7r — `declineClassicalMuxes` runs after BOTH peel sites;""")

# ---- the struct-level F-EA-8 block (L7) -------------------------------------
rep("ir-pass/include/TaintPropagation.h",
    """//   * `empty()` / `size()` count LIVE keys (r1A F-EA-8). A set used as an EVENT
//     WITNESS ("a lift occurred": `LiftedConsumers`; "a region was emitted":
//     `InLoopFlattenedPreds`, `UntaintedMergeRails`) now reads "a live member
//     remains", not "it was ever recorded". Argued not to flip at any of its
//     three readers (nothing erases a recorded member in those windows; r1A I1:
//     0 flips) — a new erasing stage inside one of those windows must re-ask it.""",
    """//   * `empty()` / `size()` count LIVE keys (r1A F-EA-8). A self-cleaning table
//     therefore CANNOT be an EVENT WITNESS ("did X ever happen?"): it answers "is
//     a member still alive?". ⚠ CORRECTED (L7, Rule-13 delta round r2 F-R2-1 /
//     bd ec7r): this note used to say the three event-witness readers could not
//     flip because "nothing erases a recorded member in those windows" — measured
//     on the pre-merge binary, and FALSE after the bd d88e merge moved
//     `specialize()` into the `LiftedConsumers` window. That gate now reads the
//     lift EVENT (`LiftedMergePhis`) and `LiftedConsumers` is gone. Every
//     remaining `empty()` gate over a table in this struct is tabled, decided and
//     MEASURED (TRACK_8E5R.md §15.2): each one gates work that only ever touches
//     the table's own LIVE members (so "no live member" and "no work" coincide),
//     or is argued in place. A new `empty()` gate over one of these tables must
//     say which of the two it is — or read an event record instead.""")

# ---- the selftest line for the removed member --------------------------------
rep("ir-pass/tools/scrub_selftest.cpp",
    """  checkSet("LiftedConsumers", T.LiftedConsumers, Add);
""", "")
print("ok")
