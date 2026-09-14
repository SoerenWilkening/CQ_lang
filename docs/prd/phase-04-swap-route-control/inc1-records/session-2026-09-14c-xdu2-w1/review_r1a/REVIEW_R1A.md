# REVIEW R1A — Rule-13 round 1, track α: the A×B composition and `SCOPE_L1a` §4's fence enumeration

**Reviewer:** independent, wrote none of this code. **Worktree:** `/Users/sorenwilkening/Desktop/CQ_rev_a`, branch `r13-r1-alpha`.
**No build, no `lit`, no `ctest`** (PROTOCOL review row). Everything below is the per-probe pipeline,
SUBJECT vs ORACLE on the SAME stage-1 file, plus source reading.

**Binaries** (`shasum -a 256`, verified before the first probe and after the last, UNCHANGED):

| role | path | sha256 |
|---|---|---|
| SUBJECT | `/Users/sorenwilkening/Desktop/CQ_merge/build/ir-pass/cq-opt` | `0e280fc62a91cec2336769edde8a873563a21ee4869744331a0fcf6811549c6d` |
| SUBJECT | `…/libCQPass.so` | `94602c7896e7a7ee1d0d0d54625a073f6a35fd6c9fe0af6e9c714b2043df507b` |
| ORACLE | `/Users/sorenwilkening/Desktop/CQ_lang/build/ir-pass/cq-opt` | `5c6f7490a81c75057fe73abcd6fa5a8e8026e0ccc810e961ff7197f62e515ba8` |

> ⚠ `cq-opt` accepts and IGNORES `-load-pass-plugin`, so every measurement here is a fact about the two
> `cq-opt` binaries; the `.so` hash is recorded only so a future rebuild is detectable.

---

## VERDICT — **CLEAR-WITH-ITEMS**

**No program was found going DECLINE → ACCEPT.** The staging safety property holds on everything I could
build: 31 hand-written probes (26 C + 2 hand-IR + 3 controls), the 10 shipped fixtures the promoter
actually fires on, and a promoter-firing sweep over **all 2039** `ir-pass/test/*.ll`.

**Two of the six items are BLOCKING for the deferred half** (F-α1, F-α2) and must not be carried into it
as "cleared". F-α1 in particular is the concrete answer to `MERGE_FILINGS.md` F-1: I found a second
cross-seam dependency beyond `getParentLoop()`, and it runs in the opposite direction from the one the
gate looked at — **`Bank`, the verdict the staged landing's own retirement trigger turns into the ACCEPT,
is strictly WEAKER than "the promoter actually promoted", and the difference is reachable from plain
`-O1` C.**

---

## F-α1 — **`Bank` ⇏ PROMOTED, and the L8 retirement trigger makes `Bank` the ACCEPT.** (blocking)

`declineTaintEscapes` consults `railBankCarveVerdict` and **never consults the promoter**. Its L8 trigger
(`TaintPropagation.cpp:995-1000`) says, verbatim: *"when that second half lands, the `Bank` arm stops
breaking and becomes a `continue` (the bank's owner emits it)"*. So `Bank` is the accept predicate of
record. But `planBank` (`RailBankPromote.cpp`) adds **nine** structural clauses after its B6 carve call
(`:291`), and **nothing anywhere records that a `Bank` which was not promoted is unsound**.

On an UNPROMOTED bank the per-trip cell is read TWICE and the second read is PARTIALLY AVAILABLE — that
is `SCOPE_L1a.md` §0 H3 verbatim — so the deferred type rewrite makes that second `load` read handle `0`,
and **`h0` is a live rail in this runtime**. §0 H3 exists precisely to say that a type rewrite without the
promotion is wrong. `Bank` does not exclude it.

**Minimal witness — a hand-IR A/B pair differing ONLY in whether the loop has a dedicated preheader block:**

```
probes/r2_nopreheader.ll   carve=[Bank] cells=3   promo=0     <-- Bank AND NOT promoted
probes/r3_withpreheader.ll carve=[Bank] cells=3   promo=1
```
(`r3` is `sed`-derived from `r2`: the entry's 2-way branch goes to a new `%pre` block that branches to
`%head`. Nothing else differs.) The deciding clause is `RailBankPromote.cpp:359`
`!Plan.L->getLoopPreheader()`; the carve asks only `getExitingBlock() && getLoopLatch()`
(`QramLowering.cpp:1523`).

**Reachable from ordinary C, three independent families, all measured `carve=[Bank] promo=0`:**

| probe | shape | why the promoter refuses (and the carve does not) |
|---|---|---|
| `g3_two_banks_onefn.c`, `g7_three_banks.c`, `f9_two_banks.c` | two/three back-to-back bank loops in one function | the earlier loop's latch has two successors ⇒ the later loop has **no dedicated preheader**. `promo=1` in all three; `g6_two_banks_sep.c` (an opaque call between the loops) gives the second loop a preheader and measures `promo=2` — the control |
| `d1_rezero_inloop.c`, `d3_rezero_arm.c` | the whole array re-`memset`-to-zero **inside** the trip | `RailBankPromote.cpp:313` "nothing non-rewritable inside `L`"; the carve's C1 asks only `DT.dominates(Init, SI)` (`QramLowering.cpp:1416`) — see F-α5 |
| `d2_lifetime_inloop.c` | `bool b[3]` declared in the loop body ⇒ `llvm.lifetime.start/end` **inside** `L` | same promoter clause; the carve's user scan `continue`s on a lifetime marker with **no location check at all** (`QramLowering.cpp:1383`) |

For d1/d2/d3 the object's contents are *reset every trip*, so at loop exit only cell `N-1` carries the
cascade and cells `0…N-2` are classical zero — the exact "a cell in a state the rail model cannot name"
that C6 is written to exclude, reaching `Bank` anyway.

⚠ **Attached, because it is the same defect seen from the carve's side:** C6's argument text
(`QramLowering.cpp:1533-1537`) reads *"With C2′'s `{0,+,1}` index, a constant trip count EQUAL to N and
one exit, cells 0…N-1 are each written exactly once."* That is TRUE of the **promoted** shape (one
unconditional store at the latch) and **FALSE of the raw shape**, whose store sits in the `if (a >= 3)`
arm — the owner's own customer program. The sentence is load-bearing for the deferred type rewrite and
it silently assumes the promotion it does not require.

**Owed:** either (a) the deferred half's accept is gated on a PROMOTED-shape proof and `Bank`'s enumerator
comment stops being read as the accept, or (b) the carve acquires the promoter's structural clauses. (a)
is the Rule-14 answer — one owner, asked by calling it. Whichever is chosen, the `Bank` enumerator
(`QramLowering.h`) and the `TaintPropagation.cpp:995-1000` trigger must both say it, in the same change
(L7-with-a-twist).

---

## F-α2 — the promoter clause that **LICENSES MOVING THE STORE** is keyed on the GEP's block, not the LOAD's, and on the `-O1` floor those differ. (blocking)

`RailBankPromote.cpp:313`:

```cpp
for (Instruction *I : NonRewritable)
  if (Plan.L->contains(I->getParent()))
    return false;
```

`NonRewritable` receives the **GEP** for a `Read`-classified constant-offset access
(`:232-233`, via `isConstantOffsetCellRead` at `:153`), never that gep's LOADS. `-O1` LICM hoists a
loop-invariant cell address out of the loop while the load stays inside it. **Measured**, on
`probes/c1_readcell1_inloop.c` (`for (i<3) { if (a>=3) b[i]=cq_theta(b[i],.5); s += b[1]; }`), stage-1 IR:

```llvm
  %2 = getelementptr inbounds i8, ptr %1, i64 1     ; PREHEADER  -> NonRewritable, block NOT in L
  br label %6
6:                                                  ; the loop
  ...
  store i8 %13, ptr %9, align 1
  %14 = load i8, ptr %2, align 1                    ; IN L, and never examined
```

This is the module the clause's own fixture header describes as *"a classical miscompile, which is why it
is easy to miss"* — and the clause does not see it. It is refused **only** by the carve's C6 in-loop-read
test (`QramLowering.cpp:1553-1566`), which compares the read's index SCEV against the store's.

**A/B control, the only difference being the position of the LOAD** (the gep sits in the same block in
both): `c1_readcell1_inloop.c` → `cq rail bank: array has cells no iteration writes`, `promo=0`;
`f1_readcell1_afterloop.c` → `carve=[Bank]`, `promo=2`. The verdict moves with the carve, not with B.

**Why this is not merely academic.** C6 was written for the *deferred type rewrite's* handle-`0` hazard
("after the type rewrite a never-written cell reads as handle 0"), not for the *store-move* hazard. The
first widening anyone will want on this surface — letting the body read an already-written cell,
`if (b[i-1]) …` — relaxes exactly that clause, and the moment it does, the classical store-move
miscompile becomes reachable **with no diagnostic anywhere and no fixture red**: the clause's own fixture
`railbank_promote_reject_inloop_other_read.ll` pins the DIRECT spelling (`%r0 = load i8, ptr %b`), which
B *does* catch, so B's `-O1` spelling has never been tested (and see F-α3: that fixture is now refused by
the carve first anyway).

**Owed:** extend the clause to the memops of a `Read` gep, not just the gep; and a red-green pair in the
hoisted-address spelling. Cross-reference it at `QramLowering.cpp:1553` as a caller of C6 that is NOT
about totality (the L3-mirror discipline: when a predicate acquires a second caller, say which direction
you are using it in).

---

## F-α3 — `MERGE_FILINGS.md` F-3's population is **at least 5, not 3**; measured, only **1 of 13** Track-B reject fixtures still isolates its clause

Measured on the SUBJECT, per fixture: the decline string, the `CQ_CTRL_DBG` carve verdict and the
`CQ_RAILBANK_DBG` promoter count.

| fixture (`railbank_promote_reject_…`) | clause it names | decline string on the SUBJECT | still isolates? |
|---|---|---|---|
| `two_cells` | B2 | `cq rail bank: array has cells no iteration writes` | **no** (F-3 lists it) |
| `store_outside_loop` | B5 | `…array is written from more than one store site` | **no** (F-3 lists it) |
| `inloop_other_read` | non-rewritable-in-`L` | `…array has cells no iteration writes` | **no** (F-3 lists it) |
| `second_exiting_block` | B3 | `…cell index is not an injective per-iteration index` | **no — NOT in F-3** |
| `early_exit` | B3 | `…cell index is not an injective per-iteration index` | **no — NOT in F-3** |
| `already_ssa` | B8 | `cq taint escape: tainted value stored to memory`, **carve=[Bank]**, promo=0 | **yes** — the only one |
| `nested_outer_loop`, `noninjective_index`, `oversized_bank`, `nonzero_init`, `volatile_cell`, `escaping_address` | carve clauses by design | the matching rail-bank string | n/a |
| `classical_store` | — | *(no decline; accepts, as intended)* | n/a |

F-3's remedy is sized for three fixtures and ~22 rebuilds; the real figure is **five** B-clause fixtures
(B2, B5, non-rewritable-in-`L`, B3 ×2) plus the standing fact that **B8 is the only B clause any fixture
still isolates**. Re-spelling must make the *B* clause refuse a module the *real* carve calls `Bank` —
`r2_nopreheader.ll` in this directory is a ready-made template for the B3/preheader half.

---

## F-α4 — OVER-DECLINE: only the FIRST of several back-to-back bank loops is ever promoted

Measured: `g3_two_banks_onefn.c` and `f9_two_banks.c` → `promo=1` of 2; `g7_three_banks.c` → `promo=1` of
3; `g6_two_banks_sep.c` (an opaque call between the loops) → `promo=2` of 2. Cause, read off the
`-O1` IR and confirmed by the `r2`/`r3` hand-IR pair: the earlier loop's latch is the later loop's only
outside predecessor and has two successors, so `Loop::getLoopPreheader()` is null and
`RailBankPromote.cpp:359` refuses. Zero observable cost today (the module declines either way); it
becomes a live over-decline the moment the deferred half lands, and the owner's 2026-09-11 ruling makes
an over-decline a defect to file, not a margin. Note `:369` also dereferences `getLoopPreheader()`, so
the clause cannot simply be dropped.

---

## F-α5 — carve C1's initializer clause does not check the property its own comment claims

`QramLowering.cpp:1409-1420`'s comment: *"An initializer that IS present must additionally DOMINATE the
bank store — **a re-zeroing write reachable inside the loop denotes a different program** … and proving
that is cheaper than arguing about it."* The code asks only `DT.dominates(Init, SI)` (`:1416`), which an
in-loop `memset` placed above the store **satisfies**. Measured: `d1_rezero_inloop.c` and
`d3_rezero_arm.c` → `carve=[Bank]`. The sibling hole is `:1383`, where a `llvm.lifetime.start/end` is
`continue`d with no location check at all — `d2_lifetime_inloop.c` → `carve=[Bank]` for an object whose
lifetime restarts every trip. Both are masked only by the promoter (F-α1's mirror). This is L5 in its
usual shape: the comment states the semantic question, the predicate answers a syntactic one.

---

## F-α6 — a PARTIAL witness for `ROUTING.md` R2 (the D1/`z9t1` byte-identity measurement), recorded so the next increment does not re-take it

R2 says D1's disclosure "states a claim whose witness is future". At the PROMOTION level the witness can
be taken now, and I took it: the promoted module of `c10_uninit.c` (`bool b[3];`) versus
`h1_customer.c` (`bool b[3] = {0};`) differs by **the `llvm.memset` line and the attribute-group
renumbering, and by nothing else** — 142 vs 148 lines, every instruction of the write loop and the
measure loop identical, including `@cq_theta_i1(i1 noundef zeroext false, …)`.
**This does not discharge R2**: `z9t1`'s 164-module argument is about the EMITTED GATE STREAM, and there
is still no accept path. It removes one of the two halves.

---

## What I attacked and found NOTHING in (this is evidence too)

* **The staging safety property.** 0 DECLINE→ACCEPT over every probe below; the `rb.sh` driver flags it
  explicitly and never fired. The 10 shipped fixtures on which the promoter fires all measure `O=1 S=1`.
* **Promoter blast radius.** A sweep over **all 2039** `ir-pass/test/*.ll` (`/tmp/r1a/one.sh`, self-tested
  in both directions first) finds the promoter fires on **exactly 10** files, every one of them this
  increment's own (`railbank_promote_*` ×7, `lowering_railbank_bank_anchor_*` ×3). No pre-existing fixture
  is touched.
* **The QRAM ⟂ rail-bank axis separation**, which the promoter does NOT re-ask (it never calls
  `qramCarveVerdict`): `q1_qram_shadow.c` (straight-line tainted-index shadow store) **accepts on both
  binaries** with `promo=0`; `q2_qram_shadow_loop.c` declines on both with `promo=0`. The two conjuncts
  `!taint.Tainted.count(G)` / `!taint.Tainted.count(RawIndex)` are doing the work, and the loop axis is a
  second, independent separator (QRAM declines in-loop; a bank requires in-loop).
* **`applyBank`'s SSA construction.** Read the emitted module for `h1_customer` (the owner's shape),
  `c13_continue` (a `continue` — builds the extra `%cq.bank1 = phi i8 [ 0, %9 ], [ %cq.bank, %18 ]`
  correctly), `f5_nested_if`, `f2_inner_loop` (an unrelated inner loop inside `L`), `q5_store_in_header`
  (`do…while`), `f6_n8`, `f8_uncond_prep`, `c9_int_cells`, `q3_short_cells`. In every one: the seed load
  folds to the literal (`@cq_theta_i1(i1 false, …)`), the intra-activation re-read becomes the region
  merge φ, and exactly ONE store survives, at the latch, with the original `!dbg`/`!tbaa`/align. No φ
  crossing the back edge was found.
* **The per-clause negatives** all decline with the matching string and `promo=0`: VLA-free variants of
  global / escaping-address / non-zero init / tainted index / fp cell / nested outer loop / alloca in a
  loop / non-injective index / stride-2 / down-counting index / `break` / `Trips < N` / read-before-loop /
  write-after-loop / second writer.
* **Termination of the promoter fixpoint.** B8 holds: after a promotion the write loop carries no in-`L`
  load, so the same bank is refused on the next turn (`h1` promotes twice — once per function — and
  stops; `g6` promotes twice and stops).
* **`Loads` completeness in the carve** (the set C6 quantifies over). By construction every load of the
  bank is either a user of a canonical cell gep or a direct user of the alloca; every other user shape
  (`ptrtoint`, `select`/`phi` of the address, a chained gep, `memcpy`, a call argument) is refused by
  `kMsgBankEscape`/`kMsgBankAlias`/`kMsgBankMixed` before `Loads` is consumed. I could not construct a
  load that escapes the set.

## Instrument discipline — what I attacked in my OWN harness, and what it caught

* **A 0-byte `.ll` ACCEPTS through the passthrough early-out.** `probes/h0_empty.ll` is a standing control;
  the driver prints `cq_intrinsic_calls=…` and flags `!!VACUOUS(no cq_* call)` for any probe with none. It
  fired on `h0_empty` (`exit=0 lines=2` on both binaries) and on nothing else.
* **`-O1` inlines `slice` into `main` and keeps the out-of-line body** (bd `1yeu`). Every promoter count in
  this record is a count over the WHOLE module, and `promo=2` on a one-bank probe is the two copies, not
  two banks. `g3_two_banks_onefn.c` was written with the bank in `main` directly to remove the ambiguity,
  and the `r2`/`r3` hand-IR pair has a single function.
* **My first sweep instrument reported `count=0` — i.e. a PASS — on a corpus that contains ten
  known-firing files.** The `xargs -I{}`/`sh -c` spelling silently produced no rows. I caught it only
  because I had a positive control (`railbank_promote_loop_n3.ll`) to check the instrument against, and I
  rebuilt it as `/tmp/r1a/one.sh` with self-tests in **both** directions (must-fire and must-not-fire)
  before trusting it. The rebuilt sweep emitted 2039 rows, which reconciles with
  `ls ir-pass/test/*.ll | wc -l`. This is CLAUDE.md L10 happening to me inside one session; the row count
  is now printed with every sweep for exactly that reason.
* **`LLVMContext::diagnose` EXITS on the first `DS_Error`** (bd `br4a`), so on a multi-bank module the
  `CQ_CTRL_DBG` carve anchor shows only the FIRST store's verdict. That is why F-α1's decisive witness is
  the single-bank `r2_nopreheader.ll` and not `g3`.
* **Lowered-IR md5s are not comparable across sweeps** (S3) — I compared nothing across sweeps; every
  comparison here is ORACLE vs SUBJECT on one stage-1 file, in one invocation of `rb.sh`.

## What I could NOT do

1. **No build** (PROTOCOL review row), so I could not take the M12-style mutant measurement — delete a
   carve conjunct and show the promoter alone over-accepts. F-α2 is therefore established by the c1/f1
   A/B differential **plus** source reading of `RailBankPromote.cpp:153/232-233/313`, not by a mutant. A
   fix agent should take the mutant.
2. I could not observe **which** `planBank` clause refuses a given module — only that it refused. Every
   attribution above (preheader, non-rewritable-in-`L`) is an A/B differential plus the source, and each
   says so.
3. No `lit`, no `ctest`, no equivalence sweep, no full corpus sweep. I did not re-run the merge gate's
   6311-row sweep; I ran a different, targeted question over 2039 fixtures (where does the promoter fire).
4. **Not attacked, and out of scope for round 1:** `declineDephasingUnmarkedLoopRails` (Track S / D4), the
   Track X `om35` re-derivation, and `free_pairing_check.py` (Track I). `MERGE_FILINGS.md` F-8 records that
   Track I's new rules have no customer in the merged tree; I did not re-measure that.

## Probes

All under `review_r1a/probes/`, driver `probes/rb.sh` (ORACLE + SUBJECT + both env anchors on one
stage-1 file) and `probes/run.sh` (the plain PROTOCOL per-probe pipeline).
`c*.c` the composition battery · `d*.c` the in-loop-initializer family · `f*.c`/`g*.c` the promotion
battery and the multi-bank counts · `q*.c` the QRAM-overlap and cell-width axis · `r2`/`r3` the hand-IR
preheader A/B · `h0_empty.ll`/`h1_customer.c`/`h2_accept.c` the harness controls.
