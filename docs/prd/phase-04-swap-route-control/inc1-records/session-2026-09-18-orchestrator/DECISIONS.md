# Owner decisions — session 2026-09-18

Batched at session open per the brief (§5 "batch the owner questions EARLY"). ⚠ The session runs
autonomously; **none of these were answered mid-session.** Each is recorded as a QUESTION with the
measured number it rests on, the orchestrator's recommendation (labelled as such), and the ASSUMPTION
the session proceeds under. Nothing here is a rule (Rule 0 / L7). Rulings the session DID receive
are in `$THIS/DECISIONS.md` (2026-09-17: S1–S6) and are carried, not restated.

---

## Q1 — bd `bbu0`: A / B / C, now that (D) is built and the number exists

**(D) is landed** (`95949550`, merge `79eb5b60`; instrument `CQ_BBU0_DEFER_DEPHASE_FENCE`, a no-op
unless set — `LoopLowering.cpp:4517`, `CQLoweringPass.cpp:933`). **The number** (`$PREV/trackD/
MEASUREMENT.md` §2, SUBJECT `libCQPass.so d4bf79c1…`, BASE = S′'s gated binary `15f6a75a…`):

| scope | FENCE rows | distinct programs | WARNED | SILENT | PREEMPTED |
|---|---|---|---|---|---|
| brief minimum (`ir-pass/test` + session probes, 2100 scanned) | 17 | 12 | 17 | **0** | 0 |
| full corpus (5289 rows) | 21 | 14 | 21 | **0** | 0 |

So `warnLiveRecordRotations` was silent on **0 of 14** programs `declineDephasingUnmarkedLoopRails`
declines; two shapes outside the minimum scope (controlled-Ry-after, angle-select-after) both warn.

Options as Track S′ put them (`$PREV/trackS/QUESTION_bbu0.md` §4), costs unchanged:
* **A** keep both, cross-referenced — cost: the duplicated record WALK (not the verdict), two places to widen.
* **B** promote the warning to a decline, delete the fence — cost: 5 of 366 accepting e2e slices decline, one a
  byte-identical twin pair; reverses bd `lyyf` unless all warnings are emitted first; ⚠ and the over-decline
  charge against B is itself unproven (byte identity cannot certify that pair correct).
* **C** rebuild the decline on the warning's candidate set + a divergence discriminator — a real increment with its
  own Rule-13 rounds; moves the stage after `lowerRotations`; one record walk.

**Orchestrator recommendation (not a ruling): C, sequenced AFTER bd `zujr`** — the number removes the one
argument against C (a silent-where-the-fence-speaks case, 0 of 14), the measurements were already
"consistent with C and no evidence for B", and C touches `LoopLowering.cpp`/`RotationLowering.cpp`
beside the loop headline, so it must not be built under it. **Assumption this session: A (status quo).**
No track touches either site for bbu0 reasons.


## Q1 — ADDENDUM (mid-session measurement): option B's "cost" is a DEFECT
The merge-and-gate's blast-radius sweep scored the twin pair cited as B's over-decline cost
(`slice_control_inplace_ry_loop_leak{,_unrolled}`) as G8-SHAPE: both halves leave interior which-path
rails dirty across a non-diagonal `cqrt_ry` on the register they copy, then measure it — a Rule-8 wrong
unitary shipping under a green `twin-identical` gate (bd `test_C_libtooling-jlf8`, P1). "B refuses a program that is
demonstrably rolled == unrolled" was true and irrelevant: both halves are wrong the same way (L10). The
measurements that pointed at C still stand; the argument against B is weaker than recorded.

## O1 — ORCHESTRATOR DECISION (flagged for owner review): re-pin the moved twin-matrix boundary control
`q_armoncond` (a pinned boundary control of `tools/loop_twin_matrix.py`) moved on the combined binary
under Track D's accept-direction widening; the tool refuses to rewrite a control by design ("moving a
control is a human decision"). I authorised the merge-and-gate agent to re-pin it ONLY with a written
adjudication (`gate/MATRIX_ADJUDICATION.md`: the track by string, old/new verdict, the per-trip argument
that the new verdict is the right circuit) and to leave it RED otherwise. Ground: the owner's 2026-09-17
S3 ruling (byte-identity is an instrument; correctness is the claim). If the owner disagrees, the re-pin
is one line to revert and the control returns to its previous verdict with D's landing then RED.

## Q2 — bd `zujr` wall 5: a scoping-only track now?

E5 (2026-09-15) recorded the four-wall table as *"the first four I could reach"*; rows 3–4 are the
first two declines of an unknown-length tail, because `LLVMContext::diagnose` exits on the first
`DS_Error`. **Recommendation: YES** — spawn a scoping-only agent (no code) on the CLOSING binary of
this session (Group 1 landed), hand-emulating (c3) + W3 + L-3 on the owner's program's stage-1 IR to
find wall 5, so the `zujr` session is sized before it starts. Cost: one agent, no build, no suite.
**Assumption: proceed if the session has room after Group 1's gate; otherwise file it on `zujr` as
the first item of the next session.** The closing `NEXT_SESSION_PROMPT.md` states the FIRST decline
of the owner's program on the closing binary either way (that measurement is owed regardless).

## Q3 — carried, not asked again unless a track needs them
* bd `dnqo` (E1 2026-09-15: KEEP ACCEPTING; closes as by-design with the scope-boundary wording) —
  Wave 0-B checks whether it was closed; if not, it is closed with E1's wording.
* bd `yiid` (E3/E7/E8: a three-increment path behind 7.6) — untouched.
* bd `wt3l` (a user Rz on a rail the spine later uncomputes) — untouched.


## Q4 — bd `tu9q`'s hoisted-template half: P0+P3 is BUILT, MEASURED and NOT LANDED (added mid-session)

Group 1 landed bd `6n1s` + P1 (the real multiplicity test) + P2 (the loop-exit anchor) on
`tu9q-hoisted-template` — the prefix SCOPE_T2 §0 pre-authorised as *"a complete, closed, independently
valuable capability … marks NO new body"*: it closes bd `1m5p` and the live `a1_apost` over-accept (16
accept→accept movers, 0 verdict flips). P0+P3 (the component partition + clause (ii-d), which would
close `s2_live_derived_region`, `hoisted_template`, `short_sext` and bd `s82e`'s residue) is built on
`tu9q-p0-p3-wip` (`30b80d7f`, binary `e951d5d1…`), works on its declared customers (`hoisted_template`
rolled 40 == twin 40, multiset identical), and **is not landed**, because it moves 8 shipped fixtures and:

1. it flips `loop_pairing_reject_round2_falsified.ll` to an ACCEPT, leaving `declineRound2FalsifiedRailGrants`
   — Track T's own L1 re-ask fence — with **zero** pinning fixtures (grep: 1 → 0); a repaying RED fixture
   must falsify a round-1 marking by a route that is NOT a hoisted template rail, and none is constructed;
2. mover 8 (`control_inplace_ry_reject_rail_inloop_carried_invariant_read`) meets its own L8 trigger's
   condition and does NOT deliver the predicted accept — P3 grants the marking, the spine does not
   discharge, the postcondition declines (safe, but the capability is one shape short);
3. the (ii-d) grants pass through `collapseFlattenedLoopRails` BEFORE the round-2 fixpoint with no
   `recordRound1RailGrant` (bd `0kjo`);
4. the postcondition is a PRESENCE check that relies on P1 for multiplicity (never land P0+P3 without P1);
5. its e2e slice pair is missing; 6. no suite, corpus or matrix has run on `e951d5d1…`.

**The question for the owner:** P0+P3 retires the SUBJECT of another owner's Rule-13 fence (`declineRound2
FalsifiedRailGrants`'s only fixture) on the argument that P1 makes its hazard impossible by construction.
The implementer and the independent reviewer both judged that flip the RIGHT direction (per-trip: the
preheader `mul` is minted once in `entry` and adjointed once at `out:`) and both declined to make the call.
**Orchestrator recommendation: land P0+P3 FIRST in the next session, under its six obligations, before
`zujr`'s body touches `LoopLowering.cpp`.** Assumption this session: P0+P3 stays a wip branch; `tu9q` and
`s82e` stay OPEN with the half-landed state written on them; `1m5p` closes.

## Rulings received this session
(none at open; appended here if the owner answers mid-session)
