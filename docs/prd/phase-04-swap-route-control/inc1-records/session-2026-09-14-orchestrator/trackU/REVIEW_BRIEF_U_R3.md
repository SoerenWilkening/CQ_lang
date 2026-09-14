# Track U — ADVERSARIAL REVIEW round 3 (Rule 13), bd `z9t1` — SCOPED TO THE φ CLAUSE ONLY

**Subject:** branch `undef-seed-zero`, tip `4044e49ea239bd4ce1a70457dbf5d17718714886`, worktree
`/Users/sorenwilkening/Desktop/CQ_undef`. Binary `cq-opt`
`a5773be142835fb8a7f0f5a324934d48698c93c12ee231ce8b2c5406741885ff`.
**ORACLE**: `cq-opt` `f7b65d8ccd7bc472303d13b3c7bd7a78c03d990a4147fe7589ef73a85487b0bc`,
`libCQPass.so` `f9e898badfd4207a758d27638a34b7e147bd3b702e5611b4fad0e0403879039d`.
**FIRST ACT: `shasum -a 256` on both. A mismatch is a FINDING and you STOP.**

## Why this round is NARROW, and why it exists anyway

Round 2 (`$SES/trackU/REVIEW_U_R2.md`) produced a **corpus-wide closure**, not a sample: it injected an
undef seed into every `@cq_theta_*` across the corpus and compared `SUBJECT(undef seed)` against
`ORACLE(concrete-zero seed)`. On all **1922** fixtures containing a theta there were **0 real divergences,
0 ACCEPT→DECLINE, and 0 new undef reaching any emitted gate**, with nine linked-and-run traces byte-identical
to their zero twins. Attacking more *shapes* therefore re-asks a question already answered uniformly —
round 2's own recommendation, which is accepted.

**One half of the rule is NOT covered by that closure, and it is the half that goes beyond the owner's
ruling.** The ruling is about the **seed**. The implementation also normalizes an `undef` **φ incoming**,
gated on "that φ carries that theta's own result". The zero twin **cannot emulate** that half, so round 2
measured it on **7 modules, not 1922** — and round 2 also found (F-U2-2) that the record's description of its
scope, *"only where the object was undefined on BOTH edges"*, is **false**. A widening beyond the ruling,
with a wrong recorded scope, measured on seven modules, is exactly where a hole would still be.

**This round is scoped to the φ clause and nothing else.** Do not re-attack the seed clause; do not re-run
round 2's sweep; do not re-litigate F-U1-1 (the owner holds it).

## What to attack

1. **Build the instrument round 2 could not.** It says it "could not synthesize phi-incoming injection
   soundly". Say why, then either build it or state precisely what makes it unsound and what the best
   available approximation measures. A population of 7 is the finding if you cannot enlarge it.
2. **The gate: "that φ carries that theta's own result."** Attack it directly. A φ with three or more
   incomings; an `undef` incoming on an **unreachable** edge; a φ whose other incoming is a *different*
   theta on the same rail; a **chained** φ (a φ of a φ); a **loop header** φ whose backedge incoming is the
   theta and whose preheader incoming is `undef`; a φ that carries the theta's result **and** something the
   program wrote. For each: does normalization change which region F1/F2 classify, which value
   `condProvenance` seeds from, or which rail a fence walks?
3. **The corrected scope, and `MergePhiPeel`'s P3b.** Round 2 measured that the false half of the recorded
   scope **disarms P3b**, a deliberate decline-*keeping* gate, and that the outcome is nonetheless sound
   (`pC_peel_p3b_carrier.ll`: `control flow` → peel fires → F2 declines, exactly the zero twin). **Verify
   that soundness yourself rather than inheriting it**, and find whether any *other* decline-keeping gate is
   disarmed the same way and is NOT saved by a downstream fence. The peel manufactures tainted values and
   grows the taint set — L1's TAINT-GROWTH species.
4. **Round 2's own residual.** It states the φ half is "the least-measured clause". Take its seven modules
   as the floor, not the ceiling.

## Limits (PROTOCOL matrix — reviewer row)

NO build, NO suite; at most ONE lit fixture re-run. **NO corpus sweep** (one per session, owned by the merge
gate) and **no twin matrix**. Probes into `$SES/trackU/review_r3_probes/` in the MAIN checkout. Never write
under `ir-pass/ include/ runtime/ tests/ tools/` of any checkout. Never relink under a running measurement;
never `pkill` by pattern. **Check every generated `.ll` is non-zero before measuring it** — a 0-byte module
ACCEPTS via the passthrough early-out, and that trap made six probes vacuous elsewhere this session.

## Verdict — `$SES/trackU/REVIEW_U_R3.md`

Findings **F-U3-<n>**: claim, probe (path + exact commands + both verdicts), severity
(**over-ACCEPT / silent miscompile** · **over-DECLINE** · **fixture/record hygiene** · **documentation**),
minimal fix. End **CLEAR** / **CLEAR-WITH-ITEMS** / **NOT CLEAR**, state what you did not examine, and give
an explicit answer to: **is the φ clause safe at a population larger than seven, and what is the largest
population you achieved?** Rule 2: verify-clean and exit 0 are not evidence — read emitted STREAMS.
