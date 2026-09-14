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

---

## D4 — bd `s82e` RE-RULED, because D2's premise was measured FALSE: **DECLINE THE DIVERGENT SUB-CASE NOW, FILE THE PAIRING**

Track S tested D2's premise before writing a fix, as its brief required, and returned **(R-diverge)**.
The orchestrator verified the two traces independently before putting the re-ruling to the owner.

**bd `s82e` is TWO classes, and D2 was shown only one of them.**

* **The benign half — D2 is RIGHT here.** The bead's own three exhibits (`w2k_noregion_invread`,
  `w2h`, `w2h3`) leak a rail entangled only with a **per-trip** register that is dead after the trip
  and is left allocated in **both** spellings. Their joint garbage never reaches the retained
  subsystem. Likewise D2's cited evidence — *"`h0 h5 h10` superseded `a`, `h3 h8 h13` the `a-3`
  temporaries"* — is **superseded value rails**, which cannot be uncomputed without destroying the
  answer that replaced them. That is a real Rule-6 accepted leak.
* **The divergent half — D2 is FALSE here, and it is a verify-clean silent miscompile.** An
  **interior template rail** left entangled with a register that is **still live and re-rotated
  afterwards**. Measured on `s1_live_shift.c` (10 trace lines rolled vs 14 unrolled, **no tainted
  control flow at all**) and `s2_live_derived_region.c` (19 vs 25), with `s3_live_rootmint_region.c`
  as the positive control at **22 == 22**. All ten modules: `opt` exit 0, verify-clean, STRICT 2b
  `0 violation(s), 0 unproven`, identical on the ORACLE — **pre-existing**.

**The verified mechanism, off the traces:** `cq_template_lshr_i32_hl(h0,1) -> h1` is **out-of-place**
— CNOTs from `y`'s qubits `j ≥ 1` onto a fresh rail, a which-path copy. The unrolled twin emits
`cq_template_lshr_i32_hl_unc(h1, h0, 1)` **then** `cqrt_free(h1)`; the rolled form emits **neither**.
So at the later `cqrt_ry_i32(h0, 0.9)` the rolled form rotates a **dephased** reduced state and the
unrolled form a pure one, and `cqrt_measure_i32(h0)` is the program's observable. Per qubit the
`αβ·sin(0.9)` cross term is present in one circuit and absent in the other; `α,β ≠ 0` on every qubit
(`cqrt_alloc_i32(5)` + tensored `cqrt_ry_i32(h0, 0.5)`). Rule 8 verbatim: *"a permutation that leaves
a rail dirty **and entangled** still dephases under later interference."*

⚠ **D2's dichotomy was wrong about DISCHARGE, and that is why it must be re-ruled rather than
refined.** D2 rejected "discharge" reading it as *free the entangled rail* — which would indeed be
the Rule-6 hidden measurement. **The twin does not do that.** It emits **`_unc` FIRST** (the adjoint,
which disentangles and restores `|0⟩`) and **only then** `cqrt_free` — Bennett, Rule-6 compliant, and
**already what this same compiler emits for the straight-line spelling of the same source.** `s3`
closes it from the other side: the identical interference pattern in a shape `invariantRegisterRoots`
serves is rolled == unrolled, with the `_unc` and both `cqrt_free` **inside** the loop body block.
**This is a closure/slot gap, not a physics wall.**

**RULED (owner, 2026-09-14c):** ship a **LOUD decline for the narrow divergent sub-case only** — a
rail left entangled with a register live after the loop — and **file "build the in-loop pairing" as
the capability**. Rationale as put to the owner: it closes an open **P1 silent miscompile in this
session**, it is far narrower than the blanket decline D2 rejected, and it **does not touch the
owner's rolled cascade**. The cost is stated and accepted: programs that could be compiled correctly
decline until the pairing is built.

⚠ **Rule 17 check.** This is **not** a punt. These programs do not currently receive a valid circuit
— they receive an **invalid** one — so declining them is the Prime Directive, not an over-decline,
and the 2026-09-11 *"do not decline code that leads to a valid quantum circuit"* ruling does not
reach them. The decline is the **interim**; the pairing is the **end state** and is filed, not
forgotten.

**ROOT-CAUSE REFINEMENT that lands with this, because the bead points at a site that never runs for
its own exhibits.** `markIfRailLocal`'s *"accumulating loop-invariant tainted input"* clause fires
for **none of the five** leaking programs: `collapseFlattenedLoopRails` opens
`if (taint.InLoopFlattenedPreds.empty()) return;` and that map is filled only by an **in-loop region
flatten**. So `w2k` / `s1` (no tainted control flow) are refused at **`markIfIterationLocal`**
(`LoopLowering.cpp:2459-2464`), whose identical clause has **no `invariantRegisterRoots` escape at
all**; and `w2h` / `w2h3` / `s2` are refused because `invariantRegisterRootsImpl` clause (ii) returns
false — for `w2h`/`w2h3` because **`-O1` LICM hoists `y & 1` into the preheader**, so the body reads a
hoisted **template** rail. **A fix aimed where the bead points would move zero programs.**

⚠ **L1 — the fix's slot carries a LIVE window.** `markIfIterationLocal` runs inside `lowerLoops`
(`CQLoweringPass.cpp:393` / `:1000`), i.e. **before** `repropagateControlMerges` (`:509` / `:1027`) —
**round-1 taint in both entry points, never re-asked.** That is L1's PREDICATE species. The decline
owes record-and-re-ask in **both** entry points.
