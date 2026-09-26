# Rule-13 review r1A — bd `xdu2.16` (commit `ee2ad6d1`), FENCE LOGIC surface

**Verdict: `CLEAR-WITH-ITEMS`. 0 P1, 0 P2, 6 P3.** No over-accept (silent miscompile) was found, and no crash
or UAF. Two new P3 over-declines were filed as bd `xdu2.21` and bd `xdu2.22`. The remaining items are
record and comment corrections.

- Subject: `cq-opt` `b1603d237fc3a739` (worktree `agent-aeb4c8cbea3df61df`, read-only use).
- Oracle: `cq-opt.main983` `438c77bf45c02e3e`.
- Both hashes were re-checked at resume.
- Instrumented private build: `scratchpad/r1A_wt` @ `ee2ad6d1` plus `probes/instrumentation_CQ_R1A_DBG.patch`
  (env-gated `errs()` of each round-1 grant, its nulled/surviving roots, the fresh roots, and the IRR/RLQ
  verdicts). It was measured byte-identical in output to the subject on `c01_slice` (only the `ModuleID`
  path differs).
- Scope boundary: the second reviewer owns `data_rotated`, the G-13 trailing gates and Rule-8 dephasing.
  I touched those only where a fence question led there, and I say so where I did.

⚠ **Interrupted and resumed.** The owner paused work mid-review. The corpus A/B sweep that was in flight
was killed by PID and RE-RUN from scratch; nothing below is taken from the interrupted run. The
re-run then exposed a defect in my OWN harness (L10). `rc=${PIPESTATUS[0]}` after a `$(…)` substitution
does not see the inner pipeline, so the first re-run printed `ACCEPT_A 2284`, which is implausible
because the corpus contains declines. It was fixed (rc taken directly from the tool; see
`probes/corpus_one.sh`) and run a third time. Only that third run is quoted.

## 1. Findings

| id | sev | finding | evidence |
|---|---|---|---|
| F-A1-1 | P3 (over-decline + vacuous record row) | A rolled compound 4.4 tree whose leaf reads a **non-foldable** out-of-place template rail (`int p = q*q; for(…) t = ((p>4)&(r<5)) ? i : 55;`) **still declines** on the subject. The string moved from the xdu2.16 wall to the (ii-d) postcondition `hoisted invariant rail admitted for in-loop discharge was not discharged`. The hand-unrolled twin accepts, and so does the single-compare rolled form of the same derived leaf. Cause (instrumented): the fresh derivation admits `p` by (ii-d), records a NEW exit obligation, and the anchor does not discharge it, even at a constant trip with a single exit. ⚠ The record's §5 twin row "derived `int p = q*3+1; (p>4)&(r<5)` IDENTICAL (60)" **never exercised a derived leaf**: `-O1` folds `q*3+1 > 4` into `icmp sgt %q, 1`. Filed **bd `xdu2.21`**. | `c10_der_mul` / `c10u_der_mul`, `c10k_der_consttrip`, `c10s_der_single`, `c19x2`, `c24_tree_plus_data`, `c43_shared_leaf_data`, `nest/n4_rolled`, `tw/hoisted_template_sel_value_*`, `impl_der/der_rolled.s1.ll`. LEDGER: these are exactly the **10 string moves**, all to the postcondition. |
| F-A1-2 | P3 (second ROLLED-ONLY cell, adjudicated) | A per-trip 4.4 select in a loop, then `if ((q>1)&(r<5)) cq_phi(0.3);` after it: **rolled ACCEPTS** (71 lines, STRICT 2b 6/0/0), **unrolled DECLINES** on both binaries (`condition used outside the branch`). The loop-free single-select control declines identically on both binaries, so the flat over-decline is pre-existing. `-O1` CSEs the trees into one `and` read by the selects **and** the phase `br`. The rolled stream is argued correct gate by gate: each trip's network (two leaf flags, toffoli node) is stripped and freed before its `%out` is measured. The post-loop kickback mints a fresh network, applies `cqrt_rz_i1(node, 0.3)`, undoes the toffoli, frees the node and strips both leaves, so the phase lands exactly on `c = (q>1)∧(r<5)`. No twin gate can witness it. Filed **bd `xdu2.22`** (the xdu2.19 pattern). | `tw2/kick_post_{rolled,unrolled}.c`, `tw2/kick_flat_ctrl.c`, rolled trace lines 59–69 |
| F-A1-3 | P3 (L2/L7, comment at the new site) | The new block's residue and "mutation" paragraphs describe round-1 residue and rollback **on failure** only. On the **success** path the fresh derivation has two side effects the comment never states. (i) NEW dtzb commitments in `InPlaceRailOps`/`PreLoopCommittedInPlaceOps` made at the re-ask slot, i.e. after `declineStaleRecordOps` / `recordStaleQuantumReaders` / `declineRecordedStaleQuantumReaders`. Round 1 committed nothing for them: its only Cand was the `and` node. Measured: `f1`/`f2` commit `cqrt_addc_i32(h0,7)` + `cqrt_xorc_i32(h0,3)` late. The intact path's "idempotent with round 1's" argument does not reach them, because fresh Cands ≠ round-1 Cands. (ii) NEW (ii-d) exit obligations (F-A1-1 is that). Both are safe today: (i) because `lowerOps`' (1b) tripwire re-asks `classifyInPlaceReassignment`, and G6 forbids any later read of the parent, so there is no reader for the stale fences to have missed (f1/f2 are byte-identical to twins in which M-C decides the same thing at `lowerOps`); (ii) because a ledger entry can only add declines. Fix the comment at the source (L7-with-a-twist). | `ch/f1_*`, `ch/f2_*`, `ch/f3_*` (f3: `q` read later → G6 refuses → IRR false → decline, a safe over-decline) |
| F-A1-4 | P3 (mutation record) | M2 ("ignore totality") is recorded MISSED because "the only clauses [`railLocalQualifies`] does not re-ask — (iii-b) … have no constructible subject". That list is incomplete. Clause **(iii)**'s in-loop in-place-gate refusal is also not re-asked when a SIBLING Cand already put the same peeled root into `Fresh`: `onRail(V)` is then true although V failed. So totality is load-bearing for (iii) in principle. I could not construct a C subject: it needs two live SSA names of one register read in the loop plus an in-body in-place gate on one of them, and every spelling I tried dies earlier at `condition predates a non-diagonal gate` / `operand predates a non-diagonal gate` on both binaries. The MISSED verdict stands; its stated reason should name (iii) as well. | `c40_inbody_rot_leafreg`, `c41_*`, `wp/x1..x4` |
| F-A1-5 | P3 (comment, L3-mirror) | `loopCarriedHandlePhi`'s header lists FOUR slots and says the two GRANT slots are backstopped by "the promotion's record half and then `declineClassicalMuxes`, one stage later". The re-ask's `invariantRegisterRoots` → clause (i) call is a fifth, **post-promotion, post-backstop** slot. It existed in the intact path (where it could only add to a union), and for a nulled grant it is now the **sole** source of the carried chain in `Fresh`. It is not listed. Measured to answer correctly post-promotion (`acc_*`, `a1`, `a4`, `a6`, `k0_acc`: fresh roots include the retyped φ and `%out`). | debug lines in §3 |
| F-A1-6 | P3 (record numbers) | "K-independent: **102** lowered lines … the only diff is the two trip constants (the loop and its inlined copy in main)" does not reproduce, and no command is recorded (Rule 19 wording). On the committed `slice_loop_condtree_select_hoisted.c` I measure **123** lines at `i < 3` and at `i < 1000` (84 excluding metadata/attributes), and the diff is **one** line (`icmp eq i32 %8, 3` vs `1000`). K-independence itself reproduces. | `probes/kind/` |

## 2. The monotonicity claim, clause by clause (attack 1)

`railLocalQualifies` reads `Roots` in exactly three places:

- `Roots.empty()` → refuse;
- `onRail` in the escaping-temp clause (`TI && !onRail` ⇒ temp; refuse if it escapes);
- `onRail` in the invariant-input clause (`!L->contains(Op) && !onRail(Op)` ⇒ refuse).

Every one refuses less as the set grows. The other clauses (tainted terminator, subloop content, L3 memory,
header φ via `loopCarriedHandlePhi`, `taintedExit`) do not read `Roots`. `AnyLocalOut` is NOT monotone, but
both re-ask paths ignore it. **The boolean is monotone.**

Hence accept(nulled) ⊆ accept(intact over the same IR with the surviving roots). The nulled path needs
IRR = true, so its set is `Fresh`, and `RLQ(Fresh) ⇒ RLQ(Surviving ∪ Fresh)`. **The relative claim holds.**
What it inherits is the intact path's premise that RLQ at FINAL taint, over the post-emission IR,
certifies a marking made at round 1. That premise is further backstopped:

- by `multiplicityAgrees` (P1), which refuses every G/At multiplicity mismatch regardless of `Roots`;
- by the (ii-d) ledger postcondition;
- by bd `6n1s`'s marked-body postcondition.

So a wrong root set cannot, by itself, produce K adjoints against one forward gate.

**L1 PREDICATE species.** The fresh derivation asks the round-1 question at FINAL taint, which is the taint
`lowerRotations` uses (`Chained`). It therefore sees MORE taint. Every round-2-grown value I built was
refused either earlier or by it, never admitted:

- `c33`: a 6.5 `%out` as a leaf literal → xdu2.13's `declineQuantumCondLiterals`, same on both binaries;
- `f3`, `c19x1`, `c11`: IRR false → decline.

## 3. What round 1 left behind (attack 2, L2), measured

Instrumented (`CQ_R1A_DBG=1`). On every nulled grant, the round-1 root set was the hoisted node (sometimes
beside carried-chain roots or `r`), and the fresh set is the leaves' registers (plus the carried φ and
`%out`). Example (acc):

```
round1 roots: %18 %20 %8   grant r1roots: %15 %out <NULL>   fresh: %15 %out %2 %3  RLQ=1
```

- **Marking.** It is re-certified or declined. Its suppressing readers run earlier and its granting
  readers later, as the comment says (all `IterationLocalBlocks` readers were grepped).
- **(ii-d) ledger for the erased node.** Read null ⇒ skipped. I verified this in
  `declineUndischargedExitObligations`: `if (!R) continue;`, and only `cq_template_*` roots are checked.
- **Raw-pointer sets holding the erased node.** `SelectMergeEmit::scrubTaint` covers `Tainted`, `BirthOrder`,
  `StaleDeclined`, `HandleWidth` and `PhiCalls`. `InPlaceRailOps` cannot hold an i1 tree node:
  - both leaves of an `and`/`or`/`xor` are tainted, so there is no G2 shape;
  - `xor i1 %c, true` → (ii-d) refuses an in-place op → no grant.
- **New raw pointers.** The xdu2.16 block reads only `WeakTrackingVH`s.
- **The pre-existing exposure.** `GateCalls` is built from the raw `ThetaCalls`/`PhiCalls` vectors, and in
  this window only inserters were found for `ThetaCalls` (no scrubbers). This is identical in the intact path
  and in `lowerLoops`; I did not attack it.
- **Zero-trip and one-trip runtime counts** (`b2/k0_*`, `k1_acc`): clean streams (nothing minted inside the
  never-run body is freed), STRICT 2b clean.

## 4. Coverage (attack 3), and reproduced claims (attack 5)

**Probe ledger** (`probes/LEDGER.txt`, generated): **168** oracle/subject pairs. **98 same, 60 D→A,
10 string moves, 0 A→D.**

Of the 60 D→A (`probes/DA_TWINS.txt`):

- **30** are byte-identical to a hand-unrolled twin.
- **10** differ, each adjudicated as an `-O1` generator difference:
  - the unrolled copy folds the accumulator (`acc_and`, `acc_or_xor`, `dowhile_acc`, `a1`, `a4`, `a6`,
    `c91_clobber_cls`). The rolled form then leaves per-trip rails that are functions of the condition.
    Every spelling that interferes `q`/`r` after the loop (`wp/x1..x4`) declines at the stale-record
    fence on both binaries, so none is reachable — handed to reviewer B's Rule-8 surface;
  - leaf-order swap (`n2`);
  - `y>4 → q<3` plus a sunk select (`preloop_sel_leaf`);
  - an `r+0` fold (`sel_value_is_leafreg_derived`).
- **1** is ROLLED-ONLY (F-A1-2).
- **19** have no twin. Most duplicate twinned shapes: `c50`, `c51`, `c60`, `c61_1`, `c61_4`, `xor3`,
  `ne_pair` and `kick_post` are twinned under `tw2/`, and `n3`'s trace sha equals the twin-identical `n1`.

**Shapes covered:**

- and / or / xor / 3-way xor / `!=`;
- `_Bool` rail leaves and rail-bank cell leaves (`b[0] & b[1]`);
- i8/i16 leaves and an i8 select;
- an fp leaf with `|`;
- a hoisted leaf under an in-body `and`;
- a leaf also read as data before, after and inside the loop;
- a tree shared by two selects, and by two loops;
- a nest (tree hoisted out of both loops; hoisted to the inner only; outer with `break`);
- `continue`, `do/while`, runtime trip 0/1/3 behind a guard, constant trip;
- a derived template chain on the select output (`d1–d3`), a pre-loop select whose `%out` feeds a leaf,
  in-place dtzb leaf operands, a 6.5 `%out` leaf, two functions in one module (bd `1yeu`);
- short-circuit `&&` (declines on both, bd `xqgx`);
- Rz- and Ry-stem angle selects (both decline `rotation angle under quantum control`).

**Reproduced by re-measurement** (not read off the record):

- corpus A/B over **2284**: null control ORA×ORA **0** movers (accepts 1129/1129, the rc field validated
  on a known decline first); ORA×SUBJ accepts **1129 → 1135**, **6 movers, all D→A, all the change's own
  fixtures**;
- the three new goldens byte-identical to their `.expected.log`;
- both `*-twin-identical` pairs byte-identical;
- K-independence (see F-A1-6 for the number);
- the mixed-literal `q && m == n` rolled/unrolled DIFFERENT (36 vs 45) identically on both binaries.

## 5. What I did NOT attack

- **A root nulled only in ROUND 2**, i.e. erased by an emitter of a region that exists only after
  `repropagateControlMerges`. Not constructed. A tree tainted at round 1 is consumed by a round-1 region,
  and an in-loop tainted `br` gets no round-1 grant at all.
- **Roots erased by emitters other than `SelectMergeEmit`.**
  - PredMux runs before `lowerLoops`, so it cannot null a round-1 root.
  - Kickback, switch and the value arm are reachable only via an in-loop tainted terminator, which
    `railLocalQualifies` refuses at round 1.
  - The angle select declines earlier.
  - `SharedCondFlags`' compare-position mint (the stated RESIDUAL) needs a compare also read outside
    `L`, which (ii-d)'s `allUsersInside` refuses.
  - All of this is argued, not exhausted.
- **A multi-latch or irreducible loop.** `-O1` normalised `continue` to one latch; nothing else was tried.
- **`+Asserts`** (bd `r4f6`): not built. The "deleted ⇒ no users" premise leans on `~Value` in principle.
- **The pre-existing `ThetaCalls` dangling-pointer exposure** in `GateCalls`, and **the intact path's
  un-re-proven round-1 roots**. Both predate xdu2.16; the nulled path is strictly stronger than both.
- **G-13 / Rule-8 and the `data_rotated` cell**: reviewer B. Only the `wp/x1..x4` reachability check was
  run.
- **A mutant build** to test F-A1-4's (iii) gap directly: argued plus C attempts only.
- **The full ctest suite / `cq-opt-equivalence-full`**: not re-run. Only the corpus A/B and targeted
  slices above.
- **`example/grover`**: not re-run.

## 6. Beads filed

- `test_C_libtooling-xdu2.21` (P3 bug) — F-A1-1.
- `test_C_libtooling-xdu2.22` (P3 bug) — F-A1-2.

Both are children of `xdu2` and `discovered-from` `xdu2.16`. F-A1-3 … F-A1-6 are record and comment items
for the implementer; no bead was filed for them.
