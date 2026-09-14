# Rule-13 round 1, track β — INDEPENDENT ADVERSARIAL REVIEW of `declineDephasingUnmarkedLoopRails`

**VERDICT: FINDING — three, two of them P1.** The fence is sound where it fires and its L1
argument holds, but **the (R-diverge) class is strictly larger than the fence's four conjuncts**,
and I reached the residual from two independent directions on the first round. One new
**over-decline** (ACCEPT → DECLINE on a program whose rolled trace is byte-identical to its
hand-unrolled twin) is also confirmed — the one Track S named at `IMPL_S` §16.3 and could not probe.

Binaries: SUBJECT `0e280fc62a91cec2…` (`libCQPass.so` `94602c7896e7a7ee…`), ORACLE
`5c6f7490a81c7505…`. Hashed before the first probe and after the last; **unmoved**. No build, no
suite (PROTOCOL review row). Worktree `/Users/sorenwilkening/Desktop/CQ_rev_b`, branch
`r13-r1-beta`; `diff -r --brief ir-pass <subject>/ir-pass` = empty, so the source I read is the
source that was built.

---

## F-β1 — **P1, SILENT MISCOMPILE SURVIVES.** Conjunct (2) requires the interfering rotation to be OUTSIDE `L`; the identical dephasing with the rotation INSIDE the loop body still ACCEPTS

`LoopLowering.cpp:3950` — `if (L->contains(&BB) || !DT.dominates(L->getHeader(), &BB)) continue;`
— skips every `@cq_theta_*` inside the loop, so `Rots` ends empty and `:3966`
`if (Rots.empty()) continue;` passes the loop over. But the dephasing mechanism does not care
whether the interference is after the loop or inside it: an unmarked body's interior rail is minted,
never `_unc`-ed and never freed, and any later non-diagonal gate on the register it copies — **in the
same trip included** — lands on a decohered mixture.

**Probe `probes/b7b_w2k_interfered.c`** is bd `s82e`'s own benign exhibit
`w2k_noregion_invread` — the program owner ruling **D4 ruled BENIGN** and the increment pins as an
ACCEPT via `loop_leak_dephase_accept_pertrip_dead.ll` — **with one line added**: `u = cq_theta(u, 0.9);`
before the trip ends. The invariant read of `y` still leaves the body unmarked, so the per-trip rails
still leak.

| | ORACLE | SUBJECT |
|---|---|---|
| `b7b_w2k_interfered` (rolled) | ACCEPT **20** lines | **ACCEPT 20** lines, lowered IR md5 `1dc4ebb6…` **equal to the oracle's** |
| `b7b_w2k_interfered_un` (hand-unrolled twin) | ACCEPT **24** lines | ACCEPT 24 lines |

The four missing lines are the (R-diverge) signature verbatim. Rolled:
`cq_template_lshr_i32_hl(h2,1) -> h3` … and nothing ever again. Twin:
`cq_template_lshr_i32_hl_unc(h2,h1,1)` **then** `cqrt_free(h2)`, twice. Then
`cqrt_ry_i32(h2, 0.9)` — tensored, non-diagonal — lands on `u`, whose qubits j≥1 are in the rolled
form maximally entangled with an ancilla nobody touches again; `cqrt_measure_i32(h2)` is the
observable. `cqrt_alloc_i32(6)` + `cqrt_ry_i32(h2, 0.4)` gives α,β ≠ 0 on every qubit, so the
`αβ·sin(0.9)` cross term is present in one circuit and absent in the other. This is the argument
Track S made at `IMPL_S` §0.2 and bd `tu9q` carries, unchanged except for where the rotation sits.
The `and` rail is measured in **both** forms and left allocated in both — symmetric, not the
divergence; the divergence is exactly the `lshr` rail.

**Second, independent instance — `probes/b7c_w2h_interfered.c`**, the same one-line addition to the
bead's *second* exhibit `w2h` (the in-loop PHASE region): **ORACLE 34 / SUBJECT 34** rolled against
**42** unrolled. Multiset diff over handle-normalised traces: the twin emits `2×
cq_template_and_i32_hl_unc`, `2× cq_template_lshr_i32_hl_unc` and **6 `cqrt_free` against the
rolled form's 2**.

**Why this matters more than one more instance.** It answers my brief's item 3 directly: **the
benign/divergent separation holds by accident on the bead's three exhibits.** Two of the three move
from (R-leak) to (R-diverge) under a one-line edit that changes nothing the fence looks at. D4's
benign ground — *"their joint garbage never reaches the retained subsystem"* — is a property of
those three **programs**, not of the shape conjunct (2) tests. Merge-gate **F-7** already recorded
that the twin matrix cannot separate benign from divergent; this shows the **fence** cannot either,
because the predicate it separates on is *the position of the rotation*, and the physics turns on
*whether the leaked rail's partner is interfered at all*.

STRICT stage 2b on the accepted rolled module: `2 rail mint(s) of which 2 left allocated, 0
cqrt_free site(s): 0 verified, **0 violation(s), 0 unproven**` — blind, exactly as the brief warned
(the leaked rail is TEMPLATE-minted, so there is no `cqrt_alloc` to count). Not clearance.

**Disposition.** Pre-existing (the ORACLE accepts identically, md5-equal), so this is not a
regression the increment introduced — it is the part of bd `s82e`'s P1 that ruling D4 believed was
closed and is not. Either conjunct (2) widens to in-loop thetas that are not the leaked rail's own
in-place base, or the decline's scope statement ("a register **live after the loop**") must be
corrected in `DECISIONS.md` D4, `LoopPlan.h`, the `LoopLowering.cpp` header and both
`loop_leak_dephase_accept_*` fixture headers, which today assert the benign half is benign.

---

## F-β2 — **P1, SILENT MISCOMPILE SURVIVES.** Conjunct (3) scans `BinaryOperator` only, and its written rationale for excluding compares is FALSE for a compare used as DATA

`LoopLowering.cpp:3983-3984` — `if (!taint.Tainted.count(&I) || !isa<BinaryOperator>(&I)) continue;`
`if (binaryStem(I.getOpcode()).empty()) continue;`. The source comment justifies the restriction:

> *"a compare rail is the region's own flag, which `emitCondNetwork` strips and frees itself, so it
> is not a divergence and widening to it would decline shipped accepts."*

That is true of a compare that **is** a region flag and false of one used as **data**. `CompareLowering`
lowers a tainted `icmp` whose result is ordinary data into an out-of-place
`cq_template_icmp_<pred>_<W>_hl` rail — a which-path copy — with no region and no `emitCondNetwork`
anywhere in the module. This is `CLAUDE.md` **L4**'s shape: a set-membership question answered by an
opcode-class proxy.

**Probe `probes/b11_cmp_rail_data.c`** — the body's only rail-minting interior op is an `icmp`
(`icmp → zext → cq_measure`); there is **no `BinaryOperator` in the loop body at all**:

```c
int y = cq_theta(5, 0.5);  int s = 0;
for (int k = 1; k <= 2; ++k) s += cq_measure(y > k);
y = cq_theta(y, 0.9);      return s + cq_measure(y);
```

| | ORACLE | SUBJECT |
|---|---|---|
| rolled | ACCEPT **10** | **ACCEPT 10**, md5 `9817ce03…` **equal to the oracle's** |
| hand-unrolled twin | ACCEPT **14** | ACCEPT 14 |

Rolled: `cq_template_icmp_sgt_i32_hl(h0,1) -> h1` and `…(h0,2) -> h3`, neither ever discharged.
Twin: `cq_template_icmp_sgt_i32_hl_unc(h1,h0,1)` + `cqrt_free(h1)`, and the same for `h3`. Then
`cqrt_ry_i32(h0, 0.9)` on the register both rails copy, then `cqrt_measure_i32(h0)`. **Every
conjunct except (3) is satisfied** — the body is unmarked, the post-loop chained theta is there and
dominated, the ancestry reaches it — so this is a single-conjunct miss, and it is the cleanest
statement of the class I found (10 vs 14, no control flow, five lines of C). The `zext` rail is
measure-owned and left allocated in both forms; the divergence is exactly the two compare rails.

STRICT 2b: `2 rail mint(s) of which 2 left allocated, 0 cqrt_free site(s): 0 verified, **0
violation(s), 0 unproven**`.

Pre-existing, like F-β1. **The fix is not simply `isa<BinaryOperator> || isa<CmpInst>`** — the
comment's worry about declining shipped region accepts is real; the discriminator wanted is "is this
compare a region flag the emitter owns", which the plan already knows, not the opcode class. Track S
named the cast/`fneg` half of this same gap at §16.1; I did not reproduce **that** half (see
"attacked, found nothing"), but the compare half proves the conjunct narrow regardless.

---

## F-β3 — **P2, NEW OVER-DECLINE (ACCEPT → DECLINE), introduced by this increment and not in its corpus sweep.** A dtzb IN-PLACE rail op passes conjunct (3) and mints no rail

This is `IMPL_S` §16.3, which Track S flagged, predicted the exact fix for, and could not construct
("both my probes died upstream… the corpus sweep is the only instrument left"). The sweep found no
mover because no corpus module has the shape. It is constructible.

**Probe `probes/b10_inplace_volatile.c`** — a constant trip count (so the loop is unguarded and the
header dominates the post-loop rotation, satisfying conjunct (2)) and a `volatile` operand (so `-O1`
cannot close-form the in-place chain away, which is what killed Track S's `s4_superseded_value`):

```c
int y = cq_theta(5, 0.5);  volatile int v = 1;
for (int k = 0; k < 3; ++k) y ^= v;
y = cq_theta(y, 0.9);      return cq_measure(y);
```

| | ORACLE | SUBJECT |
|---|---|---|
| rolled | **ACCEPT, 7 lines** | **DECLINE** `cq loop lowering: rolled body leaks a rail entangled with a register rotated after the loop` at `b10_inplace_volatile.c:10:11` |
| hand-unrolled twin | ACCEPT, 7 lines | ACCEPT, 7 lines |

**The rolled trace is BYTE-IDENTICAL to the twin's** (`cmp` clean): `cqrt_alloc_i32(5) -> h0`,
`cqrt_ry_i32(h0,0.5)`, `cqrt_xorc_i32(h0,1)` ×3, `cqrt_ry_i32(h0,0.9)`, `cqrt_measure_i32(h0)`.
`cqrt_xorc_i32` is the **in-place** emission: it relabels the rail, returns no handle, mints nothing.
There is no interior rail, nothing to leak, and **no divergence to protect against** — so the
program the compiler previously compiled to a provably-rolled-correct circuit now loudly declines.
Per the owner's 2026-09-11 ruling that is a defect to remove, not a safety margin.

Track S's pre-specified fix — one conjunct `!taint.InPlaceRailOps.count(&I)` — is the right shape,
with **two cautions it already half-stated and one I am adding**: (a) `InPlaceRailOps` is a raw
`Instruction *` set nothing scrubs (F-W2-4), so using it to SUPPRESS a decline means a recycled
pointer silently excludes a real candidate; (b) **new** — this stage runs at `CQLoweringPass.cpp:772`
/ `:1197`, i.e. **before `lowerOps`**, and `CLAUDE.md` records that `lowerOps` **re-verifies every
pre-loop in-place marking under FINAL taint and declines loudly when it fails**. A conjunct read
here is therefore reading a marking that is *not yet final* — the L1 species, in the granting
direction. Red-green it against this probe with that asymmetry stated.

---

## L1 (brief item 4) — **Track S's argument is CORRECT. Verified, not accepted.**

`taint.IterationLocalBlocks` has exactly **two writer sites**, both found by
`grep -rn "IterationLocalBlocks\.\(insert\|clear\|erase\)"`: `LoopLowering.cpp:2471`
(`markIfIterationLocal`, all of `L->blocks()`) and `:3609` (`markIfRailLocal`, `L`'s OWN blocks
only). Ordering, both entry points:

| | `lowerLoops` | round-1 `collapseFlattenedLoopRails` | `repropagateControlMerges` | **the decline** |
|---|---|---|---|---|
| `run()` | `:455` | `:555` | `:571` | **`:772`** |
| `runOnFunction` shim | `:1088` | *(absent — pre-existing, bd `8h7d.5`)* | `:1115` | **`:1197`** |

`repropagateControlMerges` itself re-invokes `collapseFlattenedLoopRails` (`TaintPropagation.cpp:1998`),
so all three marking invocations precede the stage in both entry points and it reads **final** taint
and a **final** marking set. The "no record needed" claim holds: this is an OUTCOME read after the
fixpoint, not a predicate recorded at a refusal, so the `markBranchPhaseGate` failure mode (a seventh
site that forgets the `push_back`) cannot arise. The shim's missing round-1 call marks **less**,
hence declines **more** — safe direction, and unchanged by this increment. **No L1 finding.**

⚠ One observation, not a finding: the two writers **disagree about subloop blocks** (`:2471` inserts
all of `L->blocks()`, `:3609` filters `LI.getLoopFor(BB) == L`), while conjunct (1) reads
`L->blocks()` and takes ANY. I could not turn that asymmetry into a probe and I do not claim it is
exploitable; recording it because `IMPL_S` §16.4 asserts the two markers "both insert all of `L`'s
own blocks at once", and on the subject they do not insert the same set.

---

## What I attacked and found NOTHING in (Rule 19 — these are runs, not intentions)

* **Conjunct (2)'s DOMINANCE-vs-reachability gap** (`IMPL_S` §16.2), twice: `b1_condloop_dom.c` (the
  loop under a classical `if`, `main` passing `argc` so the branch survives) and
  `b9_guarded_loop_dom.c` (an `n & 3` trip count, so `-O1` keeps the zero-trip guard and the header
  provably does not dominate the rotation). **Both decline on BOTH binaries** with
  `cq opcode lowering: operand predates a non-diagonal gate` — the bd `3d8q` stale-reader fence masks
  the gap for the shapes I could build. The gap is real in the source; I could not reach it.
* **Conjunct (2)'s CALLEE-NAME test** — whether a post-loop non-diagonal gate can stop being a
  `@cq_theta_*` call before this slot, because a region emitter already minted
  `cqrt_ry_<W>_controlled`. `b3_ctrl_ry_after.c` (compare-conditioned in-place controlled-Ry arm
  after the loop) and `b8_angle_select_after.c` (folded angle select, Ry stem, constant arms) **both
  DECLINE on the subject**: the theta call survives to this slot in both shapes (the emitter records
  the control in `taint.ControlledRotations` and leaves the call for `lowerRotations`). Conjunct (2)
  is not defeated this way.
* **`railIsInterior`'s MEASURE-OWNED exclusion** — `b5_measure_owned.c`, whose only in-body tainted
  binop is an `lshr` with a single `cq_measure` user. **8 == 8** rolled vs unrolled: the exclusion is
  sound on this instance, both forms leave the rail allocated, Rule 6 as written.
* **The CAST half of `IMPL_S` §16.1** — `b4_fpcast_rail.c` (`w = (double)(float)w` on a loop-carried
  tainted phi). **10 == 10, no divergence**: `-O1` folds `fptrunc(fpext(t)) → t`, so the second
  trip's cast collapses onto the first's and LICM hoists the pair clean out of the body — the trace
  shows one `cq_template_fptrunc…` pair *with* its `_unc` + `cqrt_free`. Every other spelling I tried
  needs a loop-variant operand, which needs a binop, which conjunct (3) then catches. **I did not
  reproduce a cast-minted instance and I am not claiming one is unreachable** — F-β2 makes the point
  the cast probe was meant to make, by a different opcode class.
* **The leaked rail copying a register re-rotated on a LATER trip** — `b2_carried_inloop_rot.c`.
  Declines on both with `cq taint escape: tainted value muxed by a classical-condition phi`. Masked
  upstream.
* **`b7_pertrip_interfered.c`**, the naive form of F-β1 without the invariant read: **18 == 18**. The
  per-trip register makes the body iteration-local, it is MARKED, conjunct (1) skips it and the spine
  discharges in-body — which is conjunct (1) working exactly as its positive control claims. This is
  why F-β1 had to keep `w2k`'s invariant read.

## Instrument discipline — what I attacked in my OWN harness, and what it caught

`probes/rb.sh`, written for this review (not inherited), deletes every derived artifact before each
run so **a stale trace cannot make a run that never linked look like an accept** (the failure Track S
measured on the inherited harness), reports `BROKEN-EMPTY-OUTPUT` and `A:LINKFAIL` as distinct from
an accept, and carries an explicit **vacuity guard**: a stage-1 module with zero `cq_{theta,phi,measure}`
calls is reported `VACUOUS-NO-QUANTUM` rather than ACCEPT. Attacked with two deliberate mutants
before any real probe — `i0_empty.c` (0 bytes) and `i1_noquantum.c` (a real loop, no intrinsics) —
and **both were caught**; without the guard both would have scored ACCEPT through the passthrough
early-out (bd memory `empty-module-accepts-vacuity-trap`).

Calibrated in **both** directions before use, reproducing `IMPL_S` §12.1 independently: movers
`s1_live_shift` (ORACLE A:10 → SUBJECT DECLINE) and `s2_live_derived_region` (A:19 → DECLINE), and
non-movers `s3_live_rootmint_region` (22/22), `w2k` (16/16), `w2h` (30/30), `w2h3` (44/44). A harness
that reproduced only the declines would be one that declines everything.

**bd `1yeu` / the `@main` decoy**: every probe is one `slice` plus a `main` that `-O1` inlines, so
each module carries two copies of the stream. This does not affect my verdicts — they are read off
**runtime traces** and off `opt`'s **exit code plus the `!dbg` source line** (`b10…c:10:11`), neither
of which can be satisfied by the wrong copy — but it does mean **F-β1/F-β2 are one-function
findings and a genuinely cross-function spelling of the same leak is invisible to my probes too**.

**Stage 2b is cited nowhere as clearance.** I ran it on both surviving over-accepts and it printed
`0 violation(s), 0 unproven` on each — recorded as evidence of its blindness, which is what my brief
predicted and what the class requires.

## What I could not do

* No build and no suite (PROTOCOL review row) — so I have **not** checked whether fixing F-β3 keeps
  `ir-pass-lit` green, and I have not run the shipped fixtures.
* **No cast-minted or `fneg`-minted instance** (above), and **no cross-function instance** of any
  finding.
* **No probe for the superseded-value-rail direction** (`IMPL_S` §11/§16.3's other half) — my
  in-place probe reached the in-place question instead.
* I did not attempt to bound **how many more** members the class has beyond the two new spellings; my
  brief's item 2 asked "how many more are there", and the honest answer from one round is **at least
  two families the fence does not cover, found in one round by attacking two named conjuncts** —
  which is `CLAUDE.md` Rule 13's "the next round finds something", and I would budget round 2 rather
  than read three green conjuncts as a closure.
