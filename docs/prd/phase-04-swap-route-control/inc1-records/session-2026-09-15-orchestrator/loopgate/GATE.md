# loopgate — THE GROUP GATE (loop-group: Track S′ × Track T × bd `emkg` × Track D)

Branch `loop-group-gate`, worktree `/Users/sorenwilkening/Desktop/CQ_LOOPGATE`.
Every gate line is hash-keyed in **`GATES.md`** (`ran:` vs `cited:`, plus a "NOT run, and why"
section and an erratum against this gate's own instrument). The merge resolutions and their reasons
are in **`MERGE.md`**; the corpus table is **`ATTRIBUTION.md`**; Track D's number, with both
caveats, is **`TRACKD_NUMBER.md`**.

| binary | `cq-opt` sha256 |
|---|---|
| ORACLE (`main` `74eabd2c`) | `0e280fc62a91cec2336769edde8a873563a21ee4869744331a0fcf6811549c6d` — verified at gate open **and at gate close**, unmoved |
| **MERGED** | **`f2ee2eb69f1cdf9b70df9e33d1c169870c0b533e8753230741a648d9f101170b`** (`libCQPass.so` `7e5ec2d764789959…`) |

## VERDICT: **GREEN**, with three things that are green-and-not-cleared

**Every gate this group owed was run, once, on the merged binary, and every one passed.**

| gate | result |
|---|---|
| full `ctest -j6` | **446/446 passed, 0 failed, 2458.29 s** |
| `e2e-loop-twin-matrix` (inside it, the owed single run) | **Passed, 2087.81 s, 338 cells, 0 moved, NO axis skew** |
| `cq-opt-equivalence-full` | **2051 fixtures, 0 mismatches** |
| corpus sweep, ORACLE vs MERGED | **90 movers, 0 UNATTRIBUTED** |
| **Track D env-gate, unset** | **BYTE-IDENTICAL sweep files vs the Track-D-free control — 0 movers / 4220 rows** |
| L8 duplicate-body scan | **9 duplicate groups, 0 contradictory verdicts** |
| S1 three post-union checks | **0 duplicate names; 432 + 4 = 436; sweep still LAST** |
| the two re-derivations (trap 1) | **both HOLD on this binary** |
| adversarial probe G1 (the gate's own) | **DECLINES, source-located to the right half** |

⚠ **The load it ran under is part of the result.** The full `ctest` started at load **3.99**, peaked
at **53.69** mid-run from other agents' work, and ended at **14.92**; wall clock was **40:59** against
the 130–230 s `CLAUDE.md` quotes for a quiet box. **That figure is not comparable to any other run**
and must not be cited as a timing regression. It cannot have produced a false pass either —
contention causes false FAILURES, never false passes — and there was nothing red to re-run serially.
There is **no ctest timeout configured** in this tree (`enable_testing()` only, no
`DartConfiguration.tcl`), which is why a 2087 s twin matrix completed instead of being killed.

## What is GREEN AND NOT CLEARED — say it in these words

1. **The fix agent's two merge-derived conversions** (`loop_leak_dephase_reject_cmp_rail_data.ll`
   and `…_reject_inloop_rotation.ll`, both shipped DECLINE fixtures that the S′ × T composition
   silently turned into ACCEPTs) **were cleared by the agent that merged them, by measurement, and
   by no independent review.** This gate **re-derived both on its own binary** and both hold —
   `c1` at **14 == 14 byte-identical**, `c2` at **24 == 24 with an empty gate multiset and a
   positional difference** — but a re-measurement by the gate is a *third* measurement, not a second
   opinion. **Rule 13 asks for a reviewer.**
2. **`r3`'s composition** (the `emkg` fix × Track S′'s conjunct-(3) `icmp`-as-data widening) is in
   the same position: measured, in the safe direction, reviewed by nobody.
3. **The A × B composition this gate found for itself** — four programs S′ **refuses** and T
   **accepts**, where the merged binary takes T's verdict (`ATTRIBUTION.md` §4). S′'s Rule-13 round
   saw a binary on which they decline; T's saw one on which S′'s refusal does not exist. All four
   agree with their hand-unrolled twin on the merged binary. **A composition is not cleared by
   clearing its parts** (`CLAUDE.md` §4c, the F × P precedent).

## The merge — four conflicts, none resolved by side

Three files conflicted (Track D is based on `dephase-fence-r2`, not on the fix branch).
`LoopPlan.h` and `LoopLowering.cpp` are **unions of disjoint additions**; `CQLoweringPass.cpp`
auto-merged and was **verified rather than trusted** (both entry points, five stages, both slot
contracts). The fourth is the one that mattered: Track D's `DEFER` instrument pin sat on a fixture
Track T's pairing turns into an **ACCEPT**, so taking Track D's side is a red suite and taking HEAD's
side **silently drops the instrument's only safety pin**. **Track D's own L8 retirement trigger named
this event and the action**, so the pin was **relocated** — host chosen by measurement, validated by
binary mutation, and **strictly stronger** in its new home because that module also warns. Full
reasoning in `MERGE.md` §4.

## Findings

**None.** Nothing red, nothing unattributable, nothing in the over-accept direction that the group
does not account for. Two things were opened rather than assumed and both came back benign:

* the **four `A→A` movers with an empty call-count delta** — a `declare` list ORDER change only,
  every instruction byte-identical (a multiset equality is not an identity, so they were opened);
* the **three `D→A` twins with a non-empty multiset** (`t3_cmp_rail_data` at **20 vs 20**, exactly
  trap 3's shape) — all three are **twin-fidelity / `-O1`-canonicalisation** artefacts with the
  ROLLED side fully discharged in every case. `ATTRIBUTION.md` §5.

## Filed, for whoever picks this up

* **`r2_two_functions` accepts with a per-function asymmetry** — `ka()` discharged, `kb()`'s hoisted
  TEMPLATE rail and its two shifts left allocated (the half Track T states it did not build,
  bd `1m5p`). Benign **only** because `kb()` has no post-loop non-diagonal gate. The gate added
  **`probes/g1_twofn_kb_rotated.c`**, which adds exactly that gate, and it **DECLINES on all five
  binaries**, source-located to `kb` at `:23:39`. ⚠ **And its hand-unrolled twin ACCEPTS, at 31 trace
  lines** — so the flat spelling *does* perform the discharge the rolled one loses, which makes the
  rolled decline exactly the compiler-consistency divergence this fence exists to refuse, rather than
  a decline of convenience. The boundary holds; it is now a committed probe rather than an argument.
  Worth promoting to a fixture.
* **A stray `cq-opt` (PID 84129) hung 9 h 02 m** on
  `trackT/probes/adv/out/b1_mixed_nonlive.sub.s1.ll`, from another worktree. **Not killed** (never
  `pkill` by pattern). This gate's sweeps read that same module on both binaries without hanging, so
  it did not reproduce here — but a possible pass hang deserves someone's attention, and it inflated
  the load figures above.
* **`bd gahu` gains a third and fourth un-renamed `*_reject_*` file that is an ACCEPT** — and this
  gate leaves them un-renamed for the reason the bead exists (L8: a `git mv`'d fixture can be
  resurrected by a merge).
