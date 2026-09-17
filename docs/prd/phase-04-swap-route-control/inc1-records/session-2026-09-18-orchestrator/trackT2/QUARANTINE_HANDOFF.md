# QUARANTINE HANDOFF — Group-1 (Track T2) → the merge-and-gate agent

Branch **`tu9q-hoisted-template`**, tip `bfb809be` (+ the fixture-hardening commit), `cq-opt`
`7c1163ad9 4d0632007566867a4a71bc7de9377352cddc4158425e41532594326`.

---

## §0 — THE HEADLINE, AND IT IS NOT THE ONE SCOPE_T2 §3.2 PREDICTED

SCOPE_T2 §3.2 hands the merge agent **12 `oder` rows to re-measure** and says the six class-A cells
*"stay QUARANTINED with NEW signatures"*. **I did not measure a single quarantine row, and I am
not handing over numbers I did not take.** Track V owns `tools/loop_twin_matrix*`; the twin
matrices are the merge-and-gate agent's gate (PROTOCOL gate matrix: *implementer — twin matrices —
"only if in-loop code lands"*, and the row above it assigns the matrices to the merge agent).
Running them here would have been a second run of another owner's gate at a hash that owner has
not seen — the §6.1 violation this session's protocol was written to stop.

**What this file hands over instead is the EXPECTATION with its derivation**, so the merge agent
can tell a cell that moved *because of this branch* from a cell that moved for another reason.

---

## §1 — WHAT THIS BRANCH IS EXPECTED TO MOVE IN THE MATRIX, AND WHY

The landed prefix is **P1 + P2**. P0 and P3 did **not** land (they are on `tu9q-p0-p3-wip`,
`30b80d7f`, NOT for merge — see `IMPL_T3.md` §5). So the matrix expectation is P2's, not P3's.

### The six `oder` class-A cells (bd `1m5p`)

| cell | ORACLE `9bd01598` | expected on this branch | the derivation |
|---|---|---|---|
| `m_none_oder_none_none_none` | rolled **25** / twin **27**, `sqrt_f64_unc` **0 vs 1** | **27 == 27**, `sqrt_f64_unc` **1 vs 1** | MEASURED directly on the probe pair (`GATES.md`), not inferred: trace **MULTISET IDENTICAL** with handle numbers normalised |
| `m_none_oder_none_none_addpost` | class A | same shape | same mechanism — the hoisted chain gains a loop-exit discharge |
| `m_none_oder_none_none_rypost` | rolled **27** / twin **29**, `sqrt_f64_unc` **0 vs 1** | **29 == 29** | MEASURED on the ORACLE at scoping; the delta is the same chain |
| `m_none_oder_none_none_rypre` | class A | same shape | same |
| `m_none_oder_none_none_rzpost` | class A | same shape | same |
| `m_none_oder_rpostmark_none` | class A | same shape | same |

⚠ **THEY DO NOT LEAVE QUARANTINE.** The rolled and unrolled forms become **multiset-identical and
ORDER-divergent**: the rolled form discharges the hoisted chain at the LOOP EXIT, the twin at
function scope after the second region. A `compare_files` twin gate would still be RED. The new
argument each row carries is *"ROLLED IS NO LONGER DEFICIENT; the divergence is POSITIONAL only"*,
which is SCOPE_T2 §3.2's own wording and is now backed by a measurement rather than a forecast.

### ⚠ RE-MEASURE ALL TWELVE `oder` CELLS, NOT SIX

SCOPE_T2 §3.2 is explicit and it is worth repeating because the temptation is to touch only the
six: the `m_none_oder_add_*` SIX are **class B** (bd `a3z7`), their digests pin the class-B
divergence, and **if class A is fixed underneath them their digests may still move**. A class-B row
whose signature moved is not evidence about class B.

### Every signature must be FRESHLY MEASURED, never transcribed

The quarantine pins `(verdict, SHA-256 of the exact unified diff)`. Those hashes are facts about a
binary and a pair of streams; two of the six have no recorded digest at all in SCOPE_T2 §3.2 (the
table says "—"). **Take all twelve fresh.**

---

## §2 — WHAT ELSE THE MERGE AGENT SHOULD EXPECT FROM THIS BRANCH

* **`ir-pass-lit`: 0 FAIL** at the branch tip (run here once, in `GATES.md`).
* **`^e2e-`: NOT RUN HERE, and this branch adds NO e2e entry** — `tests/e2e/CMakeLists.txt` is
  **untouched**, so there is no tail-anchor conflict to resolve from Group 1 and the three
  post-union checks have nothing of mine to reconcile. That is a gap against SCOPE_T2 §5, stated
  as such in `IMPL_T3.md` §6.2, not a claim of completeness.
* **Goldens: NONE touched.** No `tests/e2e/*.expected.log` is added, removed or regenerated.
* **A corpus sweep ORACLE-vs-SUBJECT** is in `probes/corpus_7c1163ad94d06320.txt`, with movers
  attributed by string in `GATES.md`.

⚠ **`e2e-loop-twin-matrix` IS THE ONLY INSTRUMENT IN THE TREE THAT CAN SEE WHAT THIS BRANCH
CHANGES.** Every rail this increment discharges is TEMPLATE-minted, and stage 2b is structurally
blind to those (no `cqrt_alloc` to count) — worse, for a discharge at a JOIN or a LOOP EXIT it
reports `U3-extern-rail` **UNPROVEN** rather than verified, because its model is per straight-line
STREAM. So a green stage 2b says nothing here in either direction, and the matrix is load-bearing.

---

## §3 — SEQUENCING

SCOPE_T2 §7 states it and it still holds: **Track V must land before Group 1's merge gate**, or
the quarantine selftest and `e2e-loop-twin-matrix` go red for two unrelated reasons at once.
