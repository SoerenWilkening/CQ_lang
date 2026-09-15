# Track E2 — bd `test_C_libtooling-fve8`: retire clause 4 for `undef` at the sink

Session 2026-09-15, implementation track, branch `fve8-undef-measure`, worktree
`/Users/sorenwilkening/Desktop/CQ_E2`, based on `main` `74eabd2c`.

**Owner ruling** (`DECISIONS.md` E2, bd `fve8` note): *"retire clause 4 for `undef` at the sink
entirely. `cq_measure` of an `undef`/`poison` operand measures the type's concrete zero, in **every**
spelling — the direct one included. The asymmetry is closed in the ACCEPT direction."* ⚠ This
**retires part of the owner's own 2026-09-14 ruling** (bd `z9t1` clause 4), so it is a code change
with a full red-green obligation, not a documentation change.

Every number below was measured by this track with the command shown. `../trackE2/GATES.md` is the
hash-keyed record; `probes/README.md` maps each probe to its question and its verdict on both
binaries.

```
ORACLE / BASELINE  0e280fc62a91cec2336769edde8a873563a21ee4869744331a0fcf6811549c6d  cq-opt
                   94602c7896e7a7ee1d0d0d54625a073f6a35fd6c9fe0af6e9c714b2043df507b  libCQPass.so
SUBJECT            57e7420c50ddf8027d9c686672a1db282ed03d8bd94e5d9c366a8d2bfdc15439  cq-opt
                   35fb4c26c1519cb185a5a1b683a93d0be4a95928f7035fc86c4619bd90ccf7ee  libCQPass.so
```

⚠ **The worktree BASELINE built bit-identical to the ORACLE.** Recorded because it is what makes
every RED below trustworthy: the red measurements were taken on a binary provably equal to the
frozen one, so no red is a stale-build artefact (CLAUDE.md §4c's trap, seen from the useful side —
`shasum -a 256 build/ir-pass/cq-opt` before believing any verdict).

---

## 1. The change

**Seven production lines plus two `#include`s, in one file** — measured, not estimated:

```
$ git diff -U0 ir-pass/src/MeasureLowering.cpp | grep -E '^[+-]' | grep -vE '^[+-][+-]' \
      | grep -vE '^[+-]\s*//' | grep -vE '^[+-]\s*$'
+#include "llvm/IR/Constant.h"   // Constant::getNullValue (the fve8 RAUW target)
+#include "llvm/IR/Constants.h"  // UndefValue / PoisonValue (the fve8 conjunct)
+      if (isa<UndefValue>(Handle)) {
+        Measure->replaceAllUsesWith(
+            Constant::getNullValue(Measure->getType()));
+        ToErase.push_back(Measure);
+        continue;
+      }
```

Nothing is deleted; the existing `valueCarriesUndef` decline is unchanged and merely moves **below**
the new clause.

`ir-pass/src/MeasureLowering.cpp`, inside `lowerMeasures`' branch (1) — the CLASSICAL measure
(bd `21mg`) — the single `valueCarriesUndef` decline becomes a two-clause split:

```c++
if (!taint.Tainted.count(Handle)) {
  // (1a) whole-value undef/poison -> ACCEPT as the type's concrete zero
  if (isa<UndefValue>(Handle)) {
    Measure->replaceAllUsesWith(Constant::getNullValue(Measure->getType()));
    ToErase.push_back(Measure);
    continue;
  }
  // (1b) the residual: a DEFINED constant that merely CARRIES an undef
  if (valueCarriesUndef(Handle)) {
    diagnoseMeasure(Measure, kMsgUndefOperand, /*WithDbg=*/true);
    continue;
  }
  ...
```

Three properties of that shape are load-bearing and each is argued at the mechanism in source:

* **`isa<UndefValue>` is bd `z9t1`'s conjunct, verbatim in shape** (`RotationLowering.cpp`: *"only a
  WHOLE-VALUE undef is rewritable (the ConstantExpr residual)"*), for the identical reason — the
  predicate gates a DECLINE everywhere else and a REWRITE here. `PoisonValue` derives from
  `UndefValue`, so one `isa` covers `poison` with no second predicate (measured: `e2j`).
* **The ORDER of (1a) before (1b) is not stylistic.** `valueCarriesUndef` is TRUE of a whole-value
  `undef`, so testing it first would re-swallow exactly the shape the ruling retired.
* **The RAUW target is `Constant::getNullValue(Measure->getType())`, never `Handle`** — §3.3, where
  it is measured rather than asserted.

Comment-only, in the same change (CLAUDE.md **L7-with-a-twist**: *a record correction that is not
applied to the source is not a correction* — a defect found **three times on one sentence** in
`RotationLowering.cpp` before it landed):

* `MeasureLowering.h`'s *"An `undef`/`poison` CLASSICAL operand is a loud decline of its own"* is
  rewritten to say what is retired and what survives, and its `lowerMeasures` contract line now says
  the classical RAUW target is the operand **or**, for a whole-value `undef`, the type's zero.
* `MeasureLowering.cpp`'s file header records that branch (1) now has an internal split **and that
  the split is NOT on taint** — see §5, the cross-track statement.
* `kMsgUndefOperand`'s four-ground rationale block is re-grounded on the residual. Two of its four
  grounds were arguments about the whole-value case and are now the grounds the retirement
  **consumed**; the block says so in those words instead of being quietly left standing.

**Fixtures**: one INVERTED, two NEW. **No** `tools/`, `runtime/`, `include/CQ.h`, YAML or e2e
change: **no ABI move, no new symbol, no new trace line, no golden.**

---

## 2. Obligation (b) — the decline string's REMAINING CUSTOMERS, enumerated by measurement

The brief and the bead both assumed this string would lose its last customer. **It does not**, and
Track M measured that before this track started. This track re-measured it (Rule 11) and found the
scoping's *name* for the residual half-wrong.

### 2.1 What survives, and the membership rule

`valueCarriesUndef` is `carriesUndefImpl(C, Seen, /*SkipGlobals=*/false)` (`LiteralIntegrity.cpp`),
so it walks **into a referenced global's initializer**. A residual member is therefore a `Constant`
that is **not** `isa<UndefValue>` and still reaches an `undef` through its operand chain.

**The membership rule, measured:** *a residual member needs a `GlobalValue` in the operand's
constant chain* — because the LLVM-19 **parser constant-folds everything else on the way in**, and a
`GlobalValue`'s address is the one thing the folder cannot evaluate.

| probe | operand | parsed as | SUBJECT |
|---|---|---|---|
| `e2k` | `ptrtoint (ptr @g to i32)`, `@g = { i32 1, i32 undef }` | unchanged | **D** (member) |
| `e2m` | `ptrtoint (ptr getelementptr(... @g ..., 1) to i32)` | unchanged | **D** (member) |
| `e2o` | `ptrtoint (ptr @h to i64)`, `undef` nested two levels down | unchanged | **D** (member) |
| `e2p` | `ptrtoint (ptr @u to i32)`, `@u = global i32 undef` | unchanged | **D** (member) |
| `e2i` | `ptrtoint (ptr undef to i32)` | **`i32 undef`** | **A** (NOT a member) |
| `e2n` | `bitcast (i32 undef to float)` | **`float undef`** | **A** (NOT a member) |
| `e2l` | `ptrtoint (ptr @g to i32)`, `@g = { i32 1, i32 2 }` | unchanged | **A** (control) |

```
$ /usr/local/opt/llvm@19/bin/opt -passes=verify -S probes/src/e2i_constexpr_undef_operand.ll | grep cq_measure
  %m = call i32 @cq_measure_si32(i32 undef)
$ /usr/local/opt/llvm@19/bin/opt -passes=verify -S probes/src/e2k_global_initializer_undef.ll | grep cq_measure
  %m = call i32 @cq_measure_si32(i32 ptrtoint (ptr @g to i32))
```

### 2.2 ⚠ THE CORRECTION THIS TRACK OWES TRACK M, AND WHAT IT WOULD HAVE COST

`SCOPE_M.md` §1.3(b) and bd `fve8`'s note name the residual the **"`ConstantExpr` /
global-initializer residual"** and call `e2i_constexpr_undef_operand.ll` *"the same species"* as
`e2k`. The `ConstantExpr` half of that name is **wrong on LLVM 19**: a bare `ConstantExpr` over a
whole-value `undef` is folded to a whole-value `undef` before the pass ever runs, so it is a member
of the **retired** clause. Track M's conclusion — *keep the string, keep the `isa<UndefValue>`
conjunct* — is **unaffected and correct**; only its account of WHICH shapes remain was off.

The cost of taking the scoping verbatim was concrete: the scoping's own fixture table proposes
`lowering_reject_measure_undef_constexpr.ll` carrying `e2i` **as a decline**. On this binary that
fixture would have gone **green because its subject no longer exists** — CLAUDE.md's
fixture-hygiene defect (c), shipped. It is instead written as `@f_constexpr_undef`, an **ACCEPT**,
with its own retirement trigger (*"if a later LLVM stops folding it, this function moves to a
DECLINE"*).

### 2.3 The fixture the string now owes, and its mutation validation

`ir-pass/test/lowering_reject_measure_undef_global_init.ll` pins `e2k`. One function, deliberately:
`LLVMContext::diagnose` EXITS on the first `DS_Error` (bd `br4a`), so a second function would pin
nothing.

**Validated by MUTATION, not by re-reading the prefixes:**

| | module | `opt` | fixture's own RUN pipeline |
|---|---|---|---|
| base | as committed | exit **1**, the undef string | **GREEN** |
| M1 | initializer → `{ i32 1, i32 2 }` | exit **0**, `ret i32 ptrtoint (ptr @g to i32)` | **RED** |
| M2 | operand → whole-value `i32 undef` | exit **0**, `ret i32 0` | **RED** |

Both mutants flip it, in the two independent directions that define the subject (*is the global's
field undef?* and *is the operand whole-value?*). The subject exists and it is exactly the residual.

### 2.4 ⚠ The residual decline may itself be an OVER-DECLINE — recorded, not fixed

The operand is a **defined value**; measuring it classically is well-defined; `slotCarriesUndef`
(the `SkipGlobals=true` twin, which exists for exactly this distinction) would accept it. Under the
owner's 2026-09-11 ruling an over-decline is a **defect to remove**, not a safety margin.

It was **not** removed here. ⚠ **RE-GROUNDED BY THE FIX ROUND, 2026-09-15** (review item 3, which
agreed with not taking the swap and disagreed with the reason): the reason first written here was
**hygienic** — *the swap would leave `kMsgUndefOperand` with no customer at all* — and **hygiene is
not a ground for keeping an over-decline** under the owner's 2026-09-11 ruling. The correct response
to "no customer" is to **delete the string**, which is exactly what retirement trigger 4 already
requires; that sentence is binding as a **consequence** of the swap and was never a **reason**
against it.

**The ground that survives is SEMANTIC, and it is the L3-mirror.** `slotCarriesUndef`'s
`SkipGlobals=true` exists for **emitted gate slots**, and its argument — *"a `GlobalValue`'s
operands are its INITIALIZER, while the value under test is the global's ADDRESS, which is defined
no matter what it is initialised to"* (`LiteralIntegrity.cpp`) — is an argument about **literal
integrity at the `-O0` stage-3 link**: the same token must denote the same value at every slot the
lowering copies it to. A **measurement** asks a different question — *what value does this read
report?* — and nobody has ruled whether an initialiser's `undef` field is reachable from it.
Swapping the predicate would be **adding a caller to a shared predicate without asking whether the
callee's argument reaches the new caller** — the defect that cost a P1 filing on 2026-09-14
(`WireWalk.h` / `readerStalesItself`), whose instruction *widen the vocabulary or fence the caller
in the same change* applies verbatim. **So the swap needs an OWNER RULING**, not developer
discretion; the question is *"does a measurement read a global's initialiser?"*, which this project
has never answered. It was also out of scope for `fve8`, whose ruling scopes the retirement to the
`undef`/`poison` **operand**.

**Practical weight: near zero.** A residual member needs a `GlobalValue` in the operand's constant
chain (§2.1), i.e. roughly `cq_measure((int)(intptr_t)&g)` with `g` partly uninitialised. No
customer writes it — a reason the question is not urgent, not a reason the answer is obvious.

**Filed for the orchestrator as an over-decline candidate**, with the retirement trigger written
into both the fixture header and the source: *if that swap is ever made, this fixture becomes an
ACCEPT and `kMsgUndefOperand` must be DELETED in the same change.*

---

## 3. Obligation (c) — THE REFINEMENT MEASUREMENT

> **The claim.** `SUBJECT(module with a whole-value `undef`/`poison` measure operand)` is
> **byte-identical** to `ORACLE(the same module with that one token written as the type's zero)`,
> over a stated population, **measured, never asserted**. Any divergence is a STOP-and-report that
> returns the ruling to the owner.

### 3.1 The population, the twin, the command

```
POPULATION  every module reaching the pass with a `@cq_measure_<sfx>` call whose operand is
            `isa<UndefValue>` AFTER LLVM-19 PARSING. ⚠ "after parsing" is load-bearing, not
            pedantry: `ptrtoint (ptr undef to i32)` is a member and its SOURCE TEXT does not
            contain a whole-value `undef` token, so a grep over source is a LOWER BOUND, never a
            census (Rule 11). `probes/refinement_check.py` therefore normalises every input
            through `opt -passes=verify -S` (which transforms nothing — the folding happens in
            `LLParser`) before deciding membership.
            Censused three ways: the shipped fixtures, the E2 probe set, and the whole
            ORACLE-vs-SUBJECT corpus sweep (§4).
TWIN        the same normalised module with each such operand token rewritten to the type's zero
            (i1 -> false, iN -> 0, half/float/double -> the fp zero, x86_fp80 -> 0xK00...).
GATE        SUBJECT(original).lowered-IR  ==bytes==  ORACLE(twin).lowered-IR,
            with only `; ModuleID` / `source_filename` stripped; both binaries read files written
            into the SAME temp dir under the SAME basename, because lowered-IR hashes are NOT
            comparable across sweeps (PROTOCOL S3).
COMMAND     python3 probes/refinement_check.py <modules...>
```

### 3.2 The result — **0 divergences, 0 `A→D`**

```
$ python3 probes/refinement_check.py \
      ir-pass/test/lowering_{accept_measure_undef_zero,reject_measure_undef_operand,reject_measure_undef_global_init}.ll \
      probes/src/e2{i,j,k,m,n,o,p}*.ll \
      probes/out/subject/e2{a,c,e,g,q,s,u,w}*.s1.ll
refinement: population 12 module(s) (6 outside the population), 12 BYTE-IDENTICAL, 0 DIVERGENCE(S), 0 SUBJ-DECLINE
```

**12 of 12 byte-identical. ZERO divergences. ZERO `A→D`.** The full per-module output is
`probes/refinement_57e7420c.txt`.

The 6 reported outside the population are exactly the four residual members, the `e2l`-style control,
and `e2w` (which declines on BOTH binaries for an unrelated reason) — i.e. the instrument's own
membership rule agrees with §2.1's, computed independently.

**The population covers every width and every downstream destination the outcome has**: i1, i32,
i64, half, double and x86_fp80 (so `0xH0000` and `0xK00…0`, the two widths where "the type's zero"
is not the digit `0` — `Constant::getNullValue` is type-generic and consults no width table, which
is the place a width family would rot); the outcome **returned**, **added to a quantum measurement's
result**, used as an **allocator seed** (`e2q`), used as a rotation **ANGLE** (`e2s` — it becomes
`cqrt_ry_i32(h0, 0x0p+0)`, NOT a quantum-derived-angle decline and NOT an `undef` angle), and used
as a **classical branch condition guarding quantum code** (`e2u`).

⚠ **`e2w` is in the table because it caught the instrument lying.** A classical `undef` measure
inside a tainted-condition arm declines on BOTH binaries (`value-arm swap-route under quantum
control`, unrelated to E2). The first spelling of `refinement_check.py` reported it as `A->D !!` — a
finding *against this change* — purely because the SUBJECT exited non-zero, never asking whether the
written-zero twin declines too. It does, identically. The classifier now decides the label **by
asking the twin**. An instrument that manufactures a regression report out of a pre-existing,
unrelated decline is the same failure class as one that reports a pass (CLAUDE.md L10).

**The C-level twin, which is a different and weaker comparison, also holds where it can.**
`e2g` (`int u; … cq_measure(u) + cq_measure(q)`) on the SUBJECT against `e2h` (`int u = 0; …`) on the
ORACLE: **traces byte-identical, equal sha-256 `ea3c225a0aadc87e…`**, and the lowered instruction
stream identical. Their lowered IR is **not** byte-equal, and the reason is stated rather than
waved: they are two different source files, so `!dbg`/`DIFile`/`DILocation` necessarily differ, and
`int u = 0;` emits a `#dbg_value(i32 0, …)` the uninitialised spelling has no statement for. **That
is exactly why the IR-level one-token twin is the instrument of record** — it holds debug info
fixed and changes only the operand.

### 3.3 ⚠ THE RAUW TARGET — measured by COUNTERFACTUAL BUILD, not inherited

Track M's finding (2) says the byte-identity claim is **FALSE** with the operand-RAUW spelling. This
track did not take that on trust. One token was changed —
`Constant::getNullValue(Measure->getType())` → `Handle` — the worktree rebuilt, the same refinement
check re-run, then the token reverted and the binary rebuilt back to `57e7420c`:

```
COUNTERFACTUAL (RAUW to the OPERAND), cq-opt 94225756f5da1852…:
  refinement: population 12 module(s) (6 outside the population), 0 BYTE-IDENTICAL, 12 DIVERGENCE(S), 0 SUBJ-DECLINE
SUBJECT        (RAUW to the TYPE'S ZERO), cq-opt 57e7420c50ddf802…:
  refinement: population 12 module(s) (6 outside the population), 12 BYTE-IDENTICAL, 0 DIVERGENCE(S), 0 SUBJ-DECLINE
```

**Track M's finding (2) is reproduced, and it is STRONGER than it was stated:** the byte-identity
claim is false on **every single member** of the population, not on some of them. **12 of 12
diverge.** Full output: `probes/refinement_counterfactual_94225756.txt`.

⚠ **And two of those divergences are not cosmetic — they are a worse PROGRAM, which is the argument
for the zero spelling rather than a preference for it.** Under RAUW-to-operand:

```
e2u:  -  %1 = icmp eq i32 0, 0          (zero twin)
      +  %1 = icmp eq i32 undef, 0      (operand spelling)   → br i1 %1, …
e2s:  -  %1 = sitofp i32 0 to double    (zero twin)
      +  %1 = sitofp i32 undef to double (operand spelling)  → the ANGLE of an emitted cqrt_ry
```

The first is a **branch on `undef`**; the second puts an `undef` into an **emitted gate's angle
slot**, which is the literal-integrity family bd `xy9n`'s GUARD 1 exists for and which bd `z9t1`'s
own F-U1-1 is still open about. The zero spelling produces neither.

The counterfactual binary was built with ONE token changed, measured, and **reverted**; the restored
source rebuilt **BIT-IDENTICAL** to the gated SUBJECT (`57e7420c…` / `35fb4c26…`), so every gate
line in `GATES.md` stands rather than needing to be retaken.

The divergence is the one the fixture's `NOUNDEF` prefix pins: `ret i1 undef` where the twin has
`ret i1 false`, and `add nsw i32 %m, undef` where the twin has `add nsw i32 %m, 0`. **With the
operand spelling the ruling's own justification does not hold.** Confirmed as Track M measured it.

---

## 4. The corpus sweep — what MOVED, over the WHOLE corpus

`probes/corpus_E2.sh` (derived from `trackS/probes/corpus_S2.sh`, which already carries PROTOCOL
S3's three corrections) over `ir-pass/test/*.ll` **plus every session dir's `track*/probes` and
`review_*_probes`** — the full PROTOCOL corpus, deliberately not narrowed (ROUTING **R3**: the
argument that a residue is structurally immobile has already LOST once, and three movers were found
outside a narrowed corpus at the 2026-09-14c gate).

```
$ probes/corpus_E2.sh probes/corpus_57e7420c50ddf802.txt     # 20:39 wall at load ~270
$ probes/analyze_corpus.sh probes/corpus_57e7420c50ddf802.txt
rows                 : 4986        (fixtures 2041 · probe modules 2945 · VACUOUS 259 · CLANGERR 2)
  1. MOVERS                                                  : 24
  2. D->A : 24        A->D : 0
  3. A->A with a MOVED STREAM (lowered-IR md5 within the row) : 0
  4. D->D with a MOVED STRING (full-stderr sha)               : 0
  5. A->A with MOVED STDERR (a warning appearing/vanishing)   : 0
```

**24 movers, every one `D→A`. Zero regressions of any kind**: no accept lost, no accepted stream
moved a byte, no decline changed its string, no accept gained or lost a warning.

**Attribution — closed by RE-MEASUREMENT, not by reading the sweep's field.** The sweep's stderr
field is cut at 160 characters, and at that width `cq_measure_<sfx> operand is an undef/poison
literal…` truncates to a prefix `cq_measure_<sfx> operand not recognized…` **also has**, so the
field alone cannot attribute a long-path row. All 24 movers were therefore re-run individually on
the ORACLE with full stderr:

```
movers: 24
  24 cq_measure_<sfx> operand is an undef/poison literal; a classical measurement needs a defined value
```

**All 24 are E2's, on E2's own string, and none is anything else.** On the SUBJECT all 24 have a
stderr sha-256 of `e3b0c442…` — the hash of the **empty file**: **0 bytes, no warning**, which is
the owner's ruled requirement for this family.

Who they are, counted from the list and not by eye — **2 + 12 + 10 = 24**:

* **2** are E2's own fixtures (`lowering_accept_measure_undef_zero.ll`, the inverted
  `lowering_reject_measure_undef_operand.ll`);
* **12** are `undef`-measure probes from the bd `21mg` and bd `z9t1` sessions —
  `trackU/{probes,fix_r1_probes}/u1.c` and `u4.c` (4), `trackU/review_r1_probes/r05_seed_and_measure.c`,
  `trackU/review_r2_probes/a2_measure_undef.c` and `a2_measure_undef.zero.c`,
  `trackU/review_r3_probes/pN_clause4_direct_u.ll`, `trackC/probes/c6_undef_bool.c`,
  `trackC/probes/i0_poison_operand.ll`, `diag_2026-09-14_probes/u1.c` and `u4.c` — i.e. **the very
  probes those sessions wrote to demonstrate the asymmetry this ruling closes**;
* **10** are E2's own probes (`e2a`, `e2c`, `e2e`, `e2g`, `e2i`, `e2j`, `e2n`, `e2q`, `e2s`, `e2u`).

There is no mover this track cannot name.

⚠ **Two instrument facts about this sweep, recorded because both could have been quietly tidied
away** (`probes/corpus_57e7420c50ddf802.NOTE.md` carries them in full):

1. **The file has NO trailing `DONE` line, and the sweep is nevertheless COMPLETE.** The parent shell
   died on a transient syntax error **because this agent edited the script while it was running** —
   `bash` reads a script incrementally by byte offset, so the interpreter resumed mid-line.
   Completeness is proven by **exact set equality** against the candidate list (4986 expected, 4986
   swept, `comm` empty in both directions), not by the trailer. The children were unaffected
   (`export -f` copies the function; they never re-read the file). ⚠ **Never edit a shell script
   while it is running.**
2. **The FIRST run of this sweep was DISCARDED after 489 rows and re-run from scratch**, because a
   change this agent made to the shared recipe gave each binary its own input filename — and the
   lowered `; ModuleID` is derived from the input path, so **267 of 267 `A:A` rows reported two
   different md5s**. A harness that reports a move on every row measures itself, not the compiler.
   Both binaries now read the same file, and a boundary control (two unchanged fixtures) was run
   before the restart.

---

## 5. ⚠ CROSS-TRACK: what this change does and does NOT do to branch (1)'s reachability

E2 is in **GROUP 1** with the rail-bank headline (`PROTOCOL.md` S1) because both touch
`MeasureLowering.cpp`, and E2's edit is **inside `lowerMeasures`' branch (1)** — the classical split
the rail-bank work exists to keep bank loads *out* of, since an untainted bank load taking branch (1)
emits no gate, no symbol and no trace line, which the golden byte-diff is structurally blind to.

**The statement, precisely:**

* **Branch (1)'s ENTRY CONDITION IS UNTOUCHED.** It is still exactly
  `if (!taint.Tainted.count(Handle))`, the same single test on the same set, asked at the same point.
  E2 adds no term to it, changes no taint rule, and touches `TaintPropagation` not at all. **Exactly
  the same set of `cq_measure` calls reaches branch (1) as before.**
* **What moves is the DISPOSITION of one subset already inside it** — operands that are
  `isa<UndefValue>` — from `diagnose + leave the call in place` to `RAUW to the type's zero + erase`.
  No value that previously took branch (2) takes branch (1), and no value that previously took
  branch (1) now takes branch (2).
* **E2 widens branch (1) for NOTHING but a whole-value `undef`/`poison` operand.** In particular it
  says nothing about, and does nothing to, a load from a rail bank: such a load is not
  `isa<UndefValue>`, so it reaches (1a) never, (1b) only if it is a `Constant` carrying an `undef`
  (it is not a `Constant` at all), and otherwise the pre-existing paths unchanged.
* **ONE second-order effect, and it is not about `undef`.** `LLVMContext::diagnose` EXITS on the
  first `DS_Error` (bd `br4a`), so this decline used to **preempt the whole module**. A module with
  one uninitialised classical measure beside other content was refused entire and now proceeds — to
  an accept, or to whatever LATER decline it always had. A corpus row that moves `D→D` on a
  *different* string is therefore an **expected** E2 mover, not an anomaly. §4 measured it: **zero
  of 4986 modules did.**

  ⚠ **Spelled out, because it is the part a reviewer should attack.** `lowerMeasures` sits at
  `CQLoweringPass.cpp:776`, and the stages after it are `lowerBreakReversePlay` →
  `lowerLateReassignments` → `uncompute` → **`declineUnpairedUndefLiterals` (bd `xy9n`, GUARD 1)** →
  `declineSurvivingIntrinsicCalls`. On a previously-preempted module **every one of those now runs
  that did not run before.** GUARD 1 is the interesting one: it is a **counting** gate over
  `undef`/`poison` literals in **emitted** gate slots (`isEmittedRuntimeCallee` = `cqrt_*` /
  `cq_template_*` / `__cq_q_*`).
  * E2 cannot lower its count: a `@cq_measure_<sfx>` call is **not** an emitted runtime callee, so
    its operand was never counted, and the RAUW introduces a concrete zero rather than an `undef`.
    (That is the **opposite direction** from bd `z9t1`'s F-U1-1, where the rewrite deleted one of
    two slots GUARD 1 was counting and the guard went silent. F-U1-1 has no analogue here, and the
    reason is structural rather than lucky: `z9t1` rewrites an operand of a call that **becomes**
    `cqrt_alloc_<W>`; E2 rewrites a call that becomes **nothing at all**.)
  * E2 **can** raise it, indirectly: a module that used to die here now emits gates, and if two of
    their slots carry one `undef` literal GUARD 1 fires — a `D→D` move onto a **different** string.
    That is a real, expected shape, and it is why the sweep compares **full-stderr sha-256** rather
    than a regex tag (PROTOCOL S3). **Measured over 4986 modules: zero such rows** (§4, line 4 of the
    analysis). That is a measurement of today's corpus, not a proof — the shape is constructible and
    a future module can exhibit it; it is simply not a REGRESSION when it does, because the module
    declined before and declines after.

**Attribution string for the group gate** (PROTOCOL S1, movers attributed per track BY STRING):
E2 owns every mover whose **ORACLE** stderr is
`cq_measure_<sfx> operand is an undef/poison literal; a classical measurement needs a defined value`.
E2 **adds** no string and **deletes** no string.

---

## 6. ⚠ DISCLOSURE — what this rule silently absorbs

> ⚠ **CORRECTED AND EXTENDED BY THE FIX ROUND, 2026-09-15** (`$SES/e2fix/FIX.md`, branch
> `fve8-fix`), after the independent Rule-13 round returned **FINDING** (`review_r13_e2/REVIEW.md`,
> 1 × P1 + 2 × P2). Three things below were wrong or missing and are fixed **here and at the
> mechanism in the same change** (CLAUDE.md L7-with-a-twist):
>
> * **A SECOND RIVAL EXISTS AND IT IS QUANTUM** (`F-E2-1`, P1; owner ruling `DECISIONS.md` **E9**:
>   ACCEPT, AND DISCLOSE THE QUANTUM RIVAL). It is stated below as **RIVAL 2**.
> * *"byte-identical to what a written `= 0` produces"* was **FALSE** for a multi-use operand
>   (`F-E2-2`, P2). What was measured is the **one-token IR twin**; the sentence now says so.
> * The **retirement-trigger set presented itself as exhaustive and was not** (`F-E2-3`, P2). Trigger
>   2 is split into the half that transfers and the half that does not, and the fact that actually
>   carries the argument — `lowerMeasures` runs **after every `Value*`-identity fence** — is added as
>   trigger 5.
>
> The **fullest copy is now the comment at the mechanism** in `ir-pass/src/MeasureLowering.cpp`
> (clause (1a)); this section and `$SES/e2fix/FIX.md` §1 carry the same text.

*(The same text stands at the mechanism in `MeasureLowering.cpp`. This is the normative copy. It is
written in the form CLAUDE.md §4c insists on, because it is the same class of silent widening as
bd `z9t1`'s own disclosure and the F2 α/β narrowing: a loud refusal becomes a silent compile, no
predicate can separate the readings after `-O1`, and the mitigation is **disclosure, not a fence**.)*

**RIVAL 1 (CLASSICAL) — THE RIVAL READING, AS A PROGRAM AND NOT AS AN IR SHAPE:**

```c
int u;  return cq_measure(u);
```

The author read an **uninitialised object**. On a real machine that object holds whatever the stack
slot held — not zero — so the rival reading is *"this measurement reports garbage, and the program
has no defined outcome."* The compiler now reports **0**, in every spelling, **silently**.

**WHY RIVAL 1 HAS NO LOWERING TO BE ROBBED OF — two halves, because either alone would be an
assertion.**

1. **On the ORACLE the module is a LOUD DECLINE** — all **24** corpus movers of §4, every one of
   them, on E2's own string and on no other. There was no circuit for the rival reading, so nothing
   is displaced.
2. **The accept it now receives is a REFINEMENT, not a choice between two circuits.** LangRef lets
   an `undef` stand for **any** value of its type, so `0` at the read is a value the source
   **already licensed**.

   ⚠ **AND THE CORROBORATION IS STATED AS WHAT WAS MEASURED** (`F-E2-2`, corrected 2026-09-15): the
   emitted stream is **byte-identical to the same module with that one operand token written as the
   type's zero** — **12 of 12** by this track (§3), extended to **32 of 32** by the review
   (`REVIEW.md` §3 item 11), 0 divergences, 0 `A→D`, against **0 of 12** for the only rival
   implementation of the same ruling (§3.3). It is **NOT** *"byte-identical to what a written `= 0`
   produces"*: that is false for an operand with more than one use, because the clause rewrites the
   **measurement's result** and never the operand's other reads — `int u; int m = cq_measure(u);
   return m + u;` keeps `undef` at the second read where the written-`= 0` source has `0` (this
   track's own probe `e2e_undef_used_twice.c`: `ret i32 undef` vs `ret i32 0`, and §8 states that
   limitation correctly, which is how the record came to contradict itself). **Soundness is
   unaffected** — the ground is LangRef, each read of an `undef` may independently be any value of
   its type — so what was overstated is the *corroboration*, by exactly the multi-use case.

   And the measurement is **classical**: branch (1) emits no gate, no rail and no trace line, so the
   **quantum** stream is untouched — the only thing that moves is a classical value LangRef already
   permitted to be anything.

**WHY DISCLOSURE AND NOT A PREDICATE, FOR RIVAL 1.** After `-O1` there is nothing left to
discriminate: *"the author meant to read garbage"* and *"the author forgot an initialiser"* are
**the same module**. A fence that refused the first would refuse the second, which is the program
the ruling exists to compile. And a warning was **deliberately not added**, for the reason the owner
has now given twice on this family — *"both codes are supposed to compie!! also no warnings."*
Measured: the accept writes **0 bytes to stderr**, and the `ACC` prefix of every accept fixture pins
that it stays that way.

---

**RIVAL 2 (QUANTUM) — AS A PROGRAM AND NOT AS AN IR SHAPE** *(added by the fix round; owner ruling
`DECISIONS.md` **E9**, on `F-E2-1`)*:

```c
int u;  int q = cq_theta(0, 0.3);  return cq_measure(q + u);
```

The author wrote a **measurement of a quantum register**. `clang -O1` folds `add nsw i32 %q, undef`
→ `undef`, and **that fold deletes the data-flow edge to the theta**, so the operand clause (1a)
sees has no quantum lineage anywhere in the module: `taint.Tainted` is correct and irrelevant,
branch (1) is entered legitimately, and (1a) reports the type's zero.

**Measured** on the two frozen binaries (`REVIEW.md` §1): ORACLE **exit 1**, the loud decline;
SUBJECT **exit 0, 0 bytes of stderr, a 2-line trace** (`cqrt_alloc_i32` + `cqrt_ry_i32`) and **no
`cqrt_measure` in the emitted module at all** — not even a declaration — while the C-level
written-zero twin (`int u = 0;`) emits **3 lines with the measurement** (`684d2394674bd01b` vs
`ea3c225a0aadc87e`). **A user-written measurement disappears and nothing is printed.** The prepared
rail is left allocated. Rule 5's hard invariant — never *insert* a measurement — is intact; its
**mirror is not**, and CQ does not diagnose that.

**WHY RIVAL 2 HAS NO LOWERING TO BE ROBBED OF — and the second half is PRE-EXISTENCE, not
refinement, because the refinement argument above does not reach it.**

1. **On the ORACLE the module is a LOUD DECLINE**, so no circuit for the rival reading is displaced.
2. **The class ALREADY SHIPS AT HEAD**, on spellings this clause never touches: `cq_measure(q * u)`
   and `cq_measure(q & u)` fold to a **concrete `0`** at stage 1 — not to `undef` — so they enter
   branch (1) with a defined operand and **accept on the ORACLE**, emitting the identical 2-line
   stream (equal trace sha `684d2394674bd01b`). ⇒ **this clause emits no stream HEAD could not
   already emit**; what it adds is the `undef`-folding spellings and the **silence**. A decline here
   would be a **new** refusal that leaves `q * u` and `q & u` untouched — it would not close the
   class, only the half this clause can see.

**WHY DISCLOSURE AND NOT A PREDICATE, FOR RIVAL 2.** The discriminator would have to be *"this
operand once carried taint"*, and `-O1` has already erased the edge that fact lived on — which is
precisely why branch (1) takes it (CLAUDE.md **L5**: a syntactic answer to a semantic question
loses). The only decidable alternative is a Rule-5-**mirror postcondition** — *"the module lowered a
theta whose handle is never measured"* — and it fires on every legitimately unmeasured register,
which is most of the tree. **No warning here either** (`DECISIONS.md` E9 restates it).

⚠ **THE INSTRUMENT AGREES WITH THIS ONE — read it before citing the refinement number.**
`probes/refinement_check.py`, the gate the rival-1 argument rests on, reports the rival-2 module
**BYTE-IDENTICAL**, because its one-token twin rewrites the measure operand of **the module the pass
sees** and therefore **inherits the very fold that erased the taint**. The only comparison that can
see rival 2 is the **C-level** twin (the `undef` source on the subject against the `= 0` source on
the oracle), a different and weaker instrument this track ran exactly once, on a program where the
two coincide. CLAUDE.md **L10** on a checker this repo ships — *an instrument's failure mode is to
report a pass*. **Do not read "0 divergences" as covering rival 2.**

**Pinned by** `ir-pass/test/lowering_measure_undef_operand_after_taint_fold.ll` (the accept, whose
whole-file `NOMEASURE` prefix pins that the user's measurement is absent) and its one-token control
`ir-pass/test/lowering_measure_taint_fold_control.ll` (accepts on **both** binaries and emits the
measurement).

**ONE MORE THING IS ABSORBED, ABOUT NEITHER RIVAL AND NOT ABOUT `undef` AT ALL.** The preemption effect of §5's
last bullet: a module that previously died at this decline now runs the rest of the pipeline. `e2g`
is the witness — on the ORACLE it emitted nothing at all; on the SUBJECT it emits a 3-line trace
whose every gate belongs to the `cq_theta` the ORACLE never reached.

### ⚠ RETIREMENT TRIGGERS — what would make the paragraph above WRONG, not merely out of date

1. **The RAUW target stops being the type's zero** (a switch to `Handle`, or a "simplification" that
   drops the explicit `Measure->getType()`). The refinement claim is a claim about THAT value;
   §3.3 measured it false for any other. Tripwire: the `NOUNDEF` prefix of
   `lowering_accept_measure_undef_zero.ll`.
2. **The clause starts rewriting anything that is not `isa<UndefValue>`.** That is the **one** fact
   this clause shares with bd `z9t1`'s trigger (ii) in `RotationLowering.cpp` — same predicate, same
   direction (it gates a DECLINE everywhere else and a REWRITE here), same consequence if widened —
   and widening it makes this an **OVER-ACCEPT**.

   ⚠ **CORRECTED 2026-09-15 (`F-E2-3`, P2).** The other half of `z9t1`'s pair — *"`undef` stops
   being uniqued per type"* — **does NOT transfer**, and this trigger claimed a **"SECOND customer"
   of the PAIR** until the fix round. Uniquing is load-bearing for `z9t1` because F1's second
   sub-clause is a literal `Value*` **identity** test (`ArmClassify.cpp`,
   `MergePhi->getIncomingValue(PredIdx) != RotBase`), so manufacturing a uniqued zero makes two
   operands *the same pointer*; **E2 performs no identity test anywhere** — it asks a type question
   and RAUWs the measurement's **result**. E2 is a **HALF customer**. This is CLAUDE.md's **mirror
   of L3**: when you add a caller to a shared argument, read the callee's trigger and **state which
   direction you are using it in**.
3. **7.6 decides that the output tape carries every user-written measurement.** Branch (1) emits no
   trace line at all and this clause moves one more shape into it. It is bd `21mg`'s open Q-1 and it
   must be answered together with that one, not separately. ⚠ Since 2026-09-15 it is also **the**
   trigger that would close **RIVAL 2**: rule that every user-written `cq_measure` reaches the tape
   and rival 2 stops compiling — together with the `q * u` / `q & u` spellings HEAD already ships,
   which is the only way to close the *class* rather than the half this clause can see.
4. **`valueCarriesUndef` stops walking global initialisers** (`SkipGlobals` flips, or
   `slotCarriesUndef` replaces it at (1b)). Then the residual has no member, `kMsgUndefOperand` has
   no customer, and the string must be **DELETED in that same change** — not left standing with a
   fixture that pins nothing. ⚠ That swap is an **owner** question (§2.4, re-grounded).
5. ⚠ **NEW, 2026-09-15 (`F-E2-3`) — and it is the fact that actually carried the argument the
   borrowed uniquing half was standing in for: `lowerMeasures` runs AFTER every `Value*`-identity
   fence in the pass.** It is called in **both** entry points after `repropagateControlMerges`,
   hence after every `detectControlRegions` / `classifyArms` / F1 / F2, so a zero manufactured here
   **cannot reach a pointer-identity test at all**. Move `lowerMeasures` earlier — the same
   reordering bd `21mg`'s own trigger already forbids for a *different* reason (a round-2 rail
   measure degrading into a classical passthrough of an `i32` handle) — and this clause's zeros
   start arriving at F1 beside `z9t1`'s, two rules compounding at a test neither was measured
   against. **One ordering fact, two triggers; read them together.**
6. ⚠ **NEW, 2026-09-15, owner ruling `DECISIONS.md` E9 — the pre-existence ground for RIVAL 2 is
   gone.** Either a taint-history record survives `-O1` folding (then a discriminator exists and
   *"no predicate can separate the readings"* is false), or `cq_measure(q * u)` / `cq_measure(q & u)`
   stop shipping this circuit on `main` (then the class no longer pre-exists and a decline here
   would close it rather than split it). **Re-derive the rival-2 paragraph from scratch; do not
   patch it.**

---

## 7. Fixtures

| file | direction | what it pins |
|---|---|---|
| `ir-pass/test/lowering_reject_measure_undef_operand.ll` | **INVERTED** decline → accept | the `i1 undef` direct spelling → `ret i1 false`. ⚠ **Filename deliberately NOT changed** (bd `gahu` / L8: a `git mv`'d fixture can be resurrected by a merge, putting one module under two names with contradictory verdicts). The header says the name is historical and why. |
| `ir-pass/test/lowering_accept_measure_undef_zero.ll` | NEW accept | `poison` at i32 (one predicate covers both), `undef` at i64 and double (the f64/angle family must not mint a rail), the parser-folded `ptrtoint` spelling, and **`@f_beside_quantum` — the RAUW-target discriminator**, pinning `add nsw i32 %m, 0` against `add nsw i32 %m, undef` |
| `ir-pass/test/lowering_reject_measure_undef_global_init.ll` | NEW decline | the residual, so the retained string is not left with a customer nobody tests (§2.3) |
| `ir-pass/test/lowering_measure_undef_operand_after_taint_fold.ll` | NEW accept *(fix round, `F-E2-1`)* | **RIVAL 2, the disclosed shape**: `cq_measure(q + u)` after `-O1` folds the operand to `undef`. Its whole-file `NOMEASURE` prefix pins that **the user's measurement is absent from the emitted module** — not a call and not even a declaration |
| `ir-pass/test/lowering_measure_taint_fold_control.ll` | NEW accept *(fix round)*, GREEN on **both** binaries | the one-token control: the same module with the operand spelled `%1` (the theta's result) emits `cqrt_measure_i32`. The pair is each other's mutant, which is what makes the `NOMEASURE` claim attributable to the fold and to nothing else |

**Rule 12 hygiene, itemised because the three shipped defects are itemised:**
(a) every count lives in its own whole-file `COUNT` prefix and every negative prefix is pure — the
`-NOT` after each count is the "exactly N" idiom, which only sees the region AFTER the match;
(b) the decline fixture's IR-text `-NOT`s are pinned by the `not` inversion, not by the text, and it
says so;
(c) every fixture moved here was checked for *"green because its subject no longer exists"* — and
§2.2 records the one case where following the scoping verbatim would have shipped exactly that.
⚠ **No bare `-NOT: undef` anywhere**: these modules' own `; ModuleID` / `source_filename` lines carry
the word in the FILE PATH (bd `qta2`'s vacuity trap), so every such negative names a full
instruction.

**Injection (mutation) matrix over the two accepts** — `probes/injection_matrix.py`, running **every**
`--check-prefix` the fixtures' own RUN lines name with the same FileCheck command line lit runs
(PROTOCOL S3: *a harness that runs a weaker command than lit measures itself, not the fixtures*):

```
  checked 15 mutants over prefixes ['CHECK', 'NOCLASSICAL', 'ACC'] in lowering_reject_measure_undef_operand.ll: 15 caught, 0 MISSED
  checked 27 mutants over prefixes ['CHECK', 'MOD', 'COUNT', 'NOALLOC', 'NOUNDEF', 'NOINTR', 'ACC'] in lowering_accept_measure_undef_zero.ll: 27 caught, 0 MISSED
injection matrix: 42 mutations over 2 fixtures, 0 MISSED, 0 HOLE(s)
```

⚠ **The harness lied once, in the MISSED direction, and it was caught by a self-check rather than by
reading the output.** Its first `rename_body` mutation was `line.replace("@f_", "@zzz_", 1)`, a
**no-op** on a fixture whose function is not named `@f_*`: a mutant identical to its base, scored
**MISSED against a fixture that catches it**. The harness now asserts that every mutant differs from
its base, and refuses to run with no argument (a matrix printing `0 mutations, 0 MISSED` is a HOLE,
not a pass). Both are CLAUDE.md L10 verbatim — *an instrument's failure mode is to report a PASS.*

### 7.1 No e2e slice — the decision, and the gap it leaves, stated rather than skipped

**No `tests/e2e/slice_*.c` or golden is added.** Three measured reasons, in order:

1. **No committed golden can move, structurally.** A module can only reach E2's clause with a
   whole-value `undef` measure operand, and every such module **declines on the ORACLE** — so no
   accepting slice exists for E2 to perturb. The corpus sweep corroborates it (§4: zero `A→A` stream
   moves, zero `A→D`), but the argument does not rest on the sweep.
2. **The classical measure emits nothing** — no symbol, no gate, no trace line — so a slice for the
   pure shape would have a **0-line golden**, and a 0-line golden is the shape CLAUDE.md warns
   pins nothing (a 0-byte module ACCEPTS through the passthrough early-out).
3. `tests/e2e/CMakeLists.txt` has **one tail anchor** and every slice-adding branch conflicts there
   (PROTOCOL S1's measured erratum). A guaranteed merge conflict for a golden with no discriminating
   content is a cost with no witness behind it.

⚠ **THE GAP, NAMED:** the e2e layer is *"the only layer that LINKS"*, and E2 therefore ships without
a gate on that layer. **The linking property is nevertheless MEASURED, just not gated**:
`probes/e2.sh` runs the full stage-1→2→2b→3→run pipeline, and `e2g_undef_measure_with_quantum.c`
links against `libcq_templates.a` + `libcq_runtime.a` and runs — **3 trace lines, STRICT stage 2b
`1 rail mint(s) of which 1 left allocated, 0 cqrt_free site(s): 0 verified, 0 violation(s), 0
unproven`**, trace **byte-identical** to the written-zero twin's. If the reviewer or the owner wants
that promoted to a gate, the slice is `e2g`'s two lines of C and its golden is the committed
`probes/out/subject/e2g_undef_measure_with_quantum.trace`.

---

## 8. What this track did NOT do, and what is left open

* **No warning, no new diagnostic, no renamed string** — the owner has ruled twice against a warning
  on this family, and renaming a live decline string is bd `OQ-13`, not a free edit.
* **The operand's OTHER uses are not rewritten.** `int u; int m = cq_measure(u); return m + u;` keeps
  `u` as `undef` at the second read (`e2e`). Deliberate, and it mirrors bd `z9t1`, which normalises
  the theta seed and its theta-carrying phi incomings and nothing else. Stated, not quietly widened.
  ⚠ **This is also the sentence §6's byte-identity claim contradicted** until the fix round — §8 was
  right and §6 was wrong, which is exactly why a record that states a limitation correctly in one
  section does not protect the claim in another (`F-E2-2`).
* **OPEN / FILED for the orchestrator:**
  1. **The residual decline is an over-decline candidate** (§2.4) — a defect to remove under the
     2026-09-11 ruling, deliberately not removed here, with the retirement trigger written down.
     ⚠ **Re-grounded 2026-09-15** on the SEMANTIC (L3-mirror) reason; the hygienic one is recorded
     as **not load-bearing**, and the swap is an **owner** question.
  2. **bd `fve8`'s note and `SCOPE_M.md` §1.3(b) need the §2.2 correction applied**, or the next
     reader re-derives the same finding (L7-with-a-twist). The *conclusion* stands; the name
     "`ConstantExpr` residual" does not. *(Still open after the fix round — `SCOPE_M.md` lives on
     Track M's branch, not this one.)*
  3. **`cq-opt-equivalence-full` is owed at the group gate** — E2 moved a decline string's
     population. *(Still owed; the fix round changed no decline string and no predicate, so the
     obligation is unchanged, not discharged.)*
  4. **Rule 13**: this is a change to the SOLE SINK. Small is not exempt. It is cleared by an
     independent adversarial reviewer, not by the green suite above.
     ✅ **Round 1 ran** (`review_r13_e2/REVIEW.md`): verdict **FINDING**, 1 × P1 + 2 × P2, 13 attacks
     held. All three findings are landed by the fix round (`$SES/e2fix/FIX.md`), the P1 by the
     owner's ruling `DECISIONS.md` E9 (accept + disclose, **no fence, no warning**).
     ⚠ **The review's own closing note stands and is not discharged by this fix:** *"do not close
     this as Rule-13-cleared on one round"*, and the composition with the **rail-bank headline**
     (both land in `lowerMeasures`' branch (1)) has had **no** review at all.
