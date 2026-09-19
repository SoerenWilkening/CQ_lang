# bd `fn1q` increment 5a — THE RAIL φ at E6. ⚠ THE OWNER'S PROGRAM COMPILES.

```
ORACLE  4db66534  a0e31e03…   (predates increments 3, 4, cfmv and 5a)
```

## 0. ⚠ THE OWNER RULED THE QUESTION, AND THE QUESTION I ASKED WAS THE WRONG ONE

I brought this back as *"which cost do we carry — claim-then-decline, or a pre-claim
test that over-declines?"* The owner's answer reframed it:

> **"Does it have to be declined by physics? if not we HAVE to make it compile!!"**

That is the 2026-09-11 ruling restated, and it is the operative test. **Answer: no.** The
shape in question is a rail φ under a CLASSICAL branch — a classical choice between two
circuits, rail-controlled on one path and constants on the other. No superposed
condition, no no-cloning problem, no dirty rail; it is realizable. So the decline was
COMPILER STRUCTURE, not physics, and it must go.

⚠ **THE STANDING LESSON FOR THE NEXT AGENT WHO WANTS TO ASK THE OWNER A QUESTION:** ask
*"is there a physics reason?"* first. A question phrased as a trade-off between two
dispositions PRESUPPOSES that declining is on the table, and for a realizable circuit it
is not.

## 1. THE RESULT

`tests/e2e/slice_grover_oracle_uncompute.c` — `example/grover/grover_oracle_uncompute.c`
verbatim, `bool b0[n]`, no workaround:

```
opt              exit 0, stderr 0 BYTES
lowered          128 lines, loop still ROLLED
stage 2b STRICT  7 rail mint(s) of which 5 left allocated,
                 3 template rail mint(s) of which 2 left dirty,
                 3 cqrt_free site(s): 3 verified, 0 violation(s), 0 unproven
run              88 trace lines
K-INDEPENDENT    117 lowered lines at n = 3, 8, 64 and 1000
```

⚠ **THE K-INDEPENDENCE MEASUREMENT HAS A PROBE TRAP IN IT, RECORDED BECAUSE I WALKED INTO
IT.** Bumping `n` ALONE makes `z[i]` read past the end of a 3-element table, and E4's
bounds proof then correctly refuses — which reads exactly like a K-dependent accept. It is
not: it is a probe without the shape it claims (bd `46oo`'s class). The figures above scale
the TABLES with `n`.

## 2. THE MECHANISM, AND WHY THE PREDICATE IS SPELLED THE WAY IT IS

`promoteRailBankCells` (`CQLoweringPass.cpp:196`) runs long before
`flattenPredMuxRegions` (`:374`), so by the time E6 looks, `if (b0[i])` is
`%cq.bank1 = phi i1 [ %31, %30 ], [ false, %23 ]` and the gate saw `E6-condtree`.

E6 **cannot** ask `preppedRailPhiRegionIdx` — `detectControlRegions` is at `:582`, so no
`ControlPlan` exists. And the obvious fallback, *"is the φ's defining branch TAINTED?"*, is
**refuted by measurement**: the owner's own prep branch is untainted at that slot. A taint
test at E6 would have refused the very program this bead exists for.

So `isStructuralRailPhi` asks the strongest thing provable with no plan and no taint:
`isCondRailPhiShape` **and** every incoming is a rail CALL (`isCondRailLeaf`) or an `i1`
CONSTANT. Both halves are CALLS to shipped predicates, not re-derivations (Rule 14).

⚠ **NECESSARY, NOT SUFFICIENT, AND THAT IS DELIBERATE.** A φ this admits may still be
refused downstream. Measured: the classical-prep spelling declines with the SAME verdict,
SAME string and SAME diagnostic as before — a decline cannot become silence. What it costs
is DETECT-BEFORE-MUTATE for that one shape, which is precisely the cost bd `cfmv`'s
Rule-13 round 2 filed as R4R2-1, and it is taken KNOWINGLY and written at the call site.

## 3. L8 WORKED — A RETIREMENT TRIGGER WAS CHARACTER-FOR-CHARACTER CORRECT

`control_predmux_reject_rail_phi_cond.ll` was written at increment 2 with a CORRECTED
trigger: *a tainted-prep rail φ will ACCEPT when this increment lands; a CLASSICAL-prep one
will STILL DECLINE, because the downstream needs a claimed region and a classical-condition
prep is not one.* Measured on the landed binary: **exactly that.** A trigger written with
its measurement was right about a binary that did not exist yet. Write them.

## 4. GATES

| gate | result |
|---|---|
| `lit ir-pass/test` | **2153 discovered**, green bar the 1 standing XFAIL, **zero existing fixtures changed** |
| corpus A/B vs the pre-session oracle, all 2153, null control first | **A→D = 0** · D→A = 8 · decline-string = 1 · stream-moves = 2 |
| stage 2b STRICT on the owner's slice | `3 verified, 0 violation(s), 0 unproven` |

Of the A/B movers, increment 5a contributes exactly ONE — its own new accept fixture. The
two stream moves are bd `cfmv`'s own fixtures; the decline-string move is increment 3's
re-derived `leave_inloop`.

## 5. STILL OPEN — INCREMENT 5b, AND IT IS AN OVER-DECLINE BY THE OWNER'S RULING

A prep under a CLASSICAL condition still declines. By the ruling above that is a DEFECT to
remove, not a boundary. The route is visible and has precedent: promote the constant
incoming to a `|0⟩` rail handle so the φ becomes a HANDLE mux under a classical condition —
the `RailBankPromote` idiom bd `zujr` already uses for the loop-carried case, where a `|0⟩`
control correctly means "this arm never fires". Filed, not hand-waved.

### 4b. THE RUN OF RECORD

```
SUBJECT cq-opt d7430d2faa2111dbf8b0bb7d8709ad7d…
```

| gate | result |
|---|---|
| full `ctest -j6` | **479/479 in 731.62 s** — ⚠ load **3.36 → 42.89**, run CONCURRENTLY with the Rule-13 agent. NOT comparable with a quiet-box figure (Rule 19). |
| `lit ir-pass/test` | **2153 discovered**, green bar the 1 standing XFAIL |

Counts: ctest **479** · fixtures **2153** · goldens **412** (⚠ includes
`e2e-slice-grover-oracle-uncompute`, the owner's own program, under test for the first
time).
