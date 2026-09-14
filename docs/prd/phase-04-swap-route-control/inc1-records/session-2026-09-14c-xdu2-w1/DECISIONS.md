# Owner decisions — session 2026-09-14c (bd `xdu2` W1, the bounded rail ARRAY)

Asked by the orchestrator at session open, from
`…/session-2026-09-14b-railbank-design/NEXT_SESSION_PROMPT.md` §3 ("three are blocking").
Answers are the owner's selections, verbatim option labels; the rationale text below each is the
orchestrator's record of what was put to the owner, not a rule (Rule 0 / L7 — a rule lives in
`CLAUDE.md`, `ROADMAP.md` or a PRD, never in a record).

---

## D1 — uninitialized `bool b0[3]`: **COMPOSE WITH bd `z9t1`**

The owner's `example/grover/grover_oracle_uncompute.c` writes `bool b0[3];` with **no `= {0}`**.
SCOPE_L1a's clause **C1** requires a proven constant-zero initializer (the `llvm.memset` arm of the
alloca-wide user scan, `QramLowering.cpp:1953-1971`), so the bank as scoped would **refuse the owner's
literal file** — over-declining the very program the increment exists to compile.

**RULED: extend bd `z9t1`'s undef-seed rule to the bank's per-cell seed.** An uninitialized bank
cell's seed normalizes to the type's concrete zero **at the allocation**, which is the same rule
`normalizeUndefRotationSeed` (`RotationLowering.cpp`) already ships for a scalar `undef` seed at a
SOURCE `cq_theta`. C1 therefore admits an alloca with **no** initializer as well as one with a
constant-zero memset.

⚠ **Consequences that must be carried, not discovered:**
* `z9t1`'s **DISCLOSURE** extends to the bank verbatim — a program that was LOUDLY REFUSED now compiles
  SILENTLY, no fence can separate the readings after `-O1`, and **no warning is added** (owner, 2026-09-14:
  *"both codes are supposed to compie!! also no warnings."*). The bank's disclosure paragraph owes the same
  two halves `CLAUDE.md` §4c requires: the rival reading stated **as a program**, and why it has **no
  lowering to be robbed of**.
* `z9t1`'s three **RETIREMENT TRIGGERS** (`CLAUDE.md` §4c) now have a second customer. Re-read them before
  touching the composition; in particular trigger (ii) — *the clause rewrites anything that is not
  `isa<UndefValue>`, or `undef` stops being uniqued per type* — is the composition's only two load-bearing
  facts as well.
* SCOPE_L1a §7 filed this as *"a composition question, not a blocker"*. It is now a **ruled composition**.

## D2 — bd `s82e` (P1): **PROVE IT**

The rolled value arm leaves entangled which-path rails (validated target: 16 handles minted, 6 freed,
**6 left over** — `h0 h5 h10` superseded `a`, `h3 h8 h13` the `a-3` temporaries).

**RULED: the leftover rails are ENTANGLED, so "left allocated" is the CORRECT circuit** (Rule 6's
accepted qubit leak in the qubits-not-scarce regime — freeing them would be a hidden measurement that
collapses the register). **The defect is that `markIfRailLocal` reaches that outcome by a SILENT
refusal rather than a proof.** Turn the silent refusal into an explicit, proven *"left allocated
because entangled"* disposition.

**NOT ruled, and explicitly rejected:** DECLINE (it would decline the rolled cascade the owner asked
for — an over-decline by the 2026-09-11 ruling, and W3 would land on it) and DISCHARGE (freeing an
entangled which-path rail is the Rule-6/Rule-8 hidden measurement).

⚠ The bead's own text recommends the decline. **This ruling supersedes it**; `bd update s82e` carries
the ruling.

## D3 — the `staleRailRecordRead` grouping key: **REFUSE LOUDLY, THEN MEASURE**

`staleRailRecordRead` is grouped per **ROOT MINT** (`ChainsByRoot` `LoopLowering.cpp:2525`, `ByRoot`
`:2296`). A bank rail has no root mint. `b[0]` and `b[1]` are **distinct rails sharing one alloca**
while **one cell across trips is one rail**, and nothing in the tree expresses that relation.
SCOPE_L1a §8.2 proposes `(alloca, index SCEV)` and calls it **UNMEASURED** — explicitly not a settled
clause.

**RULED: ship W1 with a LOUD decline for any bank rail that would reach `staleRailRecordRead`, and let
Rule-13 round 1 MEASURE whether the owner's program needs the key.** Build `(alloca, index SCEV)` only
if the measurement says it is needed, as its own red-green increment.

⚠ **Rule 17 check, stated so it is not mistaken for a punt:** this is a decline of an
*unproven-precondition input*, not a decline substituted for the lowering we set out to build. If round
1 measures that the owner's cascade **does** reach this fence, the decline becomes an over-decline and
the key must be built — bring it back to the owner at that point rather than shipping the refusal.

---

## Carried, still open with the owner (not asked this session)

bd `dnqo` (is an `undef`/`poison` ROTATION ANGLE a loud decline? — F-U1-1), bd `fve8` (the F-U3-1
disposition: the φ clause disarms ruling clause 4 upstream of `cq_measure`), bd `yiid` (is a
measurement a BARRIER or a RELABEL — `cq_measure` is not modelled as a wire event at all).
