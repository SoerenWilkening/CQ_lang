# Rule-13 adversarial review, ROUND 2 — bd `test_C_libtooling-r9e5` sub-increment 1b-B.1
## (the fix round on `review_b1_r1.md`, and the hunt for its §7 "fifth thing")

Independent reviewer, session `01NHxGVinGBKbb499HFCuwhT`, 2026-09-10.
Tree under review: branch `3qlq-inc1b-b-rail-select`, checkpoint `f9387f7` **plus the round-1 fix**,
built in `build/`. The fix was uncommitted when I started and the orchestrator committed it as
`f8d29e8` mid-review; the binary I measured is that tree. I did not write this code and did not
rebuild or edit anything under `ir-pass/`, `tests/`, `tools/` or `build/`.

# VERDICT — **BLOCK**

**One CONFIRMED silent miscompile, reachable from plain C through the shipped two-TU pipeline, and it
is a DECLINE → ACCEPT mover introduced by this increment** (finding **F-B1R2-1**). Its ROOT CAUSE is
PRE-EXISTING and shared — the compare spelling miscompiles byte-for-byte on the pre-B.1 binary
(`main` 87d0699), also from plain C — so the fix is a Rule-13-core widening whose scope is an owner
call. I grade it BLOCK on the same ground round 1 of Inc 1b graded **F-1b-1** a BLOCK: it is the
SAME defect class (a sibling in-place Ry making the control read a stale rail), the same fence
(`findNonDiagonalWireGate`'s tainted-parent ancestry), and this increment is what turns a loud
decline into a wrong unitary for the rail spelling.

**The round-1 fix itself is sound, complete for the closure it defines, and decline-monotone** — a
whole-corpus differential over all **1765** lit fixtures moves exactly **23**, every one of them a
file of the new B.1 family, and the only PRE-side ACCEPT that moves at all moves TOWARD decline.

| id | grade | one line |
|---|---|---|
| **F-B1R2-1** | **CONFIRMED-MISCOMPILE** (plain C, 2 TUs; root cause PRE-EXISTING, rail customer NEW) | the rail ladder is asked with ROUND-1 taint while `lowerRotations` decides chained-vs-source with FINAL taint — a `cq_theta` whose arg-0 becomes tainted only at `repropagateControlMerges` is a SOURCE theta to the fence and a CHAINED one to the lowering, so F-1b-1's sibling-Ry fence is vacuous in that window |
| **F-B1R2-2** | DOC | the fix's in-source reason for not collecting FORWARD wire names is stated for `gateIsHarmless`' **leg 1** only; the **leg-2 barrier** accept (a per-trip re-minted rail, measured) needs a different argument, which I give and which holds |
| **F-B1R2-3** | DOC | `railWireNamesBackward`'s stop at the first non-theta tainted parent rests on "its operands are OTHER rails", which is a fact about **M-C's G6/G7 in another file**, not about the closure — same species as round 1's F-B1R1-3; measured true today, needs a written retirement trigger |
| **F-B1R2-4** | LEAK (PRE-EXISTING, not B.1's) | a DEAD chain hanging off `%out` or off a borrowed condition register is emitted forward and left allocated with no `_unc`; identical on the compare twin |
| **F-B1R2-5** | DOC | the `RailLadderProven` tripwire is correct and, measured from all three callers, unreachable today; one sentence is owed to B.2 at `SwapRouteEmit.cpp:590` |

---

## 0. What I ran, and only that (Rule 19)

* **76 fresh adversarial programs** — `review_b1_r2_probes/`: `c/` **26** plain-C programs at
  `clang -O1`, `ll/` **47** hand-IR modules, `multi/` **3** two-TU programs run through the shipped
  6.5 recipe (per-TU `-O1` IR → `llvm-link` → ONE `cq-lowering`). Runners `run_corpus.sh`-style:
  `run.sh [PRE|POST]` and `run_multi.sh [PRE|POST]`. Each probe: (clang) → `cq-opt -passes=cq-lowering`
  → `tools/free_pairing_check.py` (stage 2b, STRICT) → link → run.
  `POST` = `build/ir-pass/{cq-opt,libCQPass.so}` (checkpoint + fix); `PRE` = the saved pre-B.1 pair.
  Verdict tables: `VERDICTS_PRE.txt` / `VERDICTS_POST.txt` (the 73 single-TU probes).
  Measured delta, `join`ed from those two files:
  * **35 movers, every one DECLINE → ACCEPT**,
  * **6 accept on BOTH**, and all six lowered modules are **byte-identical** below the module header
    (`diff <(tail -n +4 PRE) <(tail -n +4 POST)` empty for all 6),
  * **32 decline on BOTH**,
  * **0 accept → decline.**
* **Whole-corpus differential, run by me** (`corpusdiff.sh`, `CORPUS_MOVERS.txt`) — `cq-opt` on
  **every** one of the 1765 `ir-pass/test/*.ll` on both binaries, comparing return code, stderr and
  stdout: **`SCANNED=1765 MOVERS=23`**. All 23 are files of the new B.1 family:
  15 `control_swap_select_rail_*` (RCDIFF 1→0, the capability), 7
  `control_swap_reject_select_rail_*` (DIAGDIFF only — the ladder's string replacing
  `bare i1 register condition`), and **1** `control_phase_kickback_reject_rail_measured_parent_name`
  (**RCDIFF 0→1** — the fix's own kickback-side widening, an ACCEPT on `main` and a DECLINE now).
  **The other 1742 fixtures are 0 RCDIFF · 0 DIAGDIFF · 0 OUTDIFF.** That is the decline-monotonicity
  statement the fix needed, and it covers the shared helper's two kickback callers as well as the select.
* **`lit ir-pass/test --filter 'rail'`** → 1765 discovered, **118 selected, 118 PASS**, 5.2 s; and
  **`--filter 'control_phase_kickback_rail_|control_phase_nest_rail_'` → 17 selected, 17 PASS**, 1.8 s.
  **Every pre-existing kickback / nest rail ACCEPT fixture is unaffected by the widened helper.**
  (Run from `build/` and from the source root; both green here.)
* I did **not** run the full `ctest` and make no claim about it.

---

## 1. The fix, re-derived and attacked

### 1a. `railWireNamesBackward` — the closure is the right one, and it is exact

The walk follows ONE edge: a `cq_theta_*` call whose arg-0 is in `Taint.Tainted` steps to that arg-0.
That is character-for-character `RotationLowering.cpp`'s own `Chained = taint.Tainted.count(Op)`
(line 231), which is the relation that makes the whole chain RAUW onto one handle. So on the
assumption that the two are asked with the SAME taint set the closure is exactly the wire — and
F-B1R2-1 below is precisely the failure of that assumption.

Compared clause-by-clause with `WireWalk::collectWireValues` (rung (iii)'s closure), as the brief asked:

| clause | `collectWireValues` | `railWireNamesBackward` | verdict |
|---|---|---|---|
| `cq_phi_` arg-0 hop | crossed | not crossed | **vacuous** — the `@cq_phi_<sfx>` family is retired (3qlq Inc 1); `StringRef("cq_phi").starts_with("cq_phi_")` is false |
| chained theta, arg-0 is a theta/phi CALL | crossed | crossed (that arg-0 is tainted) | equivalent |
| chained theta, arg-0 TAINTED but not a call | not crossed here (`collectWireValues` is deliberately narrow — bd r903) | **crossed** | the fix is WIDER, and correctly so: this is `findNonDiagonalWireGate`'s F-1b-1 edge |
| FORWARD in-place gates on arg-0 | walked | not walked | F-B1R2-2 — sound, argument below |
| phi / select ROUTING edges | walked when `CrossValueRouting` | not walked (the phi/select is COLLECTED then the walk stops) | safe: collecting the parent is what matters for a measure; entering it would over-decline |
| in-place `add`/`xor` self-update | crossed | not crossed | F-B1R2-3 — safe today by M-C's G6/G7, measured |

The three closures in play (`collectWireValues`, `findNonDiagonalWireGate`'s per-seed backward closure,
and now `railWireNamesBackward`) are therefore three different sets with three different jobs, and the
fix's header says so. That is the 8h7d.5 F-1/F-3 discipline honoured, not violated.

**The STOP at a non-theta tainted parent is CORRECT, and I measured both directions.** A theta chained
on a template/cast result rides that result's FRESH rail, so the parent name IS the register — probes
`a04` (measure of an out-of-place `xor` result → DECLINE), `a06` (measure of a `trunc` result →
DECLINE), `f01` (measure of a 4.4 `%out`-derived `trunc` → DECLINE), `f02` (a const-global QROM read
parent → DECLINE), `f04` (a loop-carried PHI parent → DECLINE), `i05` (a chained GRANDparent →
DECLINE). The parent's own OPERANDS are a different register, and measuring one must NOT decline —
`a05` (the xor's source), `a07` (the trunc's i32 source), `a08` (the middle of a depth-2 cast chain),
`f12` (an unrelated second rail): all ACCEPT, all argued below.

### 1b. The unitary, re-derived independently

For every accepted probe the emitted stream is the shipped §5a merge with the flag replaced by a
CNOT copy. Per basis branch of the register, writing its state `Σ_x α_x |x⟩_b`:
mint `bf=|0⟩`; `cnot(b,bf)` gives `Σ α_x |x⟩_b|x⟩_bf` (a CONTROL use is diagonal on `b`, and `b`
stays live so Rule 8 has no subject); `copy_c(bf,T,out)` writes `T` iff `x=1`; `x(bf);
copy_c(bf,F,out); x(bf)` writes `F` iff `x=0` — exactly one write per branch into a fresh `|0⟩`;
`cnot(b,bf)` returns `bf` to `x⊕x=0` on every branch, so its `cqrt_free` is a proven-`|0⟩` free
(Rule 6). Net `|b⟩⊗|b?T:F⟩`. Confirmed on the flagship (`a01`, 15 lines, byte-for-byte the shipped
golden) and at i1/i64/f64 widths (`c06`, `g05`, and `control_swap_select_rail_i1_data.ll`).

The composition cases I attacked and could not break, each argued from that state vector:

* **`d02` — TWO selects on ONE rail with a chained theta BETWEEN them** (the brief's item-1 question,
  "provably after this select yet stale for a LATER one"). ACCEPT, and it is right: for select 1 the
  theta is `gateIsHarmless` leg 1 (Sel dominates it, it cannot reach Sel) so the copies read the
  pre-`.3` label; for select 2 the SEED is `%b2` and the theta is its own ANCESTRY, hence EXEMPT, so
  the position-free walk is clean and the copies read the post-`.3` label. Emitted:
  `ry(h0,.5); [merge 1]; ry(h0,.3); [merge 2]` — source order, two different labels, each read where
  the source names it. `d03` (both selects before the theta) and `d04` (select → kickback → theta)
  likewise.
* **`c01`/`c03` — MIXED trees (a rail leaf AND a compare leaf).** The two seed sets do not leak into
  each other: a theta on the RAIL's wire after the select is the DT-prong accept (`c01`), a theta on
  the COMPARE's register after the select is the position-free decline (`c02`). `c03` is the sharp
  one — the compare's operand is `zext b`, i.e. the SAME register through an out-of-place copy — and
  the emitted `toffoli(h0, h2, h3)` has two perfectly-correlated controls, so `g = b∧b = b`, which is
  what `b && ((int)b == 1)` means. No `cqrt_x` lands on `h0`.
* **`g08` — the rail is BOTH condition and true arm** (bd big5 CASE A): `copy_c(bf, h_b, out)` is a
  Toffoli over two DISTINCT wires, giving `out = x ⊕ (¬x∧c)` = `b ? 1 : c`. Correct.
* **`i08` — nested rail selects** (the first `%out` is the second's arm); **`b06`** (`%out` feeds a
  live chain, M-C fires in place on `%out` and the source never reads the pre-op value again);
  **`h04`** (`%out` escapes by `ret`, nothing freed but the flag); **`h03`** (K=32 rolled loop:
  64 `alloc_i1` / 32 `free` / 64 `cnot` / 64 `cqrt_x` / 32 `ry_i1` / 64 controlled copies — exactly one
  mint-and-free per activation, nothing accumulating across the back edge).
* **`a11`/`a17` — the leg-2 barrier accept**: a rail RE-MINTED per trip, a forward theta after the select
  and its measurement in the same body. ACCEPT, and correct: each trip allocates a fresh `h`, so the
  measurement of trip *k* cannot reach trip *k+1*'s control read. Trace: 3 × 16 lines, 3 independent
  registers.

---

## 2. F-B1R2-1 — CONFIRMED SILENT MISCOMPILE
## the rail ladder runs ONCE, with ROUND-1 taint; `lowerRotations` decides with FINAL taint

### The mechanism, derived from the source

Two predicates ask the same question about the same edge and are evaluated at two different times:

* `RotationLowering.cpp:231` — `Chained = taint.Tainted.count(Op)`. This decides whether a
  `cq_theta` is lowered IN PLACE on its arg-0's rail (one handle for the whole chain) or mints its own
  `cqrt_alloc`. It runs at `lowerRotations`, i.e. **after** `repropagateControlMerges`.
* `WireWalk.cpp`'s `findNonDiagonalWireGate` backward closure —
  `(Taint && Taint->Tainted.count(Arg0))`, the F-1b-1 widening — and, since this fix,
  `railWireNamesBackward`'s identical test. Both run inside `detectControlRegions`, i.e. at **round 1**.

`repropagateControlMerges` is not a taint touch-up: it re-seeds forward propagation from
`taint.UntaintedMergeRails` (the 6.5 classical-call-arm and 4.5 data-mux `%out` rails). The emitters
insert `%out` ITSELF into `taint.Tainted` (so `materializeCopySource` treats it as a handle — measured,
`e14`/`e15`), but everything DERIVED from `%out` becomes tainted only in that later round. So there is a
window in which a value `%x` is classical to the fence and quantum to the lowering.

In that window a `cq_theta_i1(%x, θ)` is a **SOURCE** theta to the fence — the backward closure stops
at it, its SIBLING is off the closure, and rung (iii) is clean — and a **CHAINED** theta to
`lowerRotations`, which puts it and its sibling on ONE rail. The condition's control read then lands
after BOTH rotations.

### The program (plain C, two TUs, the shipped 6.5 recipe) — `multi/e16_{caller,lib}.c`

```c
int ext_f(int a);                       /* e16_lib.c: { return a + 100; }  */
int slice(void) {
    int q = 3;  q = cq_theta(q, 0.5);
    int y = 5;
    if (q > 5) y = ext_f(7);            /* 6.5 classical-call arm -> %out   */
    int keep = cq_measure(y);           /* keeps %out live as an i32 phi    */
    bool x  = (y != 0);                 /* CLASSICAL at round 1             */
    bool b  = cq_theta(x, 0.25);
    bool b3 = cq_theta(x, 0.9);         /* SIBLING on the same wire         */
    int a = b ? 2 : 5;                  /* the rail select reads `b`        */
    return cq_measure(a) + cq_measure(b3) + keep;
}
```

* **PRE** (`main` 87d0699): `rc=1`,
  `cq controlled lowering: bare i1 register condition under quantum control`.
* **POST** (this tree): **`rc=0`**, stage 2b `2 verified, 0 violation(s), 0 unproven`, links and runs.
  Emitted (the relevant six lines of 28):

```
cq_template_icmp_ne_i32_hl(h2, 0) -> h5     <- %x's rail
cqrt_ry_i1(h5, 0x1p-2)                      <- b  = θ(x, 0.25)
cqrt_ry_i1(h5, 0x1.ccccccccccccdp-1)        <- b3 = θ(x, 0.9)   ** SAME RAIL **
cqrt_alloc_i1(0) -> h6
cqrt_cnot(h5, h6)                           <- the select's control read
...
```

The select's condition is `b`, i.e. `Ry(0.25)|x⟩`. The emitted copies are controlled on
`Ry(0.9)·Ry(0.25)|x⟩`. **A different unitary, at `opt` exit 0, verify-clean and STRICT-stage-2b clean.**
`opt` prints a `warning: cq rotation lowering: non-diagonal gate over a live derived record` and
proceeds — that warning is the M-A live-record diagnostic, downgraded from `DS_Error` by owner ruling
bd `lyyf`, and its own file-scope comment says it is **not a backstop**.

### It is the F-1b-1 class, and the discriminators prove the cause is the taint window

| probe | what it changes | PRE | POST |
|---|---|---|---|
| `ll/e04` | the same shape in hand IR (`trunc` of the 6.5 `%out`) | `bare i1 register condition` | **ACCEPT**, `ry(h5,.5); ry(h5,.9); cnot(h5,bf)` |
| `ll/e05` | **CONTROL** — identical module with `%x = trunc %q` so `%x` is tainted at ROUND 1 | `condition predates a non-diagonal gate` | **`condition predates a non-diagonal gate`** |
| `c/e03` | the plain-C spelling of the round-1 control | decline | decline |
| `ll/e11` | **DISCRIMINATOR** — the seed is an opaque classical bit that STAYS classical | decline (1b-B) | **ACCEPT, and CORRECT**: two `cqrt_alloc_i1` and two separate registers |
| `ll/e07` | the sibling AFTER the select | decline | ACCEPT — same defect on the *measurement* instead of the control |
| `ll/e06`, `c/e02` | the MEASURE form of the same window (rung (ii) instead of rung (iii)) | decline | **ACCEPT** with `measure` on the register the copies then control on |

`e05` and `e04` differ ONLY in where `%x` comes from; at `lowerRotations` time they are the SAME
physical situation, and the pass declines one and lowers the other. That is the whole finding.

### It is PRE-EXISTING for the compare path — measured, not argued

| probe | spelling | PRE | POST | module diff |
|---|---|---|---|---|
| `ll/e08` | the compare twin (`icmp eq %b, 1` on an i32 `%out`) | **ACCEPT** | **ACCEPT** | **byte-identical** |
| `multi/e13` | the same in **plain C, two TUs** | **ACCEPT**, 26 lines | **ACCEPT**, 26 lines | **byte-identical** |
| `ll/e15` | a rail-independent compare over a `%out` arm | ACCEPT | ACCEPT | byte-identical |

`e13`'s emitted stream is `ry(h2, 0.25); ry(h2, 0.9); cq_template_icmp_eq_i32_hl(h2, 1) -> h5` — the
flag minted from the post-`0.9` register while the source compares `%7`, the post-`0.25` one.
**So `main` b00fdc2 miscompiles this class today through the 4.4 compare select, from plain C.**
The kickback spelling (`ll/e09`) and the `icmp eq i1` spelling (`ll/e10`) decline on both binaries for
unrelated structural reasons, so I did not establish the window for those two consumers.

**Why nothing catches it.** `declineStaleRecordOps` sweeps PURE ops and deliberately EXCLUDES
select-condition compares (`inLowerOpsScope`; the gate-2c header says so outright: "there is NO
backstop"); by its round-2 re-sweep the compare has already been erased by `emitSelectRegion`. For the
rail spelling the stale consumer is not an op at all — it is the emitter's own `cqrt_cnot`. Stage 2b
sees perfect rail pairing. The golden byte-diff would record a self-consistent stream.

### Fix options (decline-monotone; the choice is the owner's)

1. **Re-verify, do not re-derive** — the bd `eqpx` (1b) tripwire pattern, which this project already
   ships: record `(Rail, ReadPoint)` for every EMITTED rail region and re-ask rungs (ii)+(iii) with
   FINAL taint after the round-2 fixpoint, declining loudly (never a silent fallback). Exactly targeted,
   costs no accept.
2. **Refuse the window at classify time** — decline a rail leaf whose backward closure stops at an
   arg-0 that is a (transitive) user of a `taint.UntaintedMergeRails` member, i.e. a value round 2 will
   taint. Cheap, monotone, costs nothing measured in my corpus.
3. **Treat any non-`Constant` arg-0 as chained for closure purposes** (one line, both closures).
   Monotone but blunt: it costs `e11`'s opaque-classical-seed accept.

Whichever is chosen, **widen BOTH rungs together** (`railWireNamesBackward` and
`findNonDiagonalWireGate`'s `Taint` test) — the 8h7d.5 F-1/F-3 lesson, which this very round is an
instance of — and file the compare/kickback halves as their own bd, since they miscompile on `main`.

---

## 3. Secondary findings

### F-B1R2-2 — DOC: the "no FORWARD names" justification covers leg 1 only

`railWireNamesBackward`'s header says forward names need not be collected because "a measurement of one
that precedes the read point implies that theta precedes it too, which rung (iii) already refuses as a
non-diagonal gate between the def and the read." That is exactly right for `gateIsHarmless` **leg 1**,
and I re-derived it: if leg 1 accepted, `!isPotentiallyReachable(T, Sel)`, and any measure `M` of `T`'s
result is dominated by `T`, so a path `M → Sel` would give `T → M → Sel` — contradiction. Measured:
`ll/j02` (the forward name defined and measured before the select) declines
`condition predates a non-diagonal gate`.

It is **not** the argument for **leg 2**, the barrier accept, where `T` CAN reach the select. The
correct argument there is: leg 2 accepts only when every path `T → Sel` executes a BARRIER (the seed's
own definition, or a superseding wire-tracking phi), and any measure of `T`'s result lies on such a
path, so the barrier — the seed theta re-executing — sits between the measurement and the control read.
Measured: `c/a11` and `c/a17` (a per-trip re-minted rail; 3 independent registers, 48 and 45 trace
lines) and `ll/j01`. One sentence at the helper closes it.

### F-B1R2-3 — DOC: the stop rule's ground is another file's fence

The header says the non-theta tainted parent is "COLLECTED and not entered — its own operands are OTHER
rails (an out-of-place template mints a fresh rail)". That is a statement about **M-C**, not about this
closure: if `ArithLowering::classifyInPlaceReassignment` ever fired on such a parent, the parent's own
operand would share the wire and the closure would stop one hop short. It **cannot** today, and I
measured why rather than assuming: G6 refuses any later data use of the parent and G7's
`priorUseIsSettled` refuses a prior `cq_measure` (it is a non-void, non-`_unc`, non-in-place call with
no `Zeroed && Released` witness), so a measured parent is ALWAYS lowered out of place —
`c/a09` (`cq_measure(b0)` before `x = b0 ^ 1`) emits `cq_template_xor_i1_hl(h0,1) -> h1`, a fresh rail,
and accepts correctly. This is the same species as round-1 item F-B1R1-3: give it the same written
retirement trigger ("if M-C ever admits an in-place op on a rail with a measured parent, this closure
must enter the parent").

### F-B1R2-4 — LEAK (PRE-EXISTING, not this increment's)

A DEAD chain hanging off `%out` or off a borrowed condition register is emitted FORWARD and left
allocated with no `_unc` and no free: `ll/b07` emits `add_hl(h2,3)->h5; mul_hl(h5,7)->h6;
add_hl_unc(h5,h2,3); free(h5)` and leaves `h6` dirty; `ll/d01` emits `zext(h0)->h5; addc(h5,1)` and
leaves `h5` dirty. Rule-6 safe (nothing is freed dirty) and stage-2b clean. **The compare twins behave
identically** — `ll/b08` and `ll/i01`, byte-for-byte the same disposition — so this is the whole-DAG
spine's pre-existing accounting, not the rail path's. No action for B.1.

### F-B1R2-5 — DOC: the `RailLadderProven` tripwire is right, and unreachable today

The flag is set only at `classifySelectRegion`'s ACCEPT and asked in `emitSelectRegion` BEFORE any
emission (detect-before-mutate), with the original `kBareRailCondReason` string. I re-derived the
reachability of all three callers and then measured it:

| probe | shape | PRE | POST |
|---|---|---|---|
| `ll/b01` | value arm under a BARE rail condition | `bare i1 register condition` | `bare i1 register condition` |
| `ll/b02` | value arm under a COMPOUND rail condition (`xor i1 %b, %c`) | `control flow` | `control flow` |
| `ll/b03` | all-constant data mux under a bare rail branch | `bare i1 register condition` | `bare i1 register condition` |
| `ll/b04` | 6.5 classical-call arm under a bare rail branch | `bare i1 register condition` | `bare i1 register condition` |

`classifyArms` (`ArmClassify.cpp:2212`) and `classifyClassicalCallArm` (`:4633`) both require
`isa<CmpInst>(Region.Condition)` before anything else, so no rail can reach `emitValueRegion` or
`ClassicalCallArmEmit`. The flag also cannot go stale across `repropagateControlMerges`:
`detectAndLowerOnwardControl` builds a **fresh** `ControlPlan` per round and re-runs
`classifySelectRegion`, and a round-1 select is ERASED by its own emitter
(`SelectMergeEmit.cpp:304-306`), so no region is ever emitted from a plan built in another round.
The one thing owed is a sentence at `SwapRouteEmit.cpp:590` carrying the precondition into B.2's brief,
which round 1 already asked for.

---

## 4. Over-declines found (all safe; none needs action for B.1)

* `ll/g06` — the `&&` spelling `select i1 %b, i1 %cmp, i1 false` as a DATA select's condition declines
  `control flow`: `AllowLogicalSelect` is true for the branch phase and false for the 4.4 data select.
  The documented "one grammar, two verdicts" asymmetry, already an owner question.
* `c/h05` — a rail select inside a classically-guarded block declines `control flow`.
* `c/a14` — the parent measured on a classically-guarded SIDE PATH declines on REACHABILITY even when
  the guard is never taken. Inherited verbatim from Inc 1b (OQ-1b-R2-4 / OQ-B1-2).
* `c/h01` — a controlled I/O sink under a rail condition declines
  `cq I/O output sink: conditional output is not a lowerable single-sink if(q) diamond`, so
  `lowerControlledIOSinks` (which runs BEFORE `detectControlRegions` and mints its own flag) never sees
  a rail. Good.
* `ll/i06` — an `i1` quantum ARGUMENT at the specialization boundary declines with the mis-branded
  `floating-point quantum argument or return has no reversible copy`. Identical on both binaries;
  round 1 already recorded it (r45/r46).
* `c/h02` — a `cq_invert` bracket around a rail select is ignored by the pass on both binaries and the
  `__cq_invert_{begin,end}` markers survive to the link. Phase-8, pre-existing.

## 5. Areas probed and found nothing in

* **The network with `CopyRailRoot`** (brief item 3, round 1's thinnest coverage). A shared rail leaf
  inside a tree mints nothing (`FlagOf[V] = V`) and is read only as a control — `c03`, `c05`, `i08`,
  `g08`, and the `xor`-tree accept. `CopyRoot` and tree NODES are mutually exclusive by construction
  (`collectCondTree` returns immediately for a bare rail root). No `cqrt_x` reaches a user register in
  ANY accepted module (I re-checked every accepted trace by eye and by grep: `cqrt_x` only ever names a
  flag or node ancilla). `stripCondNetwork` un-copies the flag FIRST (it was minted LAST) — pinned in
  every trace by `cnot … free` as the last two network lines.
* **The spine** (brief item 4). `bf` is freed exactly once per region and never twice (`h03`: 32 frees
  for 32 activations); `h_b` is never freed by anything (`b05` dead `%out`, `h04` escaping `%out`,
  `d01`/`h06` borrow chains); no `_inv`/`_unc` of a controlled copy is ever emitted; `%out` is left
  allocated in every accept.
* **The round-1 `%out`-as-ARM hazard I expected and did not find.** A rail select whose ARM is a 6.5
  `%out` is emitted at ROUND 1, so I expected `materializeCopySource` to mint
  `cqrt_alloc_i32(<handle>)` — a rail id in a classical slot, the bd `eqpx` shape. It does not:
  the 6.5 emitter inserts `%out` into `taint.Tainted` itself, so `materializeCopySource` returns it
  unchanged. Measured `ll/e14` (rail condition) and `ll/e15` (compare condition): both emit
  `cqrt_copy_i32_controlled(f, %out, out2)` with `%out` as a handle. Correct.
* **Clones.** `lowerCloneSelect`'s rail-tree `continue` is unreachable from two directions: a callee
  containing a `cq_theta_i1` declines `callee contains a quantum primitive (cq_*)` (`ll/i07`) and an
  `i1` quantum argument declines at the boundary (`ll/i06`); and the `buildClone` backstop
  (`Specialization.cpp:934`) declines any surviving TAINTED select loudly, so there is no third path.
* **Unreachable / abort paths.** A measure in an unreachable block (`ll/f06`) and a measure on a path
  ending in `unreachable` (`ll/i04`) do not decline the select — correct, and not over-declines.
* **Stage-2b blindness.** I counted rails dynamically from the traces rather than trusting it
  (`h03`, `a11`, `a17`).

## 6. What round 3 should do

1. Decide F-B1R2-1's scope with the owner: the rail half is B.1's to fix; the compare half is a
   confirmed plain-C miscompile on `main` and needs its own bd and its own Rule-13 round.
2. Whatever fence is chosen, **pin the discriminator pair** (`e04`/`e05` for the rail, `e13`/`e16` for
   plain C, `e11` for the accept that must survive) as fixtures, and re-run the whole-corpus
   differential — a widening of a taint-dependent closure is exactly the shape that moves other
   fixtures.
3. Ask the same question of every OTHER predicate in the pass that reads `taint.Tainted` inside
   `detectControlRegions` and whose answer is consumed after `repropagateControlMerges`. This round
   found two (`railWireNamesBackward`, `findNonDiagonalWireGate`); `RETIRE_SWAP_ROUTE_INC1_NOTES.md` §2
   already owns that table for STAGES, and it now needs a row species for PREDICATES.
4. Assume a sixth thing is here. Round 1 found four items and no miscompile; this round found one from
   the area round 1 explicitly listed as probed-and-clear (§6, "Round 2 (`repropagateControlMerges`)").
   One clean round is not evidence of absence, and neither is one dirty one.
