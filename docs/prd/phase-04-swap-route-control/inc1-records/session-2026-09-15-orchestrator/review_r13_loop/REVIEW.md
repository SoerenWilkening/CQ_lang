# Rule-13 adversarial review — the LOOP-RAIL GROUP (Track S′ × Track T), session 2026-09-15

Independent second reviewer. I did not write this code, I ran **no build and no test suite**, and I
rebuilt nothing. Everything below is analytic/trace-level reasoning plus the per-probe pipeline
against the three binaries that already existed.

## VERDICT: **FINDING** (one P1 over-accept, with two faces), plus 9 items

* **F-1 (P1, OVER-ACCEPT).** `declineDephasingUnmarkedLoopRails`' **conjunct (1)** asks *"is this
  loop's body marked?"* over `L->blocks()`, **which includes every strictly-deeper subloop's
  blocks**, while conjunct (3) asks its question over `L`'s **OWN** blocks only. A marked INNER loop
  therefore silences the fence for the enclosing OUTER loop, whose own per-trip rails are still
  leaked. Two faces:
  * **F-1a — PRE-EXISTING**, survives Track S′'s widening (reproduces on the ORACLE, `n1`);
  * **F-1b — A REGRESSION INTRODUCED BY TRACK T**, and it stands under the composition: two
    programs go **loud DECLINE → ACCEPT with a measured rolled ≠ unrolled divergence** (`n2`, `n3`).
    This is bd `s82e`'s divergent half — the exact class the fence exists to refuse — arriving
    through the door the pairing opened.
* Everything else I attacked is **clear**, including the two items the brief flagged as most likely
  to move: **T-5 I can now close with a transfer witness I measured** (§I-1), and the
  `Rule 14 / L3-mirror` charge against `measureOwnedInvariantRail` **does not stand** (§I-3) — its
  stated premise is false on the tree.

⚠ **F-1b must not ship as it stands.** An over-decline is a defect to remove (owner, 2026-09-11); an
over-accept is the unforgivable bug (Prime Directive). The fix is four lines and is spelled out in
§F-1.6, together with the red-green pair to write **with** it.

---

## 0. Provenance — hashes verified before any line was cited

| binary | `shasum -a 256` (on disk, this review) | cited in | agrees |
|---|---|---|---|
| ORACLE `main` `74eabd2c` | `0e280fc62a91cec2336769edde8a873563a21ee4869744331a0fcf6811549c6d` | brief, `trackS/GATES.md`, `trackT/GATES.md` | ✅ |
| Track S′ `dephase-fence-r2` `6882685b` | `15f6a75a50faba7a2c99a969497044ca6211293ea00ad6388510c6cc17bff96d` | `trackS/GATES.md` (`15f6a75a50faba7a`) | ✅ |
| Track T `inloop-pairing` `c0029f26` | `f972906e961c7e55be581ae18550f12da4535946b831e5c63434c0f089e33951` | `trackT/GATES.md` CLEAN row | ✅ |

Both worktrees are clean (`git status --porcelain` empty). **No cited gate line's hash disagrees with
the binary on disk.** Track T's `GATES.md` is the better of the two on this axis — it quarantines the
broken incremental binary `cfb00187163c3254` explicitly and says in writing that the lines taken on it
"are not quoted as facts about the shipped binary."

**Harness** (`review_r13_loop/probes/rv.sh`): one stage-1 module, three binaries, each linked against
its own runtime archives. Self-attacked before use with a **0-byte** `.c` and a **quantum-free** `.c`
— both report `VACUOUS-NO-QUANTUM`, never ACCEPT (bd memory `empty-module-accepts-vacuity-trap`).
`A:LINKFAIL` and `BROKEN-EMPTY-OUTPUT` are their own tags. Every probe reported below was checked
non-empty: stage-1 modules 7.4–9.1 KB with 5–11 `cq_{theta,phi,measure}` calls, lowered output
6.9–9.2 KB.

⚠ **A scratchpad hazard, recorded because it nearly produced a fabricated table.** The session
scratchpad is shared: another agent's `rv.sh` (a different script, for `CQ_F`/`CQ_P`) overwrote mine
between two invocations and produced a 14-row table of `expected top-level entity` parse errors that
would have read as "every probe declines". Caught because the output format changed. I moved to a
private subdirectory. **Do not put a harness at a shared scratchpad path.**

---

## F-1 — conjunct (1) reads `L->blocks()`; conjunct (3) reads `L`'s OWN blocks

### F-1.1 The mechanism, as source

`LoopLowering.cpp` (Track S′ worktree, `:4178` and `:4284`; both spellings are identical on `main`
and on Track T — S′ did not touch conjunct (1)):

```cpp
      // (1) THE BODY MUST BE UNMARKED.
      bool Marked = false;
      for (BasicBlock *BB : L->blocks())                 // ← ALL blocks, subloops included
        if (taint.IterationLocalBlocks.count(BB)) { Marked = true; break; }
      if (Marked)
        continue;
      ...
      // (3) AN INTERIOR TEMPLATE RAIL IN `L`'s OWN BLOCKS ...
      for (BasicBlock *BB : L->blocks()) {
        if (LI.getLoopFor(BB) != L)
          continue;                                      // ← OWN blocks only
```

`llvm::Loop::blocks()` returns the loop's blocks **including** every strictly-deeper subloop's. So
for an outer loop `L_outer` whose inner loop `L_inner` was marked, conjunct (1) sets `Marked = true`
on an inner block and `continue`s — **conjuncts (2) and (3) are never evaluated for `L_outer`'s own
body at all**, even though conjunct (3) would have excluded those very inner blocks itself.

**The tree already owns the correct spelling of this question, in the same file**, and its comment
says so in as many words — `declineUnmarkedRolledIterLocal`, `LoopLowering.cpp:4860-4869` (Track T
worktree; identical on `main`):

```cpp
      bool Marked = true;
      for (BasicBlock *BB : L->blocks()) {
        if (LI.getLoopFor(BB) != L)
          continue;  // a strictly-deeper subloop's block — not `L`'s to mark.
        if (!taint.IterationLocalBlocks.count(BB)) { Marked = false; break; }
      }
```

So the defect is **Rule 14** (two spellings of one question, and the older one is right) **and
CLAUDE.md L2** verbatim — *"when you WIDEN a set, ask what OTHER set was computed over the same
closure"*. Track T widened `taint.IterationLocalBlocks`; the other consumer computed over that set
reads it with a **different block quantifier** and a **different polarity** (see §F-1.7).

### F-1.2 The shape as a program — `n2` (the smallest one that regresses)

`review_r13_loop/probes/n2_nested_unmarked_inner.c`:

```c
#include "CQ.h"
int slice(void) {
    int y = cq_theta(5, 0.5);
    int s = 0;
    for (int i = 1; i <= 2; ++i) {
        s += cq_measure((y >> i) & 1);          /* OUTER body rail — a which-path copy of y */
        for (int j = 0; j < 2; ++j)
            s += cq_measure((y >> (j + 8)) & 1);/* INNER body — reads the invariant root mint y */
    }
    y = cq_theta(y, 0.9);                       /* the interference Rule 8 names */
    return s + cq_measure(y);
}
int main(void) { return slice(); }
```

Twin = the same program with the **outer** loop hand-unrolled and the inner loop left rolled
(`n2_nested_unmarked_inner_un.c`).

`n3_nested_iic_inner.c` is the same shape reached through clause **(ii-c)** instead (the inner loop
reads the hoisted measure-owned `y & 1` beside its own per-trip `u` chain). `n1_nested_marked_inner.c`
is the same shape reached through **`markIfIterationLocal`** (a fully iteration-local inner loop) and
needs neither track.

### F-1.3 Measured, all three binaries, one stage-1 module each

```
n1_nested_marked_inner    | ORA A:38 | S A:38 | T A:38 |     twin: 42 / 42 / 42
n2_nested_unmarked_inner  | ORA DECLINE | S DECLINE | T A:30 |  twin: DECLINE / DECLINE / 34
n3_nested_iic_inner       | ORA DECLINE | S DECLINE | T A:43 |  twin: 40 / 40 / 48
```

`_unc` + `cqrt_free` lines, rolled vs twin, per binary:

```
n1  ORA rolled=8  twin=12     S rolled=8  twin=12     T rolled=8  twin=12
n2  ORA DECLINE                S DECLINE               T rolled=8  twin=12
n3  ORA DECLINE                S DECLINE               T rolled=8  twin=12
```

Symbol-multiset delta, `n1` rolled vs twin (identical for `n2`/`n3` on T):

```
<    4 cq_template_lshr_i32_hl_unc      >    6 cq_template_lshr_i32_hl_unc
<    4 cqrt_free                        >    6 cqrt_free
```

The two missing pairs are the **outer** body's `cq_template_lshr_i32_hl(h0, 1)` and
`…(h0, 2)` — one per outer trip. Rolled trace of `n1`, lines 3–4 and 20–21, then line 37:

```
 3  cq_template_lshr_i32_hl(h0, 1) -> h1      ← minted, never _unc'd, never freed
 4  cq_template_and_i32_hl(h1, 1) -> h2
...
20  cq_template_lshr_i32_hl(h0, 2) -> h9      ← minted, never _unc'd, never freed
21  cq_template_and_i32_hl(h9, 1) -> h10
...
37  cqrt_ry_i32(h0, 0x1.ccccccccccccdp-1)     ← NON-DIAGONAL gate on the register they copy
38  cqrt_measure_i32(h0) -> 0                 ← the program's observable
```

`h1` and `h9` are undischarged which-path records of `h0`'s bits standing at a non-diagonal gate on
`h0`. The hand-unrolled twin emits `lshr_unc` + `cqrt_free` for both **before** the rotation. **Rolled
and unrolled are different unitaries** — `CLAUDE.md` Rule 8 verbatim, at `opt` exit 0, verify-clean.

This is not a twin artefact (the T-2 trap): the twin differs from the subject by the **outer** loop
only, the inner loop is rolled in both halves, and the delta is exactly `2 × (_unc + free)` on rails
the twin's own trace shows being discharged. It is the same measurement shape Track S/T used for
`s1` (10 vs 14) and `w2k` (16 vs 20).

### F-1.4 The control that isolates conjunct (1) as the cause

`n2` and `n1` differ **only** in whether the inner loop is markable:

* `n1`'s inner loop is fully iteration-local ⇒ `markIfIterationLocal` marks it ⇒ **ORACLE ACCEPTS
  (38 vs 42)** — conjunct (1) fires on an inner block.
* `n2`'s inner loop reads `y` from outside ⇒ nothing is marked on the ORACLE ⇒ conjunct (1) is false
  ⇒ conjunct (3) reaches the **outer**'s own `lshr` rail ⇒ **ORACLE DECLINES.**

Same outer loop, same rails, same interference; the only variable is whether some *other* loop's
blocks are in `IterationLocalBlocks`. That is the fence being silenced by a marking that says nothing
about the loop it is deciding.

### F-1.5 Why this is Track T's regression and not only a pre-existing hole

`n2` needs **no new clause at all** — just the round-1 root-mint escape (change (2) of Track T):
`invariantRegisterRoots` admits `y`'s root mint, `markIfRailLocal` marks the **inner** loop, and the
outer loop leaves the fence at conjunct (1). `n3` needs clause **(ii-c)** as well. Both were **loud
declines on `main` today** and are **divergent accepts on the Track-T binary**; they stay accepts
under the composition because Track S′ does not touch conjunct (1).

Track T's `IMPL_T2.md` §5 quotes conjunct (1) correctly and concludes *"every tu9q customer exits
here"* — which is true, and is exactly the problem: **the customer's ENCLOSING loop exits there too.**
Coupling **C-1** in that section anticipates a change to conjunct (1) by Track S′; what it does not
anticipate is that conjunct (1) needed changing **because of this track**. Track S′'s own source
block says *"NOTHING MEASURES HOW MANY MEMBERS THE CLASS HAS"* and carries the retirement trigger
*"any NEW member of the class"* — **F-1a is that new member, found in one round, exactly as the
trigger predicted.**

### F-1.6 The fix (four lines), and why it is narrow

Ask conjunct (1) the question `declineUnmarkedRolledIterLocal` already asks, **by calling one
predicate from both sites** rather than copying the loop (Rule 14 — a second spelling is how this
defect arose):

```cpp
// ONE spelling of "are `L`'s OWN body blocks marked iteration-local?" — a
// strictly-deeper subloop's blocks are NOT `L`'s to mark, and reading them here
// let a marked INNER loop silence this fence for its enclosing OUTER loop
// (Rule-13 round 2, 2026-09-15; bd <new>). `declineUnmarkedRolledIterLocal`
// has always spelled it this way; this is the second caller, not a second spelling.
bool bodyBlocksMarked(const Loop *L, const LoopInfo &LI, const TaintSet &taint) {
  bool Any = false;
  for (BasicBlock *BB : L->blocks()) {
    if (LI.getLoopFor(BB) != L)
      continue;                       // a strictly-deeper subloop's block
    if (!taint.IterationLocalBlocks.count(BB))
      return false;                   // ALL, not ANY — see §F-1.7
    Any = true;
  }
  return Any;
}
```

**Regression surface, argued and to be measured:** the predicate's answer changes **only** for a loop
that has a strictly-deeper subloop, or (via ALL-vs-ANY) for a loop with a partially-marked body.
Single-loop programs are untouched, so the two `loop_leak_dephase_accept_*` fixtures, the positive
control `s3_live_rootmint_region` (22 == 22 on all three binaries) and every `*-twin-identical` gate
are expected unmoved. `a9_nested_loop` is expected to stay an ACCEPT on the fixed binary: its outer
loop's **own** blocks carry no tainted rail-minting op (the shift and the `k+j` add are inside the
inner loop), so conjunct (3) finds nothing there. **Expected is not measured — the landing owes the
nested cells and a `ctest -R ir-pass-lit`.**

### F-1.7 A second, unwitnessed divergence in the same conjunct: ANY vs ALL

Conjunct (1) sets `Marked` on the **first** marked block (ANY); `declineUnmarkedRolledIterLocal`
requires **every** own block to be marked (ALL). ANY is the accept direction. The two coincide today
because both markers mark a loop's own blocks all-or-nothing and nothing in the window creates blocks
(`declineUnmarkedRolledIterLocal`'s own exhaustive scan of the block-creating APIs, `:4823-4845`),
so **I have no witness for this half** and do not claim one exists. Fix it with the same predicate
anyway: it costs nothing and it is the safe polarity.

### F-1.8 Red-green, to write WITH the fix (Rule 12)

1. **RED first — the decline fixture.** `ir-pass/test/loop_leak_dephase_reject_nested_marked_inner.ll`
   = stage 1 of `n2_nested_unmarked_inner.c` (`clang -O1 -g`), with
   `RUN: not %cq-opt … 2>&1 | FileCheck %s` mirroring `kMsgLoopLeakDephases`
   **character-for-character**. On the pre-fix merged binary this module exits **0** — write it, watch
   it fail, then fix. Validate by **binary mutation**: the fixture must NOT pass on the pre-fix
   binary (Rule 12 hygiene (b) — a decline fixture writes 0 bytes to stdout, so the property is
   pinned by the `not` inversion, never by an IR-text `CHECK-NOT`).
2. **A second decline fixture for the other route.**
   `loop_leak_dephase_reject_nested_iterlocal_inner.ll` = stage 1 of `n1` — the
   `markIfIterationLocal` half, which needs neither track and is the pre-existing member. Without it
   the fix is pinned only where Track T can reach.
3. **An ACCEPT control, counts in their OWN whole-file prefix.**
   `loop_leak_dephase_accept_nested_outer_no_own_rail.ll` = stage 1 of `a9_nested_loop.c`: the outer
   loop has no own tainted minting op, the inner is marked, and the program must keep accepting with
   `CHECK-COUNT-4: cq_template_lshr_i32_hl_unc` / `CHECK-COUNT-4: cqrt_free`. ⚠ Put the counts in a
   separate whole-file prefix from the negatives — Rule 12 hygiene **(a)**, the defect Track T's own
   `inject_T.py` caught in `loop_leak_dephase_accept_pertrip_dead.ll` **this session** (finding T-4).
4. **Extend the injection matrix** with a mutation that deletes the subloop filter (i.e. restores
   `L->blocks()`) and confirm fixture 1 or 2 catches it; report `MISSED` and `N/A` separately.
5. **The real witness stays the twin.** Add the three `n*` pairs to whatever runs them; see §I-8 on
   why the twin matrix cannot host them as it stands.

---

## Items (each checked, none blocking)

### I-1 — **T-5 (`r1_break_loop`) CAN be closed, and I closed it.** Recommend: SHIP, with the witness recorded.

Track T filed `r1_break_loop` as *"an ACCEPT with no twin witness"*, because the hand-unrolled
spelling of a `break` loop is a nested-if cascade that declines at bd `3d8q`'s fence on both binaries.
I confirm the twin is unusable — `r1_break_loop_un` declines with
`cq opcode lowering: operand predates a non-diagonal gate` on **all three** binaries — and I
also confirm the class cannot be witnessed by a split-body variant: `t5b_break_split.c` (a second
gate group after the break test, so `-O1` cannot if-convert it) declines at the **same** `3d8q`
fence on all three.

**But a transfer witness exists.** Read the lowered IR: `-O1` if-converts this `break` into one extra
disjunct on the **latch** predicate, so the body is a **single basic block**:

```llvm
1:                                    ; preds = %1, %0
  %h_op  = call i32 @cq_template_lshr_i32_hl(i32 %h, i32 %2)
  %h_op1 = call i32 @cq_template_and_i32_hl(i32 %h_op, i32 1)
  call void @cq_template_lshr_i32_hl_unc(i32 %h_op, i32 %h, i32 %2)
  call void @cqrt_free(i32 %h_op)
  %m = call i32 @cqrt_measure_i32(i32 %h_op1)
  ...
  %5 = icmp sgt i32 %4, 1            ; the `break`
  %7 = icmp eq i32 %6, 5             ; the trip bound
  br i1 %8, label %9, label %1
```

Every mint, its `_unc` and its `cqrt_free` are in **one block**, so the group is atomic per trip and
1:1 by construction; the `break` can only stop the sequence **at a group boundary**. I then built
`t5a_nobreak.c` — the identical program with `if (s > 1) break;` deleted — which **does** have a
usable twin:

```
t5a_nobreak      | ORA DECLINE | S DECLINE | T A:24 |   twin A:24  → diff EMPTY, BYTE-IDENTICAL
r1_break_loop    | ORA DECLINE | S DECLINE | T A:24 |
diff r1_break_loop.T.trace t5a_nobreak.T.trace        → EMPTY, BYTE-IDENTICAL
```

So the emitted gate stream of `r1_break_loop` **is** the stream of a program whose rolled form is
byte-identical to its hand-unrolled twin, and the only difference in the two lowered modules is the
classical `icmp sgt` folded into the latch predicate. That is a witness of the same kind the class
uses, obtained by decomposition rather than by a twin.

**Track T's structural argument also holds where I could check it**: a discharge in a block the
`break` could skip is dominated by its mint, so `discharge ⇒ mint ran`; the reverse cannot occur
because the free point must be dominated by the def. I did not exhaust multi-exit shapes and do not
claim to — `t5b` says the reachable ones die at `3d8q` first, which is a **measurement about today's
binary, not a proof.** Record the transfer witness and the `3d8q` interaction in the fixture header
with an L8 **retirement trigger**: *"when bd `3d8q`'s fence stops refusing the nested-if cascade, a
real twin becomes constructible — build it and re-derive this cell."*

**I do not recommend adding a multi-exit refusal.** It would be an over-decline on an argument nobody
can substantiate in either direction (Rule 17, owner 2026-09-11) and it would refuse a program I have
a witness for.

### I-2 — S′'s own retirement trigger **FIRES under the composition**, and neither track re-derived it. Re-derived here: SAFE, but it must be written into the source.

`mintsOutOfPlaceTemplateRail`'s argued block ends:

> ⚠ RETIREMENT TRIGGER, by name: … **if `InPlaceRailOps` gains a writer that runs AFTER this stage**,
> half (ii) is gone and this suppression becomes an OVER-ACCEPT — re-derive it from scratch.

Track T adds exactly such a writer: `declineRound2FalsifiedRailGrants` runs **immediately after** the
fence (`CQLoweringPass.cpp:772` then `:773`) and calls `invariantRegisterRoots`, which calls
`commitOutOfLoopInPlaceOps`, which calls `markInPlaceRailOp`. **The trigger fired and nobody read it**
— the same omission that cost the bd `a3z7` P1 filing (L3-mirror).

Re-derived, reading both bodies:

* **The populations are disjoint.** `commitOutOfLoopInPlaceOps` opens
  `if (L->contains(BO->getParent())) return;` — it commits **out-of-loop** ops only. The fence's
  conjunct (3) scans **`L`'s own blocks** only. No instruction can be in both.
* **The rollback cannot remove a marking the fence relied on.** `commitOutOfLoopInPlaceOps` skips an
  op already in `InPlaceRailOps` (`if (!BO || taint.InPlaceRailOps.count(BO)) continue;`), so
  `Marked` holds only this call's **new** commitments, and `invariantRegisterRoots`' failure path
  erases only those — which the fence, running earlier, could not have seen.
* **Direction of the residual skew** (the fence sees a smaller set than `lowerOps` will) is
  **more declines**, never fewer.

Half (ii) itself I verified in source and it is sound: the suppression requires
`railValueConsumerDisposition(...) == InPlace`, which is `taint.InPlaceRailOps.count(BO) ||
Claimed.count(BO)` with `Claimed` empty — i.e. **membership**, not a prediction — and `lowerOps`
re-asks every member, `PreLoopCommittedInPlaceOps` through `classifyInPlaceReassignment`
(`OpcodeLowering.cpp:688`) and the rest through the eqpx tripwire (`:786`), **both declining loudly**,
no silent fallback. The stale-marking **cede** branch lands in the eqpx tripwire's
`!Rail → diagnoseRailOpStale` arm. Composition total. ✅

**Owed:** one sentence at `mintsOutOfPlaceTemplateRail` naming `declineRound2FalsifiedRailGrants` as
the post-stage writer and why it does not reach the population — **in the source**, not only here
(L7-with-a-twist; that lesson cost three rounds on one sentence).

### I-3 — the **Rule 14 / L3-mirror charge against `measureOwnedInvariantRail` does NOT stand**, and its premise is false

The brief's premise — *"`mintsOutOfPlaceTemplateRail` calls `railValueConsumerDisposition`, **which
does not exist on `main`**"* — is **incorrect**: it is defined at `ir-pass/src/LoopLowering.cpp:242`
on `main` today, with four call sites there (`:317`, `:996`, `:2255`, `:2685`) and named by
`OpcodeLowering.cpp:768`, and both tracks inherit it unchanged. And it answers a
different question (*"will this `BinaryOperator` be lowered as an in-place mutation of rail value
`V`'s handle"*), so `measureOwnedInvariantRail` (*"is every user of `V` a `cq_measure`"*) is not a
second spelling of it.

Against `railIsInterior` the charge is closer but still fails. The two are near-complements with
**opposite safe directions**, stated at the definition: `railIsInterior` `continue`s past a
non-`Instruction` user (irrelevant to "would the twin discharge this"), `measureOwnedInvariantRail`
**refuses** one (an unclassifiable user is an absence of proof). Folding them would need a direction
parameter, which is precisely how a shared predicate acquires a caller its argument does not reach.
Accept, with the retirement trigger T already wrote.

**One strengthening the track did not claim and should.** T's argument for (ii-c) is entirely about
**multiplicity** (no `At` can land in a K-times body). The stronger ground is **physics**: a
measure-owned rail is not a *coherent* which-path record at all — the user's own measurement collapses
it, which is why Rule 6 says the measurement owns such a handle and why `computeFreePoint` returns
`Measured`. I measured this: `x1_iic_bodyrail_interfered.c` puts the (ii-c) rail beside an interfered
register, T accepts at 17 == twin 17, and `RotationLowering::warnLiveRecordRotations` is **silent on
both halves** (0 bytes of stderr) — where it fires with count 1 on `b7b_w2k_interfered` and count 2
on `b11_cmp_rail_data` on the ORACLE, and is silenced on both by T's pairing. Write the physics half
into the comment; it survives a change to `isInteriorTerminalHandle` and the multiplicity half does
not.

### I-4 — Track T's clause (ii-c) survived every attack I could build on it

| probe | attacks | result |
|---|---|---|
| `x1_iic_bodyrail_interfered` | (ii-c) rail beside a body rail whose ancestry is the interfered register | ORA/S DECLINE → T **A:17 == twin 17**, warn silent |
| `x8_iic_preheader_chain` | **the L2 gap in T's own argument**: (ii-c) proves `V` gets no `At`, and says nothing about `V`'s *preheader ancestors*, which are ordinary interior template rails (`(y>>3)&1` ⇒ `lshr` then `and`) | ORA/S A:19 (leak) → T **A:23 == twin 23**; the preheader `lshr` is `_unc`'d and freed **once**, not K times |
| `x9_…_interfered` | the same with a post-loop rotation | ORA/S A:20 → T **A:24 == twin 24** |
| `a1_ry_on_body_rail` | a body rail carrying an `Ry` (`preservesBasisUnderRecord` false) | T **16 == 16 BYTE-IDENTICAL** (re-measured) |
| `a2_fanout_body_rail` | fan-out 2 (Rule-8 linear lineage) | T **18 == 18 BYTE-IDENTICAL** (re-measured) |
| `a3` / `a4` | the "EVERY user" quantifier; a mixed rail set | DECLINE on all three — boundary held |
| `x1_xorc_inplace_in_body` | Track S′'s `cqrt_xorc` hazard | 13 == 13 on all three; lowered IR **0** `_unc` / **0** `cqrt_free`, 3 `cqrt_xorc` |

**The `cqrt_xorc` argument verified, not just the measurement** (brief item 8). An in-place dtzb op in
the body makes its rail **loop-carried**, hence a tainted header phi, and every route to the new call
site is closed before it: `tryCaseA` claims such a loop and `lowerLoops` `continue`s; if it does not,
`invariantRegisterRootsImpl` clause (i) (`for (PHINode &P : Header->phis()) if (Tainted) return
false`) and `railLocalQualifies`' `TI && isa<PHINode>(I) && BB == Header` both refuse. And an op the
peel does reach is `onRail` (not `AnyLocal`), so it is never a spine discharge candidate. The
argument holds independently of the measurement.

**Every Rule-6 `cqrt_free` Track T newly emits, and its witness** (brief item 7 — stage 2b is
structurally blind to template-minted rails, so STRICT 2b clean is NOT clearance here): every new
free is the second half of an `_unc`-then-`free` pair emitted in the **same basic block** as its
mint, and its witness is the hand-unrolled twin's byte-identical pair — `s1` 14==14, `a1` 16==16,
`a2` 18==18, `a7` 36==36, `r3` 24==24, `t5a` 24==24 (mine), plus gate-symbol-multiset identity where
`-O1` moved a hoisted gate's position (`w2k`, `w2h`, `w2h3`, `b7b`, `b7c`, `x8`, `x9`, `x1`). I found
no free without such a witness.

### I-5 — Track T's L1 re-ask: reachable, sound, and honestly scoped

`declineRound2FalsifiedRailGrants` is above `lowerRotations` and below the round-2 fixpoint, keys on
the **header block** as a `WeakTrackingVH` (not a `Loop *` — the F-W1-1 dangling defect), treats a
nulled header or a nulled root as a **loud refusal**, and asks by **calling** `railLocalQualifies`
rather than re-spelling it. Its round-2 root re-derivation is grant-only with a rollback, so a false
return leaves `taint` byte-identical. `l2_round2_grow_derived.ll` is a real witness that the window is
reachable — a fence for an unreachable window is a prediction.

⚠ Two exposures, both **disclosed by the track** and neither closed: `markIfIterationLocal`'s round-1
grant is **not** re-asked (pre-existing, not widened by this change, and now more load-bearing because
conjunct (1) consumes the marking as a suppression); and `taint.IterationLocalBlocks` is a raw
`BasicBlock *` set nothing scrubs, read in the accept direction by `FreePoint` and `Uncomputation`
**after** `lowerBreakReversePlay` creates blocks. Carry both on the bead; do not let F-1's fix be read
as closing either.

### I-6 — conjunct (2)'s peel is CLAIM-time while `onRail`'s is FACT-time (two spellings, safe direction)

`Rots.insert(peelInPlaceBase(Base, GateCalls, taint));` uses the default `AsLowered=false`, the
CLAIM-time reading, while `markIfRailLocal`'s `onRail` uses `AsLowered=true`. This is the exact
conflation `peelInPlaceStep`'s own header calls *"a measured defect, not a hypothetical"* (finding
OD-A). Here it only ever **enlarges** `Rots` relative to the physical truth — a rotation on a
derived temp that will lower out of place is attributed to the temp's base — so every error it can
make is a **decline**. Not blocking; worth one sentence at the call site saying which reading it uses
and why, so the next widening does not "tidy" it in the accept direction.

### I-7 — S′'s conjunct-(2)/(3) widening is decline-only, checked by construction

Dropping the `L->contains` skip can only **add** members to `Rots`, and `taintedAncestryReaches` is
monotone in `Rots`. Replacing the opcode proxy with `mintsOutOfPlaceTemplateRail` adds `CmpInst`
(gated by `isDataPositionCompare` **and** `compareFlagMintable`), `CastInst` (`castInScope`) and
`FNeg`; the only accept-direction change in the whole of Track S′ is the in-place suppression, which
§I-2 clears. The cast/`fneg` members are admitted **because the question admits them**, with no
measured instance either way — the track says so; that is the honest state and the error direction if
they are wrong is a decline.

### I-8 — instrument gap: **the twin matrix has no nested-LOOP axis**, which is why F-1 was invisible

`tools/loop_twin_matrix.py`'s `cells_of_matrix()` is a `PREFIX × REGION × SUFFIX` product over a
**single** loop plus sub-grids (record, Ry, mixed, `_Bool`); "nest" in it means a nested **control**
region (`if (b && a == off)`), never a nested loop. So 338/359 cells cannot see F-1. Neither can the
corpus sweeps: Track S′'s covered `ir-pass/test` completely with 8 attributable movers, Track T's
produced 14 rows before being stopped, and **no shipped fixture has the shape** (the ORACLE accepts
`n1` with nothing red). `free_pairing_check.py` is blind by construction (template-minted rails).
L10, from the usual side: *an instrument is only ever blind in the shape nobody has pointed it at
yet.* Recommend a small nested-loop sub-grid, or at minimum the three `n*` pairs as `*-twin-identical`
ctest entries with the fix.

### I-9 — merge-gate items (not compiler findings)

* **Three fixtures are edited by BOTH tracks** and will conflict:
  `loop_leak_dephase_accept_pertrip_dead.ll`, `loop_leak_dephase_reject_noregion_live.ll`,
  `loop_leak_dephase_reject_region_derivedbase_live.ll`. The semantic resolution is **measured**, not
  a matter of taste: `reject_noregion_live` is `s1_live_shift`, which the pairing turns into an
  **ACCEPT at 14 == twin 14** — Track T's conversion wins and Track S′'s decline-string edit in that
  file is dead. `reject_region_derivedbase_live` is `s2_live_derived_region`, which still **declines**
  on the T binary — Track S′'s new string wins there. Track S′'s three
  `control_phase_kickback_mixed_*_leak_control.ll` string updates must survive: all three still
  decline on the Track-T binary (verified directly), so the pairing does not retire them.
* **`cq-opt-equivalence-full` is owed** — Track S′ moved a decline string (5 fixtures mirror it) and
  says so; PROTOCOL reserves that gate for the merge agent.
* **`^e2e-` and the full `ctest -j6` are owed**, and so is one `e2e-loop-twin-matrix` on a quiet box
  (both tracks recorded its absence correctly, as an absence and not a green).
* **F-2 of `MERGE_FILINGS.md`** (the four non-bank twin cells) is now decidable: the fence Track S′
  was editing has landed, so the cells can be pinned — but **only after F-1's fix**, or they pin a
  verdict this review says is wrong.
* Track T's **T-2** adjudication of `a9_nested_loop` (24 vs 20) is independently confirmed: the
  rolled form emits 4 of each template symbol and the twin 3, because `-O1` CSEs the twin's two
  shift-2 chains (its trace measures `h4` twice). The rolled form is Bennett-clean. Not a divergence.

---

## What I attacked and did NOT find anything on — stated so "a green suite" is not the answer

1. **Clause (ii-c)'s multiplicity argument extended to `V`'s own preheader ancestors** (the L2 hole in
   T's argument — T proves a property of `V`, not of `V`'s chain). `x8`/`x9` build the chain; the
   preheader `lshr` is discharged exactly once in both forms. Nothing.
2. **The (ii-c) rail as a coherent which-path record** — `x1`. It is not: it is measured, the warn
   stage is silent, and the trace is twin-identical. Nothing (and it is the missing half of T's own
   argument — §I-3).
3. **S′'s in-place suppression under round-2 taint** (brief item 6): read `railValueConsumerDisposition`,
   both `lowerOps` tripwires and `invariantRegisterRoots`' rollback. Suppression ⟹ membership ⟹ a loud
   re-ask. The unscrubbed-`InPlaceRailOps` residual the track filed is a corroboration and not a
   proof, correctly labelled as such. Nothing.
4. **The `cqrt_xorc` hazard** (brief item 8) — argument verified, not just the measurement. Nothing.
5. **Rule 6 on every new `cqrt_free`** (brief item 7) — each has a same-block `_unc` and a twin
   witness. Nothing.
6. **The L1 re-ask over-declining** — `l1_round2_grow_65arm.ll` is the shape and T fixed it (T-1);
   the re-derivation is grant-only and rolls back. Nothing.
7. **The break loop** (brief item 1) — found a witness instead of a defect (§I-1).
8. **The `railIsInterior` / `measureOwnedInvariantRail` duplication charge** (brief item 3) — premise
   false, charge fails (§I-3).

**What would have caught F-1:** a twin pair with a nested loop — any of the three in
`review_r13_loop/probes/`. Nothing in the tree has one. The fence's own retirement trigger
(*"any NEW member of the class"*) named the obligation; what was missing was an instrument pointed at
a second loop.

---

## Reproduction

```bash
SP=<scratch>; cp review_r13_loop/probes/*.c "$SP/"; cp review_r13_loop/probes/rv.sh "$SP/"
cd "$SP" && ./rv.sh n1_nested_marked_inner.c n1_nested_marked_inner_un.c \
                    n2_nested_unmarked_inner.c n2_nested_unmarked_inner_un.c \
                    n3_nested_iic_inner.c n3_nested_iic_inner_un.c
# then, per binary tag T:
diff <(sed 's/(.*//' n1_nested_marked_inner.T.trace | sort | uniq -c) \
     <(sed 's/(.*//' n1_nested_marked_inner_un.T.trace | sort | uniq -c)
```

`rv.sh` hard-codes the three build directories and must be re-pointed at the merged build before it
is used as a merge gate. It reports `VACUOUS-NO-QUANTUM` rather than ACCEPT for an empty or
quantum-free stage 1; keep that guard if you edit it.
