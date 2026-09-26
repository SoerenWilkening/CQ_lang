# Track xdu2.16 — a compound 4.4 condition tree inside a ROLLED loop

Session 2026-09-25 (parallel with bd `9bhg`, which owns `Specialization.cpp` and the
bd `3jru` return refusal; this track touched neither). Worktree branch
`worktree-agent-aeb4c8cbea3df61df`, based on `main` at `983f9361`.
ORACLE: `cq-opt` `438c77bf45c02e3e` (main 983f9361, frozen; a fresh build of the
unmodified worktree was measured BIT-IDENTICAL to it before any edit — a build null
control). SUBJECT: `cq-opt` `b1603d237fc3a739`, `libCQPass.so` `3001ec9a1cc5bb2a`.
Probes, sweeps and the mutation harness are committed under `xdu2_16_probes/`.

**Not self-cleared.** The orchestrator owes this change independent Rule-13 rounds.
§8 says what to attack first.

> **UPDATE after Rule-13 (two independent rounds, r1A fence logic and r1B emitted
> circuit, both `CLEAR-WITH-ITEMS`, 0 P1, 0 P2):** records `review_r1A_xdu2_16/REVIEW.md`
> and `review_r1B_xdu2_16/REVIEW.md` in this directory. Every P3 item was applied as a
> COMMENT / RECORD / FIXTURE-HEADER change only — no predicate and no emitted stream
> changed (the post-edit binary is compared against `b1603d23` in §10). Where this
> record was wrong it is corrected IN PLACE and marked `⚠ CORRECTED (r1…)`; §10 maps
> every finding to its disposition.

## 1. Headline

- **The wall moved and xdu2.8's program compiles.** `railbank_dynamic_matrix.c`
  row 13 (`int p[m]; for (i<n) if (q && m == n) { a += p[i]; z -= p[i]; }`) and its
  mirror rows (`railbank_guarded_vla_matrix.c` row 6, `condtree_classical_leaf_matrix.c`
  rows 4 and 6) flip DECLINE → ACCEPT, stage 2b STRICT clean. It has its own e2e
  golden now (`slice_loop_condtree_select_hoisted_row13`, 55 trace lines).
- **The change is one block of `declineRound2FalsifiedRailGrants`** (the bd `tu9q`
  L1 re-ask). A NULLED round-1 root is no longer a refusal by itself: the grant's
  round-1 roots are ALL discarded, the grant is re-derived from scratch under FINAL
  taint by the owner (`invariantRegisterRoots`), that re-derivation must be TOTAL
  (`false` is a refusal), and `railLocalQualifies` is re-asked on the fresh set
  alone. The fence, its string, its slot and both entry points are unchanged.
- **Rolled == hand-unrolled, byte for byte**, on the two committed twin gates and on
  9 more probe cells (§5). **K-independent**: 123 lowered lines (`wc -l`; 102
  non-blank) at `i < 3` and at `i < 1000` — ⚠ CORRECTED (r1A F-A1-6): the first
  version said "102 lowered lines" with no command; the command and the full diff
  are now in §5.
- **Corpus A/B: 0 A→D, 0 string moves, 0 stream moves**; every mover is an intended
  D→A (§6).
- **ROLLED-ONLY cells exist and are adjudicated in §7.** ⚠ CORRECTED (r1B F-B1-2,
  r1A F-A1-2): the first version said "one ROLLED-ONLY cell". The review rounds found
  at least four flat-decline causes and ~50 rolled-only cell-forms, all flat
  OVER-declines in the safe direction (bd `xdu2.19`, `xdu2.22`, `xdu2.23`); the
  data-rotated cell is now WITNESSED by an IR-level twin (r1B F-B1-1).

## 2. The wall, read off the IR (Rule 11)

`for (i<n) if ((q > 1) & (r < 5)) a += 3;` (Track E's probe p19) at `clang -O1`:

```
ph:   %c1 = icmp sgt i32 %q, 1 ; %c2 = icmp slt i32 %r, 5 ; %c = and i1 %c1, %c2   ; LICM-hoisted
body: %a = phi [0, %ph], [%a.next, %body] ; %a3 = add %a, 3 ; %a.next = select i1 %c, %a3, %a
```

1. ROUND 1, `lowerLoops`: `tryBreak`/`tryCaseA`/`markIfIterationLocal` refuse; the
   bd `tu9q` root-mint escape runs `invariantRegisterRoots`: clause (i) puts the
   carried `%a` chain in `Roots` (bd `zujr`), and the ONE outside-`L` tainted read,
   `%c`, is admitted by clause **(ii-d)** — `mintsOutOfPlaceTemplateRail(and i1)` is
   true, `allUsersInside`, `loopExitDischargePoint` — which also records an exit
   obligation for it. `markIfRailLocal` marks the body; `recordRound1RailGrant`
   records `{phi, select, %c}`.
2. ROUND 1, control: the 4.4 emitter (`SelectMergeEmit`) mints the network with
   `emitCondNetwork` IMMEDIATELY BEFORE THE SELECT — i.e. in the body — from the
   LEAVES' OPERANDS (`icmp_sgt_hl(h, 1)`, `icmp_slt_hl(h2, 5)`, toffoli node), does the
   copies, strips and frees, and then cascade-erases the dead `%c`, `%c1`, `%c2`
   (`SelectMergeEmit.cpp`'s root-first dead-tree erase). The select is RAUW'd to
   `%out` (the record FOLLOWS it); `%c` is DELETED (the record goes NULL).
3. After the round-2 fixpoint the re-ask found the null and refused, unconditionally.

**What the refusal was protecting (L6).** Not the unitary: the rolled body's stream
is byte-identical to the stream of the SAME module with the three tree instructions
hand-sunk into the body (`xdu2_16_probes/p19sunk.s1.ll`, which the ORACLE already
lowers; `diff` of the two lowered functions empty). The per-trip flags are the
emitter's, discharged in-body by the emitter. The nulled root was bookkeeping: a
round-1 root naming a value the emitter made unnecessary. Clause (ii-d) admitted a
condition-position `and` as a "hoisted template rail" it would never become — the
`CmpInst` branch of `mintsOutOfPlaceTemplateRail` asks `isDataPositionCompare`, the
`BinaryOperator` branch has no analogue for a condition-position `i1` node (this is
why a SINGLE hoisted compare never hit the wall: `for (…) if (q > 1) a += 3;`
accepts on the oracle, no grant made). I did NOT change that predicate: it has three
callers, two of them suppressions (its header's own L3-mirror warning), and the
re-ask is where the question can be asked on the IR that actually exists.

## 3. The change and its soundness argument

`ir-pass/src/LoopLowering.cpp`, `declineRound2FalsifiedRailGrants`, the block
headed `bd test_C_libtooling-xdu2.16` (read it; the argument is at the site, L7):

```cpp
if (Nulled) {
  SmallPtrSet<Value *, 4> Fresh;
  if (!invariantRegisterRoots(L, taint, wd, DT, LI, GateCalls, Fresh, nullptr))
    { diagnose(header terminator, kMsgRound1GrantFalsified); return; }
  if (!railLocalQualifies(L, taint, LI, GateCalls, Fresh, AnyLocal, &WhyNot))
    { diagnose(WhyNot ?: header terminator, kMsgRound1GrantFalsified); return; }
  continue;
}
```

- **Strictly stronger than the intact path.** The intact path unions the round-1
  roots with a fresh derivation that may FAIL (a `false` "adds nothing").
  `railLocalQualifies` is MONOTONE in `Roots` (its only readers of the set —
  `Roots.empty()`, `onRail` in the escaping-temp clause and in the invariant-input
  clause — refuse less as the set grows). So a nulled grant accepted here is one the
  already-Rule-13-cleared intact path would accept over the same post-fixpoint IR,
  and on no round-1 evidence at all.
- **A nulled root is unread.** `WeakTrackingVH` nulls only on DELETE; a replaced
  value (RAUW — including LLVM's `DeleteDeadBlock`, which RAUWs to `poison`) is
  FOLLOWED. A value with remaining uses cannot be deleted in a valid module. So the
  nulled root names nothing the current IR reads; dropping it only removes coverage.
- **The marking is certified before it GRANTS anything.** `IterationLocalBlocks`'
  granting readers — `FreePoint` and `Uncomputation`, which place in-body
  discharges on it — run after this stage. Its two other readers run BEFORE it
  and read it in the SUPPRESSING direction (a marked body silences their decline):
  `declineUnmarkedRolledIterLocal` (`CQLoweringPass.cpp:729`/`:1368`) and
  `declineDephasingUnmarkedLoopRails` (`:905`/`:1446`, via `bodyBlocksMarked`).
  A suppression made on a marking this stage then refuses is harmless (the module
  declines); one made on a marking it certifies is justified after the fact. That
  is exactly the arrangement the intact path already relies on. ⚠ My first draft
  of the source comment said all readers ran after this stage — FALSE, found by
  grepping the callers before commit and corrected at the source (L7). No control
  emitter reads the set.
- **Round-1 residue.** (a) the marking — re-certified or declined; (b) clause
  (ii-d)'s exit obligation for the erased node — its handle is null too, and
  `declineUndischargedExitObligations` reads null as discharged, correctly (never
  lowered, no rail); (c) `commitOutOfLoopInPlaceOps` commitments — re-verified by
  `lowerOps`' tripwire; an `and`/`or`/`xor i1` has no dtzb chain to commit anyway.
- **Mutation before a possible decline**: `invariantRegisterRoots` rolls its own
  commitments back on failure, and `diagnose` exits (bd `br4a`).
- ⚠ CORRECTED (r1A F-A1-3, r1B F-B1-3) — **the SUCCESS path has two side effects the
  two bullets above never stated.** Round 1's only candidate was usually the hoisted
  node, so the fresh candidates (the leaves' registers) are judged for the first time
  HERE, and "idempotent with round 1's" does not reach them:
  (i) **new dtzb in-place commitments** (`InPlaceRailOps` /
  `PreLoopCommittedInPlaceOps`) made at this slot, i.e. AFTER `declineStaleRecordOps`
  / `recordStaleQuantumReaders` / `declineRecordedStaleQuantumReaders` (r1A measured
  late `cqrt_addc_i32`/`cqrt_xorc_i32` on `ch/f1`, `ch/f2`). Safe today because the
  `lowerOps` (1b) tripwire re-asks `classifyInPlaceReassignment` under FINAL taint and
  declines loudly, and its G6 conjunct forbids any later read of the parent, so no
  reader exists for the earlier stale fences to have missed (`f1`/`f2` byte-identical
  to twins where M-C decides the same at `lowerOps`; `f3` reads the parent later → G6
  refuses → IRR false → decline);
  (ii) **new (ii-d) exit obligations** recorded in the ledger at this slot for a fresh
  derived-rail candidate; `declineUndischargedExitObligations` enforces them after
  `uncompute`. That postcondition, not the re-derivation, is what stops an undischarged
  fresh root; safe because a ledger entry can only add declines. Measured as the main
  remaining wall of this shape: r1A 10 of 168 probe pairs, r1B 87 of 510 cell-forms
  move from this fence's string to `hoisted invariant rail admitted for in-loop
  discharge was not discharged` (bd `xdu2.21`). Both are now stated at the source,
  with retirement triggers.
- **Residual, stated at the site:** `railLocalQualifies` keys its scan on
  `taint.Tainted`, and emitter-minted rails are not in it. An emitter that hoisted
  its stream OUT of the loop whose body consumes it would be invisible — none does;
  retirement trigger written.

**L1.** Unchanged slot: post-fixpoint, above `lowerRotations`, both entry points
(`CQLoweringPass.cpp:912` / `:1453`). The re-derivation reads FINAL taint.
**L2.** The other sets over the same closure: the (ii-d) obligation ledger (null ⇒
discharged, argued above) and `IterationLocalBlocks` (not widened — this stage
still marks nothing). **L3 mirror / L8, the retirement trigger and its direction.**
The removed refusal's own comment said: *"if this is ever measured to fire on a
program that should compile, it is an over-decline to FILE (owner ruling
2026-09-11), not a fence to relax in place."* It was measured (Track E p19/p20, row
13), it was filed (this bead), and this is that bead's red-green: I used the trigger
in the ACCEPT direction through the process it names. The comment is replaced at the
site with the history marked. No new caller was added to a shared predicate; the
re-ask already called both owners — what changed is that a `false` from
`invariantRegisterRoots` is now a REFUSAL on this path (the safe reading).
**L7, corrected at the source in this change:** `LoopLowering.cpp`'s block above
`kMsgRound1GrantFalsified` ("A NULLED ROOT IS A REFUSAL"), `recordRound1RailGrant`'s
header, the intact path's "GRANT-ONLY" paragraph, `TaintPropagation.h`'s
`Round1RailGrant` header, `LoopPlan.h`'s declaration comment, `SelectClassify.cpp`
(its "row 13 now ACCEPTS" was FALSE when xdu2.13 wrote it — it moved to this wall),
and the three matrix sources + `slice_predmux_guarded_vla.c`.

## 4. Red → green (Rule 12)

Fixtures FIRST, run on the oracle-identical build (`438c77bf`), then the change.

| fixture | oracle | subject |
|---|---|---|
| `loop_condtree_select_accept_hoisted_and.ll` (p19, carried accumulator) | exit 1, the wall | ACCEPT, stream pinned |
| `loop_condtree_select_accept_hoisted_mixed_literal.ll` (`q && m == n`) | exit 1, the wall | ACCEPT, `and_i1_hl(…, i1 zeroext %lit)` fwd + `_unc` |
| `loop_condtree_select_accept_hoisted_leaf.ll` (hoisted compare LEAF under an in-body `and`) | exit 1, the wall | ACCEPT |
| `loop_condtree_select_accept_hoisted_nest.ll` (tree hoisted out of TWO loops) | exit 1, the wall | ACCEPT, stream in the innermost body only |
| `loop_condtree_select_accept_hoisted_data_rotated.ll` (§7) | exit 1, the wall | ACCEPT (+1 pre-existing `lyyf` warning) |
| `predmux_guarded_vla_reject_row13_hybrid_select.ll` (converted, name kept — L8/`gahu`) | exit 1, the wall | ACCEPT, both networks + guarded read pinned |
| `loop_condtree_select_reject_nulled_root_not_rederivable.ll` | exit 1, this string | exit 1, this string (totality refuses) |
| `loop_condtree_select_reject_nulled_root_rederived_escape.ll` | exit 1, this string | exit 1, this string (`railLocalQualifies` refuses) |

`lit ir-pass/test --filter 'loop_condtree_select|row13_hybrid'` on the oracle build:
5 FAILED (every accept), 1 passed (the first decline). On the subject: all green.
e2e on the oracle build: 8 of 10 owned ctest entries FAILED (3 matrices, 3 rolled
slices at stage 2, 2 twin gates); the 2 unrolled twins passed. On the subject: 10/10.

e2e added (`tests/e2e/CMakeLists.txt`, one `foreach`): `slice_loop_condtree_select_hoisted`
(+ `_unrolled`, gate `e2e-loop-condtree-select-hoisted-twin-identical`, 60 lines),
`slice_loop_condtree_select_hoisted_literal` (+ `_unrolled`, gate
`e2e-loop-condtree-select-hoisted-literal-twin-identical`, 45 lines, literal 1),
`slice_loop_condtree_select_hoisted_row13` (55 lines, no twin — the header says why).

## 5. Twins, K-independence, G-13

**Twin family** (`xdu2_16_probes/twins.py`, per-trip measured select, 3 trips, both
binaries): on the oracle every ROLLED cell declined at the wall; on the subject

| cell | rolled vs unrolled | 2b rolled |
|---|---|---|
| and / or / xor / nested `((q>1)&(r<5))|(q<-3)` | IDENTICAL (60 / 72 / 66 / 93) | clean |
| loop-variant tree, hoisted leaf `(q>1)&(r<i)` | IDENTICAL (60) | clean |
| `_Bool` rail leaf `b & (q > 1)` | IDENTICAL (51) | clean |
| hybrid `q \|\| m == n` | IDENTICAL (45) | clean |
| derived `int p = q*3+1; (p>4)&(r<5)` ⚠ see note | IDENTICAL (60) | clean |
| fp leaf `(double q > 1.0) & (r < 5)` | IDENTICAL (60) | clean |
| hybrid `q && m == n`, `q && i < m` | DIFFERENT 36 vs 45 **on BOTH binaries** | clean |
| data-rotated (Ry on the select output) | **ROLLED-ONLY** vs the C twin; IDENTICAL vs the IR twin (§7) | clean |

⚠ CORRECTED (r1A F-A1-1): the "derived" row **never exercised a derived leaf** —
`-O1` folds `q*3+1 > 4` into `icmp sgt %q, 1`. A genuinely non-foldable derived leaf
(`int p = q*q;`) still DECLINES, at the (ii-d) exit-obligation postcondition (bd
`xdu2.21`; §3's new success-path bullet (ii)).

The two DIFFERENT rows accept on the ORACLE too (rolled and unrolled): `-O1` splits
the rolled `q && m == n` into a classical `select` on `m == n` followed by a quantum
`select` on `q == 0`, while the flat copies keep the fused `and` — two spellings of
one function by the generator, not by this change.

**K-independence** — ⚠ CORRECTED (r1A F-A1-6). The first version said "102 lines
each; the only diff is the two trip constants" and recorded no command. Re-measured
on the COMMITTED `tests/e2e/slice_loop_condtree_select_hoisted.c` with
`xdu2_16_probes/kind.sh OUTDIR` (stage 1 at `-O1`, `cq-opt`, then `wc -l`,
`grep -c .`, `diff`; the K=1000 copy edits only the code loop's `i < 3; ++i`):

```
k3:    wc -l = 123, non-blank = 102
k1000: wc -l = 123, non-blank = 102
diff:  lines 1-2 (ModuleID / source_filename: the file name), and
       44c44  %9 = icmp eq i32 %8, 3   ->  1000     (in @slice)
       77c77  %4 = icmp eq i32 %3, 3   ->  1000     (in @main, which inlines slice)
```

So "102" was the non-blank count and "123" is `wc -l`; both are K-independent. The
two differing code lines are the trip constants of `@slice` and of its inlined copy
in `@main`. (r1A reports ONE differing line on the same source; I measure two, with
the command above. K-independence is not in dispute.)

**G-13** (`xdu2_16_probes/g13.py`, rolled vs unrolled, trailing `cq_theta` on `q`,
on `r`, on both; per-trip and carried shapes; both binaries): **every trailing-gate
cell DECLINES on BOTH binaries, identically on oracle and subject** — rolled with
`cq opcode lowering: operand predates a non-diagonal gate` (`diagnoseStaleRecord`,
owned by `declineStaleRecordOps` and its post-lift re-run; no `CQ_CTRL_DBG` decline
line fires, and which of the two slots speaks was NOT traced), flat at
`SelectClassify` (`condition predates a non-diagonal gate`). Both slots are ahead of
the xdu2.16 re-ask. **This is a non-divergence measured at EARLIER walls, not a
clearance**: the widened re-ask is never reached by a program that rotates a
condition register after the loop. What CAN be said is structural: per trip, every
rail the network mints (both leaf flags, the node ancilla) is stripped and freed
in-body before anything else runs (stage 2b STRICT verifies every free), so no
which-path record of `q`/`r` survives a trip. A single-compare control
(`g13single.c`) declines at `SelectClassify` on both binaries — the compound tree
landing on the stale-record fence instead is a pre-existing asymmetry of owners,
safe direction, not traced further.
(r1B §2 extends this: a trailing non-diagonal gate on a register the CONDITION reads
stays unreachable in every spelling it tried; one on a register only the per-trip
in-body DATA rails read IS reached — 5 do-while cells, all accepted STRICT-clean with
the hoisted (ii-d) rails discharged at the loop exit before the Ry. See its record.)

## 6. Measurements (commands in `xdu2_16_probes/`)

- **Corpus A/B** (exit code, stdout sha256, first error line), `ab.py ORACLE ORACLE`
  FIRST: 2282 fixtures, **0 movers**. Then `ab.py ORACLE SUBJECT`: 2282 fixtures,
  accepts 1129 → 1134, **5 movers, all D→A, all this change's own** (the 4 new
  accepts + the converted row-13 fixture); 0 A→D, 0 string moves, 0 stream moves.
  Of the 2277 pre-existing fixtures exactly ONE moved (row 13). Re-run on the final
  tree (2284 fixtures, the two late fixtures included): null control 0 of 2284 first,
  then accepts 1129 → 1135, **6 movers, all D→A** (the 5 above + the data-rotated
  fixture); `…_rederived_escape.ll` declines on both, as designed.
- **e2e source A/B**, `ab_e2e.py` over every `tests/e2e/*.c` × every declared `CASE`:
  606 jobs, 588 compiled at stage 1 (18 need other TUs/flags and were NOT swept).
  Null control 0 of 588. Subject: **7 movers, all D→A**: the 4 matrix rows and the 3
  new rolled slices.
- **Probe family** (`probes.py`, 25 C probes; `probes2.py`, 16 adversarial): movers
  are exactly the compound-tree-in-a-rolled-loop shapes. Adversarial probes that
  still decline on both binaries with the SAME string: tree defined BEFORE a Ry on
  a leaf register then used in the loop (`condition predates …`); a Ry in the body
  before/after the select on a leaf register; post-loop Ry on q/r/a
  (`operand predates …`); a measure of a leaf register before the loop; two loops
  over one register; the short-circuit `q > 1 && r < 5` (a `select i1` combinator —
  bd `xqgx`); the branch-phase form (bd `ztyc`); the tree ALSO read as data in the
  loop (`treedata` → bd `xdu2.14`'s postcondition, not a nulled root).
  Newly accepting and checked by hand: `clobber` (`(q>1) & (a<5)` on the carried
  `a` — the select writes a FRESH `%out`, the flat spelling accepts on the oracle
  too), `nest`, `der_escape` (`-O1` rewrites `p > 4` to `q > 1`; `p` only after the
  loop), `pre_rot_rz` (a classical `cq_phi` is a deleted global phase).
- **`e2e-loop-twin-matrix` + quarantine selftest**: both PASSED on the subject
  (873.6 s under load); the expected table did not move — the matrix has no cell of
  this shape (filed bd `xdu2.20`).
- **Mutation matrix** (`mutate.py`; exact-text anchor, rebuild, 48 lit + 10 ctest
  owned tests, restore asserted by binary hash): NULL mutant FIRST and LAST, 0
  movers, its binary bit-identical to the baseline. Denominator **6 real mutants:
  3 KILLED, 3 MISSED.**

  | mutant | verdict | killed by / reason |
  |---|---|---|
  | M1 withdraw a nulled grant silently (`continue`) | KILLED | both `reject_nulled_root_*` |
  | M4 restore the old unconditional refusal | KILLED | 11 (every new accept, the 3 matrices, the 3 slices) |
  | M5 accept on a total re-derivation, skip `railLocalQualifies` | KILLED | `…_rederived_escape.ll` |
  | M2 ignore the totality requirement | MISSED | shadowed: a non-total derivation usually fails on an uncovered Cand, which `railLocalQualifies`' invariant-input clause refuses too. ⚠ CORRECTED (r1A F-A1-4, r1B F-B1-4) — the first version said "the only clauses it does not re-ask — (iii-b) … — have no constructible subject". Both halves were wrong. (a) The list is incomplete: clause **(iii)**'s in-loop in-place-gate refusal is ALSO not re-asked when a sibling Cand already put the same peeled root into `Fresh` (`onRail(V)` is then true although V failed) — no C subject constructed by r1A, every spelling dies earlier. (b) **(iii-b) IS reachable from plain C** (r1B `outleaf/ol_none.c`, `int u = (q>1)?k1:k2; for(…) t = ((u>3)&(r<5))?i:55;`, bd `xdu2.24`): its `isVoidTy()` test refuses the 4.4 emitter's read-only `_unc` BORROW of the out-rail. **Measured whether it distinguishes M2** (`xdu2_16_probes/m2_olnone.py`: M2 built, bin `778de12df402b8bf`, restored to `b1603d23` by hash): **it does NOT** — `ol_none` declines with the SAME string on base and M2 (with totality ignored, `railLocalQualifies`' invariant-input clause refuses the uncovered `%out_u`, as r1B predicted); `ol_inrot`/`ol_postrot`/`ol_single` also unchanged. M2 stays MISSED |
  | M3 union the surviving round-1 roots into the fresh set | MISSED | accept-direction only (monotonicity); no subject separates them |
  | M6 treat a nulled grant as intact (drop the null, fall through) | MISSED | same: the Fresh-only + totality strengthening is defence in depth with no constructed subject in its difference |

  Read the three MISSED together: the fixtures pin that a nulled grant is RE-ASKED
  and that both refusal owners speak; they do NOT pin the choice of "discard the
  round-1 roots and require totality" over "fall through to the intact path". I
  kept the stronger form because it does not extend the intact path's unproven
  premise (its round-1 roots are never re-proven at FINAL taint) to a grant whose
  record has demonstrably changed under it.
- **Full `ctest -j6`**: see §6b. **`cq-opt-equivalence-full`**: see §6b.
- **`example/grover`** (the owner's, untracked, bd `5zwz`; copied to scratch):
  `grover_oracle_uncompute.c` — exit 0, 0 bytes of stderr, lowered IR and trace
  BYTE-IDENTICAL oracle vs subject. `main.c` — lowered IR byte-identical (its trace
  seeds `srand(time(NULL))`, so it is not comparable across runs). The other four
  files do not compile standalone at stage 1.

### 6b. Gates, as literally run

- `lit build/ir-pass/test` (full): **2284 discovered, 2283 passed, 1 XFAIL**, 148.9 s.
- `ctest --test-dir build -j6` (full, first run, subject `b1603d23`): **499/500**,
  1387 s under load (a parallel agent was building); the one red was
  `code_map_drift` — `CODE_MAP.md` records function start lines and this change
  shifts them. Regenerated with `tools/update_code_map.py` (every drifted entry is a
  file this change touches or adds); `--check` then exits 0.
- `ctest --test-dir build -j6` (full, SECOND run, on the committed tree after the
  code-map regeneration, same binary): **500/500 passed, 1086.6 s** (loaded box).
- `cmake --build build --target cq-opt-equivalence-full`: **2284 fixtures, 0
  mismatches**.
- Every comment-only edit after the measurements was followed by a rebuild whose
  `cq-opt` / `libCQPass.so` hashes were checked equal to `b1603d23` / `3001ec9a`.

## 7. The data-rotated ROLLED-ONLY cell — adjudicated, and (since r1B) witnessed

`for (i<n) { int t = ((q>1)&(r<5)) ? i : 55; t = cq_theta(t, 0.7); s += cq_measure(t); }`

- Rolled: ACCEPT on the subject (it declined at the xdu2.16 wall on the oracle).
- Hand-unrolled: DECLINE on BOTH binaries, `condition predates a non-diagonal gate`,
  at the second select, from `SelectClassify`'s POSITIONAL prong (c): `-O1` CSEs the
  three trees into one entry-block `and`, so copy 1's `cq_theta(t, 0.7)` (on the
  select OUTPUT) sits between the shared leaves and select 2 in the SAME block, and
  prong (c) refuses any tainted-operand theta there "even on another wire
  (over-decline is safe)". In the rolled form the leaves are in the preheader, prong
  (c) is same-block only, and prong (a) — the position-free wire walk that prong (c)
  is a conservative shortcut for — finds nothing on `q`'s or `r`'s wire.
- Why the rolled circuit is right: per trip the network is minted from `h`/`h2`,
  the copies write a FRESH `%out` from two CLASSICAL basis-state source rails, the
  node and both flags are uncomputed and freed, and only then `cqrt_ry_i32(%out)` and
  its measure. At the rotation nothing but `h`/`h2` is entangled with `%out` — the
  dependence the program denotes. One `lyyf` WARNING fires; the loop-free
  single-select spelling fires it identically on the ORACLE (`dr1.c`, 2 warnings),
  so it is not new.
- ⚠ The loop twin matrix's convention reads ROLLED-ONLY as "an over-accept and a
  Prime-Directive red however green the run looks". ~~This row is argued, not
  witnessed: it has no twin gate until the flat half is fixed (bd `xdu2.19`).~~
  ⚠ CORRECTED (r1B F-B1-1): **it IS witnessed, by an IR-level twin.** r1B's recipe
  (`review_r1B_xdu2_16/probes/unrl/twin_ir.sh`): make the trip constant (3), rewrite
  `llvm.loop.unroll.disable` → `llvm.loop.unroll.full` in the ROLLED stage-1 IR and
  run only `opt -passes='loop-unroll<O3>'` — no other `-O1` re-canonicalisation, so
  no cross-copy CSE and prong (c) never fires. Rolled vs IR twin: byte-identical on
  **15/15** `rot` cells, and the pre-change ORACLE lowers the IR twin to the SAME
  stream on 15/15. Re-measured here on `i32_and_rot_for` (this cell's shape): 63 = 63
  trace lines, identical; ORACLE-on-twin == SUBJECT-rolled; the ORACLE declines the
  rolled form at the xdu2.16 wall. The flat twin prints the `lyyf` warning once per
  trip (3) against the rolled form's 1 — a diagnostic count, not a stream difference.
  What stays open is only the C-level twin (bd `xdu2.19`); the recipe is noted on bd
  `xdu2.20` as the twin matrix's way around `-O1`'s CSE/fold confound.
- ⚠ CORRECTED (r1B F-B1-2, r1A F-A1-2): **this is not "the one ROLLED-ONLY cell".**
  The population is at least four flat-decline causes and **~50 rolled-only
  cell-forms** in r1B's 510-cell sweep, every one a flat OVER-decline in the safe
  direction and every one argued or witnessed correct on the rolled side:
  (1) prong (c)'s cross-wire refusal — this cell's family (bd `xdu2.19`);
  (2) a post-loop phase kickback on the same tree after an in-loop select — the flat
  CSE'd `and` is read by the selects AND the phase `br` (`condition used outside the
  branch`), r1A F-A1-2 (bd `xdu2.22`);
  (3) value routing after the trip-0 fold (`t = C ? (q+i) : 55; t = cq_theta(t,.7)`:
  flat `q+0 → q` routes the Ry onto `q`'s wire, `operand predates a non-diagonal
  gate`), and (4) i64 `trunc`/`select` order (flat `-O1` value-routes the Ry back to
  `trunc r`, `control flow`), both r1B F-B1-2 (bd `xdu2.23`).
  **And the asymmetry pre-exists on the ORACLE**: the single-compare rolled/flat pair
  (`st/single_rot_*`) and `lvar_rotr2` are already rolled-only there — xdu2.16 adds
  customers to a known asymmetry, it does not create it.

## 8. What I did NOT attack — start here

1. **The §7 cell**, by a hand-constructed IR in which the rotated register IS a
   leaf's wire but prong (a) cannot see it (e.g. through a rail bank / memory hop,
   or a `%out` of an earlier select used as a LEAF of the hoisted tree).
2. **A round-2-only nulled root**: a grant whose root is erased by the ROUND-2
   control pass (a region that exists only after `repropagateControlMerges`). The
   re-derivation reads FINAL taint by construction, but I built no fixture where the
   erasing emitter is a round-2 one.
3. **An emitter other than `SelectMergeEmit` nulling a root** (the switch data-mux,
   the 6.5 arm, `AngleSelectEmit`, PredMux's sweeps): argued (nulled ⇒ unread,
   whoever erased it), not constructed.
4. **Multi-function modules** (bd `1yeu`): every probe is one `slice` (+ `main`).
5. **The G-13 surface proper**: no accepted program rotates a condition register
   after the loop (every such probe declines earlier), so the widened re-ask was
   never asked about one. If `declineStaleRecordOps` or `SelectClassify`'s prong (a)
   is ever widened, re-run `g13.py` first.
6. `+Asserts` build (bd `r4f6`): not built; the "a deleted value has no users"
   argument leans on `~Value`'s assertion in principle and on the verifier in
   Release.
7. The (ii-d) predicate itself admitting a condition-position `i1` node (§2) — left
   as is, argued harmless at the re-ask; not re-derived for its two suppression
   callers.

(Items 1–7 above are the pre-review list, kept as written. What the two review rounds
then attacked, and what THEY did not, is in their own records' "did NOT attack"
sections; the notable remaining gaps both rounds name are a round-2-only nulled root,
roots nulled by emitters other than `SelectMergeEmit`, multi-latch/irreducible loops,
and `+Asserts`.)

## 9. Beads

- `xdu2.16`: notes updated, NOT closed (Rule-13 rounds owed).
- NEW `xdu2.19` (P3 bug): the flat `SelectClassify` prong (c) cross-wire
  over-decline that makes §7 ROLLED-ONLY.
- NEW `xdu2.20` (P3 task): the loop twin matrix has no cell of this shape.
- Related, existing: `xdu2.14` (the `treedata` / guarded-VLA row-4 wall — a
  hoisted `and` that is also read as data), `xqgx` (short-circuit `&&` data select),
  `ztyc` (the branch-phase form).
- Filed by the Rule-13 rounds (not by me): `xdu2.21` (r1A F-A1-1, the derived-leaf
  postcondition wall), `xdu2.22` (r1A F-A1-2), `xdu2.23` (r1B F-B1-2), `xdu2.24`
  (r1B F-B1-4).

## 10. Rule-13 dispositions (r1A + r1B, both `CLEAR-WITH-ITEMS`, 0 P1, 0 P2)

Every item was applied as a COMMENT / RECORD / FIXTURE-HEADER change. **No predicate
and no emitted stream changed**, measured below.

| finding | sev | disposition |
|---|---|---|
| F-A1-1 derived leaf `p = q*q` still declines at the (ii-d) postcondition; record's "derived" twin row was folded by `-O1` | P3 | **filed** bd `xdu2.21` (by r1A); record §5 row corrected in place |
| F-A1-2 post-loop kickback on the same tree: second ROLLED-ONLY family | P3 | **filed** bd `xdu2.22` (by r1A); record §7 population paragraph |
| F-A1-3 success path: new dtzb commitments after the stale fences + new (ii-d) obligations, unstated | P3 | **fixed in comment** at the xdu2.16 block (`LoopLowering.cpp`, "⚠⚠ AND ON THE SUCCESS PATH…", with the ground for each and a retirement trigger for (i)); record §3 |
| F-A1-4 M2 rationale omits clause (iii) | P3 | **fixed in record** (§6 M2 row); no C subject for (iii) — **unmeasured** beyond r1A's attempts |
| F-A1-5 `loopCarriedHandlePhi` header lists four slots; the re-ask is a fifth, post-promotion, sole source of the carried chain for a nulled grant | P3 | **fixed in comment** (header now lists FIVE slots, the backstop paragraph states the fifth is not behind the promotion/mux-guard pair and why that is safe); `LoopPlan.h`'s pointer comment updated to "FIVE". ⚠ `CLAUDE.md`'s "Where Things Live" row still says "asked at FOUR slots" — **not edited by me** (an agent message cannot authorise a `CLAUDE.md` change); flagged for the orchestrator/owner |
| F-A1-6 "102 lowered lines" irreproducible, no command | P3 | **fixed in record** §1/§5: 123 (`wc -l`) / 102 (non-blank), command `xdu2_16_probes/kind.sh`, full diff recorded |
| F-B1-1 the §7 cell has an IR-level twin, 15/15 identical, oracle agrees | P3 | **fixture header** (`…_accept_hoisted_data_rotated.ll`) and record §7 updated; one cell re-measured here; recipe cited on bd `xdu2.20` (by r1B) |
| F-B1-2 ≥4 flat-decline causes, ~50 rolled-only cell-forms | P3 | **filed** bd `xdu2.23` (by r1B); record §1/§7 and the fixture header corrected; pre-existing single-compare asymmetry on the ORACLE recorded |
| F-B1-3 87/510 cell-forms move to the (ii-d) postcondition; new obligations unstated | P3 | **fixed in comment** (same block as F-A1-3, item (ii)); data points added to bd `xdu2.21` (by r1B) |
| F-B1-4 (iii-b) reachable from plain C via a read-only `_unc` borrow; clause comment and record false | P3 | **filed** bd `xdu2.24` (by r1B); clause comment corrected at the source (`invariantRegisterRootsImpl` (iii-b)); record §6 M2 row corrected; **M2 measured** against r1B's program: does NOT distinguish it (`m2_olnone.py`) |

**Probe directories.** `review_r1A_xdu2_16/` and `review_r1B_xdu2_16/` are committed
with their generated OUTPUTS pruned to keep them lean (3877 files, ~10.8 MB): every
`*.s2.ll`, every `*.s1.ll` that has a sibling `.c` it is compiled from, and every
`*.trace` / `*.err` / `*.ea` / `*.eb`. Kept: every `.c`, every hand-written or
recipe-generated `.s1.ll` with no sibling `.c` (e.g. the 270 `unrl/*.k3{m,u}.s1.ll` IR
twins), all scripts, logs, ledgers, the instrumentation patch and both REVIEW.md
files. No built executables were present. Each pruned file is regenerable by the
round's own harness (`probes/h.py`, `probes/unrl/twin_ir.sh`, r1A's `corpus_*.sh`)
against the recorded binaries. A `PRUNED.txt` in each directory says the same.

### 10b. The post-edit binary is behaviour-identical (measured)

- Rebuilt `CQPass` + `cq-opt` after the comment edits (`LoopLowering.cpp.o` recompiled
  for both targets, timestamps checked): `cq-opt` **`b1603d237fc3a739`** and
  `libCQPass.so` **`3001ec9a1cc5bb2a`** — BIT-IDENTICAL to the pre-edit binaries.
- Corpus A/B (`xdu2_16_probes/ab.py`: exit code, stdout sha256, first error line),
  pre-edit `b1603d23` (frozen copy) vs post-edit: null control (pre vs pre) FIRST,
  **0 movers of 2284**; then pre vs post, **0 movers of 2284**, accepts 1135 = 1135.
  (The harness's positive control is the §6 sweep, where the same script reported the
  6 intended D→A movers ORACLE vs SUBJECT.)
- `lit build/ir-pass/test` (full): **2284 discovered, 2283 passed, 1 XFAIL**, 54.9 s.
- `tools/update_code_map.py` regenerated (the comment lines shift function start
  lines in `LoopLowering.cpp`); `--check` exits 0.
- The M2 build used for F-B1-4's measurement was restored and re-hashed to
  `b1603d23` before any of the above.
