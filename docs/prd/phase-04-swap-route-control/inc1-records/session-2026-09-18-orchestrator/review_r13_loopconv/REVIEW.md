# Rule-13 review — the loop group's TWO merge-derived CONVERSIONS, `r3`'s A×B composition, and a second opinion on bd `tu9q.1`

# VERDICT: **FINDING** — one P1 over-accept (F-1), plus 3 items (F-2 P3, F-3 P3, F-4 P3)

Independent second reviewer, session 2026-09-18. I wrote none of this code, **ran no build and no
suite**, edited no source, fixture or test, and wrote only under `$SES/review_r13_loopconv/`.
Everything below is the per-probe pipeline against the frozen ORACLE plus analytic/trace reasoning
(no simulation — owner 2026-06-10).

**ORACLE verified before any measurement:** `shasum -a 256 build/ir-pass/cq-opt` =
`9bd01598d574b344646281a144cf628ed4ed947d6d20df61cfcb717d321a13b3`, matching `$SES/PROTOCOL.md`
character-for-character; `main` at `cff8f7ac`, pass source unchanged since `95949550`. Gate lines in
`GATES.md`; every one is a single-probe run, so nothing was announceable under §6.1 and nothing was
cited or re-run.

**Headline, in the order the reader needs it:**

* **The two conversions themselves are RIGHT.** `c1` re-measured 14 == 14 **byte-identical**; `c2`
  24 vs 24 with the symbol multiset delta EMPTY **and** — stronger than the fixture header claims —
  the **argument-level** multiset delta empty too. I give the independent analytic argument in §A.2
  and it does not lean on either equality.
* **`r3`'s A×B composition is RIGHT and is the safe direction**, and it survives one level deeper
  than anyone has taken it (§B).
* **bd `tu9q.1` gets its missing witness.** The shipped transfer witness argues the **non-break**
  path only; I built a break the runtime actually takes and measured the break path directly —
  byte-identical to the straight-line program it denotes, at three separate break points (§C).
* **But the door both conversions walk through does not hold in general.** Conjunct (1)'s
  `bodyBlocksMarked` suppression rests on *"a marked body discharges in-body, once per trip … and is
  byte-identical to its hand-unrolled twin"*. **That is true for a single-block body and false for a
  multi-block one**, and a two-block marked body leaks a coherent which-path rail at a non-diagonal
  gate on the register it copies, at `opt` exit 0. **F-1.** The conversions are not its customers —
  both bodies are one block — but they are pinned by a suppression that is.

---

## What I read

`$REPO/CLAUDE.md` (Prime Directive; Rules 2, 6, 8, 11, 13, 19; CORRECTNESS RISK §3 L1–L10, §4c,
§5's Q-R1-1 correction). `$SES/PROTOCOL.md` whole, including §6.1. `$PREV/loopfix/FIX.md` whole
(§1, §1a, §2, §3, §4, §6, §8) and `$PREV/loopfix/probes/README.md` with the probe sources
(`n1–n3`, `r1–r5`, `x1/x8/x9`, `t5a/t5b`, `c1/c2`). `$PREV/review_r13_loop/REVIEW.md` whole,
including its own "what I attacked and did NOT find anything on" list. `bd show` for
`test_C_libtooling-emkg`, `-tu9q.1`, `-s82e`. Both converted fixtures' full headers
(`loop_leak_dephase_reject_{cmp_rail_data,inloop_rotation}.ll`).

**Source, read and not remembered:** `LoopLowering.cpp` — `bodyBlocksMarked` (`:4435`) with its
whole argued header (`:4375–4434`), `declineDephasingUnmarkedLoopRails`' conjuncts (1)/(2)/(3)
(`:4718–4878`), `railLocalQualifies` (`:3647`), `markIfRailLocal` (`:3738`),
`invariantRegisterRootsImpl` (`:3370`), `markIfIterationLocal` (`:2421`).
`Uncomputation.cpp` §4's backstop (`:940–1030`) including the `DT.dominates(G, At)` /
`PDT.dominates(At->getParent(), G->getParent())` pair and the §2.9 twin. `FreePoint.cpp`
`computeFreePoint` (`:165–356`). `tools/free_pairing_check.py` docstring and its census
(`:2628–2665`, `:2754–2831`).

---

## A. The two merge-derived conversions

### A.1 Which two, established from the record and from the tree

`FIX.md` §1a names them and `$PREV/loopfix/probes/` carries their programs:
`ir-pass/test/loop_leak_dephase_reject_cmp_rail_data.ll` (= `c1_cmp_rail_data.c`) and
`ir-pass/test/loop_leak_dephase_reject_inloop_rotation.ll` (= `c2_inloop_rotation.c`). Both still
carry `*_reject_*` in the name and both now have a positive `RUN: %cq-opt … > %t.cqd0.ll` line
rather than a `RUN: not …` — confirmed by reading the RUN lines of all twelve
`loop_leak_dephase_*.ll` in the tree. (The third `gahu` un-renamed accept,
`loop_leak_dephase_reject_noregion_live.ll`, is *not* one of the two: `FIX.md` §1 resolves it at the
merge CONFLICT and `review_r13_loop` §I-9 had already adjudicated it, so it is not "a class the
review did not check".)

### A.2 The independent argument — it does not rest on the twin equality

**`c1` (`loop_leak_dephase_reject_cmp_rail_data.ll`).** Rolled stream re-measured on the ORACLE, 14
lines. Per trip `k`:

```
cq_template_icmp_sgt_i32_hl(h0, k) -> hA     mint: hA ⊕= [y>k]
cq_template_zext_i1_to_i32(hA)     -> hB     mint: hB ⊕= zext(hA)   (reads hA, writes hB)
cq_template_icmp_sgt_i32_hl_unc(hA, h0, k)   adjoint: hA ⊕= [y>k]  ⇒ hA = |0>
cqrt_free(hA)
cqrt_measure_i32(hB)                         the user's own cq_measure
```

*Rule 6.* `hA` is written exactly twice, by the forward and by its adjoint, with the same operand
`h0` unchanged between them (no gate touches `h0` inside the body). The intervening `zext` reads
`hA` as a control and writes only `hB`, so it does not disturb it. Therefore `hA = |0>` in **every**
branch at the free — `Σ_y α_y|y⟩|0⟩_hA|f(y)⟩_hB` is a product state in `hA` — and the free collapses
nothing. This is Bennett compute–copy–uncompute, stated on the actual operands rather than by
analogy.

*Rule 8.* The only rails alive at `cqrt_ry_i32(h0, 0.9)` (line 13) are the `zext` rails `hB`, and
**each was measured before it** (lines 7 and 12). A measured copy is not a coherent which-path
record: the measurement projects the joint state into `Σ_{y: f(y)=b} α_y|y⟩ ⊗ |b⟩`, which is a
product, so the rotation acts on the `h0` factor alone. The dephasing Rule 8 names needs the rail
entangled *at the interference*, and it is not. This is clause (ii-c)'s physics ground, and it is
the right ground — `FIX.md` §5(2) corrects the multiplicity argument to exactly this.

*Rule 5.* No measurement appears that the user did not write: two `cq_measure(y>k)` plus the final
one, three in the source, three in the trace.

**`c2` (`loop_leak_dephase_reject_inloop_rotation.ll`).** 24 vs 24, not positionally identical. The
header's claim is multiset-plus-commutation; I verified it **and one level stronger**: the delta of
the traces with handle NUMBERS normalised (`sed 's/h[0-9]*/hN/g' | sort`) is also **empty**, so the
divergence is a pure reordering with identical arguments, not merely identical symbols. The single
moved gate is the LICM-hoisted `cq_template_and_i32_hl(h0,1)` (rolled line 3, twin line 10). Its
support is `{h0 read, fresh ancilla written}`; every gate between the two positions
(`cqrt_alloc_i32(6)`, `cqrt_ry_i32`, `lshr`, `and`, `lshr_unc`, `cqrt_free`, one measure) acts on
the per-trip register `u` and its own ancilla — **disjoint support, so the reorder commutes
exactly**, and an allocation of a fresh |0⟩ rail tensors in, so crossing it is a relabelling. The
per-trip `lshr` rail is minted, adjointed and freed **inside the body** in both forms; the `y & 1`
rail is measure-owned and **left allocated by both**, identically.

⚠ Both arguments are given **without** appealing to the twin equality, deliberately — owner S3
(`$THIS/DECISIONS.md`): byte identity is the instrument, not the target. The equalities corroborate.

### A.3 Attacks on the conversions — ≥3 one-operand variants each, measured on the ORACLE

| probe | one-operand delta from the conversion | ORACLE verdict | right? | why |
|---|---|---|---|---|
| `a1_c1_two_postloop_rots` | a **second** post-loop `cq_theta(y,0.3)` | ACCEPT 15, twin 15, **BYTE-IDENTICAL** | ✅ | both compare rails adjointed + freed before either rotation; survivors are measured `zext` rails |
| `a2_c1_rail_alive_at_rot` | `cq_measure(y>k)` → `(y>k)`: the record is **alive and unmeasured** at the rotation | ACCEPT 18, twin 18, **BYTE-IDENTICAL** | ✅ | all four rails (2 `icmp`, 2 `zext`) adjointed + freed before `ry(h0,0.9)`; the one survivor is the user's own `s`, which the source **requires** to stay entangled |
| `a3_c1_one_loop_deeper` | wrap the loop in `for(i=0;i<2;++i)` | ACCEPT 24, twin 24, **BYTE-IDENTICAL** | ✅ | four complete mint/unc/free groups precede the rotation |
| `a4_c1_parent_gated_in_body` | move `y = cq_theta(y,0.9)` **into** the body (the rail's borrowed parent gated per trip) | DECLINE `cq taint escape: tainted value muxed by a classical-condition phi` | ✅ safe (over-decline candidate, **pre-existing family**) | a loop-carried quantum register; the known loop-carried wall, not a conversion defect |
| `a5_c1_second_reader_postloop` | the last trip's compare **escapes** and is read after the rotation | DECLINE `cq loop lowering: rolled body leaks a rail entangled with a rotated register` (twin ACCEPTs 15) | ✅ | the rail cannot be discharged per trip; **this is the positive control that the fence is still ARMED in this family after the conversion** |
| `b1_c2_postloop_rot_on_y` | add `y = cq_theta(y,0.7)` after the loop — **a non-diagonal gate on the register the LEFT-ALLOCATED hoisted rail copies** | ACCEPT 25, twin 25, arg-multiset **EMPTY** | ✅ | the hoisted `y&1` rail is measured at lines 11 and 21, i.e. **before** the line-24 rotation; measurement disentangles it, so Rule 8's premise fails |
| `b2_c2_rail_unmeasured` | `cq_measure(y&1)` → `(y&1)` | DECLINE `cq loop lowering: loop-carried tainted value crosses iterations` | ✅ safe | the accumulator becomes a loop-carried quantum register; known wall |
| `b3_c2_one_loop_deeper` | wrap in an outer loop | ACCEPT **44 vs twin 45** | ✅ | the sole delta is **one extra `and_i32_hl(h0,1)` in the TWIN** — rolled LICMs the invariant through *both* loops (1 mint), the twin mints per unrolled body (2). Both are measure-owned, left allocated, and measured. Per-trip discharge pairs **4/4/4 in both**. The rolled side leaks **less** |
| `b4_c2_parent_gated_in_body` | add `y = cq_theta(y,0.2)` inside the body | DECLINE taint escape | ✅ safe | same known wall |
| `b5_c2_second_reader_postloop` | the per-trip `(u>>1)&1` escapes the body | DECLINE `rolled body leaks a rail entangled with a rotated register` (twin ACCEPTs 25) | ✅ | fence armed |
| `b6_c2_deeper_postloop_rot` | `b3` **plus** the post-loop rotation, so `b3`'s divergence stands at a real interference | ACCEPT 45 vs twin 46 | ✅ | identical to `b3`; both `y&1` copies measured before the rotation; discharges 4/4/4 in both |

**Nothing in this table moves the conversions.** The two declines that share the conversions' own
fence (`a5`, `b5`) fire with the exact string, which is the property a conversion is most likely to
have broken and did not.

⚠ **One instrument note that a later round should not have to re-derive.** `b3`/`b6` report
44 vs 45 and 45 vs 46. **A nested twin pair's line counts are expected to differ by the number of
loop-invariant rails LICM hoists past the outer loop**, and the difference falls on the *unrolled*
side. Read the multiset and the per-trip `mint/unc/free` triple, never the total — the same lesson
`FIX.md` §3 records from the opposite direction (`r1`'s 72 == 72 hiding a real divergence).

---

## B. `r3`'s A×B composition — Track S′'s widened conjuncts × the `emkg` own-blocks filter

**What each part contributes.** `r3_nested_cmp_rail_outer.c` has an outer loop whose *own* rail is
an `icmp` used as **data** (`s += cq_measure(y > i)`) and an inner loop that is marked. Two
independent things must hold for it to decline:

* **A = the `emkg` fix (conjunct (1) → `bodyBlocksMarked`).** Without it, the marked INNER loop puts
  a marked block in `L_outer->blocks()`, conjunct (1) sets `Marked` and `continue`s, and conjuncts
  (2)/(3) are never asked of the outer body at all. The outer's own rail is never examined.
* **B = Track S′'s conjunct-(3) membership widening (bd `7845`).** Even once (1) lets it through,
  the old `isa<BinaryOperator> && !binaryStem.empty()` test does not recognise an `icmp` as a rail
  minter, so (3) finds nothing in the outer body. S′ replaced it with `mintsOutOfPlaceTemplateRail`,
  which asks `isDataPositionCompare` and `compareFlagMintable` by calling them.

**Composed verdict, argued from source before measuring.** With A, `L_outer`'s own blocks decide and
they are unmarked (the outer body reads `y`, which is on the rail, but the inner loop's blocks are
excluded from the question). Conjunct (2): `y = cq_theta(y, 0.9)` after the loop is chained, and
`L_outer->getHeader()` dominates its block, so `Rots` is non-empty. Conjunct (3): `%cmp = icmp sgt
%y, %i` sits in `L_outer`'s own blocks, is tainted, mints an out-of-place
`cq_template_icmp_sgt_i32_hl`, is **interior** (its user is a `zext`, not a `cq_measure`), and its
ancestry reaches `y ∈ Rots`. **DECLINE.** Measured: exactly that, with the exact string and a `!dbg`
at `r3_nested_cmp_rail_outer.c:11:14`; the hand-unrolled twin ACCEPTs at 42. So the composed
verdict is the **safe** one and it needs **both** halves — `FIX.md` §4 says so and I confirm it by
re-deriving it rather than by re-reading the table.

**Attacks, including the `emkg` conjunct-(1) shape one level deeper:**

| probe | one-operand delta | ORACLE verdict | right? | why |
|---|---|---|---|---|
| `r1_triple_nest_mid_rail` (shipped fixture, re-measured) | DEPTH 3, the rail on the **middle** loop | DECLINE; twin ACCEPTs **72** | ✅ | the pinned `emkg` fourth customer; line counts agree 72 = 72 while the multiset does not — I re-measured the decline, not the multiset |
| `r1_triple_deeper` (**new**) | **DEPTH 4** — the rail on level 2 with **two** marked loops below it | DECLINE `rolled body leaks a rail entangled with a rotated register` | ✅ | the own-blocks filter still reaches the level-2 rail when the suppression has two descendants to be fed by; the `emkg` fix is not depth-2-specific |
| `r3_outer_rail_inner_marked_nodeeper` (**new**) | `r3` with the outer rail made **interior by accumulation** rather than by the `zext` | DECLINE `loop-carried tainted value crosses iterations` | ✅ (different owner) | a boundary probe that lands on the loop-carried wall before the fence; records that this route does not reach `r3`'s conjunct |

**I found nothing against `r3`.** The composition is correct, and it is correct in the direction
where being wrong would be an over-decline, not a miscompile — which is the lighter half of the
`CLAUDE.md` §4c lesson, and I say so rather than presenting it as a strong clearance.

---

## C. bd `test_C_libtooling-tu9q.1` / `r1_break_loop` — the second opinion the bead asks for

### C.1 Is the transfer witness an argument about the break path, or only the non-break path?

**Only the non-break path, for its trace half; the break path is covered by a *different* claim in
the same sentence, and the two should not be quoted as one witness.** `FIX.md` §6 runs them
together: *"the transfer witness holds — `-O1` folds the `break` into one extra disjunct on the
LATCH so the body is a single block …, the break-free twin `t5a_nobreak` is 24 == 24
byte-identical, and `diff r1_break_loop.trace t5a_nobreak.trace` is EMPTY."* Taking them apart:

* The **trace** half (`t5a` 24 == 24, and `r1_break_loop`'s trace equal to `t5a`'s) is worth exactly
  what the runtime can exercise. `r1_break_loop`'s break predicate is `s > 1` where `s` is a sum of
  `cq_measure` results, and the **trace runtime returns 0 from every measure**, so the break is
  never taken. The two traces are equal *because the break did not happen*. That half witnesses the
  non-break path and nothing else, and it would look identical if the break path were broken.
* The **atomicity** half (mint/mint/`_unc`/free/measure all in ONE basic block, so the break can
  only cut at a group boundary) **is** an argument about the break path. It is sound. But it is a
  property of `-O1`'s output for that one program, **not** anything the compiler enforces — and
  `review_r13_loop` §I-1 said as much (*"a measurement about today's binary, not a proof"*).

### C.2 The break-path witness the bead says does not exist — built and measured

`probes/t5c_classical_break_taken.c` is `r1_break_loop` with **one operand changed**: the break
predicate becomes `k >= lim` with `lim` derived from `argc`, i.e. **classical and opaque at compile
time**, so the runtime takes it. The reference is `probes/t5c_ref_two_trips.c`, the straight-line
program the loop *denotes* at `lim == 2`.

```
t5c_classical_break_taken   ACCEPT, 14 trace lines   (break taken at k == 2)
t5c_ref_two_trips           ACCEPT, 14 trace lines
diff → *** BYTE-IDENTICAL ***
```

and across break points (`probes/argsweep.sh`, bash):

```
argc=1 lim=2 | lines=14 mints=2 uncs=2 frees=2
argc=2 lim=3 | lines=19 mints=3 uncs=3 frees=3
argc=3 lim=4 | lines=24 mints=4 uncs=4 frees=4      (break on the LAST trip)
argc=4 lim=5 | lines=24 mints=4 uncs=4 frees=4      (bound, no break)
argc=5 lim=6 | lines=24 mints=4 uncs=4 frees=4
```

**mints == uncs == frees on the trip the break fires, at every break point.** The lowered `@slice`
confirms the structure directly: the body is the single block `%3` holding
`lshr` / `and` / `lshr_unc` / `cqrt_free` / `measure`, and the break is
`%10 = select i1 %7, i1 true, i1 %9` on the latch. This is the witness bd `tu9q.1` lists as closure
condition **(a)**, obtained by making the predicate classical rather than by finding a usable twin.

### C.3 Does `Uncomputation`'s post-dominance clause cover multi-exit for this shape?

**No — it is satisfied vacuously and never reasons about the break.** The clause (read in source,
`Uncomputation.cpp` §4) is

```cpp
if (!DT.dominates(G, At))                                   return false;
if (!PDT.dominates(At->getParent(), G->getParent()))        return false;
```

For `r1_break_loop` and for `t5c`, `G` and `At` are in the **same** basic block, so both are true by
identity. The clause therefore decides nothing here; **what protects this shape is that the `tu9q`
pairing emits the `_unc` and the `cqrt_free` in the mint's OWN block**, and a same-block group
cannot be split by any CFG edge, break or otherwise. That is a *stronger* property than post-
dominance and it is the one that should be recorded (see F-2).

I also removed the previous round's confound. `t5b_break_split` declines at bd `3d8q`, and one could
argue that decline came from the *measure-derived* predicate. It does not: `t5d_classical_break_split`
and `t5e_classical_break_midgroup` are the same shapes with **classical** predicates and both still
decline at `3d8q` (`cq opcode lowering: operand predates a non-diagonal gate`).

### C.4 The shape that defeats it — constructed, and it is worse than a break question

Removing the post-loop rotation lifts `3d8q`, and then multi-exit break loops **do** reach the
lowering:

* `t5f_break_split_norot` — a genuine **multi-exit** loop in the lowered IR (body blocks `%3` and
  `%8`, exiting edges `%3→%15` and `%8→%15`). ACCEPT 23, **BYTE-IDENTICAL** to its `lim == 2`
  reference. Correct, and correct for the §C.3 reason: each block holds *complete* groups.
* `t5g_break_midgroup_norot` — mint before the exit, read after. `-O1` **sank** the mint into the
  guarded block (`CLAUDE.md` Rule 9), restoring atomicity. ACCEPT 8, correct.
* `t5h_rail_straddles_break` — the rail is used in **both** body blocks (`d & 1` before the exit,
  `d & 2` after), so the mint cannot sink and the free point lands past the break edge. **ACCEPT
  11 against the flat reference's 15**, stage 2b `3 template rail mint(s) of which 1 left dirty,
  0 cqrt_free site(s)`. **This is F-1.**

And then the discriminant turned out **not to be the break at all** — see F-1.

**Recommendation on bd `tu9q.1`:** the *break* half is CLEAR and closure condition (a) is now met
(§C.2). Condition (b) should be answered **in the negative and re-aimed**: the post-dominance clause
does not cover multi-exit for this shape; same-block atomicity does. **Do not close the bead until
F-1 is dispositioned**, because `t5h` is a break spelling of F-1 and closing `tu9q.1` on §C.2 alone
would retire the only bead currently pointing anywhere near it.

---

## FINDINGS

### F-1 (P1 — OVER-ACCEPT / wrong unitary). A MARKED loop body with MORE THAN ONE BASIC BLOCK leaves its interior which-path rail undischarged, and conjunct (1)'s `bodyBlocksMarked` suppression is what silences the fence

**Reproducing probe:** `$SES/review_r13_loopconv/probes/t5j_twoblock_noexit_rot.c` (and its break
spelling `t5h_rail_straddles_break_rot.c`).

```c
for (int k = 1; k <= 4; ++k) {
    int d = (y >> k);
    s += cq_measure(d & 1);
    if (k < lim) s += cq_measure(d & 2);   /* re-joins inside the loop; NO break */
}
y = cq_theta(y, 0.9);
return s + cq_measure(y);
```

**Measured on the ORACLE `9bd01598`:** `opt` **exit 0**; stderr carries only a *warning*
(`cq rotation lowering: non-diagonal gate over a live derived record`); 18 trace lines; stage 2b
`3 template rail mint(s) of which 1 left dirty, 0 cqrt_free site(s): 0 verified, 0 violation(s),
0 unproven` **and exit 0**. The trace contains **four** `cq_template_ashr_i32_hl(h0, k)` mints and
**zero** `ashr…_unc`, **zero** `cqrt_free`, followed by `cqrt_ry_i32(h0, 0.9)` and
`cqrt_measure_i32(h0)`.

**Why it is a wrong unitary and not a Rule-6 accepted leak.** Each leaked rail `hK = ashr(h0, k)` is
32 bits wide; only `hK & 1` (and on one trip `hK & 2`) is measured, so **bits 2..31 of `hK` — i.e.
bits 3..32 of `h0` — are never measured and stay entangled with `h0`.** The rail is a *coherent*
which-path record standing at a non-diagonal gate on the register it copies, and that register is
then the program's observable. `CLAUDE.md` Rule 8 verbatim: *"a permutation that leaves a rail dirty
**and entangled** still dephases under later interference"*, and §5's Q-R1-1 correction states the
disposition in the words that apply here: *"Where the same register is rotated by a NON-DIAGONAL
gate after the loop and then measured, it is a wrong unitary."*

**The isolation — three controls, each one line from the witness:**

| probe | delta | verdict | what it proves |
|---|---|---|---|
| `t5i_straddle_nobreak_rot.c` | the `if (k < lim)` removed ⇒ **one** body block | ACCEPT 32, `0 left dirty`, **2 cqrt_free sites verified**, **no warning** | the pairing discharges correctly when the body is one block — so the defect is the SECOND BLOCK, not the rail, the fan-out, or the interference |
| `t5h_rail_straddles_break{,_rot}.c` | the same split spelled as a `break` | ACCEPT 11 vs flat 15 / ACCEPT 12 | the break is *a* spelling, not *the* cause |
| `t5k_twoblock_unmarked_control.c` | the same two blocks, plus an escaping iteration-local temp so `railLocalQualifies` refuses the marking | **DECLINE** `cq loop lowering: rolled body leaks a rail entangled with a rotated register` | **the fence is ARMED for exactly this shape and the MARKING is what silences it** |

**Where it enters, from source.** `t5j` satisfies conjunct (2) (`y = cq_theta(y,0.9)` is chained and
the header dominates its block) and conjunct (3) (`%h_op = ashr` is tainted, mints an out-of-place
`cq_template_ashr_i32_hl`, is interior — its users are two `and` templates, not `cq_measure` — and
its ancestry reaches `y ∈ Rots`). The only remaining exit is conjunct (1), and `t5k` — the same
module with the marking refused — declines through (3) with the exact string. So the suppression is
the door, by measurement and not by reading.

**Why the suppression's premise fails.** Conjunct (1)'s in-source argument is *"A marked body
discharges in-body, once per trip, against a once-per-trip forward stream — the affirmative 7.3
exception — and is byte-identical to its hand-unrolled twin."* `markIfRailLocal` inserts **all of
`L`'s own blocks**, so a body with internal classical control flow is marked **wholesale**; but
`computeFreePoint` puts `At` at the nearest common post-dominator of the *use* blocks, and its only
iteration-local guard is `IterationLocalBlocks.count(At->getParent())` — **membership, not
same-block-as-the-mint**. A rail whose uses span two marked blocks therefore gets a free point in a
different block from its mint, and the discharge does not survive. **Marked ⇏ discharged in-body.**

**Relation to the open beads — it is a different door to a known room, and I am explicit about
what I did NOT measure.** bd `s82e` is the **unmarked** leak (`markIfRailLocal`'s "accumulating
loop-invariant tainted input" clause refuses the marking and the region is emitted anyway). F-1 is
the **marked** leak: the marking is *granted* and the discharge still does not happen. Same hazard
class, different mechanism, and a fix for one need not reach the other — the fix agent should check
whether one does. ⚠ **I did not measure whether F-1 is a regression from the loop group or
pre-existing**, because this role builds nothing. The *reasoned* expectation is that it is a
regression: the body is marked only because bd `tu9q`'s round-1 root-mint escape admits `y`'s root
mint into `Roots`, without which `railLocalQualifies` refuses and conjunct (3) declines. **That is an
inference, not a measurement** — the fix agent owes the one-command check on the pre-group binary:
`clang -O1 -g` `t5j_twoblock_noexit_rot.c`, then `cq-opt` on `0e280fc6…` and on `ce3f8f3d…`.

**bd-fileable text (do NOT file from here):**

> **P1 OVER-ACCEPT — a MARKED loop body with more than one basic block leaks its interior
> which-path rails, and `declineDephasingUnmarkedLoopRails` conjunct (1) is silenced by the marking.**
> Found by the Rule-13 review of the loop group's merge-derived conversions, session 2026-09-18,
> on ORACLE `9bd01598d574b344`.
> WITNESS `t5j_twoblock_noexit_rot.c`: a 4-trip loop whose body is split by a *re-joining* classical
> `if` (no break), with `y = cq_theta(y,0.9)` after the loop. `opt` exit 0, WARNING only
> (`non-diagonal gate over a live derived record`), 18 trace lines, stage 2b
> `3 template rail mint(s) of which 1 left dirty, 0 cqrt_free site(s)` at exit 0. Four
> `cq_template_ashr_i32_hl(h0,k)` mints, ZERO `_unc`, ZERO `cqrt_free`, then `cqrt_ry_i32(h0,0.9)`
> and `cqrt_measure_i32(h0)`. Only 1–2 bits of each 32-bit rail are measured, so the rails are
> COHERENT which-path records at the interference — Rule 8, not a Rule-6 accepted leak
> (`CLAUDE.md` §5 Q-R1-1: *"rotated by a NON-DIAGONAL gate after the loop and then measured … it is a
> wrong unitary"*).
> ISOLATION, one line each: `t5i_straddle_nobreak_rot.c` (ONE body block) discharges — 32 lines,
> `0 left dirty`, 2 frees verified, no warning; `t5k_twoblock_unmarked_control.c` (same two blocks,
> marking refused) DECLINES with `cq loop lowering: rolled body leaks a rail entangled with a rotated
> register`. The marking is the door; the second block is the cause; the break is only a spelling
> (`t5h_rail_straddles_break{,_rot}.c`, 11 vs a flat 15).
> ROOT CAUSE: `markIfRailLocal` marks **all** of `L`'s own blocks, while `computeFreePoint` places
> `At` at the nearest common post-dominator of the USE blocks and guards it only by
> `IterationLocalBlocks.count(At->getParent())` — MEMBERSHIP, not same-block-as-the-mint. Conjunct
> (1)'s suppression then reads the marking as a proof of in-body discharge, which holds for a
> single-block body and not for a multi-block one.
> WHAT A FIX NEEDS (either): make conjunct (1)'s suppression ask the property it means — *"is every
> interior rail minted in `L`'s own blocks discharged in the block it is minted in?"* — rather than
> *"is the body marked?"*; or make `markIfRailLocal` refuse a body whose own blocks are more than
> one when any interior rail's uses span them. RED-GREEN PAIR TO WRITE WITH IT: RED
> `t5j_twoblock_noexit_rot.c`, GREEN `t5i_straddle_nobreak_rot.c`, isolating control
> `t5k_twoblock_unmarked_control.c`. NOT MEASURED, and owed: whether this is a regression from bd
> `tu9q`'s root-mint escape (the marking's only source here) or pre-existing — run the witness on
> `0e280fc6…` and `ce3f8f3d…`.
> Probes: `$SES/review_r13_loopconv/probes/`. Cross-reference bd `s82e` (the UNMARKED spelling of
> the same hazard) and bd `tu9q.1` (whose `t5h` shape is a customer).

### F-2 (P3 — source prose that is load-bearing and false). Conjunct (1)'s and `bodyBlocksMarked`'s argued headers state the suppression's premise as a fact

`LoopLowering.cpp:4719-4721` — *"A marked body discharges in-body, once per trip, against a
once-per-trip forward stream … and is byte-identical to its hand-unrolled twin."* F-1 is a
counter-example. `bodyBlocksMarked`'s own header (`:4375-4434`) carries three retirement triggers,
all about *which blocks* and *which polarity*, and **none** about *what the marking proves*.

`CLAUDE.md` L7-with-a-twist is explicit that a correction not applied to the source is not a
correction — that lesson cost three rounds on one sentence. **Fix the two comments in the same
change as F-1**, and add the trigger the file lacks: *"this suppression is sound only while a marked
body's interior rails are discharged in the block they are minted in; the day a marked body can have
more than one own block with a rail spanning them, re-derive it."* §C.3 supplies the correct
statement of the property for the break case.

### F-3 (P3 — a stale instrument claim, repeated in four places, that discourages running the one check that sees F-1)

Both converted fixtures assert that stage 2b cannot see this class —
`loop_leak_dephase_reject_cmp_rail_data.ll`: *"2b IS NOT THE WITNESS AND NEVER WAS: it counts
`cqrt_alloc` SITES and these rails are TEMPLATE-minted"*; `…_inloop_rotation.ll`: *"2b IS BLIND
HERE"*. `CLAUDE.md` says the same in the CORRECTNESS RISK §1 witnesses paragraph and again in the
stage-2b entry (*"structurally blind to a leaked TEMPLATE-minted rail — there is no `cqrt_alloc` to
count"*).

**That is no longer true of the tool on disk.** `free_pairing_check.py` computes a template-rail
census (`:2628-2665`) and prints `N template rail mint(s) of which M left dirty`, where *dirty* =
minted and **not** freed, uncomputed, measured, returned or escaped. On the F-1 witness it printed
**`1 left dirty`**. What *is* still true is the weaker statement that it **never gates**:
`tmpl_dirty_total` appears only in the summary line and the JSON key, never in a finding, and the
run exits **0** (measured).

So the honest wording is *"2b counts a dirty template rail and does not gate on it"*, not *"2b is
blind to it"* — and the difference is operational: a reviewer told the instrument is blind will not
look at the number, and the number is `1` on the one module in this review that is a miscompile.
⚠ The disposition is **not** automatically "make it gate": Rule 6 accepts a leak, so a dirty
template rail is a **signal**, not a violation, and it becomes a defect only in combination with a
later non-diagonal gate on the register it copies. Recommend: correct the four claims, and consider
surfacing `left dirty > 0` together with `warnLiveRecordRotations`, which also fired on the F-1
witness and on nothing else I measured.

### F-4 (P3 — my own instrument, recorded rather than hidden)

Two of my instruments misreported before they told the truth, per `CLAUDE.md` L10:

1. My harness's stage-2b sub-check ran `free_pairing_check.py` on a **relative** path after `cd`-ing
   to the repo, so it printed `cannot read ./work/*.s2.ll` for every probe **while the row still
   scored ACCEPT**. Four rows were produced that way before I read the text. Fixed (absolute work
   dir) and given a guard that exits 2 on `cannot read` or empty output.
2. An argc sweep written in **zsh** used an unquoted `$args`; **zsh does not word-split an unquoted
   parameter**, so every row passed ONE argument and the table read `lim=4 → 3 trips` — which is
   exactly what a **dropped loop trip** looks like, and I came within one cross-check of filing it.
   It was caught only because running the same binary by hand with literal arguments gave 4 trips.
   Replaced by `probes/argsweep.sh` (`#!/bin/bash`, `set --`). **Nothing in this review is reported
   from the zsh spelling.** Harness self-attacks (0-byte `.c`, quantum-free `.c`) ran before use and
   both report `VACUOUS-*`, never ACCEPT.

---

## What I did NOT attack

I did not run any suite, any corpus sweep, any twin matrix, any injection matrix or
`cq-opt-equivalence-full`, and I built nothing — so **I have no measurement on any binary other than
the ORACLE**, and in particular **I did not establish whether F-1 is a regression from the loop group
or pre-existing** (§F-1 says so in those words, and states the inference separately from the
measurement). I did not sweep the shipped corpus for existing customers of F-1, so I do not know
whether any `ir-pass/test` fixture, e2e slice or golden has a multi-block marked loop body — that is
the first thing the fix agent should measure, and it decides F-1's blast radius. I did not attack
`markIfIterationLocal`'s round-1 grant (the first of the two exposures `review_r13_loop` §I-5 left
open) nor the unscrubbed `IterationLocalBlocks` set read after `lowerBreakReversePlay` creates
blocks (the second) — both are untouched by anything here and must not be read as closed. I did not
exhaust multi-exit shapes: I built five and three of them were neutralised by `-O1` (if-conversion,
sinking) or by bd `3d8q` before reaching the lowering, which means the *reachable* multi-exit surface
is bounded by two fences in other files, either of which could move. I did not attack the `ANY→ALL`
polarity half of the `emkg` fix, which its own header states is unwitnessed. I did not attack
irreducible cycles, multi-latch loops, the 512-block budget path, or anything in `EmitInverse` /
`cq_invert`. And I did not re-verify `FIX.md`'s §2 corpus numbers, §3 mutation matrix (`MISSED 0`) or
§5's three source sentences — they are gate results on binaries that no longer exist on this box.
