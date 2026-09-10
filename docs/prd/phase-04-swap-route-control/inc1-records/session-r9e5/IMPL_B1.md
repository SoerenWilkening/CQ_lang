# IMPL_B1 — bd `test_C_libtooling-r9e5`, sub-increment 1b-B.1: the 4.4 DATA select on a bare `_Bool` (rail-root) condition

Session `01NHxGVinGBKbb499HFCuwhT`, 2026-09-10, branch `3qlq-inc1b-b-rail-select` (off `main` 87d0699).
Implementation record. Everything numeric below was MEASURED with the command shown (Rule 19); nothing is
estimated. **NOT COMMITTED** — the tree is left building and green for the orchestrator.

---

## 1. What changed — four files in `ir-pass/`, and nothing else there

`git diff --stat -- ir-pass/` (excluding the fixture):

```
 ir-pass/include/ArmAnalysis.h   |  23 +++++
 ir-pass/include/CondTreeEmit.h  |  39 +++++++-
 ir-pass/src/ArmClassify.cpp     |  73 ++++++++------
 ir-pass/src/CondTreeEmit.cpp    |  43 +++++++-
 ir-pass/src/SelectClassify.cpp  |  97 +++++++++++++++---
 ir-pass/src/SelectMergeEmit.cpp |  48 +++++++--
```

Untouched, deliberately: `SwapRouteEmit`, `AngleSelectEmit`, `ClassicalCallArmEmit`, `Specialization`,
`ArmClassify::classifyArms`, `runtime/`, `tools/opcode_table.yaml`, `include/CQ.h`. **No new runtime
symbol, no ABI change** (owner D3): the merge already minted `cqrt_copy_<W>_controlled`, and the flag
mint is `cqrt_alloc_i1` + `cqrt_cnot`, both frozen and both already emitted by the Inc-1b nest.

### (a) `CondTreeEmit` — the rail-root COPY FLAG (`CopyRailRoot`)

* `ir-pass/include/CondTreeEmit.h:112-121` — `CondNetwork` gains `RailRoot` / `RailRootFlag`.
* `ir-pass/include/CondTreeEmit.h:136-158` — `emitCondNetwork` gains a trailing
  `bool CopyRailRoot = false`, so all five pre-existing call sites are textually and behaviourally
  unchanged (`grep -rn 'emitCondNetwork(' ir-pass/src` = 5 sites; only `SelectMergeEmit`'s passes it).
* `ir-pass/src/CondTreeEmit.cpp:113-126` — `CopyRoot = CopyRailRoot && isCondRailLeaf(Root)`, decided
  BEFORE any emission, and the i1 allocator is now resolved when `CopyRoot` holds too (a bare rail root
  has no nodes, so it was previously not resolved at all). A resolution failure is still `Malformed`
  with nothing emitted (the ziov.4 detect-before-mutate discipline).
* `ir-pass/src/CondTreeEmit.cpp:194-217` — the mint, LAST in the network: `bf = cqrt_alloc_i1(0)`,
  `cqrt_cnot(rail, bf)`; `Out.RailRoot`/`RailRootFlag` recorded, `Out.Root = bf`,
  **`Out.RootIsRail = false`** (the root handed back is an ancilla).
* `ir-pass/src/CondTreeEmit.cpp:235-248` — the strip, FIRST in the LIFO: `cqrt_cnot(rail, bf)`,
  `cqrt_free(bf)`. Vacuous for every other caller (`RailRootFlag` is null).

### (b) `SelectMergeEmit` — ask for the flag; INVERT the drift guard

* `ir-pass/src/SelectMergeEmit.cpp:106-117` — the pre-emission `kBareRailCondReason` decline is REPLACED
  by the comment explaining the two rail cases (a NON-ROOT rail needs nothing; a ROOT rail needs the copy).
* `ir-pass/src/SelectMergeEmit.cpp:180-193` — `CopyRailRoot=true`, the only change at the call.
* `ir-pass/src/SelectMergeEmit.cpp:212-221` — the OPPOSITE guard: `if (Net.RootIsRail)` bail LOUDLY with
  `control flow`. It sits before step 3, and for a bare rail root the copy is the network's ONLY emission,
  so a bail there has still emitted nothing.

### (c) `SelectClassify` — the rail ladder

* `ir-pass/src/SelectClassify.cpp:812-853` — rungs (i) tainted and (ii) **not measured before the
  SELECT** (`railMeasuredBeforeReadPoint(Rail, Sel, taint, DT)` →
  `condition measured before the control route`).
* `ir-pass/src/SelectClassify.cpp:928-980` — gate 2c split into TWO seed sets. `CmpProv` keeps the
  POSITION-FREE walk byte-for-byte (with no rail leaves it is insertion-for-insertion the pre-change
  `Prov`, so every compare-conditioned select is unchanged — measured, §4). `RailProv` gets the DT prong:
  position-free clean ⇒ accept; else no `DT` ⇒ decline; else re-ask with `EmitPoint = Sel`.
  The freeze check runs over both sets; the same-block positional prong stays COMPARE-only.
* `ir-pass/src/SelectClassify.cpp:1030-1045` — the trailing `kBareRailCondReason` decline is DELETED,
  and the comment records that the ANGLE HAND-OFF ORDERING is preserved (the rail rungs run before it,
  so the Rz-stem angle select on a rail still reaches `classifyAngleSelect` and the Ry stem still
  declines `kBareRailCondReason` inside it — 1b-C).

### (d) `ArmClassify` / `ArmAnalysis.h` — `railMeasuredBeforeBranch` → `railMeasuredBeforeReadPoint`

* `ir-pass/src/ArmClassify.cpp:1813-1864` — the helper is moved OUT of the anonymous namespace, takes a
  `const Instruction *ReadPoint`, and tests a same-block measurement POSITIONALLY (`M->comesBefore`).
  The two kickback callers (`ArmClassify.cpp:3945`, `:4368`) pass `Pred->getTerminator()`, which is
  byte-unchanged by construction: a `cq_measure` user is never a terminator, so a same-block one always
  `comesBefore` it — exactly what the old unconditional `return true` said.
* `ir-pass/include/ArmAnalysis.h:144-166` — the declaration and the three-caller contract.

`grep -rn 'railMeasuredBeforeBranch' ir-pass/` → 0 (one spelling, Rule 14).

---

## 2. The analytic argument (Rule 2 — `opt -verify` proves nothing here)

**Why a COPIED ancilla and not the register itself.** Step 4 of the §5a merge must fire the second
controlled copy on `¬flag`, and this project's only spelling of that is a self-inverse `cqrt_x` bracket.
A rail root is the USER'S REGISTER and may never carry a `cqrt_x` — bd memory
`diagonal-only-on-user-registers-3qlq4` names the three lowered-stream predicates that go wrong or
over-freeze: `Uncomputation::preservesBorrowedParent` admits an uncontrolled `cqrt_rz_` BY NAME and
FAILS CLOSED on anything else (a bracket would freeze and leak every chain that borrows the register),
`ChainWalk::isInPlaceGateOn` never recovers a `cqrt_x`, and every `ArmClassify` wire fence argues from
"this region emits no non-diagonal gate on any condition register". The PHASE path escaped this with the
diagonal identity `X·P(θ)·X = e^{iθ}·P(−θ); a controlled basis COPY has no diagonal form for its ¬-half.
So the flag is copied out. This is BRIEF §1 option (a), as decided.

**The unitary.** `bf` is minted at `|0⟩`. After `cnot(b, bf)` the pair is `Σ_x α_x |x⟩_b |x⟩_bf` — a
basis-label COPY of a register that stays live, not a move, so Rule 8's prohibition (which forbids
FREEING a superposed source by copy+uncompute) has no subject. Then `copy_c(bf, T, out)` writes `T` iff
`x = 1`; `x(bf)`, `copy_c(bf, F, out)`, `x(bf)` writes `F` iff `x = 0`. Exactly one write per basis
branch, so `out = b ? T : F`. `b` is untouched throughout — the copies write `out`, the brackets act on
`bf` — so the second `cnot(b, bf)` returns `bf` to `x ⊕ x = 0` on EVERY basis branch and its `cqrt_free`
is a proven-`|0⟩` free (Rule 6). Net `|b⟩ ⊗ |out = b ? T : F⟩`: the SAME unitary the compare stream
realizes with `c(x) = b`, which is why every §5a invariant (the bracket SCOPE, the `cqrt_x` COUNT, the
single free) carries over unchanged and why the four `control_swap_select_*` invariants of bd memory
`swap-route-select-merge-invariants` are untouched.

**What touches the register.** Two `cqrt_cnot(h_b, ·)` with the register at arg 0 — a READ-ONLY control,
the SAME gate class the Inc-1b nest already emits on a rail (`cnot(h_b, g)` / `toffoli(h_b, f, g)` in
the OR/XOR/AND node emissions, Rule-13-cleared in PRD §13.6/§13.7). No new gate class on a user register,
no new gate class in the merge.

**What is left allocated.** The register, `%out` and both materialized sources. Each is entangled with
`%out` through the copy, so freeing one is a hidden measurement (Rules 6/8; bd memory
`select-merge-no-chainwalk-exemption`). MEASURED for the dead-register case
(`control_swap_select_rail_dead_register.ll`, probe `s13`): the register's only surviving users are the
two `cqrt_cnot`, which `ChainWalk` does not recognize as adjointable in-place gates, so the DAG is NOT
closed, no `_unc` is emitted and `FreePoint` places no free. Exactly ONE `cqrt_free` in the module.

**A NON-ROOT rail leaf needs nothing.** `(b != c) ? 2 : 5` gives `xor i1 %b, %c`; the tree ROOT is the
xor NODE, so `CondTreeEmit` allocates its ordinary ancilla `%g`, writes it with two `cqrt_cnot` whose
CONTROLS are the two registers, and the merge brackets `%g` — an ancilla. `RootIsRail` is false and no
copy flag is minted. Pinned by `control_swap_select_rail_in_xor_tree.ll` (probe `s09`).

---

## 3. Fixtures — Rule 12, in the brief's order

**20 files: 13 accepts + 7 declines**, `ls ir-pass/test/control_swap_select_rail_*.ll | wc -l` = **13**,
`ls ir-pass/test/control_swap_reject_select_rail_*.ll | wc -l` = **7**. One of the 13 is the `git mv` of
`control_swap_reject_select_rail_cond.ll` → `control_swap_select_rail_const.ll`, rewritten as the accept
its own header anticipated, so the corpus moves **+19**.

Accepts: `rail_{const, quantum_arm, qq_arms, post_ry, measure_after, cross_block, two_regions,
then_select, in_xor_tree, fp_data, i1_data, inloop_invariant, dead_register}`.
Declines: `reject_select_rail_{measured_before, measured_sidepath, stale_sibling_theta,
stale_chained_between, inloop_stale_theta, trunc_cond, phi_cond}`.

Each accept carries: an ORDERED `CHECK` of the whole stream; an `ORD` prefix pinning
`cnot → copy → x → copy → x → cnot → free` (the §16.3 bracket-scope hazard, verify-clean-invisible);
whole-file pure-negative prefixes `NOROUTE` (cswap / controlled rotations / `cq_phi` / surviving
`@cq_theta_i1` / `cq_template_` / a non-i1 `cqrt_rz_`), **`NOX` (no `cqrt_x` on the USER REGISTER, the
handle named because a pure-negative prefix cannot bind a capture)** and `NOUNC` (no `_unc` anywhere —
a rail condition mints no compare); and exact counts `XCNT`/`FCNT`/`CNCNT`/`CPCNT`/`RYCNT`/`ACNT`.
Handle names are DERIVED from the pass output, never guessed. One `%cq-opt` run per fixture, every
FileCheck over the same `%t.cqd0.ll` (the spawn-cost rule in Build & Test).

### Red-green, MEASURED

Swapping the pre-change `cq-opt`/plugin back into `build/ir-pass/` and running
`lit ir-pass/test --filter '…'`:

* **All 13 accepts FAIL on `main` 87d0699** (they decline).
* **`..._reject_select_rail_measured_before.ll` and `..._measured_sidepath.ll` FAIL on `main`** — they
  declined there with the blanket `bare i1 register condition`, not with rung 2's string.
* The other **5 declines PASS on both binaries** and their headers say so: they are DISCRIMINATORS, not
  red-green pins. `..._stale_{sibling_theta,chained_between}` and `..._inloop_stale_theta` pin that the
  DT-prong widening did NOT reach them; `..._{trunc,phi}_cond` pin the narrowness of `isCondRailLeaf`.

### Mutant validation of the two discriminator claims

* **M-DT** — delete the DT re-ask (accept whenever a tree exists): exactly
  `..._stale_sibling_theta`, `..._stale_chained_between` and `..._inloop_stale_theta` go RED
  (`lit --filter 'reject_select_rail_'` → 4 passed / 3 failed). The three fixtures bind the prong.
* **M-NARROW** — admit an i1 `trunc`/`phi` as a rail leaf: **SIX** fixtures go red over the whole
  corpus — my two plus four PRE-EXISTING pins of the same shared predicate
  (`control_phase_kickback_reject_bare_i1_{trunc,loop_phi}.ll`,
  `control_angle_select_reject_raw_i1_cond.ll`, `control_swap_reject_select_badcond.ll`). The header of
  `..._trunc_cond.ll` states that measured number; my first draft claimed "exactly this file and
  `..._phi_cond.ll`", which the measurement falsified and which is corrected in place.

### Injection matrix (performed, not asserted)

`11 mutations × 13 accepts = 143`, applied to the PASS OUTPUT and re-FileChecked with all 11 prefixes:
a `cqrt_x` on the register, an extra `cqrt_ry` on the register, an extra `cqrt_free`, a `cqrt_cswap`,
an extra `cqrt_cnot`, an extra `cqrt_alloc`, a `cq_template_` mint, a `_unc` call, a BRACKET SLIDE
(`x` before both copies), a DROPPED strip cnot, an extra copy.
**Result: 143 mutations, 0 MISSED, 0 DIRTY.**

The first run read **1 MISSED** and it is worth carrying: on `control_swap_select_rail_then_select.ll`
(two selects on one register) a bracket slide in region 1 **SLID INTO REGION 2** and still satisfied a
seven-entry `ORD` block. Fixed by pinning the full FOURTEEN-entry stream, with the measurement recorded
in the fixture's header. *An `ORD` block is only as strong as the number of regions it covers.*

---

## 4. Measurements

| what | command | result |
|---|---|---|
| lit fixtures | `ls ir-pass/test/*.ll \| wc -l` | 1738 → **1757** (→ **1759** after §8) (+19) |
| lit | `cd build && lit -s ir-pass/test` | **1757 discovered · 1756 passed · 1 expectedly failed · 0 unexpected**, 44.5 s |
| `ir-pass-lit` | `ctest -R ir-pass-lit` | **Passed, 39.50 s** |
| e2e | `ctest -j6 -R '^e2e-'` | **375/375 passed, 357.6 s** (`e2e-loop-twin-matrix` 357.6 s of it) |
| the other 9 | `ctest -j6 -E '^e2e-\|^ir-pass-lit$'` | **9/9 passed, 14.4 s** (runtime ×6, `frontend-lit`, `cq-opt-equivalence`) |
| ctest total | `ctest -N \| tail -1` | 377 → **385** (`^e2e-` 367 → **375**, `^e2e-slice-` 330 → **337**, `twin-identical` 27 → **28**) |
| goldens | `ls tests/e2e/*.expected.log \| wc -l` | 332 → **339** (+7) |
| **golden churn** | `git status --porcelain tests/` | **ZERO pre-existing goldens modified** — 14 new files + `CMakeLists.txt` |
| corpus diff `main` vs branch, all 1738 pre-existing fixtures (rc + stdout + stderr) | `scratchpad/impl_b1/corpus_diff.py` | **RCDIFF 1 · DIAGDIFF 1 · OUTDIFF 1**, all three the SAME file: `control_swap_reject_select_rail_cond.ll`, the `git mv` target |
| `cq-opt` vs stock `opt` full sweep (required after a diagnostic-surface change) | `cmake --build build --target cq-opt-equivalence-full` | **1757 fixtures, 0 mismatches** |

**The corpus diff is the strongest single statement here:** 1737 of 1738 pre-existing fixtures produce a
byte-identical return code, stdout AND stderr on both binaries. The one mover is the fixture this
increment deliberately flips.

I did NOT run the full `ctest -j6` as one invocation; I ran its three disjoint parts (1 + 375 + 9 = 385,
all green). The single full run is the orchestrator's gate.

---

## 5. e2e — 7 slices + 1 twin gate, all STRICT stage 2b

Registered in `tests/e2e/CMakeLists.txt` immediately after the `phase_bool` group.

| slice | shape | trace |
|---|---|---|
| `slice_control_select_bool.c` | **the owner's `main()` VERBATIM** | 15 lines |
| `slice_control_select_bool_int_twin.c` | the same with `int b0` — the compare path | 14 lines |
| `slice_control_select_bool_quantum_arm.c` | `b ? q : 9` | 16 lines |
| `slice_control_select_bool_sdagger.c` | `k3` — select, then `cq_theta(b, -0.5)` | 16 lines |
| `slice_control_select_bool_two_regions.c` | select then kickback on one register | 16 lines |
| `slice_control_select_bool_loop.c` | invariant rail, select in the loop body | 39 lines |
| `slice_control_select_bool_loop_unrolled.c` | its hand-unrolled twin | 39 lines |

`e2e-select-bool-loop-twin-identical` gates **39 = 39, byte-identical** (`cmake -E compare_files`).
The loop pair was MEASURED before it was committed, as the brief required; it is a genuine twin.

There is deliberately **NO** `compare_files` gate between the bool slice and its int twin: the witness is
a STATED reduction (15 vs 14 lines — the bool's three flag lines `alloc_i1(0) -> h1`, `cnot(h0,h1)`,
`cnot(h0,h1)` against the twin's two `cq_template_icmp_eq_i32_hl(h0,1) -> h1` and its `_unc`, plus
`i1`↔`i32` on the register), and a gate would assert something false. That is the Inc-4 state-prep
precedent, and the Inc-1b `phase_bool` group's own convention.

Every golden was read line by line against the §2 analytic stream before being committed.

---

## 6. Probes and the two findings

`probes/` holds **29 files + README.md**: the orchestrator's `k1`–`k4`, this session's `s01`–`s20` (one
per shipped fixture shape), and the Inc-1b re-runs `p08`/`p09`/`p12`/`p16`/`q08`. `probes/README.md`
carries the full PRE/POST verdict table in the `session-3qlq4/probes/README.md` format.

**THE OWNER'S FILE.** `user_file_as_of_2026-09-10_close.c` declined `bare i1 register condition` on
`main` 87d0699 and now ACCEPTS — 15 trace lines, stage 2b `1 verified, 0 violation(s), 0 unproven`:

```
cqrt_alloc_i1(0) -> h0            cqrt_x(h1)
cqrt_ry_i1(h0, 0x1p-1)            cqrt_alloc_i32(5) -> h4
cqrt_alloc_i1(0) -> h1            cqrt_copy_i32_controlled(h1, h4, h2)
cqrt_cnot(h0, h1)                 cqrt_x(h1)
cqrt_alloc_i32(0) -> h2           cqrt_cnot(h0, h1)
cqrt_alloc_i32(2) -> h3           cqrt_free(h1)
cqrt_copy_i32_controlled(h1, h3, h2)   cqrt_measure_i1(h0) -> 0
                                  cqrt_measure_i32(h2) -> 0
```

**FINDING 1 — `p09_value_arm` ACCEPTS, and the brief's expectation for it was based on a
mis-classification of what `-O1` does, not on a defect.** `BRIEF_B1.md` §5 says p09 "MUST still decline";
it does not. MEASURED: `int a = cq_theta(5,.2); bool b = cq_theta((bool)0,.5); if (b) a = a + 3;` is
NOT a value-arm diamond at `-O1` — clang HOISTS the add (`%3 = add nsw i32 %1, 3`) and folds the whole
thing to `select i1 %2, i32 %3, i32 %1`, a 4.4 DATA select with two tainted operands, i.e. exactly this
sub-increment's shape. Three facts make the accept the right answer rather than an over-accept:

1. its COMPARE twin (`int b; if (b == 1) a = a + 3;`) has ACCEPTED on `main` through this same path
   since 4.4 shipped — measured, 15 lines — and the two traces differ ONLY in the flag lines;
2. bd memory `swap-route-select-merge-invariants` names `(q>5) ? q : q+1` as a CANONICAL 4.4 accept:
   a pure-theta operand is a real-amplitude basis superposition and copies correctly;
3. gates 4/5/6 are untouched by this increment and are what decide the ARMS.

The GENUINE B.2 value arm is an unfolded diamond with a merge φ, which `-O1` does not produce for that
source. It is pinned by the hand-IR fixture `ir-pass/test/control_swap_reject_value_rail_cond.ll`, whose
`bare i1 register condition` decline is **UNCHANGED and green** — as are
`control_angle_select_reject_rail_ry.ll` (1b-C), `control_inplace_ry_reject_raw_i1_cond.ll` and
`control_angle_select_reject_raw_i1_cond.ll`. No `classifyArms` / `classifyClassicalCallArm` / phase
emitter / `AngleSelectEmit` code was touched.

**FINDING 2 — two probe shapes are not reachable from plain C, and the fixtures for them are hand IR.**
`if (q & 1) a -= 3;` gives `and`+`icmp`, a COMPARE that has always lowered (`s19` accepts on BOTH
binaries), and the loop-carried `bool` declines one layer earlier in the loop lowering
(`cq loop lowering: loop-carried tainted value crosses iterations`, `s20`). Both probes are kept as the
record of what the C route actually produces; the `trunc`/`phi` fixtures say in their headers that they
are deliberately hand-written IR.

---

## 7. Open questions for the owner / the Rule-13 reviewer

1. **OQ-B1-1 — `p09`'s reclassification.** Finding 1 means the B.1/B.2 boundary is not where the brief
   drew it: the shape the brief called "the value arm" is a DATA SELECT at `-O1`, and B.2's real
   population is the shapes `-O1` leaves as diamonds with a merge φ. Worth re-scoping B.2 against
   measured `-O1` output before it is built, rather than against source syntax.
2. **OQ-B1-2 — the side-path measure is a documented OVER-DECLINE.**
   `..._reject_select_rail_measured_sidepath.ll` refuses on REACHABILITY, so a program whose guard is
   never taken declines anyway. Inherited verbatim from Inc 1b (OQ-1b-R2-4); not widened here.
3. **OQ-B1-3 — the freeze on chains that borrow the register.** `Uncomputation::preservesBorrowedParent`
   refuses `cqrt_cnot` (it fails closed on everything it does not name), so a chain that borrows the
   condition register as a parent now sees TWO unrecognized users where a compare-conditioned select
   left none. That is the LEAK direction (Rule 6 safe) and matches the Inc-1b disposition for a rail
   under a kickback, but it is a real cost and a reviewer should decide whether the row deserves
   widening to an uncontrolled `cqrt_cnot` whose TARGET is not the parent. **I did not widen it**
   (Rule 17: the decline belongs to inputs outside the target shape, and this is a discharge question,
   not a lowering one).
4. **OQ-B1-4 — `AllowLogicalSelect` stays `false` for the data select**, as the brief directed, so
   `b && q == 5` as a DATA-select condition keeps declining `control flow`
   (`control_swap_reject_select_i1sel_combinator.ll`, shipped and green). Filed, not built.

Nothing in §2's ladder proved ambiguous; no rung was shipped as a guess.

## 8. Orchestrator addendum — finding F-B1-1 (2026-09-10, on the first B.1 build, plain-C reachable, CONFIRMED)

`railMeasuredBeforeReadPoint`'s first spelling returned `M->comesBefore(ReadPoint)` for a same-block
measure and never asked reachability. In a loop body that is an over-accept: the select's rail rung is
"has the register been measured before this read on SOME path", and a same-block measure AFTER the select
precedes its NEXT execution around the back edge. Measured:

| program | first B.1 build | after the fix |
|---|---|---|
| `probes/m1_inloop_select_measure_after.c` — `for (i…) { int a = b ? i : 5; acc += cq_measure(a) + cq_measure(b); }` (the select stays in the body: its true arm is loop-VARIANT) | ACCEPT, exit 0, verify-clean, STRICT 2b `0 violation(s)` — trip ≥2 controls its copies on a register trip 1 collapsed | DECLINE `condition measured before the control route` |
| hand IR, constant arms `b ? 2 : 5` kept in the body | ACCEPT | DECLINE (same string) |
| `probes/m4_inloop_constarm_hoisted.c` — the constant-arm form from C: `-O1` LICM-hoists the select into the preheader, the measures are downstream | ACCEPT (correct) | ACCEPT, byte-identical |
| `probes/m3_inloop_select_measure_downstream.c` — no measure of `b` in the body | ACCEPT (correct) | ACCEPT, byte-identical |
| `probes/m2_inloop_select_measure_after_compare_twin.c` — the `int b; (b == 1) ? i : 5` twin | ACCEPT | ACCEPT — **PRE-EXISTING on `main` 87d0699** (measured on the saved pre-change binary): the 4.4 compare-select classifier has NO measured-before rung at all; filed as bd `test_C_libtooling-r10v` (P1), not this increment's |

Fix (`ArmClassify.cpp`, `railMeasuredBeforeReadPoint`): the same-block shortcut is deleted and
`isPotentiallyReachable(M, ReadPoint, nullptr, DT)` is asked for every measure — LLVM answers the
same-block case itself (before ⇒ true; after ⇒ true iff the block can reach itself, false in the entry
block or an acyclic one). The two kickback callers are unaffected (a measure before a terminator is
reachable ⇒ true, the old `return true`). Pinned by `control_swap_reject_select_rail_inloop_measure_after.ll`
(the plain-C module) and `..._constarm.ll` (hand IR); `control_swap_select_rail_measure_after.ll` (flat,
`s05`) stays the accept that keeps the rung a discriminator. Lit corpus 1757 → **1759**. The owner's file,
`k1`–`k4` and every `s*` probe are byte-unchanged by the fix (re-measured). The lesson is 8h7d.5's again:
the read POINT was parameterised (widened), and the same-block clause was a second predicate over the same
closure that was not re-derived with it.
