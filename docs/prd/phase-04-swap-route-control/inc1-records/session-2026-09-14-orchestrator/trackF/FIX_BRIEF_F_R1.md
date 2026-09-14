# Track F — FIX brief for review round 1 (bd `om35`)

Worktree `/Users/sorenwilkening/Desktop/CQ_f2phi`, branch `f2-phi-descendant`, tip `baad186d`.
**READ FIRST:** `$SES/trackF/REVIEW_F_R1.md` in full, then your own `IMPL_F.md`.

The verdict is **CLEAR-WITH-ITEMS** and the review independently re-verified your headline more strongly than
you did (169 peel/stateprep fixtures compared on **lowered IR byte-for-byte**, not exit+string: 1 mover, your
own new fixture; 33 F2-string fixtures, 0 moved; the committed slice read by hand and its stream decomposed
correctly; your boundary marker proven **non-vacuous** by a de-pinning mutation).

**It also answered your round-1 assignment better than "could not build one".** Acyclic: **NO,
structurally** — no pass rewrites an existing value's definition to take an operand that does not dominate
it (invalid SSA), so a pre-region value cannot *acquire* a use of `M` in place; transforms that create
`M`-users create *new* values, and sinking moves a definition without changing operands, which is exactly
why the ≥11 sunk merge-block colliders stay declines and why this predicate is immune where a dominance
conjunct is not. Both thin places were attacked in C: the sideways rewrite went the **opposite** way, and
jump threading *removes* φ uses. Carry that into `IMPL_F.md` — it is a stronger record than what you wrote.

## F-F1-1 — MUST-FIX BEFORE MERGE. Latent over-ACCEPT; the availability ground is falsified by construction.

`collectStatePrepPhiDescendants` (`ArmClassify.cpp:1522-1548`) walks `V->users()` with **no dominance
filter**, so a **loop-header φ that takes `M` on the BACK EDGE** lands in `PhiDesc` — and such a φ
**dominates the arm *and* the pred edge**, i.e. it **is** available at both of F2's slots. Your header's two
bullets are theorems only for an **acyclic** user chain; a cycle falsifies them.

Measured: `p8_backedge_phidesc.ll` — ORACLE fires F2, SUBJECT does not (falls through to `control flow
inside a loop body`). Isolating control `p8c` (same module, carried φ reading a condition-derived value
instead of `M`) declines with F2's string on **both**.

**It is not an over-accept today**, because a φ can only be slot-available via a cycle and every in-loop
state prep declines. **But that is held up by bd `wx8g` — an open over-decline the owner has ruled a defect
to remove, and which Track W is building THIS SESSION** — and `ControlDetect.cpp:632-666` shows in-loop
regions do reach `classifyArms`. Your written retirement triggers do not name it.

**Fix (the reviewer's, 2 lines inside the helper):** skip a φ user not dominated by `M`'s block. Note
carefully that this is a **NARROWING of the exclusion set**, so it is **not** the refused dominance conjunct
(that one would narrow the *collider* set) — say so in the source comment so nobody "simplifies" it later.
Measured zero cost on all four customers. **Commit `p8`/`p8c` as a fixture PAIR**, and add `wx8g` to the
retirement triggers by name.

⚠ Your fix is itself a Rule-13 core edit and round 2 will start here.

## F-F1-2 — documentation (L7), and it leaves your worktree for `CLAUDE.md`

Your compressed ground — *"the φ is defined at the join, so a value using it is available at neither"* —
**is** the refused dominance argument, and sinking defeats it. The load-bearing step is the **OPERAND** one:
`M` is not available at the slot, so `V` cannot be spelled there **in any module**. Only your source header
states it correctly. Fix the compressed form everywhere it appears, because the orchestrator carries that
paragraph into `CLAUDE.md` and a wrong compression becomes the project's record.

## F-F1-4 / F-F1-5 / F-F1-6

* **F-F1-4** — "does not touch `Truncated`" is imprecise: a TEST decline can become a `Truncated` decline.
  Direction is safe; restate it precisely.
* **F-F1-5** — your L1 answer proves **recomputation**, not **stability**, and the RAUW drift direction is
  the **ACCEPT** direction. Unresolved by analysis alone; it is the L1 PREDICATE species. **Do not close it
  by assertion** — write it up as the round-2 assignment with the specific drift you cannot rule out.
* **F-F1-6** — duplicate-body count: reviewer 8, you 9 (normalization delta). Both new fixtures unique.
  Reconcile the two counts and say which normalization each used.

## F-F1-3 — do NOT fix; it is the merge gate's, and I am recording it there

An `undef` seed is refused at **F1**, before F2, on both binaries (`p9_undef_seed.ll`). Track U normalizes it
to a concrete zero **before classification**, which turns `p9` into your accept fixture byte-for-byte — so on
the **merged** binary `p9` goes **DECLINE(F1) → ACCEPT**, a transition **neither track's sweep can see**.
Hand `p9_undef_seed.ll` to the merge gate as a named probe; do not try to measure it yourself.

## Gates you own (PROTOCOL matrix — FIX-agent row)

`cmake --build build -j8` (**never `--target CQPass` alone**); record the new `shasum -a 256` in
`GATES.md`. Re-run: the finding's probes (`p8`, `p8c`, all four customers), every fixture you touched, and
**`ctest -R ir-pass-lit` ONCE** (pass source changed). **NO corpus sweep** — one per session and it belongs
to the merge gate; your earlier sweep result stands for the pre-fix binary and must be labelled as such.
**NEVER** the full suite, `^e2e-`, the equivalence sweep, or the twin matrices.

⚠ Every gate line you recorded against `147cb3d6` becomes **void for the new binary** — re-record, do not
carry forward, and say which lines are cited-for-the-old-binary versus re-run.

## Deliverable

Update `IMPL_F.md` and `GATES.md`, add `FIX_F_R1.md` with each finding's disposition, commit on the same
branch with the two `CLAUDE.md` trailers. Report: new tip, new binary hash, `p8`/`p8c` before/after on both
binaries, the four customers re-measured, the corrected ground paragraph (verbatim, for `CLAUDE.md`), the
reconciled duplicate-body count, the round-2 assignment for F-F1-5, and every gate line as `ran:`/`cited:`.
