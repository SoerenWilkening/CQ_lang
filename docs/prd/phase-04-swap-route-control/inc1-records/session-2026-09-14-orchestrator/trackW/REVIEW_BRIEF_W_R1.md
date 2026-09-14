# Track W — ADVERSARIAL REVIEW round 1 (Rule 13), bd `wx8g` — the in-loop ITERATION-LOCAL rail

**Subject:** branch `inloop-bool-prep`, tip `11fc1b3c33ae9b14cecd7ec5c6b120e606ff9d9d`, worktree
`/Users/sorenwilkening/Desktop/CQ_wx8g`. Binary `cq-opt`
`daeb93a36bdc57b3cbb769eaf88bb71c784671989747a2b582bbc50e352308d2`, `libCQPass.so`
`2f7ed0a69fbda48dcead831db242ced39da0209ad731fd1bf6e5178b97152090`.
**ORACLE**: `cq-opt` `f7b65d8ccd7bc472303d13b3c7bd7a78c03d990a4147fe7589ef73a85487b0bc`, `libCQPass.so`
`f9e898badfd4207a758d27638a34b7e147bd3b702e5611b4fad0e0403879039d`. The implementer's clean **pre-edit**
build was **bit-identical to the ORACLE**, so every "before" number is an ORACLE number by construction.
**FIRST ACT: `shasum -a 256` on both. A mismatch is a FINDING and you STOP.**

**READ FIRST:** `$SES/PROTOCOL.md`, `$SES/trackW/BRIEF_W.md`, and — in the subject worktree — `IMPL_W.md`
in full (§7 is the attack surface, §9.3 the owed cells). Then `bd show wx8g`, `bd show l4x4`,
`$SES/trackL/SCOPE_L1a.md` §0 (why this is wall 2 of three), and `CLAUDE.md` Prime Directive + Rules 1, 5,
6, 7, 8, 9, 12, 13, 19 and CORRECTNESS RISK §1 (in-loop rows), §2 ("Loop scope"), §3 **L1/L2/L4**.

## What shipped — two halves, and the first is a RETIREMENT

1. **The l4x4.b in-loop rail carve-out is RETIRED.** The implementer argues it was an increment boundary,
   not a fence (l4x4.b's own comment: *"NOT refused for any reason intrinsic to the shape"*), and measured
   both stated reasons false: *"no oracle twin"* is true of the **compare** twin and irrelevant, because the
   discipline is rolled-vs-**hand-unrolled** and that twin is l4x4.b's own flat capability; *"it is the C-1
   mixture"* is **vacuous for a rail**, because a bare `_Bool` condition **mints nothing and derives
   nothing**, so the per-trip condition chain whose leak is the C-1 signature has no subject. **Nothing
   replaces it** — the region falls through to R7. ⚠ **Retiring a fence is the highest-risk move in this
   codebase. Attack both arguments.**
2. **R7-loop clause (c), the ITERATION-LOCAL rail.** (c1) the rail does not cross the back edge, asked
   *positively*; (c2) minted fresh every trip by an Ry **inside** `L`, by **calling** `railChainRootMint`
   (`railPhiRootMint`'s tail factored out — Rule 14), with `L->contains` where (b′) has `DT.dominates`, and
   `MintSeed = T` for a state prep; (c3) nothing tainted defined in `L` is read outside it.

## Claimed witnesses — verify a sample yourself (Rule 11), do not restate

8 of 8 rolled/hand-unrolled pairs **byte-identical** (8/10/12/9/11/27/17/14 trace lines) + 5 committed twin
gates; **K-independence** of the lowered IR at `-DCQ_K=3` *and* `-DCQ_K=1000` (81/66/85/83/105 lines);
`ir-pass-lit` Passed 169.24 s, `lit` 1937 passed / 1 XFAIL of 1938; 15 new e2e entries 100%; **a COMPLETE
corpus sweep over the lit corpus (1983 `.ll`) + 20 probes: 3 movers, all DECLINE→ACCEPT with the ORACLE
string `control flow inside a loop body`**, 0 CLANGERR; injection applied 40, MISSED 0, N/A 5; vacuity 29
negatives, 0 VACUOUS.

**(c3) is claimed as a UNITARY fence with a measured pair:** with (c3) absent, a program whose per-trip
register **escapes** the loop gives **19 rolled vs 27 unrolled** trace lines — two entangled which-path rails
leaked per activation — while the same program measured **inside** the body is byte-identical. `opt` exit 0,
verify-clean, STRICT 2b `0 violation(s)` on all four. **That is the increment's central safety claim.
Re-derive it.**

## The attack surface — leads, not a checklist

1. **The carve-out retirement (half 1).** Is *"a bare `_Bool` condition mints nothing and derives nothing"*
   true on every path, or only on the ones probed? Find a bare-`_Bool` in-loop shape where something IS
   minted or derived per trip. This is the C-1 leak family, and `CLAUDE.md` records it as 8 instances over
   6 rounds on one function, two of them **introduced by a fix**.
2. **(c3)'s `L4` status, which the implementer flagged.** (c3) returns the **first** offender. They argue
   that is sound *here* because it has **no exemption** — a pure ∀, no `WireRuled` bit — and recorded a
   retirement trigger if one is ever added. **L4 says a wire question must be a gate SET, not a boolean over
   a return-first walker.** Decide whether the exemption-free argument actually holds, or whether an
   already-accepted construct can be placed in front of an unaccepted one.
3. **The L1 record-and-re-ask.** Clause (c)'s grant is RECORDED (`TaintSet::RolledIterLocalGates`) and
   re-asked by `declineUnmarkedRolledIterLocal` in **both** entry points after the fixpoint, on two
   conjuncts. It **caught a real hole** (`w_j`: a loop whose every register is iteration-local gets no root,
   so `markIfRailLocal` is never called) and **over-declined four correct programs** until conjunct 2 was
   gated on `bodyHasSpineDischargeCandidate`. **That gating is where a hole would now be** — is
   `bodyHasSpineDischargeCandidate` the right question, or a proxy for it?
4. **The implementer's own three (IMPL_W §7).** **H-1** a clause-(c) loop with a second still-standing
   tainted branch where the marking was granted at round 1 (marking is additive; not built). **H-2** the
   mixed loop — a clause-(c) rail beside a carried one whose exit value is read — an over-decline today,
   but widening (c3) to a real root set **inverts** their monotonicity argument. **H-3** the `cq_theta_`
   family test in (c2), believed structurally unreachable and therefore deliberately given **no** fixture.
   ⚠ **An unreachable negative is a vacuous one — but "believed unreachable" is a claim to attack, not a
   reason to skip.**
5. **`staleRailRecordRead` — "it does not become anything".** The claim is that the fence is **never asked**
   about a clause-(c) rail, structurally, because both call sites reach it only through a chain built from a
   tainted **header φ** which (c1) proves absent; and that the obligation is discharged because an
   iteration-local rail is a different physical register each trip, so no name spans two activations —
   *unless it escapes, which (c3) refuses*. **That is a two-step argument resting entirely on (c1) ∧ (c3).
   Break either.**
6. **Over-DECLINE direction.** The four programs conjunct 2 over-declined were caught by the implementer.
   Find the fifth. The owner's 2026-09-11 ruling makes an over-decline a defect, not a margin.

## Limits (PROTOCOL matrix — reviewer row)

NO build, NO suite; at most ONE lit fixture re-run. **NO corpus sweep** (one per session, owned by the merge
gate) and **NO twin matrix** (328 cells, ~998 s). Probes into `$SES/trackW/review_r1_probes/` in the MAIN
checkout. Never write under `ir-pass/ include/ runtime/ tests/ tools/` of any checkout. Never relink under a
running measurement; never `pkill` by pattern. **Check every generated `.ll` is non-zero before measuring
it** — a 0-byte module ACCEPTS via the passthrough early-out.

## Verdict — `$SES/trackW/REVIEW_W_R1.md`

Findings **F-W1-<n>**: claim, probe (path + exact commands + both verdicts), severity (**over-ACCEPT /
silent miscompile** · **over-DECLINE** · **fixture/record hygiene** · **documentation**), minimal fix. End
**CLEAR** / **CLEAR-WITH-ITEMS** / **NOT CLEAR**; state what you did not examine. The implementer budgeted
**3 rounds**; say whether round 2 is warranted and on what. Rule 2: verify-clean and exit 0 are not
evidence — read emitted STREAMS.
