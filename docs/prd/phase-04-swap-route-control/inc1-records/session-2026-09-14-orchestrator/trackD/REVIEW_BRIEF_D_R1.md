# Track D — ADVERSARIAL REVIEW round 1 (Rule 13), bd `3d8q` — the STALE-READER fence

**Subject:** branch `stale-reader-fence`, tip `e7d6efe2`, worktree `/Users/sorenwilkening/Desktop/CQ_3d8q`.
Binary: `cq-opt` `7fe2bcbfb6c9712613952e6db33ab36dc3525275af99109cf0edfe4ea112fb23`, `libCQPass.so`
`4f73e1c8cb5f5924…`. **ORACLE** (main checkout `build/`): `cq-opt`
`f7b65d8ccd7bc472303d13b3c7bd7a78c03d990a4147fe7589ef73a85487b0bc`, `libCQPass.so`
`f9e898badfd4207a758d27638a34b7e147bd3b702e5611b4fad0e0403879039d`.
The implementer's baseline build (no edits) was **bit-identical to the ORACLE**, so every ORACLE-vs-SUBJECT
row is a statement about their edits alone. **FIRST ACT: `shasum -a 256` on both. A mismatch is a FINDING
and you STOP.**

**READ FIRST:** `$SES/PROTOCOL.md`, `$SES/trackD/BRIEF_D.md`, and — in the subject worktree —
`IMPL_D.md` in full (especially §9 the attack surface and §11 the follow-ons). Then `bd show 3d8q` (all
notes), `docs/frontend.md` §3.2 (the linear rule **and** this hole, stated in the spec), and `CLAUDE.md`
Prime Directive + Rules 2, 8, 10, 11, 13, 19 and CORRECTNESS RISK §3 **L1/L2/L3/L4**.

## What this change is, and which way it points

bd `3d8q` is the project's one KNOWN pre-existing silent miscompile: two sibling `cq_theta` on one rail
lower as a chain, because `declineStaleRecordOps` sweeps PURE ops only, so a `cq_theta` or `cq_measure`
**reader** of a stale name is asked by nothing. This increment **widens a DECLINE to remove that**. So the
usual polarity is inverted and **both** directions are in scope:

* an **over-ACCEPT** left behind (a stale reader that still compiles) is the unforgivable class;
* an **over-DECLINE** introduced (a well-formed chain that stops compiling) is a defect under the owner's
  2026-09-11 ruling, not a safety margin. **The fence must be EXACT, not merely conservative.**

Shape shipped (the implementer's **fourth** design, each move forced by a measurement): a pure-analysis
`recordStaleQuantumReaders` **early** (before `lowerLoops`/peel/control, because "an SSA name denotes a
record" holds only for names the USER wrote — the rail-φ collapse, the peel and the one-register lift each
rewrite a wire-tracking name into a wire-base name); the same **delta-scoped** from `adjudicateTaintDelta`
(the L1 payment); and `declineRecordedStaleQuantumReaders` as the **diagnostic** at the last slot before
`lowerRotations` — a backstop, never a preemptor. New string:
`cq opcode lowering: rotation/measure operand predates a non-diagonal gate`. `WireWalk` gains one opt-in
bit `RequireEmitDominance` (default `true`, every existing caller byte-unchanged). `OpcodeLowering`'s
shipped sweep has **zero deleted lines**.

Measured by the implementer: 14 of 14 reproducers ACCEPT→DECLINE; the must-not-move set held with identical
trace-line counts; `ir-pass-lit` 1/1 Passed; `lit` 1935 pass / 1 XFAIL / 0 fail; corpus sweep 3093 rows,
43 movers **all this track's string, ZERO in `e2e/`**; injection 36 mutations over the 3 new accepts,
0 MISSED; `!dbg` anchor check 7/7 real `file:line:col`, 0 `<unknown>:0:0`.

## The attack surface — leads, not a checklist

1. **The `Delta` scope — the implementer could NOT isolate it and says so.** They give a *structural*
   argument that the delta-scoped round-2 re-ask closes the window, and record that **both probes they built
   to break it declined at the condition-wire fence instead**, so the argument is unfalsified rather than
   tested. That is precisely the L1 PREDICATE species. Build a probe where a value becomes a stale reader
   **only in round 2** and where no condition-wire fence stands in front. `S03` is the existing witness that
   round 2 matters (it still accepted at an earlier build).
2. **The `WeakTrackingVH` drain.** A nulled handle **silently drops a decline**. It is intended only when an
   emitter *proved* the shape. Find a path where a handle is nulled for a different reason — a flatten, an
   erase, a RAUW — and the recorded decline evaporates with no diagnostic anywhere. ⚠ `CLAUDE.md` Rule 1:
   "no third path" has been violated exactly once and adversarial review, not the suite, caught it.
3. **`preloop_commit_stale` lost its only positive pin.** That fixture was the **sole positive pin** of
   `diagnosePreLoopCommitStale`; it is now inverted to a DECLINE, and the implementer records the
   compensating argument **explicitly labelled as a plausibility argument, not a measurement**. Ask the
   question they could not: is `diagnosePreLoopCommitStale` now unreachable, vacuous, or dead? A predicate
   whose only positive fixture is gone is exactly Rule 12(c).
4. **THE DEVIATION — adjudicate it.** The brief listed `g2_measure_parent` as **must-not-move**; the
   implementer **moved it to DECLINE**, citing `review_1b_r2.md` §F-1b2-1's boundary table (which lists it in
   the DEFECT row) and that the pure-op spelling of the identical program has declined since Phase 5.
   ⚠ **bd `3d8q`'s own fix sketch says the opposite** — *"the well-formed chain and `cq_measure(b)` on it
   stay ACCEPT (ancestry exempt)"*. Two records conflict. **Decide it on the unitary, not on the records:**
   does measuring the PARENT name after a child rotation name a state the register no longer has? Say which
   record is wrong and why. A one-line revert exists either way.
5. **Leg 2 with a non-φ loop-invariant seed** — reachable for the first time, per the implementer.
6. **The exactness of the fence, in the over-DECLINE direction.** `g3`/`g4`/`l1w`/`m4`/`a02` keep their own
   strings and the must-not-move set held — verify a sample yourself (Rule 11), and hunt for a well-formed
   chain that now declines. The ancestry exemption is L4-shaped: it must be a gate SET with a per-entry
   exemption bit, never a boolean from a return-first walker.
7. **The two fixtures adjudicated "by one operand"** (`fcmp_oeq_twin`, `deadgate_leak_control`) with
   byte-identical emitted streams — verify the streams really are byte-identical and that the one operand is
   the whole difference.

## Limits (PROTOCOL matrix — reviewer row)

**NO build, NO suite**; at most ONE lit fixture re-run. **Do NOT run a corpus sweep** — at most one is in
flight across the session and it belongs to the merge gate (bd memory
`one-corpus-sweep-at-a-time-load-ceiling`). Do NOT run the twin matrix; the implementer has one in flight.
Probes into `$SES/trackD/review_r1_probes/` in the MAIN checkout. Never write under
`ir-pass/ include/ runtime/ tests/ tools/` of any checkout. Never relink under a running measurement; never
`pkill` by pattern. **Check every generated `.ll` is non-zero before measuring it** — a 0-byte module
ACCEPTS (passthrough), and that trap made six of another track's probes vacuous this session.

## Verdict — `$SES/trackD/REVIEW_D_R1.md`

Findings **F-D1-<n>**: one-line claim, probe (path + exact commands + both verdicts), severity
(**over-ACCEPT / silent miscompile** · **over-DECLINE** · **fixture/record hygiene** · **documentation**),
minimal fix. End **CLEAR** / **CLEAR-WITH-ITEMS** / **NOT CLEAR**; state plainly what you did not examine;
and give an explicit verdict on item 4. Rule 2: verify-clean and exit 0 are not evidence — read emitted
STREAMS. The implementer budgeted **≥2 rounds**; say whether round 2 is warranted and on what.
