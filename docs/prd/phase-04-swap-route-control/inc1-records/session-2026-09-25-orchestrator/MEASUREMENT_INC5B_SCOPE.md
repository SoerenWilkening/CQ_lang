# bd `fn1q` increment 5b — SCOPE, MEASURED. ⚠ IT IS **TWO** CUSTOMERS, NOT ONE, AND THE RECORD'S PROPOSED ROUTE IS FOR THE SECOND

```
SUBJECT  build/ir-pass/cq-opt  5fd7183282ee0d38…   (= HEAD a9a227e4 + increment 5a)
```
Measured read-only on the primary binary while a third-party session held `build/`;
no rebuild, no oracle A/B yet (the oracle was still compiling — **every row below is
one-sided and none of it is a DELTA measurement**).

## 0. THE PHYSICS QUESTION, ASKED FIRST (owner ruling)

> *"Does it have to be declined by physics? if not we HAVE to make it compile!!"*

**No.** `if (u > 0) b = cq_theta(b, .5);` is a CLASSICAL branch choosing between two
circuits. On one path `b` is a rail; on the other it is the classical constant `false`.
No superposed condition, no no-cloning problem, no dirty rail. Realizable, so the
decline is compiler structure and is a defect (2026-09-11 ruling).

## 1. ⚠ `clang -O1` SPLITS THE FAMILY IN TWO, AND THE RECORD DESCRIBES ONLY ONE HALF

`MEASUREMENT_INC5A.md` §5 and `control_predmux_reject_rail_phi_cond.ll`'s header both
describe 5b as *"a rail φ whose prep sits under a CLASSICAL condition"*, refused by
`preppedRailPhiRegionIdx`. That is real, but it is the SECOND of two shapes, and which
one you get is decided by whether the user also MEASURES `b`.

| C, at the `-O1` ship floor | `-O1` emits | declines at | diagnostic |
|---|---|---|---|
| **(5b-i)** `b` NOT measured — `probes/5b/classical_prep_nomeas.c` | the select is SUNK INTO THE PREP BLOCK by clang itself (`%5 = select i1 %4, i32 2, i32 5` with a **bare rail leaf** condition — an ALREADY-SUPPORTED shape), leaving `%7 = phi i32 [ %5, %prep ], [ 5, %entry ]` | `declineClassicalMuxes` | `cq taint escape: tainted value muxed by a classical-condition phi` |
| **(5b-ii)** `b` ALSO measured — `probes/5b/classical_prep.c` | the `i1` rail φ SURVIVES (`cq_measure_i1` reads it) and feeds a `select i1 %6, i32 2, i32 5` | `SelectClassify.cpp:1064`, `preppedRailPhiRegionIdx == kNoParent` | `cq controlled lowering: control flow under quantum control` |

⚠ **BOTH ARE C-LEVEL, NOT IR-LEVEL.** This matters because of bd `hrts`'s standing
caveat (CLAUDE.md §5): an IR-level accept is not a C-level one. Both C files above are
six lines and compile at `-O1` with no hand-written IR.

⚠ **5b-i IS THE ONE THE SIMPLE C PRODUCES, AND NOTHING IN THE RECORD MENTIONS IT.**
The proposed route ("promote the constant incoming to a `|0⟩` rail handle so the φ
becomes a HANDLE mux") is *exactly right for 5b-i* and lands one stage earlier than the
record implies — in `declineClassicalMuxes`/`RailBankPromote` territory, not at
`preppedRailPhiRegionIdx`. For 5b-ii the same promotion is NOT sufficient: the φ is the
CONDITION, and `preppedRailPhiRegionIdx` asks for a CLAIMED `InPlaceRotation` region,
which a classical branch never is. 5b-ii additionally owes a new admission rung in BOTH
consumers (`SelectClassify.cpp:1064` and `ArmClassify.cpp:7213`).

**Recommendation: 5b-i first, as its own increment.** It is the smaller change, it has a
direct precedent, and it is what the plainest C hits.

## 2. THE PRECEDENT, AND THE PART OF IT THAT IS A TRAP

`promoteLoopCarriedHandleSeeds` (`LoopLowering.cpp:6502`, bd `zujr`/`11qv`/`h1ip`) already
does this transform for a LOOP-CARRIED header φ: resolve `wd.allocFn(Abi)`, mint
`cqrt_alloc_<W>(seed)` at the guard's or preheader's terminator, retype the φ, record the
logical width in `taint.HandleWidth`. Its gates (P0) dead-φ, (P3) seed availability and
(P4) every-user-is-rewritten are all questions 5b-i must answer too, and (P4) is a CRASH
FENCE reached from plain C — read CLAUDE.md §4f before re-spelling it.

⚠ **AND THERE IS A WRITTEN LATENT-P1 INTERLOCK WHOSE RETIREMENT TRIGGER THIS INCREMENT
FIRES.** `RailBankPromote.cpp:688` (review item I-3) records that its own `addIncoming`
builds `Constant::getNullValue(RailTy)` for the ¬arm, and says in its own words:

> *"a RESCALED memset would write handle `0` into every cell, and handle `0` IS A LIVE
> RAIL in this runtime (`cqrt_alloc_i1(0) -> h0`)"* … *"When a conditional bank store
> accepts, the ¬arm owes a REAL `|0>` rail (a fresh `cqrt_alloc`), not the literal 0"*

So **the promoted incoming must be a FRESH `cqrt_alloc`, never the literal 0** — the
literal aliases a real handle. The same file records a THIRD obligation of the same
landing (`railBankParkedRails` seeds the stale fence at the `phi`, and
`recordBarrierCutsPath`'s barrier stops being the store). Its retirement trigger reads
*"the day a conditional bank store accepts, re-derive this claim from scratch"* — 5b-i
is a candidate for that day and owes the re-derivation, not a citation.

## 3. WHAT I DID **NOT** DO

No oracle A/B (binary still building). No population count over the corpus. No fixture,
no probe family, no Rule-13 round, no implementation. The `-O1`-splits-the-family claim
rests on TWO C files, not on a survey; the `b`-is-measured axis is the only axis I
varied. I did not check `-O2`/`-O3`, a `true` constant incoming, an else-arm prep, a
narrow or fp mux type, or the in-loop form. I did not verify that the sunk select in
(5b-i) actually lowers once the φ is promoted — **the route is PROPOSED, NOT PROVED**,
and this project's own standard (increments 3/4/5a) is to prove a route on a bypass
build before writing it up as one.

## 4. THE BAREST SUBJECT IS **FIVE LINES**, AND THE BOUNDARY PROBES MOSTLY MISS

```c
int slice(int u) { int a = 5; if (u > 0) a = cq_theta(0, 0.25); return cq_measure(a); }
```
`-O1` → `%6 = phi i32 [ %4, %then ], [ 5, %entry ]` → `cq taint escape: tainted value
muxed by a classical-condition phi`. (`probes/5b/phi_handle_vs_const.c`.)

⚠ **THREE OF MY FOUR BOUNDARY PROBES DO NOT PROBE THE ARM I WOULD BE WIDENING**, and
that is worth recording because it is bd `46oo`'s class — a probe without the shape it
claims:

| probe | what `-O1` actually emitted | verdict |
|---|---|---|
| `two_distinct_rails.c` | a **`select`**, not a φ | declines via the SELECT arm — a different owner |
| `nonconst_classical.c` | a **`select`** | declines via the SELECT arm |
| `phi_two_rails.c` | ⚠ `-O1` FOLDED BOTH ARMS INTO **ONE** `cq_theta` WITH A `select` ON THE **ANGLE** (the drbq Inc-2b fold CLAUDE.md Rule 9 names) | **ACCEPTS** — the file does not contain the shape its name claims |
| `fp_mux.c` | an angle select | **ACCEPTS** via `AngleSelectEmit` — correctly, an fp merge φ is an ANGLE not data (L9) |

So a real two-distinct-rails **φ** boundary probe still has to be constructed; the obvious
C spellings all get folded or if-converted away before the pass sees them. Whoever builds
5b-i owes that probe, and owes it in the φ arm.

## 5. TWO DESIGN OBLIGATIONS THE PROTOTYPE EXPOSED

1. ⚠ **5b-i IS A TAINT-GROWTH EVENT AND OWES THE L1 QUESTION ANSWERED IN WRITING** — and
   I overstated this on first writing, so read the corrected form. The promotion mints a
   NEW `cqrt_alloc_<W>`, i.e. a new tainted value, and its slot (`CQLoweringPass.cpp:782`
   / `:1292`) is AFTER the `repropagateControlMerges` fixpoint at `:624`, so
   `declineTaintEscapes` never adjudicates that value. It is **not** the `MergePhiPeel`
   F-B6-1 shape — that stage grows taint BEFORE the guards — and the promotion is
   argued-benign because the mint's only user is the φ being rewired, so it cannot escape.
   ⚠ **But that is an ARGUMENT, not a fence, and it is exactly the species of unwritten
   argument L7 says hardens into a ruling.** `promoteLoopCarriedHandleSeeds` stands on the
   identical unstated argument at the identical slot. Whoever lands 5b-i should write it
   down for BOTH stages, or fence it — not cite this paragraph.
2. **The prototype is deliberately far too permissive and must not be read as a candidate
   implementation.** It promotes ANY live 2-incoming φ with one tainted and one
   `ConstantInt` incoming, anywhere, including in a loop, with no width record, no (P0)
   dead-φ clause, no (P4) user-rewrite proof, and no re-ask after the round-2 fixpoint. It
   exists to answer ONE question — does the stream downstream of the promotion lower at
   all — and nothing else.

## 6. ⚠ THE ROUTE IS **PROVED FOR ONE SHAPE AND BLOCKED FOR THE OTHER** — measured, on a prototype

```
PROTO   $S/wt-5b/build/ir-pass/cq-opt  a4549be0563aea42…  = SUBJECT + promoteClassicalMuxSeedsPROTO
NULL CONTROL, RUN FIRST, whole corpus, env UNSET vs SUBJECT:
        [NULLCTL] n=2154  A->D=0  D->A=0  decline-string-moves=0  stream-moves=0
```
The gating is sound, so what follows is evidence rather than an anecdote.

**PROVED — the sunk-select shape (`probes/5b/classical_prep_nomeas.c`) COMPILES**, `opt`
exit 0, and the emitted stream is the SHIPPED idiom with nothing new in it:

```llvm
%cq.clmux = call i32 @cqrt_alloc_i32(i32 5)     ; a REAL |5> rail, NOT the literal 5
br i1 %2, label %3, label %4
3:  %h  = cqrt_alloc_i1(false) ; cqrt_ry_i1(%h, 0.5)          ; the prep
    %bf = cqrt_alloc_i1(false) ; cqrt_cnot(%h, %bf)           ; rail-root CNOT copy
    %out = cqrt_alloc_i32(0)
    cqrt_copy_i32_controlled(%bf, selop=2, %out) ; cqrt_x(%bf)
    cqrt_copy_i32_controlled(%bf, selop=5, %out) ; cqrt_x(%bf)
    cqrt_cnot(%h, %bf) ; cqrt_free(%bf)                       ; x^x = 0, proven-|0> free
4:  %5 = phi i32 [ %out, %3 ], [ %cq.clmux, %1 ]              ; HANDLE mux, CLASSICAL cond
    cqrt_measure_i32(%5)
```
```
stage 2b STRICT: 5 rail mint(s) of which 4 left allocated, 0 template rail mint(s)
                 of which 0 left dirty, 2 cqrt_free site(s): 2 verified,
                 0 violation(s), 0 unproven
```
The `|0⟩`-rail argument holds in the emitted form: `%bf` returns to `x ⊕ x = 0` and its
free is proven; the promoted `%cq.clmux` and the prep rails are LEFT ALLOCATED, which is
Rule 6's accepted leak and bd `zujr`'s accepted zero-trip cost.

⚠ **BLOCKED — the BAREST five-line shape (`probes/5b/phi_handle_vs_const.c`) HITS A SECOND
WALL.** The promotion fires (`CQ_5B_PROTO: promoted phi in @slice`) and the module then
declines `cq uncompute: tainted handle reaches an unrecognized user` — the Phase-5
uncompute spine does not recognise the promoted φ as a handle user. **So "5b-i is one
promotion" is FALSE**, and anyone reading §1–§5 alone would have concluded it. The
increment owes the spine work too, and the size of that is unmeasured.

⚠ **AND THE ALLOC IS HOISTED ABOVE THE BRANCH, NOT PLACED ON THE EDGE.** The prototype
mints at the constant incoming block's terminator, which for an `entry`-edge incoming is
BEFORE the branch — so the register is allocated on both paths. Sound (an `alloc` is
neither a measurement nor a non-diagonal gate) and consistent with the zujr precedent, but
it is a placement decision nobody has ruled on, and the real increment should make it
deliberately rather than inherit it from the prototype.

## 7. ⚠ THE PROTOTYPE'S BLAST RADIUS — AND IT BREAKS THE CANONICAL DECLINE FIXTURE

Whole corpus, PROTO with `CQ_5B_PROTO=1` vs SUBJECT, on a quiet box, null control run first:

```
[NULLCTL] n=2154  A->D=0  D->A=0  decline-string-moves=0  stream-moves=0     <- env UNSET
[PROTOON] n=2154  A->D=0  D->A=1  decline-string-moves=226  stream-moves=15  <- env SET
                                  ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
```
⚠⚠ **THE TWO MOVE COUNTS ON THE `PROTOON` LINE ARE RETRACTED — MY HARNESS WAS BROKEN AND I
RAN TWO SWEEPS AT ONCE.** `ab5b.sh` wrote its per-module intermediates to FIXED paths
(`/tmp/ab5b_{a,b}.ll`, `/tmp/ab5b_{ae,be}.txt`), and I launched a second sweep
(`SUBJECT` vs `M4`) while this one was still running, so from ~13:53 the two were
overwriting each other's files. The `decline-string-moves` and `stream-moves` figures are
therefore **not measurements of anything** and must not be quoted; the second sweep's
in-flight count of 260 movers — against a reviewer-measured 0 — is what exposed it.
**I caught it only because the number was implausible enough to re-check.** The harness now
gives each run its own `mktemp -d` and is re-validated against a null control before either
figure is re-taken.

⚠ `A->D=0` and the single `D->A` row survive the retraction for a structural reason worth
stating rather than assuming: a verdict flip is read from each binary's own EXIT CODE, which
no shared temp file can corrupt, whereas `STR`/`STREAM` are read by `diff`ing those very
files. Same run, two different reliabilities — **do not treat a contaminated sweep as
uniformly void, and do not treat it as uniformly sound either.**

**The single `D->A` is `lowering_reject_classical_mux_phi_measured.ll`** — one of the four
fixtures `TaintPropagation.cpp` names as owning `kMsgClassicalPhi`, i.e. THE canonical
decline for this guard. The prototype turns it into an accept.

⚠ **MY FIRST READING OF THAT ROW WAS "the real increment must keep it declining", AND THE
FIXTURE'S OWN HEADER REFUTES IT.** Its subject is `%p = phi i32 [ %q, %a ], [ 5, %entry ]`
— **the 5b-i shape exactly** — and the header records why it declines: *"pre-guard this was
a confirmed verify-clean SILENT miscompile … the phi survives on the i32 runtime handle and
`cqrt_measure_i32(%p)` measures 'handle-or-5'"*. The promotion **removes that hazard at its
root**: once the literal is a real `cqrt_alloc_i32(5)`, the φ muxes two registers and the
measurement reads a genuine `|5⟩`, not a handle-or-integer pun. So this row is NOT
necessarily a regression — it is plausibly this fixture's **retirement trigger firing**,
which is the L8 situation, not a boundary violation.

**What that changes for the increment:** it must decide this deliberately and re-derive the
fixture's stream from scratch, not route around it — and it must NOT simply assert either
answer. Establishing which it is means showing that EVERY consumer of the promoted φ reads
it as a handle (the uncompute spine is already known not to, §6), not just the measure.
The honest status is: **undetermined, and the most important single question 5b-i has to
answer.**

226 decline-string moves and 15 stream moves over shapes with nothing to do with 5b
(`spec_*`, `railbank_promote_*`, `lowering_uncompute_*`) say the same thing from the other
side: promoting EVERY live 2-incoming φ with one tainted and one constant incoming reaches
deep into unrelated machinery. **The route is proved; the predicate is not designed.**

⚠ Read §6 and §7 together and the honest summary of 5b-i is: *the lowering exists and
produces a correct, 2b-clean stream for one shape; a second wall (the uncompute spine)
blocks the barest shape; and the admission predicate is entirely unwritten.* Anyone quoting
§6 alone would be claiming a capability that does not exist.
