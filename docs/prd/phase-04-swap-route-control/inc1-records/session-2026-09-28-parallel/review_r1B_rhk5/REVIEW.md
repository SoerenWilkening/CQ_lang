# Rule-13 review r1B — bd `test_C_libtooling-rhk5` (surface B: circuits, the new twin-equivalence instrument, moved goldens, composition)

- **Subject**: branch `worktree-agent-a7712272d6ca568e9`, commit `c89afa59`, diff `9a230646..c89afa59`.
  `build/ir-pass/cq-opt` sha-256 `fa71e37a884ba4489e96a66a…` and `libCQPass.so` `c21a35eff3059cf6b8f64a3a…`,
  **both re-hashed by me and matching the brief**. Used read-only. I did no build.
- **Oracle**: `scratchpad/frozen/cq-opt.main_9a230646`, sha-256 `3f6db37f5cf937b4d70f5736…` (re-hashed, matches).
- **Time**: about 75 min. The box load average was 210–370 the whole time.
- **What I ran**, all of it through `probes/`:
  - `probes/pair.sh NAME 5` builds each probe as a 2-TU C program, llvm-linked the way `run_slice_multi.sh`
    links, plus its hand-inlined twin `NAME_T.c`. For **both** binaries it records the `opt` rc, warnings,
    the stage-2b STRICT census, a link (templates before runtime, via `build/tests/e2e/cq_link.sh`) and a
    run with `argv[1]=5`. It then runs `tools/trace_twin_equiv.py` on the subject's subject trace against
    the subject's twin trace. Raw output is in `probes/out/run{1,2,3}.txt` and the traces in `probes/out/`.
  - I ran 26 C probes: `b0…b6, b2n, b14, c1…c5, z1, z2, v1, l1, l2, k2x`, plus r2B's `k2, k2F, k2T, g12B`.
    Each has its twin where one exists.
  - `probes/checker/attack_checker.py` holds 28 hand-written trace pairs aimed at the instrument.
  - `probes/checker/checker_mutants.py` holds 15 mutants of the CHECKER (U0 = null). Each is scored three
    ways: the checker's own `--selftest`, the 3 committed gate pairs, and my 28 attack rows.
  - `probes/checker/rail_audit.py` lists, for each rail, its writes, its last read and whether its parents
    are written between mint and `_unc`. I ran it on the two regenerated libm goldens and on the probe traces.
  - `entangle.py` (the implementer's Rule-8 tool) on `b2`/`b2n`, both binaries.
  - A `-g` build of `b0` on the subject.
  - The one moved EXISTING lit fixture (`lowering_live_record_sibling_clone_arg_measured_accept.ll`) run
    by hand on both binaries.
- **What I did NOT run**:
  - No lit, no ctest, no corpus A/B and no mutation matrix. I read their counts, per the efficiency rule.
    My one spot-check is the lit mover above.
  - No private build. So there are no compiler mutants from me. r1A owns the fence logic, and the
    implementer's M1–M8 matrix covers the predicate's conjuncts.
  - No composed binary for cepm / 3zr4 / nlfd / ev3m / z0re. The composition section is argued, plus one
    single-binary proxy (`z1`).

## Verdict: **NOT-CLEAR**

The fix does what it says on every shape it was built for. I checked the three e2e gates, both regenerated
libm goldens and r2B's four probes by hand, and all are correct.

The block is **F-r1B-1**. Clause (b′) turns a C program that the ORACLE compiles to the correct circuit
into one that leaves a DEAD rail entangled with `q` across a later `Ry`. The subject warns when it does
this. The hand-inlined twin does the same thing on both binaries. By rhk5's own yardstick (bd rhk5 is
filed P1 as a "wrong circuit, warned"), this is a P1 regression for that population. The mechanism is L2
exactly: (b′) widened the interior-consumer set, and the COMPONENT and ANCHOR computed over that closure
moved with it.

---

## Findings

### F-r1B-1 — P1 (graded by rhk5's own yardstick) — INTRODUCED for its population; the class is PRE-EXISTING in the twin

**Title.** Clause (b′) merges a clone-consumed chain rail into the interior component of its dead sibling.
When the clone consumer sits after a non-diagonal gate on the borrowed parent, the whole component leaks.
That includes a dead rail the oracle discharged.

**Probe.** `probes/src/b2n.c` (+ `b2n.lib.c` `h(a,k)=k+1`, twin `b2n_T.c`):

    q = cq_theta(m&7, .5); p = q & 3; u = p + q;
    if (u == 10) cq_phi(PI);
    q2 = cq_theta(q, .7);
    s = h(m, p);                       // clone CONSUMES p, AFTER the Ry on q
    return cq_measure(s) + cq_measure(q2);

`probes/src/b2.c` is the same program with `p = q*3; u = p^q`.

**Repro.**
- `probes/pair.sh b2n 5` (and `b2`).
- `python3 ../rhk5_probes/tools/entangle.py --quiet-controls probes/out/b2n.{O,S}.trace`

**Measured.**

| run | rc | warning | 2b dirty | stream |
|---|---|---|---|---|
| ORACLE, `b2n` | 0 | **none** | 1 | `add_i32_unc(h2, h0, h1); free(h2)` — the dead `u` is discharged at L8, BEFORE `cqrt_ry_i32(h0, 0.7)` at L11. Only `p = q&3` (h1) is live across the Ry, and the program requires that, because `s` reads `p` after the Ry. entangle.py: `RY on h0 … LIVE entangled rails ['h1']`. |
| SUBJECT, `b2n` | 0 | `non-diagonal gate over a live derived record` | 2 | no `add_i32_unc` at all. entangle.py: `RY on h0 … LIVE entangled rails ['h1', 'h2']`. |
| twin `b2n_T`, both binaries | 0 | warns | 2 | the same as the subject |
| `b2` (`p = 3q`, `u = p^q`) | | | | identical pattern: ORACLE unwarned, dirty 1, `xor_unc(h2,…)` before the Ry; SUBJECT warned, dirty 2 |

**Mechanism.**
- **ORACLE.** A clone consumer disqualified `p` from the interior partition. So `u`'s component was `{u}`,
  with borrowed parents `q` and `p`. The clone call on `p` lies after `At` (it is excused by W2), and the
  component discharged at the strip.
- **SUBJECT.** (b′) admits the clone as a consumer of `p`, so `p` becomes an owned interior member, and
  `u = p + q` joins the same component. `planInteriorComponent` anchors `At` after ALL consumers of ALL
  owned rails, which includes the clone call after the Ry. The Ry on the borrowed parent `q` is then inside
  `(First, At)`, clause (d) refuses, and the WHOLE component leaks, `u` included.
- **Clause (3) is not involved.** The clone reads only `p`, and it lies outside `u`'s oracle window. The
  only change that can make `p` interior is (b′). That is argued from the diff (two callers), not measured
  with a mutant, because I did no private build.

**Why it is a wrong circuit, not a cosmetic leak.** Analytic, no simulator.
- Take `b2n` with `x` the value of `q`. The map `x ↦ (x&3, x+(x&3))` is injective. So in the subject,
  `q`'s reduced state before `Ry(0.7)` is fully diagonal: the dead `u` completely dephases `q`.
- In the oracle only `p = x&3` is live. Coherence survives between basis states with equal low bits.
- The kickback marks `x ∈ {7, 9}` (`x + (x&3) == 10`). The phase on `x = 9` against `x = 13` (both
  `x&3 = 1`) is interference the oracle's `Ry` can turn into amplitude, and the subject cannot.
- The user's phase oracle is **erased**. That is rhk5's own defect class, moved to a new population.
- `b2` (`p = 3q`, injective) is observationally benign, because there `p` alone already fully dephases `q`.
  That is why `b2n` is the exhibit.

**How to read "twin parity".** The brief makes the twin the correct circuit, and the subject is
twin-identical here (`trace_twin_equiv` EQUIV on `b2`/`b2n`). But the twin is itself defective, on BOTH
binaries: the M-B component granularity leaks `u` together with its late-consumed sibling. **"Pre-existing"
is true of the defect and FALSE of its population.** rhk5 brings every clone-consumer program into that
population. Before rhk5, the oracle handled this one correctly by accident: it did not treat the clone
consumer as a consumer at all.

**Corpus blindness.** The implementer's A/B over 3,355 modules (2416 lit + 614 e2e + 35 multi + 290 probes) has **0** movers from unwarned to warned
(`grep -cE "False\)\s+B=.*True\)" results/ab_oracle_vs_subject_v2.txt` = 0). No module in any population
has a (b′) consumer after a non-diagonal gate on the borrowed parent. **A clean `A→D = 0` over a population
with no members of the class is not evidence about the class.** That is §4k's lesson, and it applies here.

**Suggested direction** (the implementer's call):
- When `planInteriorComponent` fails clause (d) for a component that contains a (b′)-admitted rail, re-plan
  with that rail demoted to a borrowed parent. That is the oracle's plan, and it discharges `u`.
- More generally, split a component by consumer anchor. That would also fix the twin (pre-existing).
- Owed with the fix: a lit ACCEPT fixture of `b2n`'s shape that pins `add_i32_unc(u, …)` before the Ry,
  red on the subject today.

**Bead.** `test_C_libtooling-kyy1`, filed by this review.

### F-r1B-2 — P3 — INTRODUCED (new tool): `trace_twin_equiv.py` gives a FALSE EQUIV on a width-inconsistent Bennett block, so its "a false EQUIV is not possible" is an unmeasured overclaim

**The defect.** Rule 1's width conjunct is a substring test, `('_' + w + '_') in (t['sym'] + '_')`. A cast
producer contains both of its widths, so `cqrt_copy_i32` of the i64 result of
`cq_template_sext_i32_to_i64` is contracted as if the copy were full-width.

**Exhibit.** Attack row `A9-width-cast-substring` in `probes/checker/attack_checker.py`:
- **subject**: `sext_i32_to_i64(h0)->h1; alloc_i32(0)->h2; copy_i32(h1,h2); sext_unc(h1,h0); free(h1); x(h2); free(h2)`
- **twin**: `sext_i32_to_i64(h0)->h1; x(h1); free(h1)`

These are different circuits: X on 32 bits against X on 64. The checker says **EQUIV**.

**Limits.**
- It is not reachable from compiler output as far as I can see: the Bennett wrap copies at the clone's
  return width. So it does not affect the three gates.
- The module docstring nonetheless states *"a false DIFF is possible; a false EQUIV is not"*. Rule 1
  soundness rests on the copy being full-width, and the conjunct that is supposed to check that does not.

**Fix.** Derive the producer's RESULT width (the `_to_<W>` suffix for casts, `i1` for compares, the
operand width otherwise), or drop the claim.

**Repro.** `CQ_TOOLS=$PWD/tools python3 docs/…/review_r1B_rhk5/probes/checker/attack_checker.py` →
`FALSE EQUIV: 1 of 28` (A9).

### F-r1B-3 — P3 — INTRODUCED: half of the checker's classification table, and Rule 1's `|0⟩` conjunct, are pinned by NO control

This is the L10 lesson: an instrument's failure mode is to report a PASS.

**Surviving mutants.** `probes/checker/checker_mutants.py` (run from the worktree root). Each mutant below
turns a WRITE slot into a READ. Each leaves `--selftest` **GREEN**, and all 3 gate verdicts unchanged:

| mutant | what it changes |
|---|---|
| U6 | `cqrt_cswap` targets |
| U7 | `cqrt_toffoli` target |
| U8 | `cqrt_cnot` target |
| U9 | `cqrt_{ry,rz}_*_controlled` target |
| U10 | `cqrt_copy_*_controlled` destination |
| U11 | `cqrt_addc/xorc` |
| U3 | Rule 1 accepts ANY `alloc` init as the scratch `b`, not only `|0⟩` |

The implementer's 30 controls use none of those symbols. Each of these mutants makes a false EQUIV
possible: a write reordered across a read of the same rail.

**What kills them.** My rows kill every one:

| row | kills |
|---|---|
| A18 | U3 |
| A22 | U8 |
| A23 | U7 |
| A24 | U6 |
| A25 | U10 |
| A26 | U9 |
| A27, A28 | U11 |

Recommend adding them to `CONTROLS`. The three rhk5 goldens contain none of those symbols, which is why
nothing is wrong today. But TRACK §9 proposes the tool as a general witness (`*-twin-equivalent`), and
`f07`/`g12B` already emit `cqrt_copy_*_controlled` and `cqrt_x`.

**Also surviving, argued equivalent on real traces** (the handle counter is monotonic, `runtime/cq_runtime.c:64`):

| mutant | what it drops | why it is equivalent |
|---|---|---|
| U1 | Rule 1's "exactly 4 uses" | only admits uses AFTER the free |
| U4, U5 | Rule 2's x∉args and copy-is-second-use | redundant with the clobber check and the use ordering |
| U13 | renaming injectivity | only matters for a doubly-minted token |
| U12 | measure-as-READ | this reading is actually physically sound |

Control `bennett-scratch-reused` does NOT witness U1's conjunct. It is DIFF for a different reason: the
twin's measure token cannot bind.

### F-r1B-4 — P3 — INTRODUCED (L7): the tool's module docstring contradicts its implementation and its own controls

**The contradiction.** The module docstring says:
- *"CONTRACT every CONTIGUOUS single-template Bennett block"*
- *"THE CONTRACTION IS DELIBERATELY NARROW: one forward template, contiguous … A multi-template clone body
  is NOT contracted … so such a pair reports DIFF"*

Meanwhile:
- `contract()`'s own docstring says *"A MULTI-template clone body contracts only its LAST link"*.
- Control `bennett-noncontig` expects **EQUIV** for a non-contiguous block.
- Control `bennett-multi` expects **EQUIV**.
- The nested gate (`e2e-spec-clone-read-nested-twin-equivalent`) is EQUIV only BECAUSE of 3 contractions,
  one of them a multi-template body.

**Why it matters.** The docstring is what TRACK §4.2 and the CMake comment send a reader to ("read its
header for exactly what that does and does not witness").

**Minor.** TRACK §4.2 says "30 boundary controls"; §7, §9 and the tool say 31 (30 + the unclassified-refusal).

### F-r1B-5 — P3 — observation, not traced: an over-WARN residual on a clean trace (`l1`)

**Probe.** `probes/src/l1.c`: clone calls in a classically-bounded loop inside the chain's window, each
trip's clone result measured in the trip.

**Measured.**
- The subject now discharges the chain correctly. The trace shows `xor_unc`/`mul_unc` + frees after the
  strip and before the Ry, and 2b reports dirty 0.
- It still emits the lyyf-(B) warning. The oracle also warns, but the oracle really does leak.

**Limits.**
- I did not trace which record the late M-A guard sees. The measured clone results (`h4…h12`, collapsed)
  are the candidates.
- The twin declines (`operand predates a non-diagonal gate`), so there is no reference stream.
- This is a warning on a correct circuit (the safe direction). It is filed here so nobody reads "warned"
  on `l1` as "leaked".

**Repro.** `probes/pair.sh l1 5`; `probes/out/l1.S.{trace,err}`.

### F-r1B-6 — P3 — Rule 14 (minor): (B3′) re-spells the controlled-copy ABI fact

`formalLabelPreserved`'s (B3′) re-derives "`cqrt_copy_<W>_controlled` writes its last operand only"
inline. The source comment itself cites `RotationLowering`'s `isCopyGate` as "the same ABI fact", but that
function is file-local and not called. The re-spelling is NARROWER (it requires `_controlled`, void and
arity 3), so it is in the safe direction.

---

## What I attacked and did not break

**1. The three e2e gates, by hand.**
- `read_in_window`, `consumes_chain_rail`, `read_nested`: every chain rail (`h1`, `h2`) is `_unc`'d after
  its last reader, including the clone's reads (e.g. `consumes_chain_rail` L5/L8 read `h1` before
  `mul_unc(h1…)` at L15).
- Each is freed immediately after its `_unc`, before the second `cqrt_ry_i32(h0, 0.7)`.
- `q` (`h0`) has no write between the chain's forward gates and its adjoints.
- The clone copy-outs are correct Bennett blocks. In the nested gate, the inner block
  (`mul(h0,5)->h3 … free(h3)`), the outer block `xor(h4,h0)->h5 … copy(h5,h6) … xor_unc(h5,h4,h0)`, and the
  inner `_unc` twin's recompute (`mul->h7; copy(h7,h4); mul_unc; free`) return `h3`, `h5`, `h7`, `h4` to
  `|0⟩` before their frees.
- Re-ran the tool: EQUIV ×3. Selftest 31/31.

**2. The two regenerated libm goldens.** `rail_audit.py`:
- atan2l `h25`/`h26`, and coshl `h10`/`h11`/`h714`/`h1416`:
  - Each is written only at mint, `_unc` and free.
  - Each rail's last read precedes its `_unc`.
  - Its parents (`h0`; `h25`; `h10`) are unwritten between mint and `_unc`.
  - There are no reads after the `_unc`.
- The only `h0` write in either golden is the initial `cqrt_ry` at L2.
- The clone body's uses of `h26` are forward producers, `_unc` read slots and controlled-copy SOURCES only.
- Why others did not move: a golden moves only where a template rail is read by a clone call (openlibm
  internal non-inlined calls such as `expl` in coshl). I relied on the implementer's e2e sweep (614 swept,
  2 movers) and did not re-run it.

**3. r2B's `k2`/`k2F`/`k2T`/`g12B`.** They are not merely warning-free:
- `rail_audit` shows `p` (`h1`) and the clone's scratch discharged after the last read, before the Ry, with
  parents unwritten.
- The checker says DIFF against my twins, but only through twin vocabulary. `-O1` folds `3q*5 → 15q` and
  lowers `+1` in place (`addc`). In `g12B` the arms fold to a constant.
- I checked each by hand: same measured values, and no entangled scratch left before the Ry.

**4. The implementer's hand-classified DIFF rows `f03`/`f04`/`f06`.** Checked by hand; they are
observationally the same circuit.
- `f06`: measuring a CNOT copy of `q` collapses `q` exactly as measuring `q` does, and the copy is then a
  product state before the Ry.
- `f04`: two copies of `q+1` measured against one measured twice.
- `f03`: an in-place `addc` on `u` against a Bennett copy of `u+1` and `u` discharged.

**5. Circuit shapes beyond the positive suite.**

| probe | shape | subject vs twin | subject vs oracle |
|---|---|---|---|
| `b0` | the d4 replica with `atoi(argv[1])` | EQUIV | clean where oracle warned, dirty 2 |
| `b1` | clone consumes `p` after the kickback, before the Ry | EQUIV | — |
| `b3` | fan-out: `p` read by a clone AND a template | EQUIV | — |
| `b4` | three clone calls (q, p, q) | DIFF by CSE; circuit checked by hand, chain audit clean | — |
| `b5` | `s` measured before the kickback | EQUIV | — |
| `b6` | two kickbacks consuming one chain, clone between | EQUIV | — |
| `b14` | `q` passed in both slots | DIFF: twin `q+q → shl`; by hand OK | — |
| `c5` | clone → inner clone + a second arg `p` | DIFF: twin folds to `q*10`; clone scratch `h4…h8` all zeroed before frees | — |
| `k2x` | Q+Q consumer after the chain | DIFF by `-O1` folding; by hand OK | — |
| `l2` | clone consumer of `p` in a loop, `p` minted outside | EQUIV (twin leaks `p` too, pre-existing) | improved: `u` now discharged |
| `z1` | composition, state-prep register as borrowed parent | EQUIV | — |

**6. Declined on both binaries (same string)** — these confirm TRACK premise 2 at the C level: no
specializer-built clone can write a formal.
- `c1`: a same-TU callee that ROTATES its formal. The callee contains a quantum primitive.
- `c2`: it MEASURES its formal. The callee measures under quantum lift.
- `c3`: a phase kickback on its formal.
- `c4`: a mixed select.
- `v1`: the clone in a tainted value arm. Declines at "arm rewrites a condition operand".
- `z2`: a runtime prep seed, which is z0re's target.

**7. The instrument.** 28 attack rows: A1–A8, A11–A21 are DIFF as required, and A22–A28 are DIFF as
required. They cover:
- a non-commuting pair swapped
- control/target swapped
- a free before its reader
- a measure moved
- an angle changed
- a dropped `_unc`
- a dirty scratch "explained" as copy-out
- a clobbered copy-out
- an `alloc(1)` scratch
- a double free
- `_unc` out-slot moved
- `icmp` operand swap
- controlled-copy and controlled-rotation role swaps

The single false EQUIV is F-r1B-2.

**The relation the tool implements.** Two rewrite rules, then Mazurkiewicz equivalence under a bijective
handle renaming.
- Rule 1: Bennett copy-out → forward.
- Rule 2: recompute-copy-uncompute → out-first adjoint.
- Independence means no shared handle is WRITTEN by either gate. Reads are basis-controls, so
  read/read commutation is sound. Rz and measure count as writes (conservative).
- Handle identity is the allocation instance. The runtime counter is monotonic, so a number is never
  recycled.
- Both rewrites preserve the unitary on every non-scratch register, provided the scratch starts at `|0⟩`
  and the adjoint's operands are unwritten (both checked) and the copy is full-width (NOT checked:
  F-r1B-2).
- Blind by construction to classical post-processing of measurement results (A14), just as byte identity is.

**8. `-g`.** `b0` built with `-g` gives the identical `cq*` call sequence on the subject (measured). This
retires TRACK §7.8's "argued, not measured".

**9. Lit spot-check.** The one EXISTING lit mover gains exactly `mul_i32_hl_unc(%h_op1, %h, 3);
cqrt_free(%h_op1)` right after the clone call. There is nothing else in the diff.

## Standing-lesson questions

- **L1.** The predicate reads only final clone bodies and `SpecHandleArgMask`, and it is asked at use in
  `uncompute`/`planInteriorDischarges`. r1A owns this fence. I found nothing on my surface that contradicts it.
- **L2 — this is F-r1B-1.** The TRACK's L2 section says (I3)/(I4)/`IP->Owned`/`planInteriorDischarges`
  "move together by construction". They do. What it did not ask is what widening OWNED does to the
  component's ANCHOR, which is computed over the same closure. A formerly-borrowed parent that becomes
  owned drags `At` past a non-diagonal gate, and the sibling the oracle discharged alone now leaks.
- **L3.** The moved-anchor scan's `isInPlaceGateOn(clone) == false` premise: `c1`/`c2`/`c3` confirm that
  the specializer refuses every C callee that could write its formal. So the premise is IR-only, as the
  TRACK says.
- **L4.** `formalLabelPreserved` enumerates EVERY use and fails on the first bad one. It is a set walk,
  not return-first.
- **L5.** Label preservation is answered by a closed per-use vocabulary. That is syntactic but fail-closed.
  The name-keying inside the body is TRACK §7.1's point and belongs to r1A's surface.
- **L7.** F-r1B-4 (the tool's docstring), and F-r1B-1's L2 sentence in the TRACK.
- **Rule 14.** F-r1B-6 (minor, safe direction).
- **Rule 12.** The five accepts each have a red-on-oracle pin, and the four LEAK fixtures pin the refusal.
  The LEAK-NOT windows lie between two positive lines (strip and Ry), which is the right window, so they are
  pure. Missing: a fixture for F-r1B-1's shape.

## Composition

- **z0re (runtime state-prep seed).** `z1` is the constant-seed proxy: a prepped register (`alloc(3)` +
  `cqrt_ry_i32_controlled`) as the borrowed parent with a clone reading it inside the window. It is EQUIV to
  its twin on the subject: the chain is discharged and the frozen prep register is never freed. `z2` (seed
  `= m`) declines on both binaries at `state prep seed does not match the merge incoming`, which is z0re's
  wall. Once z0re lands, `z2` becomes the composition program. The rhk5 predicate does not read the seed,
  so I predict `z1`'s stream with `alloc(m)`. **Not measured on a composed binary.**
- **cepm / 3zr4 (spec call results classical at propagation).** A classical-result clone call that still
  reads `q` in a HANDLE slot would be admitted by clause (3) exactly like `d1b`'s classical-verdict calls.
  That is sound, because label preservation does not care about the result. But after vsfp/nlfd's
  liveness, a quantum formal that does not reach the return is dead and gets dropped. I could not construct
  a surviving member. Argued, not measured.
- **nlfd / ev3m (dead-arg liveness, musttail see-through).** More dropped slots only remove uses the
  predicate walks. A `musttail` to an UNRECORDED callee inside a clone body refuses (C1). That is the leak
  direction.
- **F-r1B-1 composes with every one of them.** Any change that admits more clone consumers widens the
  (b′) population the component-granularity leak reaches.

## Beads

- `test_C_libtooling-kyy1` (P1, filed by this review). It covers F-r1B-1: the INTRODUCED (b′) population
  and the pre-existing twin half.
- F-r1B-2 through F-r1B-6 are left to the orchestrator.
