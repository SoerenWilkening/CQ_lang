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
  9 more probe cells (§5). **K-independent**: 102 lowered lines at `i < 3` and at
  `i < 1000`.
- **Corpus A/B: 0 A→D, 0 string moves, 0 stream moves**; every mover is an intended
  D→A (§6).
- **One ROLLED-ONLY cell** was found and is adjudicated in §7: the flat half's
  decline is a pre-existing positional over-decline (filed bd `xdu2.19`), the rolled
  circuit is argued correct gate by gate. It is the first thing a reviewer should
  attack.

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
| derived `int p = q*3+1; (p>4)&(r<5)` | IDENTICAL (60) | clean |
| fp leaf `(double q > 1.0) & (r < 5)` | IDENTICAL (60) | clean |
| hybrid `q && m == n`, `q && i < m` | DIFFERENT 36 vs 45 **on BOTH binaries** | clean |
| data-rotated (Ry on the select output) | **ROLLED-ONLY** (§7) | clean |

The two DIFFERENT rows accept on the ORACLE too (rolled and unrolled): `-O1` splits
the rolled `q && m == n` into a classical `select` on `m == n` followed by a quantum
`select` on `q == 0`, while the flat copies keep the fused `and` — two spellings of
one function by the generator, not by this change.

**K-independence**: `slice_loop_condtree_select_hoisted.c` at `i < 3` and `i < 1000`
lowers to 102 lines each; the only diff is the two trip constants (the loop and its
inlined copy in `main`).

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
  | M2 ignore the totality requirement | MISSED | shadowed: a non-total derivation fails on an uncovered Cand, which `railLocalQualifies`' invariant-input clause refuses too; the only clauses it does not re-ask — (iii-b) void writes to a merge out-rail inside `L` — have no constructible subject (that clause's own comment: no emitter builds it) |
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

## 7. The ROLLED-ONLY cell — adjudicated, and the first thing to attack

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
  Prime-Directive red however green the run looks". This row is argued, not
  witnessed: it has no twin gate until the flat half is fixed (bd `xdu2.19`).

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

## 9. Beads

- `xdu2.16`: notes updated, NOT closed (Rule-13 rounds owed).
- NEW `xdu2.19` (P3 bug): the flat `SelectClassify` prong (c) cross-wire
  over-decline that makes §7 ROLLED-ONLY.
- NEW `xdu2.20` (P3 task): the loop twin matrix has no cell of this shape.
- Related, existing: `xdu2.14` (the `treedata` / guarded-VLA row-4 wall — a
  hoisted `and` that is also read as data), `xqgx` (short-circuit `&&` data select),
  `ztyc` (the branch-phase form).
