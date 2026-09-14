# Track P — ADVERSARIAL REVIEW round 1 (Rule 13), bd `3qps` + bd `4aiu`

**Subject:** branch `mergephi-phase-leaf`, tip `98951fa16581463c31fd95c06fab3824c7f84376`, worktree
`/Users/sorenwilkening/Desktop/CQ_phiphase`. Binary `cq-opt`
`283e3b3322a9a94c206eb94471e519e5c9e4ffd60c0917743519ae895a0b2daf`, `libCQPass.so`
`fa563f6941280d3d1dc181116b380621e4bc63108f366f09826a9af004d931c5`.
**ORACLE**: `cq-opt` `f7b65d8ccd7bc472303d13b3c7bd7a78c03d990a4147fe7589ef73a85487b0bc`, `libCQPass.so`
`f9e898badfd4207a758d27638a34b7e147bd3b702e5611b4fad0e0403879039d`.
**FIRST ACT: `shasum -a 256` on both. A mismatch is a FINDING and you STOP.**

**READ FIRST:** `$SES/PROTOCOL.md`, `$SES/trackP/BRIEF_P.md`, and in the subject worktree `IMPL_P.md` in
full — **§3 is the 23-row leaf-enumeration table and it is the heart of this review**, §9 the filings owed.
Then `bd show 3qps`, `bd show 4aiu`, `bd show boi6`, and `CLAUDE.md` Rules 1, 7, 12, 13, 14, 19 and
CORRECTNESS RISK §1, §2, §3 **L1/L2/L3**.

## What shipped

**ONE predicate, two consumers.** `preppedRailPhiRegionIdx` left `SelectClassify.cpp`'s anonymous namespace;
**2 call sites, 1 definition, no re-derived conjunct**. bd `3qps`: `if (b1) cq_phi(θ)` on a prep merge φ now
lowers. bd `4aiu`: a φ at an **INTERIOR** tree position lowers at **both** consumers (the ROOT-ONLY scope is
retired). The emitter needed **no new stream** — the post-M-β modules `p17`/`p18` **accept on the ORACLE**,
and `diff p01.trace p17.trace` differs on exactly one line (the prep's cancelling Ry, controlled vs not).
0 new frozen symbols.

## The attack surface — leads, not a checklist

1. **§3's 23 leaf-enumerating sites: 8 widened, 6 deliberately NOT.** That table is an L2 answer and L2's
   lesson is that the *unwidened* rows are where the hole is — **and so is an over-widened one**. The
   implementer flags **row 9 as THE would-be over-accept** and **row 20 (`Out.RootIsRail`) as the one that
   would have let the kickback `cqrt_x`-BRACKET A USER REGISTER** (Rule 7: nothing non-diagonal ever touches
   a user register under control; an X on a user register is exactly the forbidden thing). **Verify both
   verdicts independently, and check each of the 6 not-widened rows for a shape that reaches it.**
2. **The TYPE is the enforcement.** Track M deliberately did not retype `RailLeaves` and did not widen
   `isCondRailLeaf`. Confirm that discipline survived, and that `AllowRailPhi`/`AllowLogicalSelect` remain
   orthogonal (the implementer says only the φ flag moved; `(b1 && q > 3) ? A : B` from plain C must still
   decline on the **logical-select NODE**, not on the φ).
3. **H-1, the dangling `ControlRegion::Condition`.** The implementer says it has **no subject** here because
   the `hcrg` chain edge emits the kickback first with the φ live, and argues it from
   `condWireDisposition` refusing a cross-block condition. They hardened the emitter anyway
   (`CondV = BI->getCondition()`). **Attack the argument, not the hardening** — find a schedule where the φ
   is erased before the kickback reads it.
4. **F-M1, the precedence graph.** The select keeps its edge, now **per leaf** (`PrepRegionIdx` →
   `PrepRegionIdxs`); the kickback records **nothing**, because that edge would close a cycle. **Is "would
   close a cycle" true for every kickback, or only for the ones probed?** A cycle here is a teardown-order
   bug, and L6 says the sequential-region pair declined for four months because a structural guard wore a
   semantic label — the inverse error is available too.
5. **L1.** Rung 0 reads *this round's* verdict; round 2 cannot introduce the region
   (`UntaintedMergeRails` is 6.5/4.5 only); the plan is **fresh per round**; records land in
   `RailCondReads` (`WeakTrackingVH`, following M-β's RAUW before `reverifyRailCondReads`); no taint growth
   claimed. **Verify the "no taint growth" claim yourself** — `MergePhiPeel` manufactures tainted values and
   `adjudicateTaintDelta` exists for exactly that.
6. **F-P2 is the class to re-check, not just the instance.** A widening made the φ declines lose their
   `!dbg` (`<unknown>:0:0`) and it passed a green 1946-fixture lit run, a 0-MISSED matrix and a byte-identical
   288-fixture family — **caught only by a full-stderr hash**. It was fixed with one `PhiAnchor`
   (`== declAnchor(Region)` for every compare/rail shape). **Check every string this increment can emit,
   compiled WITH `-g`, for a real `file:line:col`** — including step 5c's reproduction of
   `collectCondTree`'s string split (bd `boi6` H-8: a fixture was being silently re-labelled).
7. **The known over-decline, for scope only** (IMPL_P §9.1, filed): a φ leaf **outside the kickback's own
   `Pred`** declines `condition predates a non-diagonal gate` — `if (b0) b1=θ; if (b0) b2=θ; if (b1 && b2)
   cq_phi(θ)`. Do **not** ask for it to be fixed here; **do** check the implementer's claim that at the
   KICKBACK at most ONE φ leaf can ever satisfy the in-`Pred` requirement, which makes the per-leaf loop
   effectively single-leaf there.
8. **Must keep declining** (verify a sample): `p5`/`m20`, the CHAINED arm theta (bd `drbq.7`); the
   in-place-ARM φ (Track M's pinned F-M3, whose retirement is bd `3d8q` — **which lands this session**, so
   say whether that changes anything); the depth-2 phase NEST; the Ry-stem angle select.

## Limits (PROTOCOL reviewer row)

NO build, NO suite; at most ONE lit fixture re-run. **NO corpus sweep** (one per session, the merge gate's;
the implementer's own `ir-pass/test` half did not finish, at load 574 and ~3 rows/min) and **no twin matrix**.
Probes into `$SES/trackP/review_r1_probes/` in the MAIN checkout. Never write under
`ir-pass/ include/ runtime/ tests/ tools/` of any checkout. Never relink under a running measurement; never
`pkill` by pattern. **Check every generated `.ll` is non-zero before measuring it** — a 0-byte module
ACCEPTS via the passthrough early-out.

## Verdict — `$SES/trackP/REVIEW_P_R1.md`

Findings **F-P1-<n>**: claim, probe (path + exact commands + both verdicts), severity (**over-ACCEPT /
silent miscompile** · **over-DECLINE** · **fixture/record hygiene** · **documentation**), minimal fix. End
**CLEAR** / **CLEAR-WITH-ITEMS** / **NOT CLEAR**; state what you did not examine; say whether round 2 is
warranted. Rule 2: verify-clean and exit 0 are not evidence — read emitted STREAMS.
