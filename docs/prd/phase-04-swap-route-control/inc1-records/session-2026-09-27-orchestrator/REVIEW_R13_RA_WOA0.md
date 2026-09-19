# bd `test_C_libtooling-woa0` (`357f2528`) — Rule-13 ROUND A, independent

**VERDICT: `CLEAR-WITH-ITEMS` — 0 P1, 2 P2, 6 P3.**

The fence does what it says in the direction that matters. On round 3's own exhibit it turns
`collectCondTree`'s downstream accident into a named, loud decline; the RECORD is complete over
every arm of `isSupportedCondTree` that can put a φ in an emitted predicate tree (enumerated
below, not assumed); the `!BoolAlg` gate cannot be reached by a genuine rail φ; the clone
driver's separate record is disjoint by construction rather than by argument; **my own build
from the landing source is BIT-IDENTICAL to the shipped SUBJECT** (round 3's `F-R3-3` lesson,
paid rather than inherited); and I reproduced the whole-corpus A/B independently — **1 mover of
2157**, the increment's own new fixture — plus a layer the change's record did not sweep (**all
403 compilable `tests/e2e/slice_*.c` sources: 0 movers**). I found **no over-accept, no wrong
unitary, no crash, and no decline that became silence.**

**What I did find is an over-DECLINE the record says cannot exist.** `Leaves` is described at
three sites as "the φs an EMITTED region's condition tree READS as a rail leaf". It is not: the
insert sits at the E6 **ADMISSION**, a strict superset. **Two hand-built modules that the ORACLE
compiles to a correct circuit now decline on SUBJECT** (`F-RA-1`, MEASURED, mutation-attributed
to the RECORD and to the COMMIT, and one of them recovered byte-for-byte by a one-line candidate
fix I built and measured). The change's probe matrix could not see it: measured on the supplied
instrumented binary, **both of its ACCEPT rows commit nothing at all** — `w_d_allconst` (flagged
in the record as a weak control) *and* `x2_naturalorder` (not flagged) — so the matrix contains
**zero cells in the quadrant "record populated ∧ module accepts"**, which is exactly where the
finding lives.

---

## Binaries — `shasum -a 256` re-run before the first measurement and again at the end

| role | sha-256 (first 24) | what |
|---|---|---|
| SUBJECT | `15adcac40d4455a7f2d9f785` | primary `build/ir-pass/cq-opt` (git `90e79229` = `357f2528` + records) |
| ORACLE | `fe5805a41df2e173fdfa572b` | `<S>/wt-oracle-woa0/build/ir-pass/cq-opt`, git `18d18728`, pre-fix |
| INSTR | `ec14ef9caa628f2855a37263` | `<S>/wt-woa0-INSTR-COMMITLOG/…`, env `CQ_WOA0_COMMITLOG` |
| MUTANTS | `edc6b21389e6dd9fbeed8277` | `<S>/wt-woa0-MUTANTS/…`, env `CQ_WOA0_MUT_{NORECORD,NOCOMMIT,NOBOOLALG}` |
| **PRIMARYSRC** | **`15adcac40d4455a7f2d9f785`** | **my own Release build of `90e79229` in `<R>/wt-ra-PRIMARYSRC` — BIT-IDENTICAL to SUBJECT**, and its `CMakeCache.txt` `CMAKE_HOME_DIRECTORY` points inside itself (round 3's `F-R3-3`: a matching hash does not prove which sources produced it; a self-consistent cache plus a matching hash does) |
| CANDFIX | `c3b7a5961771a56af012d6b4` | PRIMARYSRC + the single-line candidate fix in `F-RA-1`'s disposition, built by me |
| `libCQPass.so` | `bab2a8b70c57c6b036c859f8` | primary; hashed, unused by `cq-opt` |

`<S> = /private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/9109b935-…/scratchpad`,
`<R> = /private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/20672b33-…/scratchpad`.
The four supplied hashes match the brief and `MEASUREMENT_WOA0.md`. **I rebuilt nothing in the
primary tree, edited nothing in it but this file, ran no `bd update`, made no commit.** My scratch
is `<R>/ra`; my worktree is `<R>/wt-ra-PRIMARYSRC` (detached at `90e79229`).

**My instruments, with their controls, each run BEFORE the measurement it controls.**

| instrument | control | result |
|---|---|---|
| A/B harness `<R>/ra/ab.sh` (rc + normalised stderr + emitted IR + an rc≥128 crash column) | NULL, SUBJECT vs SUBJECT, whole corpus | **`DENOMINATOR=2157 MOVERS=0`** |
| same | POSITIVE, ORACLE vs SUBJECT over 3 files with 1 known mover | **`DENOMINATOR=3 MOVERS=1`**, the known one |
| commit census `<R>/ra/census.sh` on INSTR | NULL, `env -u CQ_WOA0_COMMITLOG` on `x3` | **`NULLCONTROL_EVENTS=0`** |
| same | POSITIVE, env set on `x3` | **`POSCONTROL_EVENTS=1`** |
| mutant harness on the supplied MUTANTS binary | NULL, MUT with no mutation env vs SUBJECT on my two probes | **stderr byte-identical, rc equal, 2 of 2** |
| `WeakVH` semantics probe `<R>/ra/vh.cpp`, linked against this machine's LLVM 19 | prints the pointer before/after RAUW and after erase, for BOTH handle kinds | see `F-RA-0` |

⚠ Every sweep prints its DENOMINATOR. ⚠ And my own first probe table captured `rc=$?` **after a
pipe into `head`** and printed `rc=0` for a module that exits 1 — the same class as CLAUDE.md
§3 L10's `2065 of 2106`. Every rc below is captured with no pipeline between the binary and
`$?`, and that table was re-run, not patched.

---

## F-RA-0 — not a finding: a claim I set out to falsify and could not

The source stakes the whole handle choice on *"`WeakVH` nulls on deletion and (unlike
`WeakTrackingVH`) does NOT follow RAUW, so it keeps naming the φ right through `convertPhis`'
`replaceAllUsesWith`"*. I believed from memory that `Weak` nulls on RAUW, which would make that
sentence backwards at a load-bearing place. **I measured instead of arguing** (`<R>/ra/vh.cpp`,
built and run against LLVM 19 here):

```
before RAUW: WeakVH=0x6000038d80d0 (A=0x6000038d80d0) WeakTrackingVH=0x6000038d80d0
after  RAUW: WeakVH=0x6000038d80d0                    WeakTrackingVH=0x6000038d8160 (D=…8160)
WeakVH nulled by RAUW? NO
after erase: WeakVH=0x0                               WeakTrackingVH=0x6000038d8160
```

**The comment is exactly right and my recollection was wrong.** `recordHoldsRailPhiLeaf`'s
`static_cast<const Value *>(H) == Needle` therefore cannot match a fresh φ at a recycled address
(a nulled handle never equals a live `PHINode *`), and the observation — which runs **before**
`convertPhis`' RAUW in the same loop iteration — is unaffected either way. Recorded so the next
round need not re-derive it, and because it is the one place here where a plausible-sounding
memory contradicts the source.

---

## P2 — `F-RA-1`: the record is populated at the E6 **ADMISSION**, not at "the emitted tree READS the φ" — **two MEASURED A→D on modules the ORACLE compiles CORRECTLY**

### The claim

Three sites say the same thing, and it is what the "no over-decline" argument rests on:

* `PredMuxFlatten.h`, `PredMuxRailPhiRecord::Leaves`: *"φs that an EMITTED region's condition
  tree reads as a rail leaf."*
* `PredMuxRegion::RailPhiLeaves`: *"the rail φs E6 admitted as condition-tree LEAVES, i.e. the
  ones this flatten proved it will NOT convert **and will therefore READ**."*
* `MEASUREMENT_WOA0.md` §3: *"Not one verdict moved. … it converts an accident into a fence **and
  nothing else**."*

### The mechanism

`S->RailLeaves->insert(RP)` sits inside `isSupportedCondTree`'s M4 arm
(`ir-pass/src/PredMuxFlatten.cpp:1061-1069`) — the moment E6 **admits**. Whether the φ is then
**read** is decided later and elsewhere: `literal()` / `edgePred()` / `buildNegation()` are
called **lazily**, only when `convertPhis` needs an edge predicate, and `convertPhis` skips an
incoming entirely under its `In[I].second == Acc` guard (`select(EP,x,x) = x`). A merge whose
arms agree mints no select, demands no literal, and the φ never enters the emitted module at
all — yet the region is claimed, the commit runs, and a later claim then trips a fence
protecting nothing. The same happens when the emitted select is minted and subsequently dies.

### Failure scenario, MEASURED

Both probes are round 3's `x3_outer_declines_then_claims.ll` with one edit; both are on disk at
`<R>/ra/`.

| probe | the edit | ORACLE | SUBJECT |
|---|---|---|---|
| `ra1_unread_leaf.ll` | `Am`'s two merge φs given EQUAL arms (`[2,2]`, `[3,3]`) | **rc=0**, 0 B stderr | **rc=1**, `emitted predicate tree's rail phi converted by a later flatten` |
| `ra2_deadmerge.ll` | `x3` verbatim except the two `cq_measure` calls read `%u`/`%q`, so the merge values are dead | **rc=0**, 0 B stderr | **rc=1**, same string |

Null control for the pair, run first: `x2_naturalorder.ll` — ORACLE rc=0, SUBJECT rc=0.

Both contain the shape their names claim, read off the DBG trace and the instrumented commit log
rather than off the verdict (bd `46oo`):

```
CQ_WOA0: commit fn=probe phiblk=A phi=%rp entry=A merge=Am        (INSTR, both probes)
CQ_PREDMUX_DBG: converted recorded rail phi @probe blk=A phi=%rp  (SUBJECT, both probes)
```

**The ORACLE's compile is correct, checked by reading the stream rather than by assuming.**
`ra1`'s ORACLE output is two `cqrt_alloc_*`/`cqrt_ry_*` rails plus two X-bracketed
`cqrt_copy_i32_controlled` merges on `cq_template_icmp_sle_i32_hl(h,9)` — i.e. `o = q>9 ? 2 : 7`
and `o2 = q>9 ? 3 : 8`, which is the source — with `free_pairing_check.py` reporting
`2 verified, 0 violation(s), 0 unproven`. `ra2`'s ORACLE output is the two rails, the two
measures and the classical `add`, the dead merge cone gone. Neither reads `%rp`.

**Attributed by mutation, both directions** (null control: MUT with no mutation env ≡ SUBJECT,
stderr byte-identical, on both probes):

| probe | MUT (no env) | `NORECORD` | `NOCOMMIT` | `NOBOOLALG` |
|---|---|---|---|---|
| `ra1_unread_leaf` | rc=1 (the fence) | **rc=0** | **rc=0** | rc=1 |
| `ra2_deadmerge` | rc=1 (the fence) | **rc=0** | **rc=0** | rc=1 |

So the A→D is caused by this change's RECORD and COMMIT specifically — not by anything else in
the delta and not by the `!BoolAlg` conjunct.

### Why the change's own measurements could not see it

I ran the implementer's instrument over the implementer's probe set. Of the eight shipped
probes, **the two that ACCEPT commit nothing**:

```
x1_entryphi_converted_later   commits=1 conversions=1      w_c_truerail         commits=1 conversions=1
x2_naturalorder               commits=0 conversions=0      w_d_allconst         commits=0 conversions=0
x3_outer_declines_then_claims commits=1 conversions=1      w_e_railtrue_swapped commits=1 conversions=1
w_b_railrail                  commits=1 conversions=1      w_f_boolalg_witness  commits=1 conversions=0
                                                           DENOMINATOR=8
```

`MEASUREMENT_WOA0.md` §3 calls `w_d_allconst` a weak control and says why — good — but presents
`x2_naturalorder` as an ordinary unchanged accept, and the two are weak in the identical way. So
the matrix has **no cell** in the quadrant "record populated ∧ module accepts". The whole-corpus
A/B cannot supply one either: my independent census finds **5 commit modules in 2157 and none of
them converts**. *A clean `A→D = 0` measured over a population with no members of the class is
not evidence about the class* — this record's own standing caveat, not applied to the row that
needed it.

### The scope of the defect, bounded by a candidate fix I BUILT and MEASURED

I patched exactly one line in my own worktree and rebuilt (`CANDFIX c3b7a5961771a56af012d6b4`):

```c
-      if (!BoolAlg && Rec && recordHoldsRailPhiLeaf(*Rec, P)) {
+      if (!BoolAlg && !P->use_empty() && Rec && recordHoldsRailPhiLeaf(*Rec, P)) {
```

(A φ with no uses at conversion time cannot have been read by anything, so its RAUW is a no-op
and its conversion is definitionally harmless.) Measured across all nine probes:

| probe | ORACLE | SUBJECT | CANDFIX |
|---|---|---|---|
| `ra1_unread_leaf` | rc=0 | rc=1 | **rc=0, emitted IR BYTE-IDENTICAL to the ORACLE's** |
| `ra2_deadmerge` | rc=0 | rc=1 | **rc=1 — NOT recovered** |
| `x3`, `x1`, `w_b`, `w_c`, `w_e` | rc=1 (old string) | rc=1 (fence) | rc=1 (fence) — **all five declines preserved** |
| `x2_naturalorder`, `w_d_allconst` | rc=0 | rc=0 | rc=0 |
| both shipped new fixtures | — | rc=1 / rc=0 | **rc=1 / rc=0 — unchanged** |

**The result that matters is the one that did NOT work.** `ra2` still declines, because its
emitted select is *minted and then dead*, not *never minted* — so the over-decline is at least
**two** sub-classes and `use_empty` covers only the first. Anyone reaching for a one-liner
should read that row before writing it.

### What it is NOT

**I could not reach the fence from C.** Eight perturbations of
`example/grover/grover_oracle_uncompute.c` (nested `if`, swapped nesting, `&&`, sequential
regions, a negated bank read, a ternary, a duplicated guard) at the `-O1` floor:
`C-PERTURBATION DENOMINATOR=8 MOVERS=0` on rc, stderr **and** emitted IR, and **0 of 8 reached
the fence**. So the over-decline is IR-level today. That is a result, not a proof; and the
shipped decline fixture's own PROVENANCE paragraph already concedes the whole shape is unlikely
from `clang -O1` — which argues for fixing the record, not for leaving it, because the day bd
`41g3`'s route lands, "recorded but never read" is the first class it must un-decline.

### Suggested disposition

Not blocking. **Record at the READ, not at the admission**, and until that lands say so at all
three sites (the `F-RA-6` sentence). Two routes, both needing their own red-green pair
(`ra1`/`ra2` are the green half, on disk), an injection matrix and their own round, because
**narrowing a decline is an accept-direction change**:

* *(a)* the `!P->use_empty()` line above — measured, recovers `ra1` byte-for-byte, does **not**
  recover `ra2`, moves nothing else in the corpus (see `F-RA-1`'s blast-radius row in "what I
  attacked");
* *(b)* commit the leaves **after** `run()`, filtered to those the emitted region actually reads.
  This is the total version and it re-opens the `{R.Merge}` cell the current pre-`run()`
  placement exists to cover, so it owes that argument too.

---

## P2 — `F-RA-2`: the record is keyed on SSA IDENTITY and spans two **cloning / loop-rewriting** pre-passes, and nothing argues identity stability across them

### The claim

`CQLoweringPass.cpp:375-381`: *"`railPhiRec` … is declared out here … for the only reason that
matters: the property it polices is violated BETWEEN claims … It is threaded through all THREE
fixpoints below (this one, the unroll pre-pass's and the ctlz pre-pass's) and re-asked once,
after the last of them."*

That argues why the record must **span** the three fixpoints. Nothing in the change argues that
the φ *identities* it names survive them, and two of the three are driven by stages that do not
merely mutate in place:

* `unrollConstTripLoops` **fully unrolls** a const-trip loop — erasing the body's φs and cloning
  the body (`isSafeToClone`, U8). A recorded φ inside such a loop is erased, its `WeakVH` nulls
  (measured, `F-RA-0`), and the clones are new `PHINode`s the record does not hold. If the
  emitted predicate tree that read the original was cloned with it, a later claim converting the
  CLONE is **not observed** and the module falls back to the pre-fix downstream accident.
* `recognizeCtlzIdiomLoops` likewise **erases the loop** and substitutes a closed form.

### Why P2, and exactly how far I got

The consequence is a return to the PRE-FIX state for that module, which round 3 argued
analytically cannot be a wrong unitary (RAUW is value-preserving; the unsound `buildNegation`
select arm is intra-region) and did **not** prove exhaustively. So: a hole in a fence, not a
demonstrated miscompile — and the change's headline *"what is now total is the OUTCOME"* is
weakened by it.

**ARGUED, NOT CONSTRUCTED.** `LoopUnrollPrepass.h`'s **U2** refuses a loop body containing any
`cq_*`/`cqrt_*` call, so the `cq_theta_i1` that makes a φ *structural* must sit OUTSIDE the loop
while the φ sits inside it — legal (`phi i1 [ %b, %preheader ], [ false, %latch ]`) but it must
also coexist with a PredMux claim in the same body and a block order that defers the outer claim.
**I ran out of budget before building it. "I could not construct it" is where I stopped, not a
proof that it cannot be constructed.**

### Suggested disposition

Write the argument at the field, or fence it. The cheapest honest step is a sentence plus a
null-out sweep at the re-ask (dropping a nulled `WeakVH` is a no-op today — the point is the
written retirement trigger: *"a stage that ERASES or CLONES a recorded φ inside this window makes
the record incomplete, not wrong"*). The stronger claim to check first is that each pre-pass's
own nested PredMux re-fixpoint **re-admits and re-records** any surviving clone, which would
close the hole for free — **that sentence is measurable and is currently written nowhere.**

---

## P3 findings

| # | finding | evidence | disposition |
|---|---|---|---|
| `F-RA-3` | **`convertPhis`' *"it is the only place in the pass where that conversion happens"* is false as written.** `MergePhiPeel.cpp:568` (`SelectInst::Create(CondV, TV, FV, "cq.peel.mux", IP)`) also replaces a φ with a `select`, and `SwapRouteEmit.cpp:573` does it for a value-arm merge. Both run AFTER the module re-ask (`MergePhiPeel` is called before every `detectControlRegions`, downstream of the re-ask slot), so neither is inside the fence's window — the sentence is true of PredMux and false of the pass | `grep -n "CreateSelect\|SelectInst::Create" ir-pass/src/*.cpp` → exactly 3 sites, all read | **SCOPE THE SENTENCE** to "the only place in this file", and add in the same breath that a post-re-ask converter is outside the window BY CONSTRUCTION. As written it reads as a totality claim, and the next agent who moves the window will believe it |
| `F-RA-4` | **One directive in the new ACCEPT fixture is UNCONDITIONALLY vacuous.** `control_predmux_accept_recorded_railphi_boolalg_converted.ll`'s `NEG-NOT: rail phi converted` is checked by `%filecheck %s --check-prefix=NEG < %t.cqd0.ll`, i.e. against **stdout**; the string it forbids only ever reaches **stderr** (that RUN line has no `2>&1`). It cannot fail on any binary, accepting or declining. The header concedes the NEG prefix is vacuous *on a decline*; it is vacuous on an accept too | read; the RUN line redirects only stdout | **DELETE IT, or move it to a `2>&1` RUN line.** A directive that cannot fail is worse than none, because it reads as coverage. The other two NEG lines (`select i1`, `phi i1`) are real, and the exact `grep … \| count N` lines are what actually carry the file |
| `F-RA-5` | **`declineConvertedRailPhiLeaves` SILENTLY ACCEPTS on `Converted && !AtFn`.** `if (!Rec.Converted \|\| !Rec.AtFn) return false;` — an OBSERVED violation with a null blame pointer returns **false**, i.e. the module compiles with no diagnostic anywhere. `AtFn` is null only if `D->getParent()` is null (a detached block), so it is unreachable today — but the field's own RETIREMENT TRIGGER worries about the OPPOSITE direction (*"returning true without a message is Rule 1's 'third path'"*) and the shipped code takes the worse one | read `PredMuxFlatten.cpp` (`declineConvertedRailPhiLeaves`) and `PredMuxFlatten.h`'s `AtFn` note | **SPLIT THE TEST.** `if (!Rec.Converted) return false;` then, when `!Rec.AtFn`, emit on any reachable function (or `report_fatal_error`) — never return false. One line, and it makes the trigger's own direction the shipped one |
| `F-RA-6` | **`MEASUREMENT_WOA0.md` §3's probe matrix has ZERO cells in the quadrant the over-decline surface lives in, and the record flags only half the reason.** `w_d_allconst` is correctly called a weak control; `x2_naturalorder` is presented as an ordinary unchanged accept and is weak identically. Measured on INSTR: both commit **0** | the 8-probe census table above | **ADD THE ROW AND THE SENTENCE:** "the matrix contains no cell in which the record is populated and the module accepts; the over-decline surface is therefore unmeasured." That sentence is what `F-RA-1` cost |
| `F-RA-7` | **The diagnostic's anchor is `P->getDebugLoc()` — a φ's location — and every module that reaches the fence prints `<unknown>:0:0`.** Rule 1 wants a source-located diagnostic; a `PHINode` is among the instructions LLVM most often leaves without `!dbg`, while the obvious alternatives (the converting block's terminator, the emitting region's branch) always carry one. ⚠ **OBSERVED, NOT PROVED**: I could not reach the fence from C at all, so every module that reaches it is hand-written IR with no `!dbg` | 7 shipped probes + my 2, all `<unknown>:0:0` | **FALL BACK** to the converting block's terminator loc when the φ has none, and record that the behaviour is untested with real debug info |
| `F-RA-8` | **`MEASUREMENT_WOA0.md` §5's census number is stale by one and the staleness hides the increment's own accept fixture.** §5 reports *"4, in 4 modules"* over 2156 fixtures. Re-measured on the same INSTR binary over all **2157**: **5 modules**, the fifth being `control_predmux_accept_recorded_railphi_boolalg_converted.ll` (`phiblk=J phi=%cphi entry=J`) — i.e. the census ran before that fixture landed. Harmless to every conclusion (§5's two real claims both survive: every commit is the ENTRY-φ cell, and the `!InRegion` disjunct has no commit customer anywhere) but the number as printed is not reproducible at HEAD | `<R>/ra/census.txt`, `CENSUS DENOMINATOR=2157 MODULES_WITH_COMMITS=5`, null and positive controls first | **RE-STATE AS 5 OF 2157**, or say the census predates the accept fixture. A census quoted without the tree state it was taken on is the class of number this project keeps retracting |

---

## What I attacked and did NOT break

**The RECORD is COMPLETE for the leaf route — enumerated over every admit arm, not assumed.**
`isSupportedCondTree` returns true for a `PHINode` by exactly two arms: the M4/woa0 arm (which
records) and `isConvertiblePhiCond` (which records into `BoolAlgPhis`, after which the flatten
converts that φ BY BOOLEAN ALGEBRA inside its own `run()`, so the emitted tree reads the algebra
and not the φ). Every other arm is a `CallInst` (`isCondRailLeaf`), a `ConstantInt`, a `CmpInst`,
an `and`/`or`/`xor` node, or a poison-shielded `select` — and each composite arm threads `S` into
its recursion, so a rail φ nested under `and`/`or`/`xor X,true`/either select clause is still
recorded. Under `Strict` (the two-operand-xor sub-grammar) the M4 arm is skipped and the φ is
REFUSED, so nothing is emitted unrecorded. **Three top-level scopes exist:** `PredMuxFlatten.cpp`
`:3280`/`:3281` (the two W6 witnesses, aggregate-initialised with three members so `RailLeaves`
takes its `nullptr` NSDMI — a witness walk records nothing, and neither witness is an emission)
and `:3351` (the claim scope, the only one with a non-null `RailLeaves`). One recording arm, one
recording scope, and no other route by which an emitted tree reads a φ *as a leaf*.

⚠ **The scope statement the record does not make:** a φ can also sit in an emitted tree as a
*data operand of a compare leaf* (`icmp sgt %q, %dphi`), and those are neither recorded nor
covered. The increment's own accept fixture contains exactly that (`%dphi` in block `J`) and it
compiles on both binaries — so the exclusion is currently benign, but it is an exclusion and it
should be written down beside the record's definition.

**A genuine rail φ CANNOT reach `BoolAlg == true`, so the `!BoolAlg` gate cannot skip a real
hazard.** `BoolAlg` survives only if the φ is in the converting region's `R.BoolAlgPhis` (which
bypasses the re-check) or if every incoming passes the scope-less `isBooleanCondTree`. The latter
rejects a `CallInst` outright (`PredMuxFlatten.cpp:1260-1300`: `ConstantInt`, `PHINode` via
`isConvertiblePhiCond` with a null scope ⇒ false, `CmpInst`, distinct-operand `and`/`or`; nothing
else). The former requires `isConvertiblePhiCond` to have inserted it, which demands the same
grammar on every incoming. And `isStructuralRailPhi` requires every incoming to be a
`cq_theta_i1` CALL or an `i1 ConstantInt`. The intersection is therefore the ALL-CONSTANT φ — the
boolalg fixture's cell — unless an incoming CHANGES from a rail call to something in-grammar
between the record and the conversion, and no stage in the window rewrites a `cq_theta_i1` call
into a constant or a compare (`deleteDeadPreservingCqOwned` explicitly preserves it;
`simplifyFlattenResiduesInFunction`'s `isFlattenResidue` matches only constant-operand `and`/`or
i1` and `SelectInst`, never a `PHINode` or a `CallInst`). **ARGUED from three read predicates plus
the absence of a rewriter; I constructed no counterexample and I do not claim one is impossible.**

**The `!BoolAlg` conjunct's single fixture IS non-vacuous for the conjunct, verified by RUNNING
the mutant rather than by re-reading the prefixes** (bead item 6). On
`control_predmux_accept_recorded_railphi_boolalg_converted.ll`: MUT with no env ≡ SUBJECT
(emitted IR byte-identical); `CQ_WOA0_MUT_NOBOOLALG=1` → **rc=1** with the woa0 string, an A→D;
ORACLE → rc=0 and **byte-identical to SUBJECT**. So the fixture really does hold a recorded φ
that is really converted down the boolean-algebra path. `lit --filter 'rail_phi'` +
`--filter 'railphi'`: **7 of 7 PASS** on SUBJECT. `F-RA-4` is the one directive in it that
carries nothing.

**The clone driver's record is DISJOINT BY CONSTRUCTION, not by argument** (bead item 4).
`lowerCloneControl` drives `flattenPredMuxRegions(M, ct, true, &cloneRailPhiRec)` over the whole
module, but `isTaintedCtrlTerm` consults **only** `Taint.Tainted`
(`PredMuxFlatten.cpp:107-113`), and `ct` is built by `seedClone` (`SpecializeSeed.cpp:18-47`) and
rebuilt by `reseedCloneTaintFromParams` (`Specialization.cpp:434-452`) — **both** clear-then-seed
from the clone's own `Argument`s and skip every user with `I->getFunction() != Clone`. No
terminator outside the clone can be tainted under `ct`, so no region outside the clone can be
rooted, so that driver can never convert a φ the module-level record holds. The source calls this
"argued, same species, same disposition"; it is *provable* from three files and should say so.
The re-ask's slot there (immediately after its own fixpoint, before the `Clone.size() != 1`
backstop) is right: `specialize()` runs after `detectControlRegions` and after
`repropagateControlMerges`, so no module-level slot can reach it, and the `false` return lands on
the caller's existing loud decline + retarget path.

**`buildNegation`'s unchecked `cast<ConstantInt>` is NOT made reachable by a cross-claim
conversion** (round 3's `F-R3-10`, re-derived rather than inherited). `convertPhis` can produce
exactly four select shapes from a 2-incoming structural rail φ, and E6's select clauses test
`FC->isZero()` and `TC->isOne()` (`PredMuxFlatten.cpp:1228-1237`), not mere constant-ness:
`select(EP,%rail,false)` → admitted, `buildNegation` arm 1, De Morgan correct;
`select(EP,true,%rail)` → admitted, arm 2, the cast succeeds on `true`, correct;
`select(EP,%rail,true)` and `select(EP,false,%rail)` → **refused at E6**, so `buildNegation`
never sees them. The dangerous case — a `TrueValue` that is a constant but NOT one, which would
make arm 2's De Morgan silently wrong rather than crash — is exactly the one E6 refuses.

**Whole-corpus A/B, independently reproduced.** ORACLE vs SUBJECT over all 2157 fixtures:
**`DENOMINATOR=2157 MOVERS=1`** — `control_predmux_reject_rail_phi_converted_by_later_claim.ll`,
a STRING move from `control flow under quantum control` to the new fence. **A→D = 0, D→A = 0, IR
moves = 0, rc ≥ 128 on either binary = 0.** Null control (SUBJECT vs SUBJECT, 2157) **0 movers**,
run first; positive control 1 of 3. ⚠ My harness compares exit code, normalised stderr and the
emitted IR; it does **not** evaluate any fixture's `RUN`/`CHECK` directives, so "1 mover of 2157"
is not "lit is green".

**A LAYER THE CHANGE'S RECORD DID NOT SWEEP — all 404 `tests/e2e/slice_*.c` sources** (403
compile at stage 1; 1 needs flags my harness does not pass). ORACLE vs SUBJECT on the stage-2
output: **`DENOMINATOR=404 CLANG-SKIPPED=1 MOVERS=0`** — no rc move, no stderr move, no IR move.
My stage-1 command is byte-identical to `tests/e2e/run_slice.sh:61`
(`clang -I include -include CQ.h -O1 -emit-llvm -S`), checked against the script rather than
assumed. This is the C-level population the fixture corpus cannot speak for, and it is clean.

**PROVENANCE, paid rather than inherited** (round 3's `F-R3-3`). I configured and built
`90e79229` in a fresh worktree whose `CMakeCache.txt` `CMAKE_HOME_DIRECTORY` points **inside
itself**, and the result is **`15adcac40d4455a7f2d9f785` — bit-identical to the shipped
SUBJECT**. So the source I reviewed is the source that ships.

**The owner's program, re-measured rather than quoted.** `example/grover/grover_oracle_uncompute.c`
and `tests/e2e/slice_grover_oracle_uncompute.c`: ORACLE rc=0 / **0 bytes stderr**, SUBJECT rc=0 /
**0 bytes stderr**, lowered modules **BYTE-IDENTICAL**. And it is a live customer of the record,
not an inert pass-by: INSTR logs `commit fn=main phi=%cq.bank1` on **both** files and
`CQ_PREDMUX_DBG` reports **0** conversions. The fence sees the most important accept in the tree
and correctly does not fire.

**The commit census, independently reproduced with its own controls** — `CENSUS DENOMINATOR=2157
MODULES_WITH_COMMITS=5`; every one of the five is the **ENTRY-φ** cell (`phiblk == entry`), and
the `!InRegion` disjunct (bd `0fly`'s `{R.Merge}` cell) has **no commit customer anywhere**. That
reproduces §5's two substantive claims from a second instrument; `F-RA-8` is only the count.

**The L8 duplicate-body scan, independently reproduced** (sha-256 over each fixture's
non-comment, non-blank lines, all 2157): **9 identical-body groups, none involving either new
fixture** — matching `MEASUREMENT_WOA0.md` §9 including its "nine is more than the five bd `fn1q`
recorded" note.

**The seven call sites and the round-2 / L1 clearance, RE-DERIVED rather than inherited** (bead
item 7). `grep -rn "flattenPredMuxRegions("` gives seven: `CQLoweringPass.cpp:383/407/436`
(`run()`), `:1157/1173/1191` (`runOnFunction`), `Specialization.cpp:552` (`lowerCloneControl`).
**All seven pass a record**, and neither parameter has a default, so an eighth must decide. The
round-2 conclusion survives for reasons I checked myself rather than the ones round 2 gave: the
record's predicate (`isStructuralRailPhi` — a `cq_theta_i1` CALL or an `i1` constant per
incoming) and the placement conjunct (block identity) are **purely syntactic and
taint-independent**, so no round-2 taint growth can falsify them; `repropagateControlMerges`
re-runs `detectControlRegions` + `lowerControlRegions` and does **not** re-run
`flattenPredMuxRegions`, so no PredMux claim exists inside the round-2 window at all; and the
seventh site — the one `F-R3-9` showed runs AFTER `detectControlRegions` — is clone-scoped as
above. `runOnFunction` remains a **dead shim** (`Plugin.cpp` registers only the module pass;
`CQLoweringPass.cpp:1031` says so; `grep` finds no caller), which is the only reason its per-call
record is not a hole of its own: a second call would begin with a fresh record while the module
may still hold φs the first call recorded.

**Bead item 8, answered: YES — the fence hides accepts that bd `41g3`'s route would recover, and
two of them are measured.** Under 41g3's route (record the φ so `convertPhis` cannot select-chain
it), `ra1`, `ra2` and `x3` all keep their φ and compile. The shipped decline fixture's retirement
trigger already predicts "this file becomes an ACCEPT"; what is new is that **two of the hidden
accepts are ones the pre-fix compiler already produced correctly**, so they are not hypothetical
recoveries — they are regressions waiting for the route.

**Bead item 3 — the `AtFn` raw-pointer window — attacked and not broken.** Between the write
(`convertPhis`) and the read (the re-ask) the only stages that run are the remaining
`flattenPredMuxRegions` calls (which erase `BasicBlock`s, never `Function`s), `propagate` (pure
analysis), `foldConstantConesInFunction` (instructions and blocks),
`simplifyFlattenResiduesInFunction` (instructions), and the two loop pre-passes (bodies in place
or clones into the same function). None erases a `Function`. In `lowerCloneControl` the window is
three statements. The header's argument is sound; `F-RA-5` is the part of that field's own
contract the code does not honour.

**Bead item 5 — the pre-emptive slot.** The re-ask runs before `detectSpecializations`,
`declineTaintEscapes` and everything downstream, so it now owns the decline for any module that
reaches it. Over 2157 fixtures plus 403 e2e slice sources that is exactly one module and the
owner move is the intended one. The cost is `F-RA-1`: pre-emption is free only while the fence is
right, and on `ra1`/`ra2` what it pre-empts is a successful compile.

**Blast radius of the candidate fix, for whoever lands it.** SUBJECT vs CANDFIX over all 2157
fixtures: see `<R>/ra/ab_subject_vs_candfix.txt`. **`DENOMINATOR=2157 MOVERS=0`** (null control 0 of 2157 run first, on the same harness). So route (a) is inert on the whole committed corpus and its ONLY witnesses would be `ra1` (recovered, byte-identical to the ORACLE) and `ra2` (still declining) — i.e. it lands in the bd `test_C_libtooling-e1gr` class, a predicate with an empty corpus population, pinned by a new fixture pair or by nothing. Say that in the increment rather than quoting the clean sweep.

---

## ⚠ WHAT I DID NOT ATTACK

* **No simulation, no statevector** (Rule 2). Every correctness claim above is a verdict, a
  string, a byte-diff, an event count, a read of the emitted stream, or a 2b free-pairing line.
* **No `+Asserts` build** (bead item 2). I did not exercise the new unchecked `cast<PHINode>`
  context (round 3's `F-R3-6`); the tree still cannot have a Debug `cq-opt`.
* **I did not run the full `ctest`**, `e2e-loop-twin-matrix`, the quarantine selftest,
  `free_pairing_check_test.py`, `cq-opt-equivalence`, or any e2e slice end-to-end (link + run +
  golden diff). At the lit layer I ran `--filter 'rail_phi'` and `--filter 'railphi'` — **7 tests,
  all PASS** — and nothing else. **So: "7 targeted lit tests green, two whole-corpus stage-2 A/B
  sweeps clean, and 403 e2e slice sources clean at stage 2" — NOT "the suite passes".** A
  harness-level red is invisible to everything I ran.
* **I did not build the total version of `F-RA-1`'s fix** (route (b), commit-after-`run()`
  filtered to actual reads), and my measured route (a) provably does **not** cover `ra2`. The
  second sub-class (an emitted select that is minted and then dies) has no candidate predicate in
  this report.
* **I did not construct `F-RA-2`'s instance** (a recorded φ erased and cloned by
  `unrollConstTripLoops` or `recognizeCtlzIdiomLoops` inside the record's window). U2's
  no-`cq_*`-call fence makes it awkward, not obviously impossible. Reported as ARGUED, and I did
  **not** check whether each pre-pass's nested PredMux re-fixpoint re-records the clone — that is
  the measurement that would close or confirm it.
* **I did not build the "emitted tree READS the converted φ AND the module still accepts" case**,
  which is the strongest form of `F-RA-1` and round 3's own unbuilt shape. My reading says it is
  foreclosed for the 4.4 DATA-select consumer (`collectCondTree` is called there with
  `AllowLogicalSelect=false`, so `select(EP,%rail,false)` is off-grammar) and open only for a
  PHASE consumer (`AllowLogicalSelect=true` reads it as `And(EP,%rail)`, which is the φ's exact
  meaning) — but a phase branch reading such a φ would also need `preppedRailPhiRegionIdx` to own
  it, and I got no module past that. **Unbuilt in both directions; do not read my reading as a
  proof that the case is empty.**
* **I did not attack `MergePhiPeel` as a converter of a recorded φ** beyond establishing that it
  mints selects from φs and runs after the re-ask (`F-RA-3`). Whether a *structural rail* φ can
  be peeled, and what the already-emitted PredMux tree then reads, is unexamined.
* **I did not attack the data-operand exclusion** (a φ inside a compare leaf of an emitted tree)
  beyond observing that the increment's own accept fixture contains one and compiles.
* **I did not re-derive increments 1–5a, bd `0fly`'s unwritten dominance argument, bd `41g3`'s
  original P1, or any round-3 finding other than `F-R3-9` and `F-R3-10`.** My ORACLE contains all
  of them, which is what makes the woa0 delta clean; that is all I used them for.
* **I did not run the injection matrix** over either new fixture (Rule 12 hygiene (c)); `F-RA-4`
  is a read of one directive, not a matrix.
* **I did not test the diagnostic with real debug info** (`F-RA-7`) — no module carrying `!dbg`
  reaches the fence.
* **I did not exercise `runOnFunction`**; it has no caller.
* **I did not sweep the `run_slice_multi.sh` multi-source slices**, the `-O2`/`-O3` regression
  matrix, or anything outside `ir-pass/test/*.ll` + `tests/e2e/slice_*.c` + `example/grover`.
* **I did not read ROUND B's report**, which was already present in this directory when I started
  writing; overlap and contradiction between the two are for the orchestrator to reconcile.
* **Load and timing.** The box carried my own background sweeps and two worktree builds during
  parts of this review. **No row above is a timing**, and every sweep was preceded by its own
  null and positive control on the same binaries.
* **Everything is on disk.** Probes `<R>/ra/{ra1_unread_leaf,ra2_deadmerge,ra3_halfequal}.ll` and
  `<R>/ra/cvar/v{1..8}.c`; harnesses `<R>/ra/{ab.sh,abdir.sh,census.sh}`; the `WeakVH` probe
  `<R>/ra/vh.cpp`; sweeps `<R>/ra/{null.txt,ab_oracle_vs_subject.txt,ab_subject_vs_candfix.txt,census.txt}`.

**State of the tree on exit.** All four supplied binary hashes re-checked and unchanged; the
primary `build/ir-pass/cq-opt` is still `15adcac40d4455a7f2d9f785`. The primary working tree's
`git status` is the session-start set plus this one file; I did not build in, write to, or delete
the primary `build/`. I added one git worktree, `<R>/wt-ra-PRIMARYSRC` (detached at `90e79229`,
now carrying the one-line candidate patch and its `CANDFIX` binary so the measurement is
reproducible); whoever owns cleanup should `git worktree remove` it.

---

## Appendix — the two `F-RA-1` probes, reproducible without my scratch directory

My scratch is session-scoped and will be reaped, so both probes are given as exact edits to the
committed fixture `ir-pass/test/control_predmux_reject_rail_phi_converted_by_later_claim.ll`
(which is round 3's `x3_outer_declines_then_claims.ll` verbatim).

**`ra1_unread_leaf.ll`** — the emitted tree never reads the recorded φ, because the merge mints
no select at all:

```diff
 Am:
-  %v  = phi i32 [ 2, %Aarm ], [ 5, %A ]
-  %v2 = phi i32 [ 3, %Aarm ], [ 6, %A ]
+  %v  = phi i32 [ 2, %Aarm ], [ 2, %A ]
+  %v2 = phi i32 [ 3, %Aarm ], [ 3, %A ]
   br label %Bm
```

**`ra2_deadmerge.ll`** — the emitted selects are minted and then die, because nothing reads the
merge:

```diff
-  %m1 = call i32 @cq_measure_si32(i32 %o)
-  %m2 = call i32 @cq_measure_si32(i32 %o2)
+  %m1 = call i32 @cq_measure_si32(i32 %u)
+  %m2 = call i32 @cq_measure_si32(i32 %q)
```

Both: **ORACLE `fe5805a4…` rc=0, 0 bytes stderr; SUBJECT `15adcac4…` rc=1,
`cq controlled lowering: emitted predicate tree's rail phi converted by a later flatten`.**
`CQ_WOA0_MUT_NORECORD=1` and `CQ_WOA0_MUT_NOCOMMIT=1` each restore rc=0 on both.
`CANDFIX c3b7a596…` restores `ra1` (emitted IR byte-identical to the ORACLE's) and leaves `ra2`
declining.

The C perturbation family (`F-RA-1`'s reachability negative) is
`example/grover/grover_oracle_uncompute.c` with the loop body's second statement replaced, in
turn, by each of:

```c
if (b0[i]) { if (Z > 1) { Z -= z[i]; } P += p[i]; }                 /* v1 */
if (Z >= 2) { if (b0[i]) { Z -= z[i]; P += p[i]; } }                /* v2 */
if (b0[i] && Z > 1) { Z -= z[i]; P += p[i]; }                       /* v3 */
if (b0[i]) { Z -= z[i]; P += p[i]; } if (Z > 2) { P += 1; }         /* v4 */
if (Z > 2) { P += 1; } if (b0[i]) { Z -= z[i]; P += p[i]; }         /* v5 */
if (b0[i]) { Z -= z[i]; } if (b0[i]) { P += p[i]; }                 /* v6 */
if (!b0[i]) { Z -= z[i]; P += p[i]; }                               /* v7 */
int t = b0[i] ? z[i] : 0; if (Z > t) { Z -= t; P += p[i]; }         /* v8 */
```

`clang -I include -include CQ.h -O1 -emit-llvm -S`, then both binaries:
`C-PERTURBATION DENOMINATOR=8 MOVERS=0`, and `grep -c "rail phi converted"` on SUBJECT's stderr
is **0** for all eight.
