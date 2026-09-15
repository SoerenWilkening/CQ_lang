# Rule-13 independent round — bd `test_C_libtooling-hlhh`, the **F′ × P′ COMPOSITION**

Reviewer: independent agent, session 2026-09-15. Subject: the composed binary
(Track F′ `f2-phidesc-precision` `3637fdd2` + Track P′ `prep-leaf-grammar` `28b9eb01`).
No build of an existing worktree, no suite run. Per-probe pipeline + analytic/trace reasoning
(Rule 2 — no simulator).

## VERDICT: `CLEAR-WITH-ITEMS`

Nothing I could construct makes the composed binary emit a wrong circuit that either part
alone would not have emitted. **The composition itself comes out clean by the project's own
strongest witness**: every composed accept I built has a gate stream and a runtime trace that
are **BYTE-IDENTICAL** to a twin that needs only one of the two increments, and the three-way
in-loop one is additionally K-independent.

Six items follow. One is a **population widening of an open P1** (R-1). One is a **method
finding** that falsifies a sentence in `COMPOSITION.md` (R-2) — the composed ACCEPT surface is
not empty, and it took one round to show it. Four are disclosure/coverage items.

---

## 0. Binaries — hashes checked against every cited `GATES.md` line

| role | commit | `cq-opt` sha256 | `GATES.md` says | on disk |
|---|---|---|---|---|
| ORACLE | `main` `74eabd2c` | `0e280fc62a91cec2336769edde8a873563a21ee4869744331a0fcf6811549c6d` | ✓ | ✓ MATCH |
| BASE_F (Track F′) | `3637fdd2` | `8cda04ca3f32bd735f9be2fd8dd468c4d8916e739c4dcbcfe303641cef44dd16` | ✓ | ✓ MATCH |
| SUBJ_P (composed) | `28b9eb01` | `7916923f56fb36af90dfd05efe0b8c45317db5dc30d4d90ec56f8ffadba56e72` | ✓ | ✓ MATCH |
| **P_ALONE (NEW — built by this round)** | `main` + P′ only | `3bb2fd4dcee6101318763bb6508499764387001594bbc80468f1a2959925994f` | — | — |

`libCQPass.so`: ORACLE `94602c78…` ✓, BASE_F `10c2ae8d…` ✓, SUBJ_P `b8ec2892…` ✓,
P_ALONE `8cd12b61632552775a0ef71d4e50644824489889d53dcb7c1ceb4506c9777bbc`.

**No stale citation found.** Every hash a track's `GATES.md` cites matches the binary on disk
(`shasum -a 256`), so the gate lines this round relied on are facts about the binaries I measured.

### 0a. THE FOURTH BINARY EXISTS NOW — hand it on rather than rebuilding it

`COMPOSITION.md` §1 states its one limit in the right words — *"'MINE' is an inference, not a
proof, and the honest way to close it is a fourth binary (`main` + P′ alone), which this track
did not build"* — and §6 item 1 calls it *"the single highest-value thing this track could not
afford."* It cost **one `git archive main` + one `git apply` of P′'s three source files + one
`cmake --build -j4`**; P′'s diff applies to `main` with `git apply --check` clean, because F′'s
hunks (`ArmClassify.cpp` ~1452–2200) and P′'s (~51, 2631, 6320–6958) do not overlap.

Built at, and reproducible from,
`$SCRATCH/R4` (`git archive 74eabd2c | tar -x`, then
`git diff 3637fdd2 28b9eb01 -- ir-pass/src/ArmClassify.cpp ir-pass/include/ControlPlan.h ir-pass/src/SwapRouteEmit.cpp | git apply`).

**Its provenance is checked by behaviour, not asserted**: it DECLINES F′'s own recovered accept
`trackF/probes/acc1_dead_nondominated_phi.ll` at F2 (so it carries no F′) and ACCEPTS
`trackP/probes/a1_clean_gap2.ll` with an md5 equal to SUBJ_P's (so it carries all of P′).

**Every "MINE" row I re-measured is confirmed a measurement, not an inference.** All seven probe
rows of `COMPOSITION.md` §3's MINE table (`p19`, `r18`, `r21`, `a1`, `a2`, `a3`, `d5`) are
`ORACLE == BASE_F != SUBJ_P == P_ALONE` with **md5-identical** accepted IR on the two right-hand
cells; the three shipped-fixture MINE rows and the two F′-only fixture rows come out the same way
in the sweep of §7.

---

## R-1 — ITEM (**P1 population**, not a new defect): F′ adds a customer to the OPEN P1 bd `s82e`, and its new ACCEPT fixture calls that class "ORTHOGONAL to this landing"

### The shape, as a program

```llvm
mB:
  %MB = phi i32 [ %tb, %armB ], [ 0, %pre ]      ; the controlled state prep's register
  %dz = zext i32 %q  to i64
  %dd = add  i64 %dz, -7
  %mz = zext i32 %MB to i64                       ; <-- copies %MB out
  %pm = mul  i64 %dd, %mz
  %u  = trunc i64 %pm to i32                      ; <-- the copy SURVIVES: a template rail
  %r  = call i32 @cq_theta_si32(i32 %MB, double 0.9)   ; chained, NON-DIAGONAL, in place on %MB
  %m0 = call i32 @cq_measure_si32(i32 %r)
  ...
J:
  %p  = phi i32 [ %u, %mB ], [ 0, %Y ]            ; DEAD, and not dominated by %mB
```
(`probes/m1_malign_leak_then_rotate_measure.ll`.)

### Measured

| probe | ORACLE | BASE_F | SUBJ_P | P_ALONE |
|---|---|---|---|---|
| `m1_malign_leak_then_rotate_measure.ll` | **D** `state prep seed is proven equal to the condition register` | **ACCEPT** | **ACCEPT** | **D** (same string) |
| `m1c_control_offdesc.ll` (ONE operand changed: `%mz = zext i32 %q`) | D | D | D | D |
| `m2_nodeadphi_reference.ll` (`%p` deleted) | **ACCEPT** | ACCEPT | ACCEPT | ACCEPT |

`m1c` attributes the flip to φ-descendant **membership** and to nothing about deadness or layout.
Stage 2b on `m1`'s lowered IR: `2 rail mint(s) of which 2 left allocated, 4 cqrt_free site(s):
4 verified, 0 violation(s), 0 unproven` — clean, and **structurally blind** to what follows
(CLAUDE.md: there is no `cqrt_alloc` for a template-minted rail to count).

The emitted stream on SUBJ_P ends:

```
%h_cast3 = call i32 @cq_template_trunc_i64_to_i32(i32 %h_op)   ; never _unc'd, never freed
... (h_op, h_cast2, h_cast are uncomputed and freed) ...
call void @cqrt_ry_i32(i32 %h1, double 9.000000e-01)
%m = call i32 @cqrt_measure_i32(i32 %h1)
```

### The mechanism, and why it is a wrong distribution

`%h1` is the prepped register, put into superposition by `cqrt_ry_i32_controlled`. `%h_cast3`
retains a **which-path copy** of a function of `%h1` (for `q != 7`, of `%h1` itself) and is never
uncomputed. A non-diagonal `cqrt_ry_i32(%h1, 0.9)` then runs on `%h1` and `%h1` is measured. The
leftover entangled record makes the branches the second Ry would have interfered
**distinguishable**, so the measured distribution is the dephased one. That is Rule 8 verbatim —
*"a permutation that leaves a rail dirty **and** entangled still dephases under later
interference"* — and it is the exact reading CLAUDE.md §5's 2026-09-14c correction (Q-R1-1 /
bd `s82e`, bd `tu9q`) installed, converting three shipped fixtures to declines for it.

### Why this is an ITEM and not a FINDING

⚠ **Say the direction first, so this is not read as harmless: for the program `m1`, this landing
is an OVER-ACCEPT (P1 direction).** A module `main` refuses loudly now compiles, and the circuit
it compiles to is the dephased one.

**What is NOT new is the class, and `m2` is the control that settles it.** With the dead φ
deleted the module ACCEPTS on the ORACLE, and its gate stream is **byte-identical** to `m1`'s on
SUBJ_P (checked line by line modulo SSA renumbering). So the hazardous circuit already ships from
`main`; F′ widens its population by one spelling. CLAUDE.md's own formulation applies:
*"'pre-existing' is true of the defect and FALSE of its population"* — and the precedent for
grading it this way is bd `1m5p` / bd `a3z7` at the 2026-09-14 gate, both recorded as
owner-disposition filings rather than blockers on exactly this reasoning.

### What is owed

1. **A three-word correction in a shipped fixture header.**
   `ir-pass/test/control_inplace_ry_stateprep_acyclic_nondominated_phi_accept.ll` says of the
   leak: *"That leak is the bd `test_C_libtooling-s82e` family and is **ORTHOGONAL to this
   landing**: it is the ordinary disposition of a dead tainted chain."* The first clause is
   right and the second is the one CLAUDE.md §5 has already called false once, in the same
   words, about three other fixtures: *"Rule 6 governs whether a dirty rail may be FREED; it says
   nothing about whether leaving it entangled is semantically free, and Rule 8 says it is not."*
   The fixture itself is in the **benign** half (its `%MB` is measured directly, no rotation
   after) — but the capability the landing ships covers the malign half, which `m1` demonstrates.
   "ORTHOGONAL" should read "a customer this landing adds to bd `s82e`", with `m1`/`m2` named.
2. **File the customer on bd `s82e` / bd `tu9q`.** It is a filing because `m2` proves the class
   is pre-existing and the fence is not this track's to build.

### Red-green pair to write WITH the s82e fix (not now)

* **RED / decline**: `m1_malign_leak_then_rotate_measure.ll`, mirroring whatever string the
  s82e fence prints, character-for-character.
* **GREEN / accept**: `m2`-shaped but with the trailing `cq_theta`/`cq_measure` removed, i.e.
  the leak with the register never touched again — the half CLAUDE.md §5 says is a genuine
  Rule-6 accepted leak.
* **Isolating control**: `m1c_control_offdesc.ll`, which must keep declining at F2 under every
  spelling, so the pair cannot go green because its subject vanished (fixture-hygiene defect (c)).

---

## R-2 — FINDING (method, no wrong circuit): the composed ACCEPT surface is **NOT empty**, and one round found two (plus three untested P′-only interactions)

`COMPOSITION.md` §4 says, correctly and carefully, *"the honest statement is 'no composed ACCEPT
was found', not 'there is none'. The surface is sampled, not enumerated."* **It is not empty.**

### First, a sharpening of bd `hlhh`'s own mechanism, which is why P′'s sampling missed it

bd `hlhh` says *"`preppedRailPhiRegionIdx` admits a φ as a rail leaf only for a region
`classifyArms` **already accepted**, and this change makes `classifyArms` accept state preps it
used to decline"*, and both tracks then looked for a program where the two widenings **meet on
one φ**. ⚠ **They cannot, except as the crash** — and the reason is one line of the pipeline:
**every F2 decline is FATAL to the module** (`diagnoseUnderControl` → `DS_Error` →
`LLVMContext::diagnose` EXITS, bd `br4a`), so a region F2 refuses never sits in a plan beside
anything. F′ therefore cannot "add a leaf to a plan that already existed"; it can only turn a
**dead module into a live one**.

So every F′ × P′ composition is **module-level**: any program that contains an F′-dependent prep
*anywhere* and a P′-dependent kickback *anywhere*. That surface is large, trivially reachable,
and is what the constructions below occupy. The shape-level surface P′ probed is the one
confined to `fxp1`.

### C1 — the canonical composed accept, in ONE function

`probes/c1_composed_onefn_f32prep_plus_p_i1_crossblock.ll`. Two independent state preps in one
function:

* **(A)** Track F′'s own `acc1` prep at **i32** — its only F2 witness reaches the seed through a
  DEAD, NON-DOMINATED join φ. Needs F′. ⚠ **At i32 the dead φ does NOT hit the broken-module
  defect**, because `lowerOps` RAUWs the tainted i32 op to an **i32** handle and the types agree.
  That is the whole trick, and it is why `fxp1` could not be an accept.
* **(B)** an **i1** prep whose merge φ conditions a phase kickback across ONE empty gap block.
  Needs P′.

Because a decline is module-wide, the module lowers only on a binary carrying both:

| | ORACLE | BASE_F (+F′) | P_ALONE (+P′) | SUBJ_P (+both) |
|---|---|---|---|---|
| `c1` | D `state prep seed is proven equal to the condition register` | D `condition predates a non-diagonal gate` | D `state prep seed is proven…` | **ACCEPT** |
| `c1a` — same module, kickback branch moved INTO the prep's own merge block | D `state prep seed…` | ACCEPT | D | ACCEPT |

`c1a` is the isolating control: it needs F′ only, so the delta between the two rows is exactly P′.

**And the composition is clean by the project's own strongest witness.** `c1`'s gate stream is
**BYTE-IDENTICAL** to `c1a`'s, and linked and run (`libcq_templates.a` before `libcq_runtime.a`)
the two traces are **BYTE-IDENTICAL at 27 lines** — the leading `cqrt_alloc_i32/ry_i32/icmp/
alloc/ry_i32_controlled/…` half A, then `alloc_i1 → ry_i1 → alloc_i1 → ry_i1_controlled →
rz_i1(h8) !cq.branchphase → measure_i1(h8)`. Half B's invariants read straight off it: `h7` is
read only as the control of `cqrt_ry_i1_controlled`, never `cqrt_x`-bracketed, never freed; the
kickback is the diagonal `rz` on the rail root, which is `emitKickbackGroup`'s shipped
convention. STRICT stage 2b: `4 rail mint(s) of which 4 left allocated, 4 cqrt_free site(s):
4 verified, 0 violation(s), 0 unproven`.

### C2 — the THREE-WAY composition `COMPOSITION.md` §6.3 names and bd `oej0` says nobody has built

`probes/c2_composed_threeway_with_wx8g_loop.ll` — F′ (slot test) × P′ (cross-block φ leaf) ×
bd `wx8g` (the ROLLED in-loop kickback). Half B's kickback is bd `52og`'s in-loop shape on an
OUTSIDE prep's φ, with the gap block inside the loop body.

```
ORACLE D(F2) | BASE_F D(P4 cross-block) | P_ALONE D(F2) | SUBJ_P ACCEPT
```

Witnesses, all measured on SUBJ_P:
* **rolled-vs-unrolled twin trace: BYTE-IDENTICAL, 29 = 29 lines**
  (`probes/c2t_unrolled_twin.ll`, three sequential kickbacks, no loop);
* **K-independence**: the lowered module is **99 lines at K=3 and 99 at K=1000**.

### O1 / O2 / O3 — NOT compositions, but three P′ accepts neither track's probe set contains

⚠ **These accept on `P_ALONE` too, so they are P′-only, not composed.** They are recorded here
because they are the interactions with *already-landed* features that P′'s probes miss, and a
composition review is the round that should find them.

* **`o1` / `o2`** — one prep merge φ read by **TWO consumers with OPPOSITE order obligations**:
  a 4.4 **data select** (bd `boi6` F-M1: *prep before select*) and a **cross-block phase
  kickback** (P′: *kickback before prep*), in both CFG orders. This is the shape where P′'s
  "one field, two opposite obligations, keyed on `Kind`" is actually exercised.
* **`o3`** — a **MIXED condition tree**: one φ leaf cross-block behind an empty gap block (so the
  `hcrg` adjacency is broken and only the plan's new edge orders it) plus one φ leaf in `Pred`
  (whose prep gets the alias edge). One edge from each source, inside one region.

All three ACCEPT on SUBJ_P and P_ALONE, and all three are **BYTE-IDENTICAL** in gate stream to a
twin that accepts on the **ORACLE** (`o1a`, `o2a`, and `a2_two_prep_phi_leaves.ll` for `o3`);
`o1`'s **runtime trace is byte-identical to `o1a`'s at 19 lines**. The emitted order is source
order (the select's `cnot/copy_i32_controlled/x/…/cnot/free` merge, then `rz_i1
!cq.branchphase`), which is what *"every emitter inserts positionally"* predicts, and `o3`'s
stream is the textbook one: `toffoli(h1,h2,g) → rz_i1(g,0.3) !cq.branchphase → toffoli(h1,h2,g)
→ free(g)`, with `h1`/`h2` read only as controls and `g` returned to `|0⟩` before its free.

### The part of the surface that is EMPTY, and why — an argument, not a theorem (L5)

The **shape-level** composition — F′'s newly-accepted prep feeding P′'s leaf, which is what
bd `hlhh` describes — is confined to the pre-existing broken module or to a decline, for a
structural reason worth writing down:

1. P′'s leaf grammar needs the prep's merge φ to be **i1** — read in source, not assumed:
   `isCondRailPhiShape` (`SelectClassify.cpp:644`) is
   `P && P->getType()->isIntegerTy(1) && P->getNumIncomingValues() == 2`.
2. F2's witness must therefore be a **tainted i1** value.
3. The only values F′ newly excludes are φs off `MergeBB`'s dominance subtree that are
   slot-unavailable, **and their downstream closure** — every one of them tainted.
4. **Every tainted i1 value is RAUW'd to an `i32` handle** (`lowerOps` to a template handle,
   `lowerRotations`/M-β to a rail handle; Rule 15: *a runtime handle is always `i32`*). So a
   **dead** i1 φ over one is always the broken module (`fxp2`, exit 134 on all four binaries).
5. A **live** one reads a tainted value under a classical condition and is claimed by
   `declineClassicalMuxes` (`TaintPropagation.cpp:1476` — `if (Phi->use_empty()) continue;` then
   `readsTaintedValue`), and `liftOneRegisterMergePhi` cannot rescue it: one incoming is a
   **template result**, which the lift's clause (3) says *"mints fresh rails and never
   resolve[s] — a derived-value arm stays declined"*, and the bypass incoming cannot resolve to
   `M` because `M` is not available on the bypass.

Measured corroboration (mine, four binaries, ORACLE/BASE_F/SUBJ_P/P_ALONE): `fxp1`
D/D/**134**/D, `fxp1c` D/**134**/**134**/D, `fxp2` **134**/**134**/**134**/**134**. For the LIVE
variant I am *citing* Track F′ rather than re-running it — `acc2 | 8cda04ca3f32bd73 | ORACLE F2 /
SUBJECT taint-escape` (`trackF/GATES.md`, hash re-checked against the binary on disk).
**Do not read step 5 as a theorem** — it
is an argument about today's `declineClassicalMuxes`, which is itself under widening pressure,
and it is exactly F′'s own `hrts` live trigger one level up.

### STRICT stage 2b on every new accept (`tools/free_pairing_check.py`, SUBJ_P's lowered IR)

| probe | result |
|---|---|
| `c1` | `4 rail mint(s) of which 4 left allocated, 4 cqrt_free site(s): 4 verified, 0 violation(s), 0 unproven` |
| `c2` | `4 / 4 left allocated, 4 free: 4 verified, 0 violation(s), 0 unproven` |
| `c2t` (unrolled twin) | identical to `c2` |
| `o1` | `6 / 5 left allocated, 1 free: 1 verified, 0 violation(s), 0 unproven` |
| `o2` | `6 / 5 left allocated, 1 free: 1 verified, 0 violation(s), 0 unproven` |
| `o3` | `4 / 3 left allocated, 1 free: 1 verified, 0 violation(s), 0 unproven` |

⚠ Read that table the way CLAUDE.md says to: stage 2b witnesses rail **pairing**, is
**structurally blind** to a leaked TEMPLATE-minted rail, and `0 violation(s)` is not clearance
for the R-1 class. `c1`/`c2` each carry one such leaked rail (the `trunc` of half A) — benign
there, because the register it copies is measured and never rotated again.

### What is owed

Record against bd `oej0` and in `COMPOSITION.md` that the surface is non-empty, that `c1` and
`c2` are the two composed constructions (and `o1`/`o2`/`o3` three untested P′-only ones), and
that all five are **twin-identical**. This is the object the round exists for and it should not
be re-derived next session.

---

## R-3 — ITEM: F′ shipped **no source-mutation gate**; P′ did, and P′'s found a real defect

P′ ran S-M1/S-M2/S-M3 (`trackP/probes/source_mutation.sh`) and S-M1 **did not flip its fixture on
the first run** — the finding P′ records as *"a decline fixture reached by two roads measures
neither"*, fixed by rebuilding the latch fixture around an OFF-WIRE operand. P′'s three new
decline fixtures each disclose their coverage explicitly (`…_cross_block_theta.ll` is
**deliberately left doubly covered** and says so; `…_offwire_theta.ll` and
`…_inloop_latch_theta.ll` carry the single-road argument).

Track F′'s `GATES.md` has **no source-mutation row**. Its decline tripwires
(`…_backedge_{phi,nonphi}desc_collider.ll`, `…_acyclic_nondominated_phi_control.ll`,
`…_accept_control.ll`) are pinned by ORACLE-vs-SUBJECT isolation and by an injection matrix over
the *accept* fixture only. Isolation is real evidence — it is what makes the two `_control`
files non-vacuous — but it does not answer *"would this fixture flip if the truncation clause in
`collectStatePrepPhiDescendants` were deleted?"*, which is the over-accept direction and the one
the two back-edge files exist for. The historical measurement quoted in CLAUDE.md §4c (*"the
ORACLE fires F2, the un-narrowed subject does not"*) was taken against a **different** binary and
a **different** spelling of the predicate.

**Owed:** one `source_mutation.sh`-style run on the F′ branch — replace
`availableAtAnF2Slot`'s body with `return false;` and confirm both back-edge fixtures go red.
Cheap (one rebuild), and it converts an inherited claim into a fact about the shipped binary.

---

## R-4 — ITEM (CLAUDE.md L3-mirror): P′ adds a population to `RailCondReads` **case (3)** without reading the record's retirement trigger

`ir-pass/include/TaintPropagation.h:536-570` states three cases at `reverifyRailCondReads` and
names case (3) — *"a LIVE value that is NOT a `CallInst` — today, exactly a region-merge
`PHINode` (bd `3qps`/`4aiu`, Track P, which is the FIRST increment to put φs into this record:
**the flat kickback is emitted BEFORE its prep**, so `markRailCondRead` sees the φ). It is
SKIPPED TOO, and that skip is **INERT, not conservative**"* — with the trigger:

> ⚠ RETIREMENT TRIGGER for case (3), and it is the ONLY thing holding it: the day ANY emitter
> can record a non-`CallInst` control read whose value is NOT subsequently RAUW'd to a
> `cq_theta_*` call — **a second φ-recording emitter**, …

P′'s whole increment is about the sentence in bold: it **enlarges** the set of kickbacks emitted
before their prep (from the ones the `hcrg` alias supplies for free, to every cross-block φ leaf
under an explicit `Precedes[kickback] = {prep}` edge). `IMPL_P.md` and `COMPOSITION.md` mention
M-β three times but **never mention `RailCondReads`, `reverifyRailCondReads` or case (3)**, and
neither does `trackF/IMPL_F2.md`.

**I checked the direction and the premise HOLDS**: the prep region is still emitted inside the
same `lowerControlRegions` call (P′'s edge changes the order within it, not whether it runs),
`emitInPlaceRotationRegion`'s M-β RAUWs the φ to the hoisted `cq_theta_i1`, the record's
`WeakTrackingVH` follows the RAUW, and `reverifyRailCondReads` runs after the round-2 fixpoint —
so case (3) still becomes case (2) before the reader looks. **This is a disclosure item, not a
defect.**

It is filed because CLAUDE.md records this precise omission as having cost a P1 on 2026-09-14
(*"when you ADD A CALLER to a shared predicate, read the callee's RETIREMENT TRIGGER and state
which direction you are using it in"*), and because the next widening of this edge — an emitter
that records a φ whose prep is **not** in the same plan, or a `SelectRegion`-kind prep — is
exactly the day the trigger fires. **Owed:** two sentences in `ControlPlan.h`'s
`PrepRegionIdxs` block naming `RailCondReads` case (3) and stating that the M-β premise is
preserved by construction.

---

## R-5 — ITEM (CLAUDE.md L1): neither record carries a round-2 item for the **widened positional scan**

`chainedThetaBetweenDefAndBranch` decides on `Taint.Tainted.count(CI->getArgOperand(0))` at
**classification time**, i.e. round-1 taint. The L1 record-and-re-ask machinery that exists for
this family (`markRailCondRead` → `reverifyRailCondReads`) re-asks **rungs (ii) and (iii) only** —
the measure question and the wire question, *"exactly as `railCondWireDisposition` asks them"* —
and `railCondWireDisposition` **has no positional prong**. So the positional theta scan is never
re-asked after `repropagateControlMerges` re-seeds taint from the 6.5/4.5 `%out` rails.

`IMPL_P.md` §6's vector list V1–V13 contains **no L1 item at all**.

The exposure is **pre-existing** — the in-`Pred` window has it identically, and P′'s in-`Pred`
path is byte-identical by construction — but P′ moves a population from an *unconditional*
decline onto a taint-dependent test, which is new customers for an old premise. I argue the
residual is probably empty (the same-wire half is covered by rung (iii)'s re-ask at FINAL taint,
and the other-wire half's only target is a dtzb in-place `add`/`xor`, which R-6 below shows G6
refuses for this species) and **I did not construct it**. Say that, rather than "closed".

**Owed:** one paragraph in `chainedThetaBetweenDefAndBranch`'s header stating the round-1-taint
premise and why the residual is believed empty, with a retirement trigger naming
`reverifyRailCondReads`.

---

## R-6 — ITEM: V12's ground HOLDS, and it holds for a stronger reason than V12 gives

`IMPL_P.md` §6 V12 is the load-bearing safety claim of the whole track — the positional prong
scans only for `cq_theta_*`, so cross-block P′ newly admits programs with a **dtzb in-place
`add`/`xor`** on the φ's rail in the gap; V12 clears it by measuring the in-`Pred` twin `c5`
and observing the `xor` lowers out of place. That is an argument from one twin. I re-derived it
and it is better than V12 says:

* **Measured on the SUBJECT, not by analogy**: `d5_bare_xor_in_gap.ll` lowers to
  `%h_op = cq_template_xor_i1_hl(i32 %h1, i1 true)` — a **fresh** handle — followed by
  `cqrt_rz_i1(i32 %h1, 0.9), !cq.branchphase`. The kickback's control is untouched.
* **The stronger reason**: the only names of the condition rail that are *available* in the gap
  are the φ itself and values derived from it. The arm theta's result is **not** — spelling the
  `xor` on it is invalid SSA, measured: `probes/r1_crossblock_xor_on_theta_name.ll` and its
  in-`Pred` twin `r2_…` are both rejected by the verifier, *"Instruction does not dominate all
  uses!"*, on all three binaries. And a state prep's straight-through incoming is the **seed**,
  which F1 requires to be untainted (*"a TAINTED pred incoming is a no-cloning mux"*), so it is
  classical and its `xor` is not a rail op at all. The φ is then always read later — by the
  branch (φ ROOT) or by a tree node in `Pred` (φ LEAF) — so `ArithLowering.cpp`'s G6 loop
  (*"no data use AFTER the op"*, `provablyBefore` over **every** user) refuses the in-place
  conversion on it. G6 additionally bails unconditionally inside a loop
  (`LI.getLoopFor(Site->getParent()) || blockCanRepeat(…) → return false`).

**Owed:** replace V12's one-twin argument in the source comment with the availability argument
above, and add the `r1`/`r2` invalid-IR measurement as the reason no other wire name can appear
in the gap. Same retirement trigger (*"If M-C's G6 ever admits an in-place op on a rail with a
later read, this ground is gone"*), now with the fourth pin.

---

## 6. What else I attacked, and what would have caught it

### F′ — `availableAtAnF2Slot` in the GRANTING direction (brief item 3)

I re-derived A5 rather than reading it. On reachable code the new member set is a **strict
superset** of the old, hence strictly more exclusions and strictly fewer witnesses:

* a **non-φ** user `J` of a member `V` has `V` dominating `J` by SSA, so `J` slot-available
  would make `V` slot-available, contradicting `V`'s membership — the test never fires for a
  non-φ (bd `dpau` is behaviour-neutral, by SSA transitivity, not by an opcode list);
* a **φ** the old proxy inserted satisfies `dom(MergeBB, IBB)`; slot-availability means
  `IBB dom Pred` or `IBB dom ArmBB`, either of which gives `dom(MergeBB, Pred)` or
  `dom(MergeBB, ArmBB)` by transitivity — impossible, since `Pred` strictly dominates `MergeBB`
  and every path to `ArmBB` reaches it through `Pred` on the first arrival.

I could not find a value **genuinely spellable at a slot** that the predicate drops. The two
slot spellings are the right ones: `DT.dominates(I, PredSlot)` is exactly "may be the merge φ's
pred-edge incoming" (and the header is right that `DT.dominates(I->getParent(), Pred)` would be
wrong for a value defined in `Pred`); the arm clause is a block-dominance **over**-approximation,
which can only add skips, i.e. keep rivals in, i.e. decline. **The refused dominance conjunct is
not reintroduced**: the walk still requires the operand chain to reach `M`, so the ≥11 shipped
merge-block colliders never enter it — F′ measured 17/17 collider + `Truncated` fixtures
unmoved, and my sweep reproduces that (§7).

### The pre-existing broken-module defect from **C** (brief item 2)

Three independent C spellings — a self-referential loop-carried `_Bool` accumulator, a classical
`if/else`-merged `_Bool` never read, and one read only by a branch `-O1` folds
(`probes/deadphi_c{1,2,3}.c`) — all produce **zero** `phi i1` in the stage-1 module and all
ACCEPT on all four binaries. **Not demonstrated from C**, which corroborates both tracks'
caveats rather than closing the question. The route I did **not** construct, and which would not
need `-O1` to keep a dead φ: `declineClassicalMuxes` runs **after** `lowerControlRegions`, so a
φ that is live in the source but whose only user an emitter erases is dead by the time the
liveness filter looks. That is where I would attack next.

### P′'s species scoping under F′'s widening (brief item 4)

*"What happens when F′'s widening makes more regions claimed?"* — **measured answer: for any
module that lowers, it cannot.** `preppedRailPhiRegionIdx` needs an **i1** prep; F′ can newly
accept an i1 prep only through a φ that is dead (broken module) or live
(`declineClassicalMuxes`), by R-2's step 3–5. Every F′-newly-accepted prep I could build that
reaches emission is **i32**, which the leaf grammar does not take. So F′ does not grow
`CondIsClaimedRailPhi`'s population; it composes with P′ **module-wide** (c1/c2), not
shape-wise. Stated as an argument, not a theorem.

### The precedence edge

* The Kahn backstop is **loud**: `if (Order.size() != N) { … declineRegion(...); return; }`
  (`SwapRouteEmit.cpp:2817-2823` in the CQ_P worktree) — a cycle lowers nothing. An unsatisfiable pair is therefore
  an over-decline (P2), never a silent pick.
* The two-consumer cases in both CFG orders (`o1`, `o2`) schedule and emit in source order, with
  byte-identical streams and traces to their in-`Pred` twins.
* The dedupe against the alias edge is correct and the `P >= N || P == i` guard declines rather
  than skipping.

### Other over-accept probes that came back clean

| probe | what it attacks | result |
|---|---|---|
| `x2_crossblock_gap_has_theta_on_other_wire.ll` | a chained theta on ANOTHER register in the gap — the case the positional prong exists for and no wire walk can see | **D** `condition predates a non-diagonal gate` on all four; its non-vacuity control `x2c` (theta deleted) **accepts** |
| `x1_inloop_prep_phi_read_after_loop.ll` | a prep INSIDE a bounded loop whose merge φ is read by a kickback AFTER the loop (the exit value) | **D** `control flow inside a loop body` on all four — safe direction, unmoved by either track |
| `r1`/`r2` | a dtzb `xor` in the gap on a rail wire name other than the φ | **invalid IR** on all three — the shape is not expressible |
| `x3_crossblock_gap_theta_inside_callee.ll` | bd `1yeu`'s **cross-function** gap aimed at the scan: the chained theta sits inside a `internal` CALLEE reached from the gap, so the `starts_with("cq_theta_")` name match cannot see it | **D** on all four, at the specialization guard (`cq specialization: …argument or return has no reversible copy`) — the vector is closed upstream, unmoved by either track. ⚠ Unrelated pre-existing nit: that string says *"floating-point quantum argument"* for an `i1` argument |

---

## 7. The four-binary corpus sweep over the shipped fixtures

`probes/sweep4.sh` — one row per fixture, four binaries on the same input, accepts keyed by an
md5 of the lowered IR with `ModuleID`/`source_filename` stripped, declines by **full stderr**
with the `Stack dump` / `Program arguments` argv noise normalised away (PROTOCOL S3 plus Track
P′'s own correction). Run at `-P 3` under a host load average that rose from 5 to **124** during
the run (another agent's suite); contention causes false FAILURES and never false passes, and
this instrument compares verdicts only.

**COMPLETE: 2047 / 2047 shipped `ir-pass/test` fixtures × 4 binaries.** Rows:
`probes/sweep4_3bb2fd4d.txt`, one row per fixture as
`<relpath>|ORACLE|BASE_F|SUBJ_P|P_ALONE`.

| classification | count |
|---|---|
| identical on all four | **2042** |
| **F′-only** (`ORACLE == P_ALONE != BASE_F == SUBJ_P`) | **2** |
| **P′-only** (`ORACLE == BASE_F != SUBJ_P == P_ALONE`) | **3** |
| **COMPOSED** (`ORACLE == BASE_F == P_ALONE != SUBJ_P`) | **0** |
| REVERSION (`ORACLE == SUBJ_P != BASE_F`) | **0** |
| OTHER / unattributed | **0** |
| `EMPTY` (0-byte module — the passthrough vacuity trap) | **0** (checked: no input file is 0 bytes) |

The 2 F′-only rows are `control_inplace_ry_reject_stateprep_acyclic_nondominated_phi.ll` and
`control_inplace_ry_stateprep_acyclic_nondominated_phi_accept.ll`; the 3 P′-only rows are
`control_phase_kickback_{reject_mergephi_cross_block, mergephi_two_leaves_cross_block,
mergephi_inloop_outside_prep}.ll`. **Every one is a fixture the owning track added or converted
deliberately, in the direction it claimed, and the P_ALONE column now says so as a measurement
rather than an inference.** In particular the ≥11 shipped merge-block colliders
(`range_forward_*`, `sideways_*`, `merge_edge_sideways`, `offwire_sideways_min`,
`step_cap_over`) and the four `Truncated` fixtures are in the 2042 — F′ did **not** drift into
the refused dominance conjunct.

⚠ **What this sweep does NOT cover, said plainly**: only `ir-pass/test`. Track F′'s sweep
(3933 rows) and Track P′'s (3953 rows) additionally cover every session `track*/probes` and
`review_*_probes` corpus; I re-measured only the rows I inspected from those, listed in §0a.
`sweep4.sh` normalises `Stack dump` / `Program arguments` / frame lines out of stderr before
hashing, so an `LLVM ERROR` row does not read as a mover because of its own argv (Track P′'s
correction, adopted).

Every mover it reached is one the tracks named, in the direction they named, and no row is
`ORACLE == SUBJ_P != BASE_F` (a reversion) or "differs on SUBJ_P while agreeing on both
single-track binaries" (an unattributed composed mover).

---

## 8. Two sentences that should not survive this round

1. `COMPOSITION.md` §4: *"no composed ACCEPT was found"* — true when written, falsified by
   `c1`, `c2`, `o1`, `o2`. Replace with the constructions and their twin-identity witnesses.
2. `control_inplace_ry_stateprep_acyclic_nondominated_phi_accept.ll`: *"That leak … is
   **ORTHOGONAL to this landing**"* — R-1.

## 9. What this round did NOT do

No build of `CQ_F` or `CQ_P`, no relink of any measured binary, no suite. `ctest`, `ir-pass-lit`,
`^e2e-` and `cq-opt-equivalence-full` are **absences here, not passes** — the merge-and-gate
agent owes them, and this landing moves an analysis site and a decline population, so it owes
the equivalence sweep too. I did not attack a multi-latch or irreducible loop body against the
back-edge clause (P′'s own "attack first (a′)"), the 512-block budget's decline path, or a
round-2-only-tainted theta in the gap (R-5).
