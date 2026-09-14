# Track U — IMPLEMENTATION brief: the ruled undef-seed-is-zero-at-allocation rule (bd `z9t1`, P1)

Worktree: `/Users/sorenwilkening/Desktop/CQ_undef`, branch `undef-seed-zero` (already created off `main`
607b6fe4; do NOT create it yourself). Records: `$SES/trackU/` **inside your worktree**. Session dir (`$SES`)
= `docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/`;
`$PREV` = `…/session-2026-09-13-orchestrator/`.

**READ FIRST, in this order:** `$SES/PROTOCOL.md` (binding — the gate-ownership matrix, `GATES.md`, the
`cited:`/`ran:` discipline, S1–S3), `CLAUDE.md` (Prime Directive; Rules 1, 3, 12, 13, 14, 17, 19; the
`LiteralIntegrity.cpp` row of Where Things Live), `bd show z9t1` (the ruling verbatim, five clauses),
`$PREV/DIAG_2026-09-14.md` §Q2 (the three measured sites and the `-O1` IR lines).

---

## 1. What is ruled — build EXACTLY this, no more and no less

Owner, 2026-09-14, verbatim: *"we should NOT make every uninitialized variable to 0. Jut before it hits
cq_alloc_*. then clang still can exploid it"* and *"both codes are supposed to compie!! also no warnings."*

1. **SCOPE — the rule attaches to QUBIT ALLOCATION, not to variables.** An `undef`/`poison` **seed** reaching
   a **source** `@cq_theta_<sfx>`'s **arg-0** becomes a concrete **zero of that type** at the allocation. CQ
   makes **no** claim about the C variable and clang keeps every liberty it has — including deleting a branch
   that reads the same uninitialized value (MEASURED: `DIAG_2026-09-14.md` Q2 row iv — an uninitialized `int`
   in a guard makes the guard vanish before the pass runs). That residual is **documented, never fenced**.
2. **BOTH SPELLINGS COMPILE**: `bool b; b = cq_theta(b,.5);` **and** `bool b; if (c) b = cq_theta(b,.5);`
   This FORCES the placement: **normalize EARLY, before classification**, so F1/F2 and every downstream fence
   see a concrete `0`. Normalizing at the emission site is WRONG — there the in-region spelling still dies at
   F1 `state prep seed does not match the merge incoming`.
3. **SILENT.** No warning, no diagnostic, exit 0.
4. **`cq_measure` of a never-quantum uninitialized value KEEPS DECLINING** (bd `21mg`'s fence, landed
   `23b0cd1`). No allocation, no register, nothing quantum — the rule does not reach it. **That asymmetry is
   principled; write that sentence in the source comment.**
5. **NOT TOTAL.** `valueCarriesUndef` is CONSTANT-ONLY, so an undef arriving through a `phi` with an undef
   incoming is not caught and stays exactly as today. Record it as the residual; bd `bwsh` holds it.

**Why this is an improvement, not a loosening — put this in the source comment.** Today the unconditional
shape compiles **silently** and hands `i1 undef` to `cqrt_alloc_i1`, so the starting basis state is whatever
the `-O0` stage-3 link materializes (the trace printed `cqrt_alloc_i1(1)` — a value the program never wrote).
With the rule the rail is deterministically `|0⟩` and every reader of the emitted IR sees **one** constant,
which **REMOVES** the `declineUnpairedUndefLiterals` multi-materialization hazard rather than creating it.

---

## 2. Design constraints

* **Rule 14 — call the one owner.** `valueCarriesUndef` lives in `LiteralIntegrity.cpp` and is the shared
  predicate; CALL it, do not re-spell it. If it is not exported where you need it, export it — do not copy it.
* **Placement.** "Early, before classification" means before `detectControlRegions` / `MergePhiPeel` in
  `CQLoweringPass::run` **in BOTH entry points** if there are two. You decide the exact site (a candidate is
  the `cq_*` collection/prototype-validation step in `TaintPropagation.cpp`, another is a tiny normalizer
  called from the orchestrator before `propagate()`); **report the site and the reason in your IMPL report.**
  ⚠ L1 applies: control detect+lower runs TWICE (`repropagateControlMerges`). A normalizer that runs once
  before round 1 is fine **iff** nothing can introduce a NEW undef seed between the rounds — state whether
  that is true, with the argument, or run it in both entry points.
* **SOURCE only.** A `cq_theta` whose arg-0 is a constant `undef`/`poison` is by construction a SOURCE (undef
  carries no taint). Do not touch a CHAINED theta's arg-0 (it is an SSA handle, not a constant).
* **Arg-1 is the ANGLE and is never touched** (Rule 3). An `undef` ANGLE is out of scope for this increment —
  measure what it does today and report it; do not change it.
* **`cq_phi`** carries no register and is untouched.
* **`cq_measure`** is untouched (clause 4).
* Zero of the right type: `Constant::getNullValue(ArgTy)` — covers `i1`…`i64` and the fp widths (`+0.0`).
  Check what `CQ.h`'s 14 types actually reach arg-0 and cover them all, or state precisely which you cover.

---

## 3. Rule 12 — red-green, fixtures FIRST

Write these before the code, watch them fail, then implement minimally.

**lit fixtures** (`ir-pass/test/*.ll`, positive `CHECK` + negatives; remember §3's hygiene rules — counts in
their own whole-file prefix, negatives pure, and run `$PREV/trackM/probes/impl/vacuity.py` over the batch):

| # | shape | expected |
|---|---|---|
| U1 | `call i1 @cq_theta_i1(i1 undef, double 5.0e-01)` uncontrolled | ACCEPT, `cqrt_alloc_i1(i1 false)`, **no `undef` anywhere in the emitted module** |
| U2 | the same with `poison` | ACCEPT, identical |
| U3 | the in-region spelling (the `u2.c` module from `$PREV/diag_2026-09-14_probes/`) | ACCEPT, the state prep lowers |
| U4 | an `iN` / fp width other than `i1` (pick at least one integer > 1 and one fp) | ACCEPT, `getNullValue` of that type |
| U5 | **NEGATIVE** — `cq_measure` of an `undef`: the `21mg` string, mirrored character-for-character | DECLINE, exit non-zero |
| U6 | **NEGATIVE/residual** — a `phi i1 [ undef, %a ], [ %x, %b ]` reaching arg-0 | UNCHANGED from today; measure today's verdict on the ORACLE first and pin THAT |
| U7 | a CHAINED theta on a normalized rail | ACCEPT, unchanged stream |

**e2e slices** (`tests/e2e/`, + `CMakeLists.txt` registration + golden):
* `slice_undef_seed_uncontrolled.c` = customer **C2a** `bool b; b = cq_theta(b,.5); … cq_measure(b);`
* `slice_undef_seed_in_region.c` = customer **C2b** `bool b; if (c) b = cq_theta(b,.5); …`
Both must run STRICT stage 2b. The golden must show the seed as the normalized constant.

**Must stay byte-identical** (re-run these slices, they are the discriminators):
`slice_measure_classical_bool` (the `21mg` pair, C3 — MUST KEEP DECLINING),
`lowering_accept_undef_literal_single_slot.ll`, every `declineUnpairedUndefLiterals` fixture,
`slice_control_cascade_two_bools.expected.log` (29 lines), `va` (19).
⚠ `lowering_accept_undef_literal_single_slot.ll` is the committed certificate that ONE occupied undef slot is
sound. If your normalizer changes it, STOP and report — that fixture is a ruling, not a detail.

---

## 4. Gates you own (PROTOCOL §matrix — do not exceed it)

Configure + build your worktree ONCE per edit batch:
```
cmake -S . -B build -DLLVM_DIR=$(brew --prefix llvm@19)/lib/cmake/llvm -DCMAKE_BUILD_TYPE=Release
cmake --build build -j8            # NEVER --target CQPass alone
shasum -a 256 build/ir-pass/cq-opt # record in $SES/trackU/GATES.md after EVERY rebuild
```
Inner loop: `cd build && lit -v ir-pass/test --filter '<name>'` and `ctest --test-dir build -R
'^e2e-slice-<name>$'`. **ONCE at hand-off:** `ctest --test-dir build -R ir-pass-lit`, one corpus sweep
ORACLE-vs-SUBJECT (`$PREV/../session-2026-09-11-orchestrator/review_integration_probes/corpus.sh`; corpora =
`ir-pass/test/*.ll` + every session `probes/` dir listed in PROTOCOL) written to
`$SES/trackU/probes/corpus_<hash16>.txt`, and one injection/mutation matrix over your new accept fixtures
with the MISSED count reported. **NEVER** `^e2e-`, **NEVER** the full suite, **NEVER** the equivalence sweep.

⚠ Your expected corpus movers, for the group gate's per-track attribution: rows whose ORACLE verdict was an
ACCEPT emitting `undef` into an alloc, and rows whose ORACLE verdict was an F1
`state prep seed does not match the merge incoming` on an **undef** seed. **Any other mover is a FINDING** —
report it, do not explain it away.

---

## 5. Deliverables

Into `$SES/trackU/` in your worktree: `IMPL_U.md` (the site chosen + why, the L1 argument, the diff summary,
every fixture with its verdict, the measured before/after on the DIAG probes `u1`–`u5`/`u3b`/`u4b`, the
corpus movers table, the mutation MISSED count, the residual statement for clause 5, and every gate line as
`ran:`/`cited:`), `GATES.md` (hash-keyed), `probes/` (your `.c`/`.ll` probes + the corpus file).

**Commit on your branch** (do NOT push, do NOT touch `main`). Message: `feat(rotation): bd z9t1 — …`, ending
with the two trailers from `CLAUDE.md`'s attribution reminder:
`Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>` and
`Claude-Session: https://claude.ai/code/session_013Hi5y8TF8WpYRVVqZH21Vo`.

Then report to the orchestrator: the branch tip hash, the binary hash, every gate line, the fixture table,
and anything you could not do. **Rule 17: if the real lowering proves hard, bring the question back — do not
ship a decline-only stub.** **Rule 19: report only what you ran.**
