# Rule-13 round 5 — bd `test_C_libtooling-4jok` — the COMPOSED ACCEPT SURFACE

**Theme:** *the conjunct that is supposed to establish the licence does not; the
postcondition does.*
**Reviewer:** independent, 2026-09-21. I did not write either increment.
**Verdict: `CLEAR-WITH-ITEMS`. P1 count: 0.** Seven findings (1 × P2, 6 × P3).

The headline, and both halves are measured on the hashes in §1:

> **I could not find a silent miscompile in the composition, and I found the
> reason it is safe is NOT the reason the code says it is.** Clause (ii-d)'s own
> comment claims its `loopExitDischargePoint(L)` conjunct establishes the
> placement licence — *"if there is no once-per-mint point, there is no licence,
> and the root is refused"* (`LoopLowering.cpp:4127-4129`). **In a NEST that
> sentence is false**: the clause tests the loop it is MARKING and
> `Uncomputation::anchorForConsumer` places at the OUTERMOST loop enclosing the
> consumer that does not contain the mint. I built the shape where those differ
> (`w3_nest_multiexit_rotq.ll`), and the root is **not** refused — the grant is
> made, the anchor returns `nullptr`, and the ONLY thing between that and a leak
> with conjunct (1) of `declineDephasingUnmarkedLoopRails` already disarmed is
> `declineUndischargedExitObligations`. It fires, correctly and loudly. But the
> load-bearing member is the postcondition, and the comment points at the
> conjunct. That is `CLAUDE.md` L7's shape and bd `xt20`'s shape, one bead over.

Second result, worth as much as the first because it cuts the other way:

> **The composition FIXES a known wrong unitary rather than restoring one.**
> Three of the four D→A corpus movers are `control_phase_kickback_mixed_*_leak_control.ll`
> and `loop_leak_dephase_reject_region_derivedbase_live.ll` — fixtures
> `CLAUDE.md` §5 converted to DECLINES with the words *"the ACCEPT was the
> defect"* and *"do not restore their old `CHECK` prefixes, which pinned the
> leaking stream"*. On COMPOSED they accept, and the stream is **not** the old
> one: `CLAUDE.md` §5 records `3/0 rolled and 3/3 unrolled` for the per-bit `and`
> rails; I measure **3 forwards / 3 adjoints rolled** at trace level, with the
> hoisted `mul` rail discharged once at the loop exit **before** the trailing
> `cqrt_ry_i32`. The old prefixes must not come back; a *new* accept prefix is
> the correct re-derivation, and the distinction is exactly what an agent landing
> this will get wrong.

---

## 1. Binaries, verified before any measurement

```
$ shasum -a 256 build/ir-pass/cq-opt /private/tmp/claude-501/cq-composed/build/ir-pass/cq-opt
8280ea8d86bcaf4ed82cae92f65733fe8ae601086dfb721d58feeda55d8d9da2  build/ir-pass/cq-opt
3368af1262695d7e4c573d3958f0a9aa48e604bf5248e1b85a52362ac76f69dc  /private/tmp/claude-501/cq-composed/build/ir-pass/cq-opt
```

| tag | sha256 | contents |
|---|---|---|
| **MAIN** | `8280ea8d…` | `main` `78b6bf64` — the shipped compiler, **including** Rule-13 round 4's (P4) crash fence |
| **COMPOSED** | `3368af12…` | MAIN + `tu9q` P0+P3 (merge `c24fa34f`) |

Neither binary was rebuilt, relinked or touched. No `ctest`, no `lit`.
⚠ **My pair is not round 3's pair**: round 3's COMPOSED was built on `00c36e93`,
below round 4's (P4) fix. Every number below is re-measured, never quoted — and
where I contradict round 3 I say so (F-7).

The merged code I read: `ir-pass/src/LoopLowering.cpp` clause **(ii-d)** at
`:4189-4196`, its comment at `:4108-4188`, the ledger at `:3910`, the
postcondition `declineUndischargedExitObligations` at `:6073`,
`loopExitDischargePoint` at `:6142`; `ir-pass/src/Uncomputation.cpp`
`multiplicityAgrees` at `:246`, `anchorForConsumer` at `:368`, the postcondition
call at `:2082`.

**Reproduction of the brief's baseline.** All nine composed-only accepts
reproduce on my pair: `opt` exit 0, **stderr 0 bytes (no warning)**, stage-2b
STRICT `0 violation(s), 0 unproven`, link + run OK. `round5/verdict_table.txt`
row-for-row. The owner's own shipped program is the control and is **unmoved**:
`grover_oracle_uncompute.c` lowers to 85 lines / 50 trace lines on both, and
`diff` of the lowered IR (minus `ModuleID`) and of the trace is **empty**
(`rc=0` both).

---

## 2. Findings

| # | sev | finding | probe |
|---|---|---|---|
| **F-1** | **P2** | Clause (ii-d)'s stated licence is **not** what holds. In a nest the conjunct tests one loop and the anchor places at another; the root is granted where the anchor has nowhere to put the discharge. Safety is carried entirely by the postcondition, and the comment says otherwise in so many words. | `w3` + attribution control `w4` |
| **F-2** | P3 | `dephase.py` — the instrument the brief's clearance rests on — is **blind to every entanglement edge that is not a `cq_template_*` mint operand**. It reports "OK" on the three canonical Rule-8 violations and on a **real compiled program** that MAIN itself warns about. | `cnot/copyc/toffoli` controls + `y3` |
| **F-3** | P3 (positive) | The (ii-d) postcondition is non-vacuous on **four** shapes round 3 never reached — a guarded (runtime-trip) loop, an in-loop parent mutation, a non-foldable parent mutation, and the multi-exit nest. Round 3 had one witness. | `z3`, `u1`, `u4`, `w3` |
| **F-4** | P3 | `declineRound2FalsifiedRailGrants` loses its **only** shipped fixture on COMPOSED but is **still reachable**. I wrote the replacement and measured it firing character-for-character on both binaries. | `w1` |
| **F-5** | P3 | The three `*_leak_control` / `loop_leak_dephase_reject_*` D→A movers are a **fix, not a regression** — 3/3 rolled against `CLAUDE.md` §5's recorded 3/0. Their headers and `CHECK` prefixes are owed a re-derivation the landing must not get backwards. | corpus + trace |
| **F-6** | P3 | The merge leaves a comment **in the same file** asserting the opposite of what the merged code does. | `LoopLowering.cpp:7039-7051` |
| **F-7** | P3 | Round 3's F-6 ("the (L3) gap is still empty") **does not reproduce** for `g3` on my pair, and two new constructions reach a **different wall** on COMPOSED. What holds (L3)'s trigger closed is a fence other than the (I1) ground its comment gives. | `g3`, `v1`, `v2` |

---

### F-1 (P2) — the conjunct checks one loop, the anchor places at another

**The claim under attack, verbatim** (`ir-pass/src/LoopLowering.cpp:4122-4129`):

```
    //        THE LICENCE IS **PLACEMENT**, AND IT LIVES IN ANOTHER FILE.
    //        `Uncomputation::anchorForConsumer` (piece P2) discharges such a rail
    //        ONCE, at the loop's unique exit, and `multiplicityAgrees` (piece P1)
    //        refuses every other pairing — including the preheader-gate /
    //        in-body-`At` one this clause would otherwise open. Both halves are
    //        REQUIRED. `loopExitDischargePoint` is the SAME predicate P2's anchor
    //        walk calls (Rule 14, declared in `LoopPlan.h`): if there is no
    //        once-per-mint point, there is no licence, and the root is refused.
```

**The code.** The clause (`:4189-4196`) asks it of `L`, the loop being marked:

```cpp
    if (auto *VI = dyn_cast<Instruction>(V))
      if (!L->contains(VI->getParent()) &&
          mintsOutOfPlaceTemplateRail(VI, taint) &&
          loopExitDischargePoint(L) && allUsersInside(V, L)) {
        RootsOut.insert(Root);
        recordExitDischargeObligation(Root);
```

The anchor (`ir-pass/src/Uncomputation.cpp:369-381`) asks it of `LOut`, the
**outermost** loop enclosing the *consumer* that does not contain the mint:

```cpp
  for (const Loop *L = LI.getLoopFor(U->getParent()); L; L = L->getParentLoop())
    if (!L->contains(R->getParent()))
      LOut = L;  // keep walking: the LAST one that qualifies is the outermost.
  if (!LOut)
    return U->getNextNode();
  BasicBlock *Exit = loopExitDischargePoint(LOut);
  if (!Exit)
    return nullptr;
```

It is the same *predicate*, asked of a **different loop**. `Rule 14` is
satisfied; `CLAUDE.md` **L2** is not — *"when you WIDEN a set, ask what OTHER set
was computed over the same closure"*. The file already carries this exact warning
for the *other* pair in this increment (`markedHeaderOf`'s innermost `LI.getLoopFor`
vs the anchor's outermost `Loop::contains`, stated at both sites, citing bd
`emkg`). **The third quantifier mismatch — which loop's exit — is stated at
neither site.**

**The construction** (`round5/probes/w3_nest_multiexit_rotq.ll`): a nest whose
**inner** loop has a unique exit (`%outerlatch`) and whose **outer** loop has two
exit destinations (`%bailout` from the header, `%out` from the latch); the
hoisted template rail `%m2 = mul i32 %q, 2` is minted outside the whole nest and
read only by the inner body; `%q` is rotated at `%out`. So
`loopExitDischargePoint(inner) != nullptr` (the clause grants and records an
obligation) while `loopExitDischargePoint(outer) == nullptr` (the anchor
abandons).

```
$ "$M" -passes=cq-lowering -S w3_nest_multiexit_rotq.ll -o …/w3m.ll 2>/tmp/w3m.err ; rc=$?
MAIN rc=0 :: cq rotation lowering: non-diagonal gate over a live derived record
$ "$C" -passes=cq-lowering -S w3_nest_multiexit_rotq.ll -o …/w3c.ll 2>/tmp/w3c.err ; rc=$?
COMP rc=1 :: cq loop lowering: hoisted invariant rail admitted for in-loop discharge was
```

**Attribution control** (`w4_nest_singleexit_control.ll` — the identical nest with
the outer loop's second exit removed):

```
MAIN rc=0 ::            (no warning)
COMP rc=0 ::            (no warning)
=== COMPOSED w4: where is the mul _unc placed? ===
10:  %h_op = call i32 @cq_template_mul_i32_hl(i32 %h, i32 2)
32:outerlatch:
38:out:
40:  call void @cq_template_mul_i32_hl_unc(i32 %h_op, i32 %h, i32 2)
41:  call void @cqrt_free(i32 %h_op)
42:  call void @cqrt_ry_i32(i32 %h, double 9.000000e-01)
```

One conjunct of difference — the outer loop's exit-uniqueness, which the clause
never asks about — decides between "granted and correctly placed at the outer
exit before the interference" and "granted with nowhere to place".

**Why this is P2 and not P1 today.** The postcondition catches it, loudly, every
time I could reach it (F-3). The exposure is entirely in the *argument*: the next
agent reads `:4127-4129`, believes the conjunct guarantees placement, and
narrows, moves or drops `declineUndischargedExitObligations` "because the clause
already refuses". The ledger's own header says the postcondition exists because
*"no fence in THIS file can see that outcome"* — that is the true statement, and
the clause's comment 60 lines above contradicts it.

**What I recommend, and it is a wording change plus one measured line, not code.**
(a) Correct `:4127-4129` to say the conjunct is a **necessary** condition asked of
the marked loop and **not** the placement licence, which is established ex post by
the postcondition. (b) Add the `LOut ≠ L` quantifier note the file already gives
for `markedHeaderOf`. (c) Ship `w3`/`w4` as the pair. ⚠ **`w3` is also the
missing fixture tu9q's own `trackT2/IMPL_T3.md` §3 F-R2-1 asks for** — it records
that the genuinely multi-exit path *"is owed a fixture and has none: three C
shapes were built for it and `-O1` renormalised or declined every one … a
PREDICTION rather than a test"*. It is a test now.

⚠ **Read the MAIN column of `w3` before filing anything against the composition.**
MAIN accepts it at exit 0 with `0` occurrences of `cq_template_mul_i32_hl_unc` in
the lowered module and `cqrt_ry_i32(i32 %h, double 9.000000e-01)` standing over the
live record — the bd `s82e` / bd `1m5p` class, carrying the bd `lyyf` **ruled
WARNING**. The composition converts that into a loud decline. On this shape the
composition is strictly stricter.

---

### F-2 (P3) — `dephase.py` cannot see the edges the merge path is built from

`probes/dephase.py` builds `parent[out]` **only** from the handle operands of a
`cq_template_*` mint. Every correlation created by a permutation gate —
`cqrt_cnot`, `cqrt_toffoli`, `cqrt_cswap`, `cqrt_copy_<W>`,
`cqrt_copy_<W>_controlled`, `cqrt_x_controlled` — produces **no ancestry edge**.
Those gates are exactly how the 4.4/4.5 value-merge and the rail-root CNOT copy
build their rails, so in `o1_owner_plus_hoisted` the merged rails `h9`, `h16`,
`h23` and the flag ancillas `h8`, `h15`, `h22` all have **empty ancestry** under
it.

Verbatim, the three canonical Rule-8 violations:

```
=========== dephase.py (the orchestrator's instrument) ===========
cnot_record      mints=  2 uncs=  0 frees=  0 left-allocated=['h0', 'h1']
    OK: no multiplicity, no double-free, no live record across any Ry or measure
copyc_record     mints=  3 uncs=  0 frees=  0 left-allocated=['h0', 'h1', 'h2']
    OK: no multiplicity, no double-free, no live record across any Ry or measure
toffoli_record   mints=  3 uncs=  0 frees=  0 left-allocated=['h0', 'h1', 'h2']
    OK: no multiplicity, no double-free, no live record across any Ry or measure
dephase rc=0
=========== entangle.py (round 5) ===========
cnot_record      !! L5: RY on h0 (dep=[0]) with LIVE entangled rails ['h1']
copyc_record     !! L6: RY on h0 (dep=[0]) with LIVE entangled rails ['h1']
toffoli_record   !! L6: RY on h0 (dep=[0]) with LIVE entangled rails ['h2']
```

⚠ **And it is not a synthetic gap.** `y3_rot_merged_unrolled.c` is a real program
that compiles on BOTH binaries; `dephase.py` calls it clean and `entangle.py`
flags it:

```
$ python3 probes/dephase.py y3_rot_merged_unrolled.trace ; echo rc=$?
y3_rot_merged_unrolled  mints= 21 uncs=  7 frees= 10 left-allocated=[…]
    OK: no multiplicity, no double-free, no live record across any Ry or measure
dephase rc=0
$ python3 round5/probes/entangle.py --quiet-controls y3_rot_merged_unrolled.trace ; echo rc=$?
    !! L70: RY on h20 (dep=[4, 7, 10, 11, 12, 13, 15, 16, 17, 19, 20]) with LIVE
           entangled rails ['h4', 'h7', 'h11', 'h14', 'h16', 'h17', 'h18']
entangle rc=1
$ cat y3_rot_merged_unrolled.opt.err
warning: <unknown>:0:0: in function slice i32 (i32): cq rotation lowering:
         non-diagonal gate over a live derived record
```

**The compiler itself warns about the very thing `dephase.py` says is not
there.** `y3` is identical on MAIN and COMPOSED (114 lines both) and is the bd
`lyyf` ruled-and-warned class, so it is not a composition finding — it is the
proof that the instrument's blind spot is reachable from C.

**This does not overturn the brief's clearance; it re-establishes it on a
stronger instrument.** I re-ran everything with `round5/probes/entangle.py`,
which records those edges (XOR/symmetric-difference for linear gates so an
exactly-paired CNOT bracket cancels, UNION for non-linear ones), models a
measurement as a projection (the project's own `declineUndischargedMarkedBodyRails`
clause (b) reasoning), and adds an **adjoint-operand-identity** axis neither
`dephase.py` nor the golden byte-diff asks:

```
### COMPOSED rc=1 traces=26
   y3_rot_merged_unrolled ->  !! L70: RY on h20 … with LIVE entangled rails […]
### MAIN rc=1 traces=15
   y3_rot_merged_unrolled ->  !! L70: RY on h20 … with LIVE entangled rails […]
   z3_guarded_measloop    ->  !! L6:  RY on h1  … with LIVE entangled rails ['h2']
```

**26 composed traces, ONE Rule-8 finding, and it is the loop-free program that is
byte-identical on MAIN and carries the compiler's own warning.** MAIN has a
second (`z3`) which COMPOSED declines. **No Rule-8 finding is attributable to the
composition.** 18/18 boundary controls pinned on every invocation, including two
null controls (an empty trace is reported VACUOUS, not clean; a classical trace
never fires) and an `UNCLASSIFIED trace line` refusal so a new `cqrt_*` symbol
cannot be silently guessed.

---

### F-3 (P3, positive) — the postcondition fires on four shapes round 3 never reached

Round 3's only witness for `declineUndischargedExitObligations` was `j2`. I
reached it four more ways, each a different mechanism:

| probe | shape | MAIN | COMPOSED |
|---|---|---|---|
| `z3_guarded_measloop` | **runtime trip bound** ⇒ `-O1` zero-trip guard; forward gate before the guard, discharge at the loop exit | ACCEPT, `warn=1`, `3 template rail mint(s) of which 2 left dirty` | `kMsgExitObligation` |
| `u1_parent_mutated_inloop` | the rail's **parent relabelled in-loop** (`q ^= 1`) | ACCEPT, 2 left dirty | `kMsgExitObligation` |
| `u4_parent_xor_index` | parent relabelled by a mutation `-O1` **cannot close-form** (`q ^= i`, K=1000) | ACCEPT, 2 left dirty, 9007 trace lines | `kMsgExitObligation` |
| `w3_nest_multiexit_rotq.ll` | **multi-exit outer loop** in a nest (F-1) | ACCEPT + `lyyf` warning | `kMsgExitObligation` |

`z3` is worth a sentence of its own because it is the hazard I set out to find
and the compiler got right. MAIN's `z3` trace, run with one trip **zero** trips:

```
1  cqrt_alloc_i32(7) -> h0
2  cqrt_ry_i32(h0, 0x1.3333333333333p-2)
3  cqrt_alloc_i32(4) -> h1
4  cqrt_ry_i32(h1, 0x1p-1)
5  cq_template_shl_i32_hl(h1, 1) -> h2      <-- the hoisted rail, minted
6  cqrt_ry_i32(h1, 0x1.ccccccccccccdp-1)    <-- the interference, h2 STILL LIVE
7  cqrt_measure_i32(h1) -> 0
```

The forward gate is before the guard and runs; the loop-exit discharge is on a
path not taken; **one forward gate, zero adjoints, a live record across the Ry**.
That is the path-dependent leak a golden (one trip count per run) and a
K-independence check cannot see. MAIN compiles it with the `lyyf` warning;
**COMPOSED declines.** Its fixed-trip control `z4` accepts on both, and there the
composition discharges strictly more (`3 mints / 1 left dirty` → `3 mints / 0
left dirty`, 16 → 20 trace lines, the extra six lines being the per-trip
`ashr_unc` + `free` pairs).

---

### F-4 (P3) — the L1 fence loses its only fixture but not its reachability

`loop_pairing_reject_round2_falsified.ll` is the **only** shipped fixture of
`declineRound2FalsifiedRailGrants`, and it moves D→A on COMPOSED (tu9q's own
declared mover #7). I checked two things round 3 did not.

**(a) The accept is sound.** The fixture's header predicts that leaving the grant
standing is *"K adjoints against ONE forward gate — an over-reversed rail, a wrong
unitary, not a leak"*. Measured on COMPOSED, it is not: the forward
`cq_template_mul_i32_hl(i32 %out1, i32 2)` is in `entry` (once) and the adjoint
`cq_template_mul_i32_hl_unc(i32 %h_op, i32 %out1, i32 2)` + `cqrt_free` are in
`out`, the loop's unique exit (once). **P2's anchor is what makes the accept
defensible**, exactly as the clause intends. The header's prediction was correct
*for a tree without P2*.

**(b) The fence is still reachable.** I wrote
`round5/probes/w1_round2_falsified_readafter.ll` — the same module with `%m2`
**also read after the loop**, so (ii-d)'s `allUsersInside` conjunct is false and
the round-2 re-derivation cannot rescue the round-1 grant:

```
MAIN rc=1 :: cq loop lowering: round-1 iteration-local marking falsified by round-2 tain
COMP rc=1 :: cq loop lowering: round-1 iteration-local marking falsified by round-2 tain
```

Character-for-character, on both binaries. **The landing owes this file** (or one
like it); without it the fence becomes a prediction again (`CLAUDE.md` L10), and
`declineRound2FalsifiedRailGrants` is an L1 cure, which is the class this project
keeps losing to.

---

### F-5 (P3) — the leak-control movers are the fix, and the re-derivation is easy to get backwards

Three of the four D→A corpus movers are fixtures `CLAUDE.md` §5 converted to
declines in terms that read like a prohibition:

> *"**That sentence is false for those programs.** … All three are converted to
> declines by bd `s82e`; **do not restore their old `CHECK` prefixes, which
> pinned the leaking stream.**"*

Measured on COMPOSED, the accept is **not** the old stream. Structurally
(`control_phase_kickback_mixed_hoisted_template_leak_control.ll`, lowered):
`%h_op = cq_template_mul_i32_hl(i32 %h, i32 3)` in the preheader; in body block
`%4`, `%h_op2 = cq_template_and_i32_hl(i32 %h_op, i32 %6)` **and**
`cq_template_and_i32_hl_unc(i32 %h_op2, i32 %h_op, i32 %6)` + two `cqrt_free`;
in exit block `%2`, `cq_template_mul_i32_hl_unc(i32 %h_op, i32 %h, i32 3)` +
`cqrt_free(i32 %h_op)` **before** `cqrt_ry_i32(i32 %h, double 9.000000e-01)`.
At trace level, linked and run:

```
### control_phase_kickback_mixed_hoisted_template_leak_control : 40 lines
  and forwards=3  and adjoints=3
### control_phase_kickback_mixed_short_sext_leak_control : 40 lines
  and forwards=3  and adjoints=3
entangle.py: OK: no dirty free, no UAF, no multiplicity, no entangled rail live
             across any uncontrolled Ry      (left-allocated = ['h0','h1'] only)
```

`CLAUDE.md` §5 records these as `3/0 rolled and 3/3 unrolled`. They are now
**3/3 rolled**, i.e. the rolled form matches its twin. **The landing owes new
headers and new `CHECK` prefixes**, and the §5 sentence must be re-read rather
than obeyed literally: the instruction is against the *old* prefixes because they
pinned the *leaking* stream, not against an accept prefix over the *discharging*
one. ⚠ Their L8 triggers are due, and — protocol item 2, for the fifth time in
this bead's history — the triggers name a wall that is no longer the next one.

---

### F-6 (P3) — the merge leaves a comment contradicting its own file

`/private/tmp/claude-501/cq-composed/ir-pass/src/LoopLowering.cpp:7039-7051`,
untouched by the merge (`git diff 78b6bf64 HEAD -- ir-pass/src/LoopLowering.cpp`
does not mention it):

```
      // ever BE that preheader gate. A hoisted loop-invariant TEMPLATE rail
      // (`int p = q * 3;`) is exactly what (I1) admits and is exactly what clause
      // (ii) refuses; it is UNCHANGED here and still leaks (still declines, under
      // bd `s82e`). Widening clause (ii) to it needs the real multiplicity test
      // `Uncomputation.cpp:982-1000` specifies, and is NOT part of this change.
```

Clause **(ii-d)** at `:4189` of the same file is that widening. `CLAUDE.md` L7's
twist is explicit that *a record correction not applied at the source is not a
correction*, and this is the cheaper version: a source comment that was true
before the merge and false after it, 2800 lines from the code that falsifies it.
Fix it in the landing commit, not afterwards.

---

### F-7 (P3) — round 3's "(L3) gap is still empty" does not reproduce

Round 3's F-6 concluded the (L3) retirement trigger (*"the day a bank cell can
hold a TEMPLATE-minted rail"*) is still un-fired, with `g3`, `g5` recorded as
*"never reach the bank question (earlier walls, same on all four)"*. Re-measured
on my pair:

```
g3_bank_mixed_one_loop|MAIN|DECLINE(1)|cq loop lowering: rolled body leaks a rail entangled with a ro
g3_bank_mixed_one_loop|COMPOSED|ACCEPT|ll=87 tr=34 warn=0 2b=0 [6 verified, 0 violation(s), 0 unproven] [3 template rail mint(s) of which 0 left dirty]
```

**`g3` is a MAIN→COMPOSED accept**, i.e. a tenth member of the surface round 3
tabulated as nine. Its stream is clean under `entangle.py` (`left-allocated =
['h0']` — only the user's own register; every rail discharged).

Two new constructions that write a bank cell from the **hoisted template rail**
(which is (ii-d)'s subject, where round 3's five all wrote from `q` directly)
reach a **wall that does not exist on MAIN**:

```
v1_bank_cell_from_hoisted|MAIN|DECLINE(1)|cq loop lowering: rolled body leaks a rail entangled with a ro
v1_bank_cell_from_hoisted|COMPOSED|DECLINE(1)|cq rail bank: cell type rewrite failed on a proven bank
v2_bank_cell_xor_hoisted |MAIN|DECLINE(1)|cq loop lowering: rolled body leaks a rail entangled with a ro
v2_bank_cell_xor_hoisted |COMPOSED|DECLINE(1)|cq rail bank: cell type rewrite failed on a proven bank
```

Both decline — the safe direction, nothing to file against the unitary. **The
item is the ground.** (L3)'s comment says the exemption rests on
`isInteriorTerminalHandle` **(I1)** ("every rail a bank can hold today IS
alloc-minted"). On COMPOSED these modules get past the `s82e` wall and are stopped
by `rewriteRailBankCellTypes` instead — a **different, contingent** fence. That is
`CLAUDE.md` L7's shape and precisely what bd `xt20` records for (P1): *a closure
that holds today for a reason other than the stated one*. (L3)'s own trigger says
*"Re-derive this exemption then"*; on the composed binary it is due.

---

## 3. What I attacked and did NOT find

*"No finding" without the list is worthless.* Every row below is measured on the
two hashes in §1.

**Systematic.**

1. **2109-fixture corpus A/B, MAIN vs COMPOSED**, recording exit code, first
   diagnostic, a sha-256 of the lowered stdout, **and CRASHES as a separate
   bucket** (round 3's sweep buckets every non-zero exit as a decline and could
   not have seen round 4's exit-134 class). `round5/probes/corpus5.py`, with
   three boundary controls run before the first real measurement — both binary
   hashes, a **NULL TAG** (MAIN vs MAIN over 120 fixtures ⇒ 0 movers) and a
   positive control (a known mover ⇒ exactly 1). Verbatim:

   ```
   BOUNDARY CONTROLS (before the first real measurement):
     [ok ] MAIN sha256 8280ea8d86bcaf4ed82cae92f65733fe8ae601086dfb721d58feeda55d8d9da2
     [ok ] COMPOSED sha256 3368af1262695d7e4c573d3958f0a9aa48e604bf5248e1b85a52362ac76f69dc
     [ok ] NULL TAG: MAIN vs MAIN over 120 fixtures -> 0 movers (must be 0)
     [ok ] POSITIVE: loop_pairing_reject_round2_falsified.ll -> 1 mover (must be 1)

   MOVERS 8: A->D 0 · D->A 4 · CRASH-involved 0 · stream-only 3 · decline-string-only 1
   ```

   **Zero A→D, zero crashes.** The eight are exactly tu9q P0+P3's own declared
   movers — the same set round 3 found on a *different* base, so round 4's (P4)
   fix neither adds nor removes one. `round5/corpus5.txt`.
   ⚠ `subprocess.run(...).returncode` is read from the process object; there is
   no shell and no pipeline, so last session's `rc=$?`-after-a-pipe defect
   ("2065 movers of 2106") cannot occur here.

2. **26 composed traces + 15 MAIN traces through `entangle.py`** (F-2), on four
   axes: per-rail mint/`_unc`/free multiplicity, dirty free (including the
   template-rail case), UAF/double-free, **adjoint operand identity**, and the
   Rule-8 question with permutation-gate edges. **One finding, on the
   pre-existing warned flat program, identical on MAIN.**

**Directed, and all negative.**

* **Cross-function ledger clearing — the brief's stated highest-value area, and
  bd `1yeu`'s structural blind spot.** Five modules pairing an ACCEPTING quantum
  function with an OFFENDER for each of the two module-scoped self-clearing
  ledgers, **in both orders**, plus one with all three functions:
  `x1`/`x2` (tu9q's `declineUndischargedExitObligations`), `x3`/`x4` (6n1s's
  `declineUndischargedMarkedBodyRails`), `x5` (both). **Every one declines with
  the offender's own string**; an accepting function sharing the module masks
  nothing, in either order. I also read the mechanism: the `Discharged` set is
  keyed on `Value*`, and a discharge in function A cannot name function B's rail
  by pointer identity; `lowerLoops` clears the ledger on entry and runs **once
  per module** (`CQLoweringPass.cpp:500` / `:1192`), `uncompute` likewise
  (`:877` / `:1341`), so there is no second clear in the window.
* **`allUsersInside`, the conjunct (ii-d) calls "the clause's SUBJECT, not
  conservatism".** `q4_ht_read_after` (the hoisted rail read after the loop)
  declines on both. `q5_ht_two_loops` / `e2` / `p4` (one hoisted rail, two
  sibling loops) decline on both. I could not launder a post-loop reader past it
  — through a second loop, a bank cell, a merge phi or an M-C in-place rewrite.
* **The multiplicity hazard the (ii-d) trigger names**, seven constructions:
  outer-loop early `return` (`p1`, `q2`), inner-loop-preheader mint so the anchor
  block repeats (`p2`, `q6`), latch-folded `break` (`p3`, `q3b`), nested
  (`q1`), two loops one rail (`q5`), guarded/runtime trip (`q7`, `z1`, `z2`,
  `z3`), and the multi-exit nest (`w3`, F-1). The accepting ones (`q1`, `q3b`)
  mint the hoisted rail **once** and adjoint it **once** at the loop exit before
  the trailing `cqrt_ry_i32`; the rest decline. **No trace anywhere shows
  `_unc` count > mint count.**
* **The exit-anchored adjoint against a MUTATED parent** (`u1`, `u2`, `u3`,
  `u4`) — the sharpest wrong-unitary candidate I had, since P2 moves the
  discharge far from the mint. `u2`/`u3` accept on both and are correct
  (`-O1` rewrote the add-recurrence into a closed form **after** the loop, so the
  parent is never touched inside it — `CLAUDE.md` Rule 9); `u1`/`u4` decline on
  COMPOSED at the postcondition. Adjoint operand identity holds in every
  composed trace.
* **A non-diagonal gate on the MERGED register** (`y1`, `y2`) — the shape where
  the value path's leftover pre-merge rails would dephase `a`. Both decline on
  both binaries (`control flow under quantum control`). Its hand-unrolled twin
  `y3` accepts **identically on MAIN and COMPOSED** with the `lyyf` warning: the
  pre-existing bd `1m5p`/`s82e` class, unmoved by the composition.
* **bd `zujr`'s L8 tripwire** `loop_carried_handle_reject_postloop_rotation.ll`:
  `cq controlled lowering: control flow under quantum control` on **both**. The
  composition does not move that wall.
* **The owner's own shipped program**: lowered IR and trace **byte-identical**
  between the two binaries (`diff` rc=0 on both).
* **Stage 2b is not as blind as I expected, and I checked rather than quoting.**
  Deleting a template rail's `_unc` while keeping its `cqrt_free` gives
  `VIOLATION T1-no-reversal` (same-stream) or `UNPROVEN U1-cross-stream`
  (the hoisted rail) — both non-zero under STRICT. So the postcondition's
  deliberately "generous" acceptance of a bare `cqrt_free` as a discharge is
  backed by a gate that does speak for a *freed* rail. It stays blind to a rail
  **left allocated**, which is the sense `CLAUDE.md` intends.

---

## 4. What I did NOT do — precisely

* **No `ctest`, no `lit`, and not one `FileCheck` line executed.** My corpus A/B
  records exit code, diagnostic and lowered-IR hash for all 2109 fixtures — a
  superset of what `ir-pass-lit` measures about the IR and a **subset of what it
  asserts**. A fixture whose verdict and stream are unchanged but whose `CHECK`
  prefixes no longer match is invisible to me. (I can state with certainty only
  that the 4 D→A movers' `not`-inverted RUN lines go red on COMPOSED.)
* **Only TWO binaries.** I have no BASE and no TU9QONLY, so **I cannot certify
  any probe as "composition-only"** — `q1`, `q3b` and `g3` are MAIN→COMPOSED
  movers and may well flip on tu9q alone (`q1`/`q3b` are nests/variants of
  `tu9q_ht_rolled`, which round 3 measured flipping on TU9QONLY alone). Where I
  say "the composition", read "MAIN vs COMPOSED on the two hashes in §1".
* **No twin matrix and no e2e slice sweep.** Round 3 ran both on its pair and
  found zero; I did not re-run them on mine, so the round-4 (P4) fix's
  interaction with those two instruments is unmeasured by me.
* **No simulator** (Rule 2, owner decision 2026-06-10). Every unitary claim is
  analytic/trace-level.
* **No mutation or injection matrix over the composed accepts**, and no Rule-12
  red-green pair authored for any of the nine. `w1`, `w2`, `w3`, `w4` are written
  as fixtures with RUN/CHECK lines but **were never run through lit**, so their
  prefixes are unvalidated; `w2`'s `CHECK: cq` is a placeholder (it declines at
  the stale-reader fence before the placement question is reached, which is why
  `w3` exists).
* **I did not attack**: irreducible or multi-latch bodies (I read that the loop
  scope fence refuses them and did not try to falsify that); the `use_empty()` φ
  and `liftOneRegisterMergePhi` residuals round 1's F-4 names; the
  `WeakTrackingVH`-nulled-root path through `declineUndischargedExitObligations`
  (I argued it is unreachable — a deleted root has no uses and so no rail to leak
  — but did not construct it); the `as_level`-style interaction of (ii-d) with
  the 7.2 abort-park or 7.4 `break` reverse-play; or the ABA hazard of
  `taint.IterationLocalBlocks` holding raw `BasicBlock *` across `RegionFlatten`
  erasures (pre-existing, widened in population by the composition, not
  constructed).
* **My own instrument's blind spots, stated so nobody cites it beyond them.**
  `entangle.py` (a) **trusts an `_unc`'s symbol and arg-0**: a trace cannot see a
  parent relabelled in place under the same handle id, so an adjoint computed
  against a mutated parent passes; (b) models non-linear gates by UNION, which
  over-reports and never under-reports, but means a hit needs hand adjudication;
  (c) treats a measured rail as fully projected — the project's own ruling, but
  coarse: a partial measurement of one of several correlated registers is not
  modelled; (d) **cannot see phase (Rz) correlations at all**, by design, so a
  phase-kickback bug is outside it; (e) handle ids are per-execution, so it
  cannot distinguish "one IR call site ran K times" from "K call sites ran once".
  Its 18 boundary controls, including the two null controls, are the only reason
  to trust it at all.
* **A probe-design trap I fell into and am recording because round 3 is exposed
  to it too.** Every round-3 probe calls `slice(4)` from `main`. `-O1`
  const-propagates the argument, so a `break` or a guard written in terms of that
  parameter is **deleted before the pass ever sees it**. My `q3_ht_break` measured
  a loop with no break at all; `q3b_ht_break_runtime` (bound from `argc`) is the
  corrected probe. Any round-3 conclusion about `break`, early exit or trip count
  that rests on a `slice(4)` probe is measuring a folded program.
* Nothing was committed, nothing pushed, no `bd` write, neither `build/`
  directory touched. The only files I created are under
  `session-2026-09-21-orchestrator/round5/`.

---

## 5. Reproducing this

```bash
R=/Users/sorenwilkening/Desktop/Projects/CQ_lang
D=$R/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-21-orchestrator

shasum -a 256 $R/build/ir-pass/cq-opt /private/tmp/claude-501/cq-composed/build/ir-pass/cq-opt

# one C probe on both binaries (stages 1,2,2b,3,4)
bash $D/probes/ab.sh $D/round5/probes/z3_guarded_measloop.c

# one .ll probe on both binaries
$R/build/ir-pass/cq-opt                       -passes=cq-lowering -S $D/round5/probes/w3_nest_multiexit_rotq.ll -o /tmp/w3m.ll ; echo rc=$?
/private/tmp/claude-501/cq-composed/build/ir-pass/cq-opt -passes=cq-lowering -S $D/round5/probes/w3_nest_multiexit_rotq.ll -o /tmp/w3c.ll ; echo rc=$?

# the entanglement-edge Rule-8 checker (18 boundary controls run every time)
python3 $D/round5/probes/entangle.py --selftest
python3 $D/round5/probes/entangle.py /private/tmp/claude-501/adj4jok/COMPOSED/*.trace

# the 2109-fixture A/B with crash bucketing and a null-tag control (~14 min)
python3 $D/round5/probes/corpus5.py $R/ir-pass/test/loop_pairing_reject_round2_falsified.ll
```

**Artefacts in this directory.** `probes/` — `entangle.py` (the checker),
`corpus5.py` (the sweep), and 35 probe sources: `p1`–`p4` (multiplicity),
`q1`–`q7` (tu9q's own customer under nest / break / early-return / read-after /
two-loops / runtime-trip), `u1`–`u4` (mutated parent), `v1`–`v3` (bank ×
template rail), `w1`–`w4` (the `.ll` fixtures: the L1-fence replacement and the
multi-exit nest with its attribution control), `x1`–`x5` (cross-function
ledgers), `y1`–`y3` (rotation on the merged register), `z1`–`z4` (guarded
zero-trip). `verdict_table.txt` — every probe on both binaries.
`corpus5.txt` — the sweep output including its boundary controls.
