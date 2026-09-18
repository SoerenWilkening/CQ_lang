# bd `fn1q` increment 3 — E2's IN-LOOP ADMISSION (measured)

```
ORACLE   main 4db66534
         cq-opt a0e31e0316496f71a6843cf8c31aebb81bcfbdc6fea162b5d34c0d32cc4d000b
```
⚠ The oracle was REBUILT FROM SCRATCH in a clean worktree at `4db66534` and came out
**BIT-IDENTICAL** to the hash the 2026-09-23 brief recorded. Every A/B row below is that
binary against the subject.

⚠ **CLOCK NOTE.** The system clock on this machine reads **2026-09-18**, while this
record chain runs to `session-2026-09-23-orchestrator`. The directory is named for
sequence position, not for the clock; nothing in this increment depends on a date.

⚠ **ONE RECORDED HASH DID NOT REPRODUCE AND IT IS NOT `cq-opt`.** The brief records
`libCQPass.so 7920b44cc1ac809b8c51…`; a from-scratch build at the same commit gives
`4088a779f4dfdb25e798…`. `cq-opt` — the binary every lit RUN line and every A/B here
uses — reproduces exactly, twice, in two trees. Treat the `.so` hash as unreliable
(a non-reproducible link), not as evidence of a dirty tree.

---

## 1. THE SUBJECT, AND IT EXISTS ONLY BECAUSE INCREMENT 2 LANDED

`probes/inc3/e2_only_subject.c` (committed by the previous session). Measured on the
oracle: `gate=E2-cycle` **and nothing else**, then the loud `control flow` decline.

## 2. WHAT E2 WAS, AND WHAT IT IS NOW

The gate was one clause — `for (B : R.InRegion) if (OnCycle.count(B)) leave("E2-cycle")`.
The PRD (§4.2) records it as a SCOPING choice, not a proven fence: *"PredMux is
loop-orthogonal by E2; if 7.3+ later unrolls a bounded loop into an acyclic region,
PredMux composes for free — noted, not designed here."*

It is now: **ask the question only when some region block is on a cycle**, and then
admit exactly a region lying STRICTLY INSIDE ONE LOOP BODY. Five refusals, each
NAMED so a fixture can pin it individually (bd `e1gr`):

| clause | gate name | reachable? | pinned by |
|---|---|---|---|
| (a)/(e-outer) entry in no natural loop (incl. a region that CONTAINS a loop) | `E2-cycle` | yes | `lowering_ctlz_idiom_guarded_no_preshift.ll` (pre-existing) |
| (b) the header as a NON-ENTRY region block | `E2-loopheader` | **NO — measured** | nothing; see §5 |
| (c) the MERGE is the loop header (the flatten would make a BACK EDGE unconditional) | `E2-loopbackedge` | yes | `control_predmux_reject_inloop_backedge_merge.ll` |
| (d) a block or the merge is not in `L` (inner loop, or a TAINTED LOOP EXIT) | `E2-loopstraddle` | yes, **both halves** | `…_reject_inloop_tainted_exit.ll`, `…_reject_inloop_inner_loop.ll` |
| (e-inner) an IRREDUCIBLE cycle wholly inside `L` | `E2-regioncycle` | yes | `…_reject_inloop_irreducible.ll` |

⚠ **(e-inner) IS THE CLAUSE THAT CANNOT BE DROPPED AS REDUNDANT.** An irreducible cycle
inside `L` reports `L` for every one of its blocks, so (b), (c) and (d) all PASS on it.
Only the Kahn proof sees it — which is why E2 calls `topoOrderRegion` itself instead of
leaving it to the tail of `recoverRegion`, where it would be a silent `return false`
with no gate name.

## 3. ⚠ THE FIRST DRAFT REFUSED ITS OWN SUBJECT, AND THE LESSON IS THE GENERAL ONE

The first spelling of clause (b) refused a region whose ENTRY is the loop header. It is
wrong: `clang -O1` puts the `cq_theta` and the tainted `br` IN the header block, so
**the shape this increment exists for is a header-entry region** — measured,
`gate=E2-loopheader` on `e2_only_subject.c` itself.

It is safe for the reason every other entry is: the flatten APPENDS to the entry's body
and rewrites only its TERMINATOR, so the header keeps its phis, its incoming edges and
its position. The two things a header entry could additionally reach are owned
elsewhere and were measured: a region that swallows the LATCH makes `InDeg[Entry] != 0`
(→ `E2-regioncycle`), and a header entry whose branch is the loop's own tainted EXIT
fails (d) on the merge.

**The general lesson, which is this bead's own, paid a third time:** when you replace a
STRUCTURAL containment with predicates, ENUMERATE WHAT THE STRUCTURE WAS HOLDING — and
then check the enumeration against the subject, because an over-tight clause fails
CLOSED and therefore looks like "still declining" rather than like a bug.

## 4. THE WITNESS — `br` AND `select` EMIT THE SAME STREAM

The axis is `br` vs `select` and `-O1` picks it. MEASURED on one program: at **two and
three** carried variables `-O1` if-converts the arm and the region never reaches PredMux;
at **four** it emits the `br` diamond. So the widening puts a `br` spelling onto a path
the compiler was ALREADY lowering.

* **IR level, byte-identical:** `control_predmux_accept_inloop_value_diamond.ll` vs
  `…_twin.ll` — **24 calls, `diff` empty**, guarded by `test -s`.
* **e2e level, identical after a handle rename:** the two goldens agree byte for byte
  over **lines 7..118 (112 lines)** once `h4<->hA …` is applied. Lines 1..6 are four
  `cqrt_alloc_i32(5)` seed mints that `-O1` numbers in the OPPOSITE order for the two
  spellings; four independent allocations of one literal onto four fresh registers
  commute. Excluded BY LINE RANGE, never by a wildcard.
* **the pre-existing FP in-loop diamond:** its per-trip stream is **byte-identical (13
  calls)** to the committed loop-free accept `control_predmux_accept_fp_diamond_solephi.ll`.
  The rolled form is the general trip of the flat form.

⚠ **THE ROLLED-vs-UNROLLED TWIN IS NOT USABLE FOR THIS SHAPE AND THAT IS MEASURED, NOT
ASSUMED.** With constant seeds `-O1` const-folds the unrolled arithmetic outright; with a
`volatile` seed it still folds **4 of 12** `add`s into literal `cqrt_alloc` seeds, so the
unrolled program is not the same circuit. This is this bead's own recorded trap ("THE TWIN
PROVES NOTHING"). The `br`-vs-`select` twin is the witness; the rolled-vs-unrolled one is
reported below as a FENCE check only.

## 5. THE STANDING PROBE (a TRAILING non-diagonal gate on every register the condition reads)

`probes/inc3/trail_rolled.c` / `trail_unrolled.c` — `q = cq_theta(q, 0.9)` after the loop,
on the condition's own register.

| | ORACLE | SUBJECT |
|---|---|---|
| rolled | `control flow` (E2 refused) | **`condition predates a non-diagonal gate`** |
| unrolled | `condition predates a non-diagonal gate` | `condition predates a non-diagonal gate` |

**The rolled form now declines at the SAME 2c fence its unrolled twin hits, on both
binaries.** The widening does not open the bd `s82e` / Q-R1-1 door for this shape; the
condition-wire fence owns it in both spellings.

Without the trailing gate both spellings accept and stage 2b is STRICT-clean both ways
(`4 verified, 0 violation(s), 0 unproven` rolled). ⚠ Say the leak honestly: the rolled
form leaves **4 template rail mints dirty** (the hoisted adds) and the unrolled form
leaves **8** — on the ORACLE. The class is pre-existing and present in BOTH spellings;
this shape adds customers to it, and the accepting door is closed by 2c the moment a
later non-diagonal gate touches the condition's register.

## 6. OTHER SHAPES MEASURED

| shape | ORACLE | SUBJECT |
|---|---|---|
| region inside the INNER loop of a NEST | `control flow` (E2-cycle) | CLAIMED, then **`loop lowering: loop-carried tainted value crosses iterations`** — still a loud decline |
| tainted `switch` inside a loop, **straight-line arms** | `control flow inside a loop body` (W-witness) | **IDENTICAL** — the W witness refuses before E2 |
| tainted `switch` inside a loop, **arm hosting further tainted control** | `control flow inside a loop body` | ⚠ **ACCEPT.** The `NestedTainted` witness fires, so W does NOT refuse and E2 was the gate that used to. Correct circuit (4-way mux, loop-free twin already accepts on the ORACLE), 2b `11 verified, 0 violation(s)`. Fixtured as `control_predmux_accept_inloop_switch_nested.ll` |
| a function with **NO REACHABLE `ret`** (degenerate post-dominance) | `control flow` (E2-cycle) | ⚠ **ACCEPT**, region claimed and flattened, 2b `2 verified, 0 violation(s)`. Sound by E3+Kahn whatever block the degenerate merge names. Fixtured as `control_predmux_accept_noreturn_degenerate_merge.ll` |
| `control_predmux_leave_inloop.ll` (multi-arm nest round a carried accumulator) | `nested control flow` | CLAIMED, then `loop-carried tainted value crosses iterations` — decline preserved, owner moved |
| `control_predmux_leave_fp_diamond_inloop.ll` | `control flow` | **ACCEPT** — see §4 |

## 7. CORPUS A/B — NULL CONTROL RUN FIRST

Every one of the 2136 `ir-pass/test/*.ll` fixtures, oracle against subject, comparing
exit code, decline text, and the emitted `cqrt_*` / `cq_template_*` call stream.

```
[NULL-CONTROL]       n=2136  A->D=0  D->A=0  decline-string-moves=0  stream-moves=0
[ORACLE-vs-SUBJECT]  n=2136  A->D=0  D->A=2  decline-string-moves=1  stream-moves=0
--- movers ---
D->A  control_predmux_accept_inloop_value_diamond.ll     (this increment's own new accept)
D->A  control_predmux_leave_fp_diamond_inloop.ll         (§4 — byte-identical to the loop-free accept)
STR   control_predmux_leave_inloop.ll                    (decline PRESERVED, owner moved)
```

**`A->D=0` and `stream-moves=0`.** Nothing that compiled stops compiling, and no existing
accept's emitted stream changed by a single call. All three movers are accounted for above
and each has been re-derived in its own fixture.

⚠ **THE A/B ALSO PROVES THE TWIN'S OWN CLAIM, WHICH NO LIT RUN LINE CAN.**
`control_predmux_accept_inloop_value_diamond_twin.ll` is **NOT in the movers list** — it
accepts on the ORACLE and on the SUBJECT with an identical stream. That is what makes the
sibling's `diff` an INHERITANCE rather than a tautology, and it is measured, not argued.

⚠ **THE NULL CONTROL'S OWN TRAP, RECORDED BECAUSE IT NEARLY READ AS A FAILURE.** The sweep
script ends with `[ -f "$OUT/movers" ] && { … }`, so with NO movers its LAST COMMAND returns
1 and the whole script exits 1 — a clean null control reported as "failed". The result line
is the measurement; the exit code is the script's last test. This is CLAUDE.md's own
`rc=$?`-after-a-pipeline lesson in a second spelling: **a harness's exit status is not a
verdict unless the harness was written to make it one.**

## 8. GATES — measured, with the wording Rule 19 requires

```
SUBJECT cq-opt 63d34f76ab57d228a77614a2a9d498e73982cdcc4931e381767f3998a1538817
```

| gate | result |
|---|---|
| `lit ir-pass/test` | **2136 discovered, 2135 passed, 1 XFAIL** |
| full `ctest -j6` | **477/477 in 578.14 s** — ⚠ **load 3.65 -> 31.55**, run CONCURRENTLY with the independent Rule-13 agent. Not comparable with a quiet-box figure. |
| corpus A/B | §7 — null control clean, `A->D=0`, `stream-moves=0` |
| count gate mutation (`grep \| count 4` -> 3 and -> 5) | BOTH fail; 4 passes. Closed in both directions. |
| twin gate mutation (wrong rename map; shifted line range) | BOTH fail. |
| stage 2b STRICT on the new slice | `4 verified, 0 violation(s), 0 unproven` |

Count chain, re-measured (not copied):

| quantity | before | after |
|---|---|---|
| ctest | 474 | **477** |
| `^e2e-` | 464 | **467** |
| `^e2e-slice-` | 406 | **408** |
| `twin-identical` | 44 | **45** |
| `ls ir-pass/test/*.ll` | 2130 | **2136** |
| `ls tests/e2e/*.expected.log` | 408 | **410** |

⚠ **§2's CLAUSE TABLE AND §6's SWITCH ROW WERE BOTH CORRECTED BY THE RULE-13 ROUNDS —
read `REVIEW_R13_R1_INC3.md` and `REVIEW_R13_R2_INC3.md` BEFORE quoting either.** In
particular: clause (b) IS reachable (§2 said it was not), the whole predicate is
REDUNDANT over every module anyone has constructed (R2-1), and what fences the shipped
in-loop owners is `W-witness` — not E2, and not E4 as round 1's own correction claimed
(R2-2).

⚠ **WHAT IS NOT ESTABLISHED (Rule 2, in the words it has to be said in).** This is exit
codes, gate streams, stage-2b rail identities, emitted traces, twin identity and analytic
reasoning. **There is no simulator.** The independent opinion is the Rule-13 round's, and
its own "WHAT I DID NOT DO" section is the boundary of this clearance.
